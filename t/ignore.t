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
# Testing ignore lists.
#

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More tests => 287;

use testutil;
use Stow::Util qw(join_paths);

init_test_dirs();
cd("$TEST_DIR/target");

my $stow = new_Stow();

sub test_ignores {
    my ($stow_path, $package, $context, @tests) = @_;
    $context ||= '';
    while (@tests) {
        my $path          = shift @tests;
        my $should_ignore = shift @tests;
        my $not = $should_ignore ? '' : ' not';
        my $was_ignored = $stow->ignore($stow_path, $package, $path);
        is(
            $was_ignored, $should_ignore,
            "Should$not ignore $path $context"
        );
    }
}

sub test_local_ignore_list_always_ignored_at_top_level {
    my ($stow_path, $package, $context) = @_;
    test_ignores(
        $stow_path, $package, $context,
        $Stow::LOCAL_IGNORE_FILE             => 1,
        "subdir/" . $Stow::LOCAL_IGNORE_FILE => 0,
    );
}

sub test_built_in_list {
    my ($stow_path, $package, $context, $expect_ignores) = @_;

    for my $ignored ('CVS', '.cvsignore', '#autosave#') {
        for my $path ($ignored, "foo/bar/$ignored") {
            my $suffix = "$path.suffix";
            (my $prefix = $path) =~ s!([^/]+)$!prefix.$1!;

            test_ignores(
                $stow_path, $package, $context,
                $path   => $expect_ignores,
                $prefix => 0,
                $suffix => 0,
            );
        }
    }

    # The pattern catching lock files allows suffixes but not prefixes
    for my $ignored ('.#lock-file') {
        for my $path ($ignored, "foo/bar/$ignored") {
            my $suffix = "$path.suffix";
            (my $prefix = $path) =~ s!([^/]+)$!prefix.$1!;

            test_ignores(
                $stow_path, $package, $context,
                $path   => $expect_ignores,
                $prefix => 0,
                $suffix => $expect_ignores,
            );
        }
    }
}

sub test_user_global_list {
    my ($stow_path, $package, $context, $expect_ignores) = @_;

    for my $path ('', 'foo/bar/') {
        test_ignores(
            $stow_path, $package, $context,
            $path . 'exact'       => $expect_ignores,
            $path . '0exact'      => 0,
            $path . 'exact1'      => 0,
            $path . '0exact1'     => 0,

            $path . 'substring'   => 0,
            $path . '0substring'  => 0,
            $path . 'substring1'  => 0,
            $path . '0substring1' => $expect_ignores,
        );
    }
}

sub setup_user_global_list {
    # Now test with global ignore list in home directory
    $ENV{HOME} = tempdir();
    setup_global_ignore(<<EOF);
exact
.+substring.+ # here's a comment
.+\.extension
myprefix.+       #hi mum
EOF
}

sub setup_package_local_list {
    my ($stow_path, $package, $list) = @_;
    my $package_path = join_paths($stow_path, $package);
    make_path($package_path);
    my $package_ignore = setup_package_ignore($package_path, $list);
    $stow->invalidate_memoized_regexp($package_ignore);
    return $package_ignore;
}

sub main {
    my $stow_path = '../stow';
    my $package;
    my $context;

    # Test built-in list first.  init_test_dirs() already set
    # $ENV{HOME} to ensure that we're not using the user's global
    # ignore list.
    $package = 'non-existent-package';
    $context = "when using built-in list";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 1);

    # Test ~/.stow-global-ignore
    setup_user_global_list();
    $context = "when using ~/$Stow::GLOBAL_IGNORE_FILE";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 0);
    test_user_global_list($stow_path, $package, $context, 1);

    # Test empty package-local .stow-local-ignore
    $package = 'ignorepkg';
    my $local_ignore = setup_package_local_list($stow_path, $package, "");
    $context = "when using empty $local_ignore";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 0);
    test_user_global_list($stow_path, $package, $context, 0);
    test_ignores(
        $stow_path, $package, $context,
        'random'          => 0,
        'foo2/bar'        => 0,
        'foo2/bars'       => 0,
        'foo2/bar/random' => 0,
        'foo2/bazqux'     => 0,
        'xfoo2/bazqux'    => 0,
    );

    # Test package-local .stow-local-ignore with only path segment regexps
    $local_ignore = setup_package_local_list($stow_path, $package, <<EOF);
random
EOF
    $context = "when using $local_ignore with only path segment regexps";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 0);
    test_user_global_list($stow_path, $package, $context, 0);
    test_ignores(
        $stow_path, $package, $context,
        'random'          => 1,
        'foo2/bar'        => 0,
        'foo2/bars'       => 0,
        'foo2/bar/random' => 1,
        'foo2/bazqux'     => 0,
        'xfoo2/bazqux'    => 0,
    );

    # Test package-local .stow-local-ignore with only full path regexps
    $local_ignore = setup_package_local_list($stow_path, $package, <<EOF);
foo2/bar
EOF
    $context = "when using $local_ignore with only full path regexps";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 0);
    test_user_global_list($stow_path, $package, $context, 0);
    test_ignores(
        $stow_path, $package, $context,
        'random'          => 0,
        'foo2/bar'        => 1,
        'foo2/bars'       => 0,
        'foo2/bar/random' => 1,
        'foo2/bazqux'     => 0,
        'xfoo2/bazqux'    => 0,
    );

    # Test package-local .stow-local-ignore with a mixture of regexps
    $local_ignore = setup_package_local_list($stow_path, $package, <<EOF);
foo2/bar
random
foo2/baz.+
EOF
    $context = "when using $local_ignore with mixture of regexps";
    test_local_ignore_list_always_ignored_at_top_level($stow_path, $package, $context);
    test_built_in_list($stow_path, $package, $context, 0);
    test_user_global_list($stow_path, $package, $context, 0);
    test_ignores(
        $stow_path, $package, $context,
        'random'          => 1,
        'foo2/bar'        => 1,
        'foo2/bars'       => 0,
        'foo2/bar/random' => 1,
        'foo2/bazqux'     => 1,
        'xfoo2/bazqux'    => 0,
    );

    test_examples_in_manual($stow_path);
    test_invalid_regexp($stow_path, "Invalid segment regexp in list", <<EOF);
this one's ok
this one isn't|*!
but this one is
EOF
    test_invalid_regexp($stow_path, "Invalid full path regexp in list", <<EOF);
this one's ok
this/one isn't|*!
but this one is
EOF
    test_ignore_via_stow($stow_path);
}

sub test_examples_in_manual {
    my ($stow_path) = @_;
    my $package = 'ignorepkg';
    my $context = "(example from manual)";

    for my $re ('bazqux', 'baz.*', '.*qux', 'bar/.*x', '^/foo/.*qux') {
        my $local_ignore = setup_package_local_list($stow_path, $package, "$re\n");
        test_ignores(
            $stow_path, $package, $context,
            "foo/bar/bazqux" => 1,
        );
    }

    for my $re ('bar', 'baz', 'qux', 'o/bar/b') {
        my $local_ignore = setup_package_local_list($stow_path, $package, "$re\n");
        test_ignores(
            $stow_path, $package, $context,
            "foo/bar/bazqux" => 0,
        );
    }
}

sub test_invalid_regexp {
    my ($stow_path, $context, $list) = @_;
    my $package = 'ignorepkg';

    my $local_ignore = setup_package_local_list($stow_path, $package, $list);
    eval {
        test_ignores(
            $stow_path, $package, $context,
            "foo/bar/bazqux" => 1,
        );
    };
    like($@, qr/^Failed to compile regexp: Quantifier follows nothing in regex;/,
         $context);
}

sub test_ignore_via_stow {
    my ($stow_path) = @_;

    my $package = 'pkg1';
    make_path("$stow_path/$package/foo/bar");
    make_file("$stow_path/$package/foo/bar/baz");

    setup_package_local_list($stow_path, $package, 'foo');
    $stow->plan_stow($package);
    is($stow->get_tasks(),     0, 'top dir ignored');
    is($stow->get_conflicts(), 0, 'top dir ignored, no conflicts');

    make_path("foo");
    for my $ignore ('bar', 'foo/bar', '/foo/bar', '^/foo/bar', '^/fo.+ar') {
        setup_package_local_list($stow_path, $package, $ignore);
        $stow->plan_stow($package);
        is($stow->get_tasks(), 0, "bar ignored via $ignore");
        is($stow->get_conflicts(), 0, 'bar ignored, no conflicts');
    }

    make_file("$stow_path/$package/foo/qux");
    $stow->plan_stow($package);
    $stow->process_tasks();
    is($stow->get_conflicts(), 0, 'no conflicts stowing qux');
    ok(! -e "foo/bar", "bar ignore prevented stow");
    ok(-l "foo/qux",   "qux not ignored and stowed");
    is(readlink("foo/qux"), "../$stow_path/$package/foo/qux", "qux stowed correctly");
}

main();
