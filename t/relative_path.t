#!/usr/local/bin/perl

#
# Testing relative_path();
#

# load as a library
BEGIN { use lib qw(. ..); require "stow"; }

use Test::More tests => 5;

is(
    relative_path('a/b/c', 'a/b/d'),
    '../d',
    => 'different branches'
);

is(
    relative_path('/a/b/c', '/a/b/c/d'),
    'd',
    => 'lower same branch'
);

is(
    relative_path('a/b/c', 'a/b'),
    '..',
    => 'higher, same branch'
);

is(
    relative_path('/a/b/c', '/d/e/f'),
    '../../../d/e/f',
    => 'common parent is /'
);

is(
    relative_path('///a//b//c////', '/a////b/c/d////'),
    'd',
    => 'extra /\'s '
);

