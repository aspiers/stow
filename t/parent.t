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
# Testing parent()
#

use strict;
use warnings;

use Stow::Util qw(parent);

use Test::More tests => 5;

is(
    parent('a/b/c'),
    'a/b'
    => 'no leading or trailing /'
);

is(
    parent('/a/b/c'),
    '/a/b'
    => 'leading /'
);

is(
    parent('a/b/c/'),
    'a/b'
    => 'trailing /'
);

is(
    parent('/////a///b///c///'),
    '/a/b'
    => 'multiple /'
);

is (
    parent('a'),
    ''
    => 'empty parent'
);

