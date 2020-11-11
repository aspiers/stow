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
# Testing Stow::link_dest_within_stow_dir()
#

use strict;
use warnings;

use Test::More tests => 6;

use testutil;
use Stow::Util;

init_test_dirs();

# This is a relative path, unlike $ABS_TEST_DIR below.
my $stow = new_Stow(dir => "$TEST_DIR/stow",
                    target => "$TEST_DIR/target");

subtest("relative stow dir, link to top-level package file" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("../stow/pkg/dir/file");
    is($package, "pkg", "package");
    is($path, "dir/file", "path");
});

subtest("relative stow dir, link to second-level package file" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("../stow/pkg/dir/subdir/file");
    is($package, "pkg", "package");
    is($path, "dir/subdir/file", "path");
});

# This is an absolute path, unlike $TEST_DIR above.
$stow = new_Stow(dir => "$ABS_TEST_DIR/stow",
                    target => "$ABS_TEST_DIR/target");

subtest("relative stow dir, link to second-level package file" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("../stow/pkg/dir/file");
    is($package, "pkg", "package");
    is($path, "dir/file", "path");
});

subtest("absolute stow dir, link to top-level package file" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("../stow/pkg/dir/subdir/file");
    is($package, "pkg", "package");
    is($path, "dir/subdir/file", "path");
});

# Links with destination in the target are not pointing within
# the stow dir, so they're not owned by stow.
subtest("link to path in target" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("./alien");
    is($path, "", "alien is in target, so path is empty");
    is($package, "", "alien is in target, so package is empty");
});

subtest("link to path outside target and stow dir" => sub {
    plan tests => 2;
    my ($package, $path) =
        $stow->link_dest_within_stow_dir("../alien");
    is($path, "", "alien is outside, so path is empty");
    is($package, "", "alien is outside, so package is empty");
});
