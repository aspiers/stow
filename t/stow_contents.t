#!/usr/local/bin/perl

#
# Testing stow_contents()
#

use strict;
use warnings;

use Test::More tests => 23;
use Test::Output;
use English qw(-no_match_vars);

use Stow::Util qw(canon_path);
use testutil;

init_test_dirs();
cd("$OUT_DIR/target");

my $stow;
my %conflicts;

# Note that each of the following tests use a distinct set of files

#
# stow a simple tree minimally
# 
$stow = new_Stow(dir => '../stow');

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');

$stow->plan_stow('pkg1');
$stow->process_tasks();
is($stow->get_conflicts(), 0, 'no conflicts with minimal stow');
is( 
    readlink('bin1'),  
    '../stow/pkg1/bin1', 
    => 'minimal stow of a simple tree' 
);

#
# stow a simple tree into an existing directory
#
$stow = new_Stow();

make_dir('../stow/pkg2/lib2');
make_file('../stow/pkg2/lib2/file2');
make_dir('lib2');
$stow->plan_stow('pkg2');
$stow->process_tasks();
is( 
    readlink('lib2/file2'),
    '../../stow/pkg2/lib2/file2', 
    => 'stow simple tree to existing directory' 
);

#
# unfold existing tree 
#
$stow = new_Stow();

make_dir('../stow/pkg3a/bin3');
make_file('../stow/pkg3a/bin3/file3a');
make_link('bin3' => '../stow/pkg3a/bin3'); # emulate stow

make_dir('../stow/pkg3b/bin3');
make_file('../stow/pkg3b/bin3/file3b');
$stow->plan_stow('pkg3b');
$stow->process_tasks();
ok( 
    -d 'bin3' &&
    readlink('bin3/file3a') eq '../../stow/pkg3a/bin3/file3a'  &&
    readlink('bin3/file3b') eq '../../stow/pkg3b/bin3/file3b' 
    => 'target already has 1 stowed package'
);

#
# Link to a new dir conflicts with existing non-dir (can't unfold)
#
$stow = new_Stow();

make_file('bin4'); # this is a file but named like a directory
make_dir('../stow/pkg4/bin4'); 
make_file('../stow/pkg4/bin4/file4'); 
$stow->plan_stow('pkg4');
%conflicts = $stow->get_conflicts();
like(
    $conflicts{stow}{pkg4}[-1],
    qr(existing target is neither a link nor a directory)
    => 'link to new dir conflicts with existing non-directory'
);

#
# Target already exists but is not owned by stow
#
$stow = new_Stow();

make_dir('bin5'); 
make_link('bin5/file5','../../empty');
make_dir('../stow/pkg5/bin5/file5'); 
$stow->plan_stow('pkg5');
%conflicts = $stow->get_conflicts();
like( 
    $conflicts{stow}{pkg5}[-1],
    qr(not owned by stow)
    => 'target already exists but is not owned by stow'
);

#
# Replace existing but invalid target 
#
$stow = new_Stow();

make_link('file6','../stow/path-does-not-exist');
make_dir('../stow/pkg6');
make_file('../stow/pkg6/file6');
$stow->plan_stow('pkg6');
$stow->process_tasks();
is( 
    readlink('file6'),
    '../stow/pkg6/file6' 
    => 'replace existing but invalid target'
);

#
# Target already exists, is owned by stow, but points to a non-directory
# (can't unfold)
#
$stow = new_Stow();

make_dir('bin7');
make_dir('../stow/pkg7a/bin7');
make_file('../stow/pkg7a/bin7/node7');
make_link('bin7/node7','../../stow/pkg7a/bin7/node7');
make_dir('../stow/pkg7b/bin7/node7');
make_file('../stow/pkg7b/bin7/node7/file7');
$stow->plan_stow('pkg7b');
%conflicts = $stow->get_conflicts();
like(
    $conflicts{stow}{pkg7b}[-1],
    qr(existing target is stowed to a different package)
    => 'link to new dir conflicts with existing stowed non-directory'
);

#
# stowing directories named 0
#
$stow = new_Stow();

make_dir('../stow/pkg8a/0');
make_file('../stow/pkg8a/0/file8a');
make_link('0' => '../stow/pkg8a/0'); # emulate stow

make_dir('../stow/pkg8b/0');
make_file('../stow/pkg8b/0/file8b');
$stow->plan_stow('pkg8b');
$stow->process_tasks();
ok( 
    scalar($stow->get_conflicts) == 0 &&
    -d '0' &&
    readlink('0/file8a') eq '../../stow/pkg8a/0/file8a'  &&
    readlink('0/file8b') eq '../../stow/pkg8b/0/file8b' 
    => 'stowing directories named 0'
);

#
# overriding already stowed documentation
#
$stow = new_Stow(override => ['man9', 'info9']);

make_dir('../stow/pkg9a/man9/man1');
make_file('../stow/pkg9a/man9/man1/file9.1');
make_dir('man9/man1');
make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

make_dir('../stow/pkg9b/man9/man1');
make_file('../stow/pkg9b/man9/man1/file9.1');
$stow->plan_stow('pkg9b');
$stow->process_tasks();
ok( 
    scalar($stow->get_conflicts) == 0 &&
    readlink('man9/man1/file9.1') eq '../../../stow/pkg9b/man9/man1/file9.1' 
    => 'overriding existing documentation files'
);

#
# deferring to already stowed documentation
#
$stow = new_Stow(defer => ['man10', 'info10']);

make_dir('../stow/pkg10a/man10/man1');
make_file('../stow/pkg10a/man10/man1/file10.1');
make_dir('man10/man1');
make_link('man10/man1/file10.1' => '../../../stow/pkg10a/man10/man1/file10.1'); # emulate stow

make_dir('../stow/pkg10b/man10/man1');
make_file('../stow/pkg10b/man10/man1/file10.1');
$stow->plan_stow('pkg10b');

stderr_like(
  sub { $stow->process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process'
);
ok( 
    scalar($stow->get_conflicts) == 0 &&
    readlink('man10/man1/file10.1') eq '../../../stow/pkg10a/man10/man1/file10.1' 
    => 'defer to existing documentation files'
);

#
# Ignore temp files
#
$stow = new_Stow(ignore => ['~', '\.#.*']);

make_dir('../stow/pkg11/man11/man1');
make_file('../stow/pkg11/man11/man1/file11.1');
make_file('../stow/pkg11/man11/man1/file11.1~');
make_file('../stow/pkg11/man11/man1/.#file11.1');
make_dir('man11/man1');

$stow->plan_stow('pkg11');
$stow->process_tasks();
ok( 
    scalar($stow->get_conflicts) == 0 &&
    readlink('man11/man1/file11.1') eq '../../../stow/pkg11/man11/man1/file11.1' &&
    !-e 'man11/man1/file11.1~' && 
    !-e 'man11/man1/.#file11.1'
    => 'ignore temp files'
);

#
# stowing links library files
#
$stow = new_Stow();

make_dir('../stow/pkg12/lib12/');
make_file('../stow/pkg12/lib12/lib.so');
make_link('../stow/pkg12/lib12/lib.so.1','lib.so');

make_dir('lib12/');
$stow->plan_stow('pkg12');
$stow->process_tasks();
ok( 
    scalar($stow->get_conflicts) == 0 &&
    readlink('lib12/lib.so.1') eq '../../stow/pkg12/lib12/lib.so.1' 
    => 'stow links to libraries'
);

#
# unfolding to stow links to library files
#
$stow = new_Stow();

make_dir('../stow/pkg13a/lib13/');
make_file('../stow/pkg13a/lib13/liba.so');
make_link('../stow/pkg13a/lib13/liba.so.1', 'liba.so');
make_link('lib13','../stow/pkg13a/lib13');

make_dir('../stow/pkg13b/lib13/');
make_file('../stow/pkg13b/lib13/libb.so');
make_link('../stow/pkg13b/lib13/libb.so.1', 'libb.so');

$stow->plan_stow('pkg13b');
$stow->process_tasks();
ok( 
    scalar($stow->get_conflicts) == 0 &&
    readlink('lib13/liba.so.1') eq '../../stow/pkg13a/lib13/liba.so.1'  &&
    readlink('lib13/libb.so.1') eq '../../stow/pkg13b/lib13/libb.so.1'  
    => 'unfolding to stow links to libraries'
);

#
# stowing to stow dir should fail
#
make_dir('stow');
$stow = new_Stow(dir => 'stow');

make_dir('stow/pkg14/stow/pkg15');
make_file('stow/pkg14/stow/pkg15/node15');

$stow->plan_stow('pkg14');
stderr_like(
  sub { $stow->process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process'
);
ok(
    scalar($stow->get_conflicts) == 0 &&
    ! -l 'stow/pkg15'
    => "stowing to stow dir should fail"
);

#
# stow a simple tree minimally when cwd isn't target
#
cd('../..');
$stow = new_Stow(dir => "$OUT_DIR/stow", target => "$OUT_DIR/target");

make_dir("$OUT_DIR/stow/pkg16/bin16");
make_file("$OUT_DIR/stow/pkg16/bin16/file16");

$stow->plan_stow('pkg16');
$stow->process_tasks();
is($stow->get_conflicts(), 0, 'no conflicts with minimal stow');
is(
    readlink("$OUT_DIR/target/bin16"),
    '../stow/pkg16/bin16',
    => "minimal stow of a simple tree when cwd isn't target"
);

#
# stow a simple tree minimally to absolute stow dir when cwd isn't
# target
#
$stow = new_Stow(dir    => canon_path("$OUT_DIR/stow"),
                 target => "$OUT_DIR/target");

make_dir("$OUT_DIR/stow/pkg17/bin17");
make_file("$OUT_DIR/stow/pkg17/bin17/file17");

$stow->plan_stow('pkg17');
$stow->process_tasks();
is($stow->get_conflicts(), 0, 'no conflicts with minimal stow');
is(
    readlink("$OUT_DIR/target/bin17"),
    '../stow/pkg17/bin17',
    => "minimal stow of a simple tree with absolute stow dir"
);

#
# stow a simple tree minimally with absolute stow AND target dirs when
# cwd isn't target
#
$stow = new_Stow(dir    => canon_path("$OUT_DIR/stow"),
                 target => canon_path("$OUT_DIR/target"));

make_dir("$OUT_DIR/stow/pkg18/bin18");
make_file("$OUT_DIR/stow/pkg18/bin18/file18");

$stow->plan_stow('pkg18');
$stow->process_tasks();
is($stow->get_conflicts(), 0, 'no conflicts with minimal stow');
is(
    readlink("$OUT_DIR/target/bin18"),
    '../stow/pkg18/bin18',
    => "minimal stow of a simple tree with absolute stow and target dirs"
);
