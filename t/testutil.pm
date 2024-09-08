#!/usr/bin/perl
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

#
# Utilities shared by test scripts
#

package testutil;

use strict;
use warnings;

use Carp qw(confess croak);
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Spec;
use Test::More;

use Stow;
use Stow::Util qw(parent canon_path join_paths);

use base qw(Exporter);
our @EXPORT = qw(
    $ABS_TEST_DIR
    $TEST_DIR
    init_test_dirs
    cd
    new_Stow new_compat_Stow
    make_path make_link make_invalid_link make_file
    setup_global_ignore setup_package_ignore
    remove_dir remove_file remove_link
    cat_file
    is_link is_dir_not_symlink is_nonexistent_path
);

our $TEST_DIR = 'tmp-testing-trees';
our $ABS_TEST_DIR = File::Spec->rel2abs('tmp-testing-trees');

sub init_test_dirs {
    my $test_dir = shift || $TEST_DIR;
    my $abs_test_dir = File::Spec->rel2abs($test_dir);

    # Create a run_from/ subdirectory for tests which want to run
    # from a separate directory outside the Stow directory or
    # target directory.
    for my $dir ("target", "stow", "run_from", "stow directory") {
        my $path = "$test_dir/$dir";
        -d $path and remove_tree($path);
        make_path($path);
    }

    # Don't let user's ~/.stow-global-ignore affect test results
    $ENV{HOME} = $abs_test_dir;
    return $abs_test_dir;
}

sub new_Stow {
    my %opts = @_;
    # These default paths assume that execution will be triggered from
    # within the target directory.
    $opts{dir}    ||= '../stow';
    $opts{target} ||= '.';
    $opts{test_mode} = 1;
    my $stow = eval { new Stow(%opts) };
    if ($@) {
        confess "Error while trying to instantiate new Stow(%opts): $@";
    }
    return $stow;
}

sub new_compat_Stow {
    my %opts = @_;
    $opts{compat} = 1;
    return new_Stow(%opts);
}

#===== SUBROUTINE ===========================================================
# Name      : make_link()
# Purpose   : safely create a link
# Parameters: $link_src => path to the link
#           : $link_dest => where the new link should point
#           : $invalid => true iff $link_dest refers to non-existent file
# Returns   : n/a
# Throws    : fatal error if the link can not be safely created
# Comments  : checks for existing nodes
#============================================================================
sub make_link {
    my ($link_src, $link_dest, $invalid) = @_;

    if (-l $link_src) {
        my $old_source = readlink join('/', parent($link_src), $link_dest)
            or croak "$link_src is already a link but could not read link $link_src/$link_dest";
        if ($old_source ne $link_dest) {
            croak "$link_src already exists but points elsewhere\n";
        }
    }
    croak "$link_src already exists and is not a link\n" if -e $link_src;
    my $abs_target = File::Spec->rel2abs($link_src);
    my $link_src_container = dirname($abs_target);
    my $abs_source = File::Spec->rel2abs($link_dest, $link_src_container);
    #warn "t $link_src c $link_src_container as $abs_source";
    if (-e $abs_source) {
        croak "Won't make invalid link pointing to existing $abs_target"
            if $invalid;
    }
    else {
        croak "Won't make link pointing to non-existent $abs_target"
            unless $invalid;
    }
    symlink $link_dest, $link_src
        or croak "could not create link $link_src => $link_dest ($!)\n";
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
        croak "a non-file already exists at $path\n";
    }

    open my $FILE ,'>', $path
        or croak "could not create file: $path ($!)\n";
    print $FILE $contents if defined $contents;
    close $FILE;
}

sub setup_global_ignore {
    my ($contents) = @_;
    my $global_ignore_file = join_paths($ENV{HOME}, $Stow::GLOBAL_IGNORE_FILE);
    make_file($global_ignore_file, $contents);
    return $global_ignore_file;
}

sub setup_package_ignore {
    my ($package_path, $contents) = @_;
    my $package_ignore_file = join_paths($package_path, $Stow::LOCAL_IGNORE_FILE);
    make_file($package_ignore_file, $contents);
    return $package_ignore_file;
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
        croak qq(remove_link() called with a non-link: $path);
    }
    unlink $path or croak "could not remove link: $path ($!)\n";
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
        croak "file at $path is non-empty\n";
    }
    unlink $path or croak "could not remove empty file: $path ($!)\n";
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
        croak "$dir is not a directory";
    }

    opendir my $DIR, $dir or croak "cannot read directory: $dir ($!)\n";
    my @listing = readdir $DIR;
    closedir $DIR;

    NODE:
    for my $node (@listing) {
        next NODE if $node eq '.';
        next NODE if $node eq '..';

        my $path = "$dir/$node";
        if (-l $path or (-f $path and -z $path) or $node eq $Stow::LOCAL_IGNORE_FILE) {
            unlink $path or croak "cannot unlink $path ($!)\n";
        }
        elsif (-d "$path") {
            remove_dir($path);
        }
        else {
            croak "$path is not a link, directory, or empty file\n";
        }
    }
    rmdir $dir or croak "cannot rmdir $dir ($!)\n";

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
    chdir $dir or croak "Failed to chdir($dir): $!\n";
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
    open F, $file or croak "Failed to open($file): $!\n";
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
# end:
# vim: ft=perl
