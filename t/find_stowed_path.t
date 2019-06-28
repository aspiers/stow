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

use Test::More tests => 18;

use testutil;
use Stow::Util qw(set_debug_level);

init_test_dirs();

my $stow = new_Stow(dir => "$TEST_DIR/stow");
#set_debug_level(4);

my ($path, $stow_path, $package) =
    $stow->find_stowed_path("$TEST_DIR/target/a/b/c", "../../../stow/a/b/c");
is($path, "$TEST_DIR/stow/a/b/c", "path");
is($stow_path, "$TEST_DIR/stow", "stow path");
is($package, "a", "package");

cd("$TEST_DIR/target");
$stow->set_stow_dir("../stow");
($path, $stow_path, $package) =
    $stow->find_stowed_path("a/b/c", "../../../stow/a/b/c");
is($path, "../stow/a/b/c", "path from target directory");
is($stow_path, "../stow", "stow path from target directory");
is($package, "a", "from target directory");

make_path("stow");
cd("../..");
$stow->set_stow_dir("$TEST_DIR/target/stow");

($path, $stow_path, $package) =
    $stow->find_stowed_path("$TEST_DIR/target/a/b/c", "../../stow/a/b/c");
is($path, "$TEST_DIR/target/stow/a/b/c", "path");
is($stow_path, "$TEST_DIR/target/stow", "stow path");
is($package, "a", "stow is subdir of target directory");

($path, $stow_path, $package) =
    $stow->find_stowed_path("$TEST_DIR/target/a/b/c", "../../empty");
is($path, "", "empty path");
is($stow_path, "", "empty stow path");
is($package, "", "target is not stowed");

make_path("$TEST_DIR/target/stow2");
make_file("$TEST_DIR/target/stow2/.stow");

($path, $stow_path, $package) =
    $stow->find_stowed_path("$TEST_DIR/target/a/b/c","../../stow2/a/b/c");
is($path, "$TEST_DIR/target/stow2/a/b/c", "path");
is($stow_path, "$TEST_DIR/target/stow2", "stow path");
is($package, "a", "detect alternate stow directory");

# Possible corner case with rogue symlink pointing to ancestor of
# stow dir.
($path, $stow_path, $package) =
    $stow->find_stowed_path("$TEST_DIR/target/a/b/c","../../..");
is($path, "", "path");
is($stow_path, "", "stow path");
is($package, "", "corner case - link points to ancestor of stow dir");
