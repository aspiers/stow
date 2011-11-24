#!/usr/bin/perl

#
# Utilities shared by test scripts
#

package testutil;

use strict;
use warnings;

use Stow;
use Stow::Util qw(parent canon_path);

use base qw(Exporter);
our @EXPORT = qw(
    $OUT_DIR
    init_test_dirs
    cd
    new_Stow new_compat_Stow
    make_dir make_link make_file
    remove_dir remove_link
);

our $OUT_DIR = 'tmp-testing-trees';

sub init_test_dirs {
    for my $dir ("$OUT_DIR/target", "$OUT_DIR/stow") {
        -d $dir and remove_dir($dir);
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
# Returns   : n/a
# Throws    : fatal error if the link can not be safely created
# Comments  : checks for existing nodes
#============================================================================
sub make_link {
    my ($target, $source) = @_;

    if (-l $target) {
        my $old_source = readlink join('/', parent($target), $source) 
            or die "could not read link $target/$source";
        if ($old_source ne $source) {
            die "$target already exists but points elsewhere\n";
        }
    }
    elsif (-e $target) {
        die "$target already exists and is not a link\n";
    }
    else {
        symlink $source, $target
            or die "could not create link $target => $source ($!)\n";
    }
    return;
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
    my ($path, $contents) =@_;

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

1;

# Local variables:
# mode: perl
# cperl-indent-level: 4
# end:
# vim: ft=perl
