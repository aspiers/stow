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
# Testing Stow:: find_stowed_path()
#

use strict;
use warnings;

use Test::More tests => 10;

use testutil;
use Stow::Util qw(set_debug_level);

init_test_dirs();

subtest("find link to a stowed path with relative target" => sub {
    plan tests => 3;

    # This is a relative path, unlike $ABS_TEST_DIR below.
    my $target = "$TEST_DIR/target";

    my $stow = new_Stow(dir => "$TEST_DIR/stow", target => $target);
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../../stow/a/b/c");
    is($path, "../stow/a/b/c", "path");
    is($stow_path, "../stow", "stow path");
    is($package, "a", "package");
});

my $stow = new_Stow(dir => "$ABS_TEST_DIR/stow", target => "$ABS_TEST_DIR/target");

# Required by creation of stow2 and stow2/.stow below
cd("$ABS_TEST_DIR/target");

subtest("find link to a stowed path" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../../stow/a/b/c");
    is($path, "../stow/a/b/c", "path from target directory");
    is($stow_path, "../stow", "stow path from target directory");
    is($package, "a", "from target directory");
});

subtest("find link to alien path not owned by Stow" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../alien");
    is($path, "", "alien is not stowed, so path is empty");
    is($stow_path, "", "alien, so stow path is empty");
    is($package, "", "alien is not stowed in any package");
});

# Make a second stow directory within the target directory, so that we
# can check that links to package files within that stow directory are
# detected correctly.
make_path("stow2");

# However this second stow directory is still "alien" to stow until we
# put a .stow file in it.  So first test a symlink pointing to a path
# within this second stow directory
subtest("second stow dir still alien without .stow" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../stow2/a/b/c");
    is($path, "", "stow2 not a stow dir yet, so path is empty");
    is($stow_path, "", "stow2 not a stow dir yet so stow path is empty");
    is($package, "", "not stowed in any recognised package yet");
});

# Now make stow2 a secondary stow directory and test that
make_file("stow2/.stow");

subtest(".stow makes second stow dir owned by Stow" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../stow2/a/b/c");
    is($path, "stow2/a/b/c", "path");
    is($stow_path, "stow2", "stow path");
    is($package, "a", "detect alternate stow directory");
});

subtest("relative symlink pointing to target dir" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../..");
    # Technically the target dir is not owned by Stow, since
    # Stow won't touch the target dir itself, only its contents.
    is($path, "", "path");
    is($stow_path, "", "stow path");
    is($package, "", "corner case - link points to target dir");
});

subtest("relative symlink pointing to parent of target dir" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../../..");
    is($path, "", "path");
    is($stow_path, "", "stow path");
    is($package, "", "corner case - link points to parent of target dir");
});

subtest("unowned symlink pointing to absolute path inside target" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "$ABS_TEST_DIR/target/d");
    is($path, "", "path");
    is($stow_path, "", "stow path");
    is($package, "", "symlink unowned by Stow points to absolute path outside target directory");
});

subtest("unowned symlink pointing to absolute path outside target" => sub {
    plan tests => 3;
    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "/dev/null");
    is($path, "", "path");
    is($stow_path, "", "stow path");
    is($package, "", "symlink unowned by Stow points to absolute path outside target directory");
});

# Now make stow2 the primary stow directory and test that it still
# works when the stow directory is under the target directory
$stow->set_stow_dir("$ABS_TEST_DIR/target/stow2");

subtest("stow2 becomes the primary stow directory" => sub {
    plan tests => 3;

    my ($path, $stow_path, $package) =
        $stow->find_stowed_path("a/b/c", "../../stow2/a/b/c");
    is($path, "stow2/a/b/c", "path in stow2");
    is($stow_path, "stow2", "stow path for stow2");
    is($package, "a", "stow2 is subdir of target directory");
});
