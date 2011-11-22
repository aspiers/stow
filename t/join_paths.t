#!/usr/local/bin/perl

#
# Testing join_paths();
#

use strict;
use warnings;

use Stow::Util qw(join_paths);

use Test::More tests => 14;

is(
    join_paths('a/b/c', 'd/e/f'),
    'a/b/c/d/e/f'
    => 'simple'
);

is(
    join_paths('/a/b/c', '/d/e/f'),
    '/a/b/c/d/e/f'
    => 'leading /'
);

is(
    join_paths('/a/b/c/', '/d/e/f/'),
    '/a/b/c/d/e/f'
    => 'trailing /'
);

is(
    join_paths('///a/b///c//', '/d///////e/f'),
    '/a/b/c/d/e/f'
    => 'mltiple /\'s'
);

is(
    join_paths('', 'a/b/c'),
    'a/b/c'
    => 'first empty'
);

is(
    join_paths('a/b/c', ''),
    'a/b/c'
    => 'second empty'
);

is(
    join_paths('/', 'a/b/c'),
    '/a/b/c'
    => 'first is /'
);

is(
    join_paths('a/b/c', '/'),
    'a/b/c'
    => 'second is /'
);

is(
    join_paths('///a/b///c//', '/d///////e/f'),
    '/a/b/c/d/e/f'
    => 'multiple /\'s'
);


is(
    join_paths('../a1/b1/../c1/', '/a2/../b2/e2'),
    '../a1/c1/b2/e2'
    => 'simple deref ".."'
);

is(
    join_paths('../a1/b1/../c1/d1/e1', '../a2/../b2/c2/d2/../e2'),
    '../a1/c1/d1/b2/c2/e2'
    => 'complex deref ".."'
);

is(
    join_paths('../a1/../../c1', 'a2/../../'),
    '../..'
    => 'too many ".."'
);

is(
    join_paths('./a1', '../../a2'),
    '../a2'
    => 'drop any "./"'
);

is(
    join_paths('a/b/c', '.'),
    'a/b/c'
    => '. on RHS'
);
