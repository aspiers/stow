#!/usr/local/bin/perl

#
# Testing find_stowed_path()
#

use strict;
use warnings;

use testutil;

use Test::More tests => 6;

make_fresh_stow_and_target_dirs();

my $stow = new_Stow(dir => 't/stow');

is(
    $stow->find_stowed_path('t/target/a/b/c', '../../../stow/a/b/c'),
    't/stow/a/b/c'
    => 'from root'
);

cd('t/target');
$stow->set_stow_dir('../stow');
is(
    $stow->find_stowed_path('a/b/c','../../../stow/a/b/c'),
    '../stow/a/b/c'
    => 'from target directory'
);

make_dir('stow');
cd('../..');
$stow->set_stow_dir('t/target/stow');

is(
    $stow->find_stowed_path('t/target/a/b/c', '../../stow/a/b/c'),
    't/target/stow/a/b/c'
    => 'stow is subdir of target directory'
);

is(
    $stow->find_stowed_path('t/target/a/b/c','../../empty'),
    ''
    => 'target is not stowed'
);

make_dir('t/target/stow2');
make_file('t/target/stow2/.stow');

is(
    $stow->find_stowed_path('t/target/a/b/c','../../stow2/a/b/c'),
    't/target/stow2/a/b/c'
    => q(detect alternate stow directory)
);

# Possible corner case with rogue symlink pointing to ancestor of
# stow dir.
is(
    $stow->find_stowed_path('t/target/a/b/c','../../..'),
    ''
    => q(corner case - link points to ancestor of stow dir)
);
