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
# Test unstowing packages
#

use strict;
use warnings;

use File::Spec qw(make_path);
use POSIX qw(getcwd);
use Test::More tests => 35;
use Test::Output;
use English qw(-no_match_vars);

use testutil;
use Stow::Util qw(canon_path);

my $repo = getcwd();

init_test_dirs($TEST_DIR);

our $COMPAT_TEST_DIR = "${TEST_DIR}-compat";
our $COMPAT_ABS_TEST_DIR = init_test_dirs($COMPAT_TEST_DIR);

sub init_stow2 {
    make_path('stow2'); # make our alternate stow dir a subdir of target
    make_file('stow2/.stow');
}

sub create_unowned_files {
    # Make things harder for Stow to figure out, by adding
    # a bunch of alien files unrelated to Stow.
    my @UNOWNED_DIRS = ('unowned-dir', '.unowned-dir', 'dot-unowned-dir');
    for my $dir ('.', @UNOWNED_DIRS) {
        for my $subdir ('.', @UNOWNED_DIRS) {
            make_path("$dir/$subdir");
            make_file("$dir/$subdir/unowned");
            make_file("$dir/$subdir/.unowned");
            make_file("$dir/$subdir/dot-unowned");
        }
    }
}

# Run a subtest twice, with compat off then on, in parallel test trees.
#
# Params: $name[, $setup], $test_code
#
# $setup is an optional ref to an options hash to pass into the new
# Stow() constructor, or a ref to a sub which performs setup before
# the constructor gets called and then returns that options hash.
sub subtests {
    my $name = shift;
    my $setup = @_ == 2 ? shift : {};
    my $code = shift;

    $ENV{HOME} = $ABS_TEST_DIR;
    cd($repo);
    cd("$TEST_DIR/target");
    create_unowned_files();
    # cd first to allow setup to cd somewhere else.
    my $opts = ref($setup) eq 'HASH' ? $setup : $setup->($TEST_DIR);
    subtest($name, sub {
        make_path($opts->{dir}) if $opts->{dir};
        my $stow = new_Stow(%$opts);
        $code->($stow, $TEST_DIR);
    });

    $ENV{HOME} = $COMPAT_ABS_TEST_DIR;
    cd($repo);
    cd("$COMPAT_TEST_DIR/target");
    create_unowned_files();
    # cd first to allow setup to cd somewhere else.
    $opts = ref $setup eq 'HASH' ? $setup : $setup->($COMPAT_TEST_DIR);
    subtest("$name (compat mode)", sub {
        make_path($opts->{dir}) if $opts->{dir};
        my $stow = new_compat_Stow(%$opts);
        $code->($stow, $COMPAT_TEST_DIR);
    });
}

sub plan_tests {
    my ($stow, $count) = @_;
    plan tests => $stow->{compat} ? $count + 2 : $count;
}

subtests("unstow a simple tree minimally", sub {
    my ($stow) = @_;
    plan tests => 3;

    make_path('../stow/pkg1/bin1');
    make_file('../stow/pkg1/bin1/file1');
    make_link('bin1', '../stow/pkg1/bin1');

    $stow->plan_unstow('pkg1');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f '../stow/pkg1/bin1/file1');
    ok(! -e 'bin1' => 'unstow a simple tree');
});

subtests("unstow a simple tree from an existing directory", sub {
    my ($stow) = @_;
    plan tests => 3;

    make_path('lib2');
    make_path('../stow/pkg2/lib2');
    make_file('../stow/pkg2/lib2/file2');
    make_link('lib2/file2', '../../stow/pkg2/lib2/file2');
    $stow->plan_unstow('pkg2');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f '../stow/pkg2/lib2/file2');
    ok(-d 'lib2'
        => 'unstow simple tree from a pre-existing directory'
    );
});

subtests("fold tree after unstowing", sub {
    my ($stow) = @_;
    plan tests => 3;

    make_path('bin3');

    make_path('../stow/pkg3a/bin3');
    make_file('../stow/pkg3a/bin3/file3a');
    make_link('bin3/file3a' => '../../stow/pkg3a/bin3/file3a'); # emulate stow

    make_path('../stow/pkg3b/bin3');
    make_file('../stow/pkg3b/bin3/file3b');
    make_link('bin3/file3b' => '../../stow/pkg3b/bin3/file3b'); # emulate stow
    $stow->plan_unstow('pkg3b');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-l 'bin3');
    is(readlink('bin3'), '../stow/pkg3a/bin3'
        => 'fold tree after unstowing'
    );
});

subtests("existing link is owned by stow but is invalid so it gets removed anyway", sub {
    my ($stow) = @_;
    plan tests => 2;

    make_path('bin4');
    make_path('../stow/pkg4/bin4');
    make_file('../stow/pkg4/bin4/file4');
    make_invalid_link('bin4/file4', '../../stow/pkg4/bin4/does-not-exist');

    $stow->plan_unstow('pkg4');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(! -e 'bin4/file4'
        => q(remove invalid link owned by stow)
    );
});

subtests("Existing invalid link is not owned by stow", sub {
    my ($stow) = @_;
    plan tests => 3;

    make_path('../stow/pkg5/bin5');
    make_invalid_link('bin5', '../not-stow');

    $stow->plan_unstow('pkg5');
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-l 'bin5', 'invalid link not removed');
    is(readlink('bin5'), '../not-stow' => "invalid link not changed");
});

subtests("Target already exists, is owned by stow, but points to a different package", sub {
    my ($stow) = @_;
    plan tests => 3;

    make_path('bin6');
    make_path('../stow/pkg6a/bin6');
    make_file('../stow/pkg6a/bin6/file6');
    make_link('bin6/file6', '../../stow/pkg6a/bin6/file6');

    make_path('../stow/pkg6b/bin6');
    make_file('../stow/pkg6b/bin6/file6');

    $stow->plan_unstow('pkg6b');
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-l 'bin6/file6');
    is(
        readlink('bin6/file6'),
        '../../stow/pkg6a/bin6/file6'
        => q(ignore existing link that points to a different package)
    );
});

subtests("Don't unlink anything under the stow directory",
         sub {
             make_path('stow');
             return { dir => 'stow' };
             # target dir defaults to parent of stow, which is target directory
         },
         sub {
    plan tests => 5;
    my ($stow) = @_;

    # Emulate stowing into ourself (bizarre corner case or accident):
    make_path('stow/pkg7a/stow/pkg7b');
    make_file('stow/pkg7a/stow/pkg7b/file7b');
    # Make a package be a link to a package of the same name inside another package.
    make_link('stow/pkg7b', '../stow/pkg7a/stow/pkg7b');

    stderr_like(
        sub { $stow->plan_unstow('pkg7b'); },
        $stow->{compat} ? qr/WARNING: skipping target which was current stow directory stow/ : qr//
        => "warn when unstowing from ourself"
    );
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg7b');
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-l 'stow/pkg7b');
    is(
        readlink('stow/pkg7b'),
        '../stow/pkg7a/stow/pkg7b'
        => q(don't unlink any nodes under the stow directory)
    );
});

subtests("Don't unlink any nodes under another stow directory",
         sub {
             make_path('stow');
             return { dir => 'stow' };
         },
         sub {
    my ($stow) = @_;
    plan tests => 5;

    init_stow2();
    # emulate stowing into ourself (bizarre corner case or accident)
    make_path('stow/pkg8a/stow2/pkg8b');
    make_file('stow/pkg8a/stow2/pkg8b/file8b');
    make_link('stow2/pkg8b', '../stow/pkg8a/stow2/pkg8b');

    stderr_like(
        sub { $stow->plan_unstow('pkg8a'); },
        qr/WARNING: skipping marked Stow directory stow2/
        => "warn when skipping unstowing"
    );
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg8a');
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-l 'stow2/pkg8b');
    is(
        readlink('stow2/pkg8b'),
        '../stow/pkg8a/stow2/pkg8b'
        => q(don't unlink any nodes under another stow directory)
    );
});

# This will be used by subsequent tests
sub check_protected_dirs_skipped {
    my ($stderr) = @_;
    for my $dir (qw{stow stow2}) {
        like($stderr,
             qr/WARNING: skipping marked Stow directory $dir/
             => "warn when skipping marked directory $dir");
    }
}

subtests("overriding already stowed documentation",
         {override => ['man9', 'info9']},
         sub {
    my ($stow) = @_;
    plan_tests($stow, 2);

    make_file('stow/.stow');
    init_stow2();
    make_path('../stow/pkg9a/man9/man1');
    make_file('../stow/pkg9a/man9/man1/file9.1');
    make_path('man9/man1');
    make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

    make_path('../stow/pkg9b/man9/man1');
    make_file('../stow/pkg9b/man9/man1/file9.1');
    my $stderr = stderr_from { $stow->plan_unstow('pkg9b') };
    check_protected_dirs_skipped($stderr) if $stow->{compat};
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(!-l 'man9/man1/file9.1'
        => 'overriding existing documentation files'
    );
});

subtests("deferring to already stowed documentation",
         {defer => ['man10', 'info10']},
         sub {
    my ($stow) = @_;
    plan_tests($stow, 3);

    init_stow2();
    make_path('../stow/pkg10a/man10/man1');
    make_file('../stow/pkg10a/man10/man1/file10a.1');
    make_path('man10/man1');
    make_link('man10/man1/file10a.1'  => '../../../stow/pkg10a/man10/man1/file10a.1');

    # need this to block folding
    make_path('../stow/pkg10b/man10/man1');
    make_file('../stow/pkg10b/man10/man1/file10b.1');
    make_link('man10/man1/file10b.1'  => '../../../stow/pkg10b/man10/man1/file10b.1');

    make_path('../stow/pkg10c/man10/man1');
    make_file('../stow/pkg10c/man10/man1/file10a.1');
    my $stderr = stderr_from { $stow->plan_unstow('pkg10c') };
    check_protected_dirs_skipped($stderr) if $stow->{compat};
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg10c');
    is($stow->get_conflict_count, 0, 'conflict count');
    is(
        readlink('man10/man1/file10a.1'),
        '../../../stow/pkg10a/man10/man1/file10a.1'
        => 'defer to existing documentation files'
    );
});

subtests("Ignore temp files",
         {ignore => ['~', '\.#.*']},
         sub {
    my ($stow) = @_;
    plan_tests($stow, 2);

    init_stow2();
    make_path('../stow/pkg12/man12/man1');
    make_file('../stow/pkg12/man12/man1/file12.1');
    make_file('../stow/pkg12/man12/man1/file12.1~');
    make_file('../stow/pkg12/man12/man1/.#file12.1');
    make_path('man12/man1');
    make_link('man12/man1/file12.1'  => '../../../stow/pkg12/man12/man1/file12.1');

    my $stderr = stderr_from { $stow->plan_unstow('pkg12') };
    check_protected_dirs_skipped($stderr) if $stow->{compat};
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(! -e 'man12/man1/file12.1' => 'man12/man1/file12.1 was unstowed');
});

subtests("Unstow an already unstowed package", sub {
    my ($stow) = @_;
    plan_tests($stow, 2);

    my $stderr = stderr_from { $stow->plan_unstow('pkg12') };
    check_protected_dirs_skipped($stderr) if $stow->{compat};
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12');
    is($stow->get_conflict_count, 0, 'conflict count');
});

subtests("Unstow a never stowed package", sub {
    my ($stow) = @_;
    plan tests => 2;

    eval { remove_dir($stow->{target}); };
    mkdir($stow->{target});

    $stow->plan_unstow('pkg12');
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12 which was never stowed');
    is($stow->get_conflict_count, 0, 'conflict count');
});

subtests("Unstowing when target contains real files shouldn't be an issue", sub {
    my ($stow) = @_;
    plan tests => 4;

    # Test both a file which do / don't overlap with the package
    make_path('man12/man1');
    make_file('man12/man1/alien');
    make_file('man12/man1/file12.1');

    $stow->plan_unstow('pkg12');
    is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12 for third time');
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f 'man12/man1/alien', 'alien untouched');
    ok(-f 'man12/man1/file12.1', 'file overlapping with pkg untouched');
});

subtests("unstow a simple tree minimally when cwd isn't target",
         sub {
             my $test_dir = shift;
             cd($repo);
             return {
                 dir => "$test_dir/stow",
                 target => "$test_dir/target"
             }
         },
         sub {
    my ($stow, $test_dir) = @_;
    plan tests => 3;

    make_path("$test_dir/stow/pkg13/bin13");
    make_file("$test_dir/stow/pkg13/bin13/file13");
    make_link("$test_dir/target/bin13", '../stow/pkg13/bin13');

    $stow->plan_unstow('pkg13');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f "$test_dir/stow/pkg13/bin13/file13", 'package file untouched');
    ok(! -e "$test_dir/target/bin13" => 'bin13/ unstowed');
});

subtests("unstow a simple tree minimally with absolute stow dir when cwd isn't target",
         sub {
             my $test_dir = shift;
             cd($repo);
             return {
                 dir => canon_path("$test_dir/stow"),
                 target => "$test_dir/target"
             };
         },
         sub {
    plan tests => 3;
    my ($stow, $test_dir) = @_;

    make_path("$test_dir/stow/pkg14/bin14");
    make_file("$test_dir/stow/pkg14/bin14/file14");
    make_link("$test_dir/target/bin14", '../stow/pkg14/bin14');

    $stow->plan_unstow('pkg14');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f "$test_dir/stow/pkg14/bin14/file14");
    ok(! -e "$test_dir/target/bin14"
        => 'unstow a simple tree with absolute stow dir'
    );
});

subtests("unstow a simple tree minimally with absolute stow AND target dirs when cwd isn't target",
         sub {
             my $test_dir = shift;
             cd($repo);
             return {
                 dir => canon_path("$test_dir/stow"),
                 target => canon_path("$test_dir/target")
             };
         },
         sub {
    my ($stow, $test_dir) = @_;
    plan tests => 3;

    make_path("$test_dir/stow/pkg15/bin15");
    make_file("$test_dir/stow/pkg15/bin15/file15");
    make_link("$test_dir/target/bin15", '../stow/pkg15/bin15');

    $stow->plan_unstow('pkg15');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'conflict count');
    ok(-f "$test_dir/stow/pkg15/bin15/file15");
    ok(! -e "$test_dir/target/bin15"
        => 'unstow a simple tree with absolute stow and target dirs'
    );
});

sub create_and_stow_pkg {
    my ($id, $pkg) = @_;

    my $stow_pkg = "../stow/$id-$pkg";
    make_path($stow_pkg);
    make_file("$stow_pkg/$id-file-$pkg");

    # create a shallow hierarchy specific to this package and stow
    # via folding
    make_path("$stow_pkg/$id-$pkg-only-folded");
    make_file("$stow_pkg/$id-$pkg-only-folded/file-$pkg");
    make_link("$id-$pkg-only-folded", "$stow_pkg/$id-$pkg-only-folded");

    # create a deeper hierarchy specific to this package and stow
    # via folding
    make_path("$stow_pkg/$id-$pkg-only-folded2/subdir");
    make_file("$stow_pkg/$id-$pkg-only-folded2/subdir/file-$pkg");
    make_link("$id-$pkg-only-folded2",
              "$stow_pkg/$id-$pkg-only-folded2");

    # create a shallow hierarchy specific to this package and stow
    # without folding
    make_path("$stow_pkg/$id-$pkg-only-unfolded");
    make_file("$stow_pkg/$id-$pkg-only-unfolded/file-$pkg");
    make_path("$id-$pkg-only-unfolded");
    make_link("$id-$pkg-only-unfolded/file-$pkg",
              "../$stow_pkg/$id-$pkg-only-unfolded/file-$pkg");

    # create a deeper hierarchy specific to this package and stow
    # without folding
    make_path("$stow_pkg/$id-$pkg-only-unfolded2/subdir");
    make_file("$stow_pkg/$id-$pkg-only-unfolded2/subdir/file-$pkg");
    make_path("$id-$pkg-only-unfolded2/subdir");
    make_link("$id-$pkg-only-unfolded2/subdir/file-$pkg",
              "../../$stow_pkg/$id-$pkg-only-unfolded2/subdir/file-$pkg");

    # create a shallow shared hierarchy which this package uses, and stow
    # its contents without folding
    make_path("$stow_pkg/$id-shared");
    make_file("$stow_pkg/$id-shared/file-$pkg");
    make_path("$id-shared");
    make_link("$id-shared/file-$pkg",
              "../$stow_pkg/$id-shared/file-$pkg");

    # create a deeper shared hierarchy which this package uses, and stow
    # its contents without folding
    make_path("$stow_pkg/$id-shared2/subdir");
    make_file("$stow_pkg/$id-shared2/file-$pkg");
    make_file("$stow_pkg/$id-shared2/subdir/file-$pkg");
    make_path("$id-shared2/subdir");
    make_link("$id-shared2/file-$pkg",
              "../$stow_pkg/$id-shared2/file-$pkg");
    make_link("$id-shared2/subdir/file-$pkg",
              "../../$stow_pkg/$id-shared2/subdir/file-$pkg");
}

subtest("unstow a tree with no-folding enabled - no refolding should take place", sub {
    cd("$TEST_DIR/target");
    plan tests => 15;

    foreach my $pkg (qw{a b}) {
        create_and_stow_pkg('no-folding', $pkg);
    }

    my $stow = new_Stow('no-folding' => 1);
    $stow->plan_unstow('no-folding-b');
    is_deeply([ $stow->get_conflicts ], [] => 'no conflicts with --no-folding');

    $stow->process_tasks();

    is_nonexistent_path('no-folding-b-only-folded');
    is_nonexistent_path('no-folding-b-only-folded2');
    is_nonexistent_path('no-folding-b-only-unfolded/file-b');
    is_nonexistent_path('no-folding-b-only-unfolded2/subdir/file-b');
    is_dir_not_symlink('no-folding-shared');
    is_dir_not_symlink('no-folding-shared2');
    is_dir_not_symlink('no-folding-shared2/subdir');
});

# subtests("Test cleaning up subdirs with --paranoid option", sub {
# TODO
# });
