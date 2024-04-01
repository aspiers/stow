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
# Test stowing packages.
#

use strict;
use warnings;

use Test::More tests => 22;
use Test::Output;
use English qw(-no_match_vars);

use Stow::Util qw(canon_path set_debug_level);
use testutil;

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;
my %conflicts;

# Note that each of the following tests use a distinct set of files

subtest('stow a simple tree minimally', sub {
    plan tests => 2;
    my $stow = new_Stow(dir => '../stow');

    make_path('../stow/pkg1/bin1');
    make_file('../stow/pkg1/bin1/file1');

    $stow->plan_stow('pkg1');
    $stow->process_tasks();
    is_deeply([ $stow->get_conflicts ], [], 'no conflicts with minimal stow');
    is(
        readlink('bin1'),
        '../stow/pkg1/bin1',
        => 'minimal stow of a simple tree'
    );
});

subtest('stow a simple tree into an existing directory', sub {
    plan tests => 1;
    my $stow = new_Stow();

    make_path('../stow/pkg2/lib2');
    make_file('../stow/pkg2/lib2/file2');
    make_path('lib2');

    $stow->plan_stow('pkg2');
    $stow->process_tasks();
    is(
        readlink('lib2/file2'),
        '../../stow/pkg2/lib2/file2',
        => 'stow simple tree to existing directory'
    );
});

subtest('unfold existing tree', sub {
    plan tests => 3;
    my $stow = new_Stow();

    make_path('../stow/pkg3a/bin3');
    make_file('../stow/pkg3a/bin3/file3a');
    make_link('bin3' => '../stow/pkg3a/bin3'); # emulate stow

    make_path('../stow/pkg3b/bin3');
    make_file('../stow/pkg3b/bin3/file3b');

    $stow->plan_stow('pkg3b');
    $stow->process_tasks();
    ok(-d 'bin3');
    is(readlink('bin3/file3a'), '../../stow/pkg3a/bin3/file3a');
    is(readlink('bin3/file3b'), '../../stow/pkg3b/bin3/file3b'
        => 'target already has 1 stowed package');
});

subtest("Package dir 'bin4' conflicts with existing non-dir so can't unfold", sub {
    plan tests => 2;
    my $stow = new_Stow();

    make_file('bin4'); # this is a file but named like a directory
    make_path('../stow/pkg4/bin4');
    make_file('../stow/pkg4/bin4/file4');

    $stow->plan_stow('pkg4');
    %conflicts = $stow->get_conflicts();
    is($stow->get_conflict_count, 1);
    like(
        $conflicts{stow}{pkg4}[0],
        qr!cannot stow ../stow/pkg4/bin4 over existing target bin4 since neither a link nor a directory and --adopt not specified!
        => 'link to new dir bin4 conflicts with existing non-directory'
    );
});

subtest("Package dir 'bin4a' conflicts with existing non-dir " .
        "so can't unfold even with --adopt", sub {
    plan tests => 2;
    my $stow = new_Stow(adopt => 1);

    make_file('bin4a'); # this is a file but named like a directory
    make_path('../stow/pkg4a/bin4a');
    make_file('../stow/pkg4a/bin4a/file4a');

    $stow->plan_stow('pkg4a');
    %conflicts = $stow->get_conflicts();
    is($stow->get_conflict_count, 1);
    like(
        $conflicts{stow}{pkg4a}[0],
        qr!cannot stow directory ../stow/pkg4a/bin4a over existing non-directory target bin4a!
        => 'link to new dir bin4a conflicts with existing non-directory'
    );
});

subtest("Package files 'file4b' and 'bin4b' conflict with existing files", sub {
    plan tests => 3;
    my $stow = new_Stow();

    # Populate target
    make_file('file4b',       'file4b - version originally in target');
    make_path('bin4b');
    make_file('bin4b/file4b', 'bin4b/file4b - version originally in target');

    # Populate stow package
    make_path('../stow/pkg4b');
    make_file('../stow/pkg4b/file4b',       'file4b - version originally in stow package');
    make_path('../stow/pkg4b/bin4b');
    make_file('../stow/pkg4b/bin4b/file4b', 'bin4b/file4b - version originally in stow package');

    $stow->plan_stow('pkg4b');
    %conflicts = $stow->get_conflicts();
    is($stow->get_conflict_count, 2 => 'conflict per file');
    for my $i (0, 1) {
        my $target = $i ? 'file4b' : 'bin4b/file4b';
        like(
            $conflicts{stow}{pkg4b}[$i],
            qr,cannot stow ../stow/pkg4b/$target over existing target $target since neither a link nor a directory and --adopt not specified,
            => 'link to file4b conflicts with existing non-directory'
        );
    }
});

subtest("Package files 'file4d' conflicts with existing directories", sub {
    plan tests => 3;
    my $stow = new_Stow();

    # Populate target
    make_path('file4d');  # this is a directory but named like a file to create the conflict
    make_path('bin4d/file4d'); # same here

    # Populate stow package
    make_path('../stow/pkg4d');
    make_file('../stow/pkg4d/file4d',       'file4d - version originally in stow package');
    make_path('../stow/pkg4d/bin4d');
    make_file('../stow/pkg4d/bin4d/file4d', 'bin4d/file4d - version originally in stow package');

    $stow->plan_stow('pkg4d');
    %conflicts = $stow->get_conflicts();
    is($stow->get_conflict_count, 2 => 'conflict per file');
    for my $i (0, 1) {
        my $target = $i ? 'file4d' : 'bin4d/file4d';
        like(
            $conflicts{stow}{pkg4d}[$i],
            qr!cannot stow non-directory ../stow/pkg4d/$target over existing directory target $target!
            => 'link to file4d conflicts with existing non-directory'
        );
    }
});

subtest("Package files 'file4c' and 'bin4c' can adopt existing versions", sub {
    plan tests => 8;
    my $stow = new_Stow(adopt => 1);

    # Populate target
    make_file('file4c',       "file4c - version originally in target\n");
    make_path ('bin4c');
    make_file('bin4c/file4c', "bin4c/file4c - version originally in target\n");

    # Populate stow package
    make_path('../stow/pkg4c');
    make_file('../stow/pkg4c/file4c',       "file4c - version originally in stow package\n");
    make_path ('../stow/pkg4c/bin4c');
    make_file('../stow/pkg4c/bin4c/file4c', "bin4c/file4c - version originally in stow package\n");

    $stow->plan_stow('pkg4c');
    is($stow->get_conflict_count, 0 => 'no conflicts with --adopt');
    is($stow->get_tasks, 4 => 'two tasks per file');
    $stow->process_tasks();
    for my $file ('file4c', 'bin4c/file4c') {
        ok(-l $file, "$file turned into a symlink");
        is(
            readlink $file,
            (index($file, '/') == -1 ? '' : '../' )
            . "../stow/pkg4c/$file" => "$file points to right place"
        );
        is(cat_file($file), "$file - version originally in target\n" => "$file has right contents");
    }

});

subtest("Target already exists but is not owned by stow", sub {
    plan tests => 1;
    my $stow = new_Stow();

    make_path('bin5');
    make_invalid_link('bin5/file5','../../empty');
    make_path('../stow/pkg5/bin5/file5');

    $stow->plan_stow('pkg5');
    %conflicts = $stow->get_conflicts();
    like(
        $conflicts{stow}{pkg5}[-1],
        qr/not owned by stow/
        => 'target already exists but is not owned by stow'
    );
});

subtest("Replace existing but invalid target", sub {
    plan tests => 1;
    my $stow = new_Stow();

    make_invalid_link('file6','../stow/path-does-not-exist');
    make_path('../stow/pkg6');
    make_file('../stow/pkg6/file6');

    $stow->plan_stow('pkg6');
    $stow->process_tasks();
    is(
        readlink('file6'),
        '../stow/pkg6/file6'
        => 'replace existing but invalid target'
    );
});

subtest("Target already exists, is owned by stow, but points to a non-directory", sub {
    plan tests => 1;
    my $stow = new_Stow();
    #set_debug_level(4);

    make_path('bin7');
    make_path('../stow/pkg7a/bin7');
    make_file('../stow/pkg7a/bin7/node7');
    make_link('bin7/node7','../../stow/pkg7a/bin7/node7');
    make_path('../stow/pkg7b/bin7/node7');
    make_file('../stow/pkg7b/bin7/node7/file7');

    $stow->plan_stow('pkg7b');
    %conflicts = $stow->get_conflicts();
    like(
        $conflicts{stow}{pkg7b}[-1],
        qr/existing target is stowed to a different package/
        => 'link to new dir conflicts with existing stowed non-directory'
    );
});

subtest("stowing directories named 0", sub {
    plan tests => 4;
    my $stow = new_Stow();

    make_path('../stow/pkg8a/0');
    make_file('../stow/pkg8a/0/file8a');
    make_link('0' => '../stow/pkg8a/0'); # emulate stow

    make_path('../stow/pkg8b/0');
    make_file('../stow/pkg8b/0/file8b');

    $stow->plan_stow('pkg8b');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0);
    ok(-d '0');
    is(readlink('0/file8a'), '../../stow/pkg8a/0/file8a');
    is(readlink('0/file8b'), '../../stow/pkg8b/0/file8b'
        => 'stowing directories named 0'
    );
});

subtest("overriding already stowed documentation", sub {
    plan tests => 2;
    my $stow = new_Stow(override => ['man9', 'info9']);

    make_path('../stow/pkg9a/man9/man1');
    make_file('../stow/pkg9a/man9/man1/file9.1');
    make_path('man9/man1');
    make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

    make_path('../stow/pkg9b/man9/man1');
    make_file('../stow/pkg9b/man9/man1/file9.1');

    $stow->plan_stow('pkg9b');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0);
    is(readlink('man9/man1/file9.1'), '../../../stow/pkg9b/man9/man1/file9.1'
        => 'overriding existing documentation files'
    );
});

subtest("deferring to already stowed documentation", sub {
    plan tests => 3;
    my $stow = new_Stow(defer => ['man10', 'info10']);

    make_path('../stow/pkg10a/man10/man1');
    make_file('../stow/pkg10a/man10/man1/file10.1');
    make_path('man10/man1');
    make_link('man10/man1/file10.1' => '../../../stow/pkg10a/man10/man1/file10.1'); # emulate stow

    make_path('../stow/pkg10b/man10/man1');
    make_file('../stow/pkg10b/man10/man1/file10.1');

    $stow->plan_stow('pkg10b');
    is($stow->get_tasks, 0, 'no tasks to process');
    is($stow->get_conflict_count, 0);
    is(readlink('man10/man1/file10.1'), '../../../stow/pkg10a/man10/man1/file10.1'
        => 'defer to existing documentation files'
    );
});

subtest("Ignore temp files", sub {
    plan tests => 4;
    my $stow = new_Stow(ignore => ['~', '\.#.*']);

    make_path('../stow/pkg11/man11/man1');
    make_file('../stow/pkg11/man11/man1/file11.1');
    make_file('../stow/pkg11/man11/man1/file11.1~');
    make_file('../stow/pkg11/man11/man1/.#file11.1');
    make_path('man11/man1');

    $stow->plan_stow('pkg11');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0);
    is(readlink('man11/man1/file11.1'), '../../../stow/pkg11/man11/man1/file11.1');
    ok(!-e 'man11/man1/file11.1~');
    ok(!-e 'man11/man1/.#file11.1'
        => 'ignore temp files'
    );
});

subtest("stowing links library files", sub {
    plan tests => 3;
    my $stow = new_Stow();

    make_path('../stow/pkg12/lib12/');
    make_file('../stow/pkg12/lib12/lib.so.1');
    make_link('../stow/pkg12/lib12/lib.so', 'lib.so.1');

    make_path('lib12/');

    $stow->plan_stow('pkg12');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0);
    is(readlink('lib12/lib.so.1'), '../../stow/pkg12/lib12/lib.so.1');
    is(readlink('lib12/lib.so'), '../../stow/pkg12/lib12/lib.so'
        => 'stow links to libraries'
    );
});

subtest("unfolding to stow links to library files", sub {
    plan tests => 5;
    my $stow = new_Stow();

    make_path('../stow/pkg13a/lib13/');
    make_file('../stow/pkg13a/lib13/liba.so.1');
    make_link('../stow/pkg13a/lib13/liba.so', 'liba.so.1');
    make_link('lib13','../stow/pkg13a/lib13');

    make_path('../stow/pkg13b/lib13/');
    make_file('../stow/pkg13b/lib13/libb.so.1');
    make_link('../stow/pkg13b/lib13/libb.so', 'libb.so.1');

    $stow->plan_stow('pkg13b');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0);
    is(readlink('lib13/liba.so.1'), '../../stow/pkg13a/lib13/liba.so.1');
    is(readlink('lib13/liba.so'  ), '../../stow/pkg13a/lib13/liba.so');
    is(readlink('lib13/libb.so.1'), '../../stow/pkg13b/lib13/libb.so.1');
    is(readlink('lib13/libb.so'  ), '../../stow/pkg13b/lib13/libb.so'
       => 'unfolding to stow links to libraries'
    );
});

subtest("stowing to stow dir should fail", sub {
    plan tests => 4;
    make_path('stow');
    $stow = new_Stow(dir => 'stow');

    make_path('stow/pkg14/stow/pkg15');
    make_file('stow/pkg14/stow/pkg15/node15');

    stderr_like(
        sub { $stow->plan_stow('pkg14'); },
        qr/WARNING: skipping target which was current stow directory stow/,
        "stowing to stow dir should give warning"
    );

    is($stow->get_tasks, 0, 'no tasks to process');
    is($stow->get_conflict_count, 0);
    ok(
        ! -l 'stow/pkg15'
        => "stowing to stow dir should fail"
    );
});

subtest("stow a simple tree minimally when cwd isn't target", sub {
    plan tests => 2;
    cd('../..');
    $stow = new_Stow(dir => "$TEST_DIR/stow", target => "$TEST_DIR/target");

    make_path("$TEST_DIR/stow/pkg16/bin16");
    make_file("$TEST_DIR/stow/pkg16/bin16/file16");

    $stow->plan_stow('pkg16');
    $stow->process_tasks();
    is_deeply([ $stow->get_conflicts ], [], 'no conflicts with minimal stow');
    is(
        readlink("$TEST_DIR/target/bin16"),
        '../stow/pkg16/bin16',
        => "minimal stow of a simple tree when cwd isn't target"
    );
});

subtest("stow a simple tree minimally to absolute stow dir when cwd isn't", sub {
    plan tests => 2;
    my $stow = new_Stow(dir => canon_path("$TEST_DIR/stow"),
                        target => "$TEST_DIR/target");

    make_path("$TEST_DIR/stow/pkg17/bin17");
    make_file("$TEST_DIR/stow/pkg17/bin17/file17");

    $stow->plan_stow('pkg17');
    $stow->process_tasks();
    is_deeply([ $stow->get_conflicts ], [], 'no conflicts with minimal stow');
    is(
        readlink("$TEST_DIR/target/bin17"),
        '../stow/pkg17/bin17',
        => "minimal stow of a simple tree with absolute stow dir"
    );
});

subtest("stow a simple tree minimally with absolute stow AND target dirs when", sub {
    plan tests => 2;
    my $stow = new_Stow(dir    => canon_path("$TEST_DIR/stow"),
                        target => canon_path("$TEST_DIR/target"));

    make_path("$TEST_DIR/stow/pkg18/bin18");
    make_file("$TEST_DIR/stow/pkg18/bin18/file18");

    $stow->plan_stow('pkg18');
    $stow->process_tasks();
    is_deeply([ $stow->get_conflicts ], [], 'no conflicts with minimal stow');
    is(
        readlink("$TEST_DIR/target/bin18"),
        '../stow/pkg18/bin18',
        => "minimal stow of a simple tree with absolute stow and target dirs"
    );
});

subtest("stow a tree with no-folding enabled", sub {
    plan tests => 82;
    # folded directories should be split open (unfolded) where
    # (and only where) necessary
    #
    cd("$TEST_DIR/target");

    sub create_pkg {
        my ($id, $pkg) = @_;

        my $stow_pkg = "../stow/$id-$pkg";
        make_path ($stow_pkg);
        make_file("$stow_pkg/$id-file-$pkg");

        # create a shallow hierarchy specific to this package which isn't
        # yet stowed
        make_path ("$stow_pkg/$id-$pkg-only-new");
        make_file("$stow_pkg/$id-$pkg-only-new/$id-file-$pkg");

        # create a deeper hierarchy specific to this package which isn't
        # yet stowed
        make_path ("$stow_pkg/$id-$pkg-only-new2/subdir");
        make_file("$stow_pkg/$id-$pkg-only-new2/subdir/$id-file-$pkg");
        make_link("$stow_pkg/$id-$pkg-only-new2/current", "subdir");

        # create a hierarchy specific to this package which is already
        # stowed via a folded tree
        make_path ("$stow_pkg/$id-$pkg-only-old");
        make_link("$id-$pkg-only-old", "$stow_pkg/$id-$pkg-only-old");
        make_file("$stow_pkg/$id-$pkg-only-old/$id-file-$pkg");

        # create a shared hierarchy which this package uses
        make_path ("$stow_pkg/$id-shared");
        make_file("$stow_pkg/$id-shared/$id-file-$pkg");

        # create a partially shared hierarchy which this package uses
        make_path ("$stow_pkg/$id-shared2/subdir-$pkg");
        make_file("$stow_pkg/$id-shared2/$id-file-$pkg");
        make_file("$stow_pkg/$id-shared2/subdir-$pkg/$id-file-$pkg");
    }

    foreach my $pkg (qw{a b}) {
        create_pkg('no-folding', $pkg);
    }

    $stow = new_Stow('no-folding' => 1);
    $stow->plan_stow('no-folding-a');
    is_deeply([ $stow->get_conflicts ], [] => 'no conflicts with --no-folding');
    my @tasks = $stow->get_tasks;
    use Data::Dumper;
    is(scalar(@tasks), 13 => "6 dirs, 7 links") || warn Dumper(\@tasks);
    $stow->process_tasks();

    sub check_no_folding {
        my ($pkg) = @_;
        my $stow_pkg = "../stow/no-folding-$pkg";
        is_link("no-folding-file-$pkg", "$stow_pkg/no-folding-file-$pkg");

        # check existing folded tree is untouched
        is_link("no-folding-$pkg-only-old", "$stow_pkg/no-folding-$pkg-only-old");

        # check newly stowed shallow tree is not folded
        is_dir_not_symlink("no-folding-$pkg-only-new");
        is_link("no-folding-$pkg-only-new/no-folding-file-$pkg",
                "../$stow_pkg/no-folding-$pkg-only-new/no-folding-file-$pkg");

        # check newly stowed deeper tree is not folded
        is_dir_not_symlink("no-folding-$pkg-only-new2");
        is_dir_not_symlink("no-folding-$pkg-only-new2/subdir");
        is_link("no-folding-$pkg-only-new2/subdir/no-folding-file-$pkg",
                "../../$stow_pkg/no-folding-$pkg-only-new2/subdir/no-folding-file-$pkg");
        is_link("no-folding-$pkg-only-new2/current",
                "../$stow_pkg/no-folding-$pkg-only-new2/current");

        # check shared tree is not folded. first time round this will be
        # newly stowed.
        is_dir_not_symlink('no-folding-shared');
        is_link("no-folding-shared/no-folding-file-$pkg",
                "../$stow_pkg/no-folding-shared/no-folding-file-$pkg");

        # check partially shared tree is not folded. first time round this
        # will be newly stowed.
        is_dir_not_symlink('no-folding-shared2');
        is_link("no-folding-shared2/no-folding-file-$pkg",
                "../$stow_pkg/no-folding-shared2/no-folding-file-$pkg");
        is_link("no-folding-shared2/no-folding-file-$pkg",
                "../$stow_pkg/no-folding-shared2/no-folding-file-$pkg");
    }

    check_no_folding('a');

    $stow = new_Stow('no-folding' => 1);
    $stow->plan_stow('no-folding-b');
    is_deeply([ $stow->get_conflicts ], [] => 'no conflicts with --no-folding');
    @tasks = $stow->get_tasks;
    is(scalar(@tasks), 11 => '4 dirs, 7 links') || warn Dumper(\@tasks);
    $stow->process_tasks();

    check_no_folding('a');
    check_no_folding('b');
});
