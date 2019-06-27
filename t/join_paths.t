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
