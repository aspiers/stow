#!/usr/bin/perl

#
# Utilities shared by test scripts
#

package testutil;

use strict;
use warnings;

use Carp qw(croak);
use File::Basename;
use File::Path qw(remove_tree);
use File::Spec;
use Test::More;

use Stow;
use Stow::Util qw(parent canon_path);

use base qw(Exporter);
our @EXPORT = qw(
    $OUT_DIR
    init_test_dirs
    cd
    new_Stow new_compat_Stow
    make_dir make_link make_invalid_link make_file
    remove_dir remove_link
    cat_file
    is_link is_dir_not_symlink is_nonexistent_path
);

our $OUT_DIR = 'tmp-testing-trees';

sub init_test_dirs {
    for my $dir ("$OUT_DIR/target", "$OUT_DIR/stow") {
        -d $dir and remove_tree($dir);
        make_dir($dir);
    }

    # Don't let user's ~/.stow-global-ignore affect test results
    $ENV{HOME} = '/tmp/fake/home';
}

sub new_Stow {
    my %opts = @_;
    $opts{dir}    ||= '../stow';
    $opts{target} ||= '.';
    $opts{test_mode} = 1;
    return new Stow(%opts);
}

sub new_compat_Stow {
    my %opts = @_;
    $opts{compat} = 1;
    return new_Stow(%opts);
}

#===== SUBROUTINE ===========================================================
# Name      : make_link()
# Purpose   : safely create a link
# Parameters: $target => path to the link
#           : $source => where the new link should point
#           : $invalid => true iff $source refers to non-existent file
# Returns   : n/a
# Throws    : fatal error if the link can not be safely created
# Comments  : checks for existing nodes
#============================================================================
sub make_link {
    my ($target, $source, $invalid) = @_;

    if (-l $target) {
        my $old_source = readlink join('/', parent($target), $source) 
            or die "$target is already a link but could not read link $target/$source";
        if ($old_source ne $source) {
            die "$target already exists but points elsewhere\n";
        }
    }
    die "$target already exists and is not a link\n" if -e $target;
    my $abs_target = File::Spec->rel2abs($target);
    my $target_container = dirname($abs_target);
    my $abs_source = File::Spec->rel2abs($source, $target_container);
    #warn "t $target c $target_container as $abs_source";
    if (-e $abs_source) {
        croak "Won't make invalid link pointing to existing $abs_target"
            if $invalid;
    }
    else {
        croak "Won't make link pointing to non-existent $abs_target"
            unless $invalid;
    }
    symlink $source, $target
        or die "could not create link $target => $source ($!)\n";
}

#===== SUBROUTINE ===========================================================
# Name      : make_invalid_link()
# Purpose   : safely create an invalid link
# Parameters: $target => path to the link
#           : $source => the non-existent source where the new link should point
# Returns   : n/a
# Throws    : fatal error if the link can not be safely created
# Comments  : checks for existing nodes
#============================================================================
sub make_invalid_link {
    my ($target, $source, $allow_invalid) = @_;
    make_link($target, $source, 1);
}

#===== SUBROUTINE ===========================================================
# Name      : make_dir()
# Purpose   : create a directory and any requisite parents
# Parameters: $dir => path to the new directory
# Returns   : n/a
# Throws    : fatal error if the directory or any of its parents cannot be
#           : created
# Comments  : none
#============================================================================
sub make_dir {
    my ($dir) = @_;

    my @parents = ();
    for my $part (split '/', $dir) {
        my $path = join '/', @parents, $part;
        if (not -d $path and not mkdir $path) {
            die "could not create directory: $path ($!)\n";
        }
        push @parents, $part;
    }
    return;
}

#===== SUBROUTINE ===========================================================
# Name      : create_file()
# Purpose   : create an empty file
# Parameters: $path => proposed path to the file
#           : $contents => (optional) contents to write to file
# Returns   : n/a
# Throws    : fatal error if the file could not be created
# Comments  : detects clash with an existing non-file
#============================================================================
sub make_file {
    my ($path, $contents) = @_;

    if (-e $path and ! -f $path) {
        die "a non-file already exists at $path\n";
    }

    open my $FILE ,'>', $path
        or die "could not create file: $path ($!)\n";
    print $FILE $contents if defined $contents;
    close $FILE;
}

#===== SUBROUTINE ===========================================================
# Name      : remove_link()
# Purpose   : remove an esiting symbolic link
# Parameters: $path => path to the symbolic link
# Returns   : n/a
# Throws    : fatal error if the operation fails or if passed the path to a
#           : non-link
# Comments  : none
#============================================================================
sub remove_link {
    my ($path) = @_;
    if (not -l $path) {
        die qq(remove_link() called with a non-link: $path);
    }
    unlink $path or die "could not remove link: $path ($!)\n";
    return;
}

#===== SUBROUTINE ===========================================================
# Name      : remove_file()
# Purpose   : remove an existing empty file
# Parameters: $path => the path to the empty file
# Returns   : n/a
# Throws    : fatal error if given file is non-empty or the operation fails
# Comments  : none
#============================================================================
sub remove_file {
    my ($path) = @_;
    if (-z $path) {
        die "file at $path is non-empty\n";
    }
    unlink $path or die "could not remove empty file: $path ($!)\n";
    return;
}

#===== SUBROUTINE ===========================================================
# Name      : remove_dir()
# Purpose   : safely remove a tree of test files
# Parameters: $dir => path to the top of the tree
# Returns   : n/a
# Throws    : fatal error if the tree contains a non-link or non-empty file
# Comments  : recursively removes directories containing softlinks empty files
#============================================================================
sub remove_dir {
    my ($dir) = @_;

    if (not -d $dir) {
        die "$dir is not a directory";
    }

    opendir my $DIR, $dir or die "cannot read directory: $dir ($!)\n";
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (@listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $path = "$dir/$node";
        if (-l $path or -z $path or $node eq $Stow::LOCAL_IGNORE_FILE) {
            unlink $path or die "cannot unlink $path ($!)\n";
        }
        elsif (-d "$path") {
            remove_dir($path);
        }
        else {
            die "$path is not a link, directory, or empty file\n";
        }
    }
    rmdir $dir or die "cannot rmdir $dir ($!)\n";

    return;
}

#===== SUBROUTINE ===========================================================
# Name      : cd()
# Purpose   : wrapper around chdir
# Parameters: $dir => path to chdir to
# Returns   : n/a
# Throws    : fatal error if the chdir fails
# Comments  : none
#============================================================================
sub cd {
    my ($dir) = @_;
    chdir $dir or die "Failed to chdir($dir): $!\n";
}

#===== SUBROUTINE ===========================================================
# Name      : cat_file()
# Purpose   : return file contents
# Parameters: $file => file to read
# Returns   : n/a
# Throws    : fatal error if the open fails
# Comments  : none
#============================================================================
sub cat_file {
    my ($file) = @_;
    open F, $file or die "Failed to open($file): $!\n";
    my $contents = join '', <F>;
    close(F);
    return $contents;
}

#===== SUBROUTINE ===========================================================
# Name      : is_link()
# Purpose   : assert path is a symlink
# Parameters: $path => path to check
#           : $dest => target symlink should point to
#============================================================================
sub is_link {
    my ($path, $dest) = @_;
    ok(-l $path => "$path should be symlink");
    is(readlink $path, $dest => "$path symlinks to $dest");
}

#===== SUBROUTINE ===========================================================
# Name      : is_dir_not_symlink()
# Purpose   : assert path is a directory not a symlink
# Parameters: $path => path to check
#============================================================================
sub is_dir_not_symlink {
    my ($path) = @_;
    ok(! -l $path => "$path should not be symlink");
    ok(-d _       => "$path should be a directory");
}

#===== SUBROUTINE ===========================================================
# Name      : is_nonexistent_path()
# Purpose   : assert path does not exist
# Parameters: $path => path to check
#============================================================================
sub is_nonexistent_path {
    my ($path) = @_;
    ok(! -l $path => "$path should not be symlink");
    ok(! -e _     => "$path should not exist");
}


1;

# Local variables:
# mode: perl
# cperl-indent-level: 4
# end:
# vim: ft=perl
