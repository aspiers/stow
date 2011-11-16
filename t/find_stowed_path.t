#!/usr/local/bin/perl

#
# Testing find_stowed_path()
#

BEGIN { require "t/util.pm"; require "stow"; }

use Test::More tests => 5;

eval { remove_dir('t/target'); };
eval { remove_dir('t/stow');   };
make_dir('t/target');
make_dir('t/stow');

$Stow_Path = 't/stow';
is(
    find_stowed_path('t/target/a/b/c', '../../../stow/a/b/c'),
    't/stow/a/b/c',
    => 'from root'
);

$Stow_Path = '../stow';
is(
    find_stowed_path('a/b/c','../../../stow/a/b/c'),
    '../stow/a/b/c',
    => 'from target directory'
);

$Stow_Path = 't/target/stow';

is(
    find_stowed_path('t/target/a/b/c', '../../stow/a/b/c'),
    't/target/stow/a/b/c',
    => 'stow is subdir of target directory'
);

is(
    find_stowed_path('t/target/a/b/c','../../empty'),
    '',
    => 'target is not stowed'
);

make_dir('t/target/stow2');
make_file('t/target/stow2/.stow');

is(
    find_stowed_path('t/target/a/b/c','../../stow2/a/b/c'),
    't/target/stow2/a/b/c'
    => q(detect alternate stow directory)
);
