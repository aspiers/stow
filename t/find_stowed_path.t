#!/usr/local/bin/perl

#
# Testing find_stowed_path()
#

use strict;
use warnings;

use testutil;

use Test::More tests => 6;

init_test_dirs();

my $stow = new_Stow(dir => 't/stow');

is_deeply(
    [ $stow->find_stowed_path('t/target/a/b/c', '../../../stow/a/b/c') ],
    [ 't/stow/a/b/c', 't/stow', 'a' ]
    => 'from root'
);

cd('t/target');
$stow->set_stow_dir('../stow');
is_deeply(
    [ $stow->find_stowed_path('a/b/c','../../../stow/a/b/c') ],
    [ '../stow/a/b/c', '../stow', 'a' ]
    => 'from target directory'
);

make_dir('stow');
cd('../..');
$stow->set_stow_dir('t/target/stow');

is_deeply(
    [ $stow->find_stowed_path('t/target/a/b/c', '../../stow/a/b/c') ],
    [ 't/target/stow/a/b/c', 't/target/stow', 'a' ]
    => 'stow is subdir of target directory'
);

is_deeply(
    [ $stow->find_stowed_path('t/target/a/b/c','../../empty') ],
    [ '', '', '' ]
    => 'target is not stowed'
);

make_dir('t/target/stow2');
make_file('t/target/stow2/.stow');

is_deeply(
    [ $stow->find_stowed_path('t/target/a/b/c','../../stow2/a/b/c') ],
    [ 't/target/stow2/a/b/c', 't/target/stow2', 'a' ]
    => q(detect alternate stow directory)
);

# Possible corner case with rogue symlink pointing to ancestor of
# stow dir.
is_deeply(
    [ $stow->find_stowed_path('t/target/a/b/c','../../..') ],
    [ '', '', '' ]
    => q(corner case - link points to ancestor of stow dir)
);
