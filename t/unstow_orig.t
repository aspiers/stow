#!/usr/local/bin/perl

#
# Test unstowing packages in compat mode
#

use strict;
use warnings;

use Test::More tests => 23;
use Test::Output;
use English qw(-no_match_vars);

use testutil;
use Stow::Util qw(canon_path);

init_test_dirs();
cd("$OUT_DIR/target");

# Note that each of the following tests use a distinct set of files

my $stow;
my %conflicts;

#
# unstow a simple tree minimally
# 

$stow = new_compat_Stow();

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_link('bin1', '../stow/pkg1/bin1');

$stow->plan_unstow('pkg1');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/pkg1/bin1/file1' && ! -e 'bin1'
    => 'unstow a simple tree' 
);

#
# unstow a simple tree from an existing directory
#
$stow = new_compat_Stow();

make_dir('lib2');
make_dir('../stow/pkg2/lib2');
make_file('../stow/pkg2/lib2/file2');
make_link('lib2/file2', '../../stow/pkg2/lib2/file2');
$stow->plan_unstow('pkg2');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/pkg2/lib2/file2' && -d 'lib2'
    => 'unstow simple tree from a pre-existing directory' 
);

#
# fold tree after unstowing
#
$stow = new_compat_Stow();

make_dir('bin3');

make_dir('../stow/pkg3a/bin3');
make_file('../stow/pkg3a/bin3/file3a');
make_link('bin3/file3a' => '../../stow/pkg3a/bin3/file3a'); # emulate stow

make_dir('../stow/pkg3b/bin3');
make_file('../stow/pkg3b/bin3/file3b');
make_link('bin3/file3b' => '../../stow/pkg3b/bin3/file3b'); # emulate stow
$stow->plan_unstow('pkg3b');
$stow->process_tasks();
ok( 
    $stow->get_conflict_count == 0 &&
    -l 'bin3' &&
    readlink('bin3') eq '../stow/pkg3a/bin3' 
    => 'fold tree after unstowing'
);

#
# existing link is owned by stow but is invalid so it gets removed anyway
#
$stow = new_compat_Stow();

make_dir('bin4');
make_dir('../stow/pkg4/bin4');
make_file('../stow/pkg4/bin4/file4');
make_invalid_link('bin4/file4', '../../stow/pkg4/bin4/does-not-exist');

$stow->plan_unstow('pkg4');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    ! -e 'bin4/file4'
    => q(remove invalid link owned by stow)
);

#
# Existing link is not owned by stow
#
$stow = new_compat_Stow();

make_dir('../stow/pkg5/bin5');
make_invalid_link('bin5', '../not-stow');

$stow->plan_unstow('pkg5');
# Unlike the corresponding stow_contents.t test, this doesn't
# cause any conflicts.
#
#like(
#    $Conflicts[-1], qr(can't unlink.*not owned by stow)
#    => q(existing link not owned by stow)
#);
ok(
    -l 'bin5' && readlink('bin5') eq '../not-stow'
    => q(existing link not owned by stow)
);

#
# Target already exists, is owned by stow, but points to a different package
#
$stow = new_compat_Stow();

make_dir('bin6');
make_dir('../stow/pkg6a/bin6');
make_file('../stow/pkg6a/bin6/file6');
make_link('bin6/file6', '../../stow/pkg6a/bin6/file6');

make_dir('../stow/pkg6b/bin6');
make_file('../stow/pkg6b/bin6/file6');

$stow->plan_unstow('pkg6b');
ok(
    $stow->get_conflict_count == 0 &&
    -l 'bin6/file6' &&
    readlink('bin6/file6') eq '../../stow/pkg6a/bin6/file6'
    => q(ignore existing link that points to a different package)
);

#
# Don't unlink anything under the stow directory
#
make_dir('stow'); # make out stow dir a subdir of target
$stow = new_compat_Stow(dir => 'stow');

# emulate stowing into ourself (bizarre corner case or accident)
make_dir('stow/pkg7a/stow/pkg7b');
make_file('stow/pkg7a/stow/pkg7b/file7b');
make_link('stow/pkg7b', '../stow/pkg7a/stow/pkg7b');

$stow->plan_unstow('pkg7b');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg7b');
ok(
    $stow->get_conflict_count == 0 &&
    -l 'stow/pkg7b' &&
    readlink('stow/pkg7b') eq '../stow/pkg7a/stow/pkg7b'
    => q(don't unlink any nodes under the stow directory)
);

#
# Don't unlink any nodes under another stow directory
#
$stow = new_compat_Stow(dir => 'stow');

make_dir('stow2'); # make our alternate stow dir a subdir of target
make_file('stow2/.stow');

# emulate stowing into ourself (bizarre corner case or accident)
make_dir('stow/pkg8a/stow2/pkg8b');
make_file('stow/pkg8a/stow2/pkg8b/file8b');
make_link('stow2/pkg8b', '../stow/pkg8a/stow2/pkg8b');

$stow->plan_unstow('pkg8a');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg8a');
ok(
    $stow->get_conflict_count == 0 &&
    -l 'stow2/pkg8b' &&
    readlink('stow2/pkg8b') eq '../stow/pkg8a/stow2/pkg8b'
    => q(don't unlink any nodes under another stow directory)
);

#
# overriding already stowed documentation
#
$stow = new_compat_Stow(override => ['man9', 'info9']);
make_file('stow/.stow');

make_dir('../stow/pkg9a/man9/man1');
make_file('../stow/pkg9a/man9/man1/file9.1');
make_dir('man9/man1');
make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

make_dir('../stow/pkg9b/man9/man1');
make_file('../stow/pkg9b/man9/man1/file9.1');
$stow->plan_unstow('pkg9b');
$stow->process_tasks();
ok( 
    $stow->get_conflict_count == 0 &&
    !-l 'man9/man1/file9.1'
    => 'overriding existing documentation files'
);

#
# deferring to already stowed documentation
#
$stow = new_compat_Stow(defer => ['man10', 'info10']);

make_dir('../stow/pkg10a/man10/man1');
make_file('../stow/pkg10a/man10/man1/file10a.1');
make_dir('man10/man1');
make_link('man10/man1/file10a.1'  => '../../../stow/pkg10a/man10/man1/file10a.1');

# need this to block folding
make_dir('../stow/pkg10b/man10/man1');
make_file('../stow/pkg10b/man10/man1/file10b.1');
make_link('man10/man1/file10b.1'  => '../../../stow/pkg10b/man10/man1/file10b.1');


make_dir('../stow/pkg10c/man10/man1');
make_file('../stow/pkg10c/man10/man1/file10a.1');
$stow->plan_unstow('pkg10c');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg10c');
ok( 
    $stow->get_conflict_count == 0 &&
    readlink('man10/man1/file10a.1') eq '../../../stow/pkg10a/man10/man1/file10a.1' 
    => 'defer to existing documentation files'
);

#
# Ignore temp files
#
$stow = new_compat_Stow(ignore => ['~', '\.#.*']);

make_dir('../stow/pkg12/man12/man1');
make_file('../stow/pkg12/man12/man1/file12.1');
make_file('../stow/pkg12/man12/man1/file12.1~');
make_file('../stow/pkg12/man12/man1/.#file12.1');
make_dir('man12/man1');
make_link('man12/man1/file12.1'  => '../../../stow/pkg12/man12/man1/file12.1');

$stow->plan_unstow('pkg12');
$stow->process_tasks();
ok( 
    $stow->get_conflict_count == 0 &&
    !-e 'man12/man1/file12.1'
    => 'ignore temp files'
);

#
# Unstow an already unstowed package
#
$stow = new_compat_Stow();
$stow->plan_unstow('pkg12');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12');
ok(
    $stow->get_conflict_count == 0
    => 'unstow already unstowed package pkg12'
);

#
# Unstow a never stowed package
#

eval { remove_dir("$OUT_DIR/target"); };
mkdir("$OUT_DIR/target");

$stow = new_compat_Stow();
$stow->plan_unstow('pkg12');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12 which was never stowed');
ok(
    $stow->get_conflict_count == 0
    => 'unstow never stowed package pkg12'
);

#
# Unstowing when target contains a real file shouldn't be an issue.
#
make_file('man12/man1/file12.1');

$stow = new_compat_Stow();
$stow->plan_unstow('pkg12');
is($stow->get_tasks, 0, 'no tasks to process when unstowing pkg12 for third time');
%conflicts = $stow->get_conflicts;
ok(
    $stow->get_conflict_count == 1 &&
    $conflicts{unstow}{pkg12}[0]
        =~ m!existing target is neither a link nor a directory: man12/man1/file12\.1!
    => 'unstow pkg12 for third time'
);

#
# unstow a simple tree minimally when cwd isn't target
#
cd('../..');
$stow = new_Stow(dir => "$OUT_DIR/stow", target => "$OUT_DIR/target");

make_dir("$OUT_DIR/stow/pkg13/bin13");
make_file("$OUT_DIR/stow/pkg13/bin13/file13");
make_link("$OUT_DIR/target/bin13", '../stow/pkg13/bin13');

$stow->plan_unstow('pkg13');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f "$OUT_DIR/stow/pkg13/bin13/file13" && ! -e "$OUT_DIR/target/bin13"
    => 'unstow a simple tree' 
);

#
# unstow a simple tree minimally with absolute stow dir when cwd isn't
# target
#
$stow = new_Stow(dir    => canon_path("$OUT_DIR/stow"),
                 target => "$OUT_DIR/target");

make_dir("$OUT_DIR/stow/pkg14/bin14");
make_file("$OUT_DIR/stow/pkg14/bin14/file14");
make_link("$OUT_DIR/target/bin14", '../stow/pkg14/bin14');

$stow->plan_unstow('pkg14');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f "$OUT_DIR/stow/pkg14/bin14/file14" && ! -e "$OUT_DIR/target/bin14"
    => 'unstow a simple tree with absolute stow dir'
);

#
# unstow a simple tree minimally with absolute stow AND target dirs
# when cwd isn't target
#
$stow = new_Stow(dir    => canon_path("$OUT_DIR/stow"),
                 target => canon_path("$OUT_DIR/target"));

make_dir("$OUT_DIR/stow/pkg15/bin15");
make_file("$OUT_DIR/stow/pkg15/bin15/file15");
make_link("$OUT_DIR/target/bin15", '../stow/pkg15/bin15');

$stow->plan_unstow('pkg15');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f "$OUT_DIR/stow/pkg15/bin15/file15" && ! -e "$OUT_DIR/target/bin15"
    => 'unstow a simple tree with absolute stow and target dirs'
);


# Todo
#
# Test cleaning up subdirs with --paranoid option

