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
# Testing find_stowed_path()
#

use strict;
use warnings;

use testutil;

use Test::More tests => 6;

init_test_dirs();

my $stow = new_Stow(dir => "$TEST_DIR/stow");

is_deeply(
    [ $stow->find_stowed_path("$TEST_DIR/target/a/b/c", '../../../stow/a/b/c') ],
    [ "$TEST_DIR/stow/a/b/c", "$TEST_DIR/stow", 'a' ]
    => 'from root'
);

cd("$TEST_DIR/target");
$stow->set_stow_dir('../stow');
is_deeply(
    [ $stow->find_stowed_path('a/b/c','../../../stow/a/b/c') ],
    [ '../stow/a/b/c', '../stow', 'a' ]
    => 'from target directory'
);

make_path('stow');
cd('../..');
$stow->set_stow_dir("$TEST_DIR/target/stow");

is_deeply(
    [ $stow->find_stowed_path("$TEST_DIR/target/a/b/c", '../../stow/a/b/c') ],
    [ "$TEST_DIR/target/stow/a/b/c", "$TEST_DIR/target/stow", 'a' ]
    => 'stow is subdir of target directory'
);

is_deeply(
    [ $stow->find_stowed_path("$TEST_DIR/target/a/b/c",'../../empty') ],
    [ '', '', '' ]
    => 'target is not stowed'
);

make_path("$TEST_DIR/target/stow2");
make_file("$TEST_DIR/target/stow2/.stow");

is_deeply(
    [ $stow->find_stowed_path("$TEST_DIR/target/a/b/c",'../../stow2/a/b/c') ],
    [ "$TEST_DIR/target/stow2/a/b/c", "$TEST_DIR/target/stow2", 'a' ]
    => q(detect alternate stow directory)
);

# Possible corner case with rogue symlink pointing to ancestor of
# stow dir.
is_deeply(
    [ $stow->find_stowed_path("$TEST_DIR/target/a/b/c",'../../..') ],
    [ '', '', '' ]
    => q(corner case - link points to ancestor of stow dir)
);
