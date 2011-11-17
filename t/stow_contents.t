#!/usr/local/bin/perl

#
# Testing 
#

# load as a library
BEGIN { use lib qw(.); require "t/util.pm"; require "stow"; }

use Test::More tests => 14;
use Test::Output;
use English qw(-no_match_vars);

# local utility
sub reset_state {
    @Tasks          = ();
    @Conflicts      = ();
    %Link_Task_For  = ();
    %Dir_Task_For   = ();
    %Option         = ();
    return;
}

### setup 
eval { remove_dir('t/target'); };
eval { remove_dir('t/stow'); };
make_dir('t/target');
make_dir('t/stow');

chdir 't/target';
$Stow_Path= '../stow';

# Note that each of the following tests use a distinct set of files

#
# stow a simple tree minimally
# 
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
stow_contents('../stow/pkg1', './', '../stow/pkg1');
process_tasks();
is( 
    readlink('bin1'),  
    '../stow/pkg1/bin1', 
    => 'minimal stow of a simple tree' 
);

#
# stow a simple tree into an existing directory
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg2/lib2');
make_file('../stow/pkg2/lib2/file2');
make_dir('lib2');
stow_contents('../stow/pkg2', '.', '../stow/pkg2');
process_tasks();
is( 
    readlink('lib2/file2'),
    '../../stow/pkg2/lib2/file2', 
    => 'stow simple tree to existing directory' 
);

#
# unfold existing tree 
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg3a/bin3');
make_file('../stow/pkg3a/bin3/file3a');
make_link('bin3' => '../stow/pkg3a/bin3'); # emulate stow

make_dir('../stow/pkg3b/bin3');
make_file('../stow/pkg3b/bin3/file3b');
stow_contents('../stow/pkg3b', './', '../stow/pkg3b');
process_tasks();
ok( 
    -d 'bin3' &&
    readlink('bin3/file3a') eq '../../stow/pkg3a/bin3/file3a'  &&
    readlink('bin3/file3b') eq '../../stow/pkg3b/bin3/file3b' 
    => 'target already has 1 stowed package'
);

#
# Link to a new  dir conflicts with existing non-dir (can't unfold)
#
reset_state();
$Option{'verbose'} = 0;

make_file('bin4'); # this is a file but named like a directory
make_dir('../stow/pkg4/bin4'); 
make_file('../stow/pkg4/bin4/file4'); 
stow_contents('../stow/pkg4', './', '../stow/pkg4');
like( 
    $Conflicts[-1], qr(CONFLICT:.*existing target is neither a link nor a directory)
    => 'link to new dir conflicts with existing non-directory'
);

#
# Target already exists but is not owned by stow
#
reset_state();
$Option{'verbose'} = 0;

make_dir('bin5'); 
make_link('bin5/file5','../../empty');
make_dir('../stow/pkg5/bin5/file5'); 
stow_contents('../stow/pkg5', './', '../stow/pkg5');
like( 
    $Conflicts[-1], qr(CONFLICT:.*not owned by stow) 
    => 'target already exists but is not owned by stow'
);

#
# Replace existing but invalid target 
#
reset_state();
$Option{'verbose'} = 0;

make_link('file6','../stow/path-does-not-exist');
make_dir('../stow/pkg6');
make_file('../stow/pkg6/file6');
eval{ stow_contents('../stow/pkg6', './', '../stow/pkg6'); process_tasks() };
is( 
    readlink('file6'),
    '../stow/pkg6/file6' 
    => 'replace existing but invalid target'
);

#
# Target already exists, is owned by stow, but points to a non-directory
# (can't unfold)
#
reset_state();
$Option{'verbose'} = 0;

make_dir('bin7');
make_dir('../stow/pkg7a/bin7');
make_file('../stow/pkg7a/bin7/node7');
make_link('bin7/node7','../../stow/pkg7a/bin7/node7');
make_dir('../stow/pkg7b/bin7/node7');
make_file('../stow/pkg7b/bin7/node7/file7');
stow_contents('../stow/pkg7b', './', '../stow/pkg7b');
like( 
    $Conflicts[-1], qr(CONFLICT:.*existing target is stowed to a different package)
    => 'link to new dir conflicts with existing stowed non-directory'
);

#
# stowing directories named 0
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg8a/0');
make_file('../stow/pkg8a/0/file8a');
make_link('0' => '../stow/pkg8a/0'); # emulate stow

make_dir('../stow/pkg8b/0');
make_file('../stow/pkg8b/0/file8b');
stow_contents('../stow/pkg8b', './', '../stow/pkg8b');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    -d '0' &&
    readlink('0/file8a') eq '../../stow/pkg8a/0/file8a'  &&
    readlink('0/file8b') eq '../../stow/pkg8b/0/file8b' 
    => 'stowing directories named 0'
);

#
# overriding already stowed documentation
#
reset_state();
$Option{'verbose'} = 0;
$Option{'override'} = ['man9', 'info9'];

make_dir('../stow/pkg9a/man9/man1');
make_file('../stow/pkg9a/man9/man1/file9.1');
make_dir('man9/man1');
make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

make_dir('../stow/pkg9b/man9/man1');
make_file('../stow/pkg9b/man9/man1/file9.1');
stow_contents('../stow/pkg9b', './', '../stow/pkg9b');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('man9/man1/file9.1') eq '../../../stow/pkg9b/man9/man1/file9.1' 
    => 'overriding existing documentation files'
);

#
# deferring to already stowed documentation
#
reset_state();
$Option{'verbose'} = 0;
$Option{'defer'} = ['man10', 'info10'];

make_dir('../stow/pkg10a/man10/man1');
make_file('../stow/pkg10a/man10/man1/file10.1');
make_dir('man10/man1');
make_link('man10/man1/file10.1' => '../../../stow/pkg10a/man10/man1/file10.1'); # emulate stow

make_dir('../stow/pkg10b/man10/man1');
make_file('../stow/pkg10b/man10/man1/file10.1');
stow_contents('../stow/pkg10b', './', '../stow/pkg10b');
stderr_like(
  sub { process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process'
);
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('man10/man1/file10.1') eq '../../../stow/pkg10a/man10/man1/file10.1' 
    => 'defer to existing documentation files'
);

#
# Ignore temp files
#
reset_state();
$Option{'verbose'} = 0;
$Option{'ignore'} = ['~', '\.#.*'];

make_dir('../stow/pkg11/man11/man1');
make_file('../stow/pkg11/man11/man1/file11.1');
make_file('../stow/pkg11/man11/man1/file11.1~');
make_file('../stow/pkg11/man11/man1/.#file11.1');
make_dir('man11/man1');

stow_contents('../stow/pkg11', './', '../stow/pkg11');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('man11/man1/file11.1') eq '../../../stow/pkg11/man11/man1/file11.1' &&
    !-e 'man11/man1/file11.1~' && 
    !-e 'man11/man1/.#file11.1'
    => 'ignore temp files'
);

#
# stowing links library files
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg12/lib12/');
make_file('../stow/pkg12/lib12/lib.so');
make_link('../stow/pkg12/lib12/lib.so.1','lib.so');

make_dir('lib12/');
stow_contents('../stow/pkg12', './', '../stow/pkg12');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('lib12/lib.so.1') eq '../../stow/pkg12/lib12/lib.so.1' 
    => 'stow links to libraries'
);

#
# unfolding to stow links to library files
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg13a/lib13/');
make_file('../stow/pkg13a/lib13/liba.so');
make_link('../stow/pkg13a/lib13/liba.so.1', 'liba.so');
make_link('lib13','../stow/pkg13a/lib13');

make_dir('../stow/pkg13b/lib13/');
make_file('../stow/pkg13b/lib13/libb.so');
make_link('../stow/pkg13b/lib13/libb.so.1', 'libb.so');

stow_contents('../stow/pkg13b', './', '../stow/pkg13b');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('lib13/liba.so.1') eq '../../stow/pkg13a/lib13/liba.so.1'  &&
    readlink('lib13/libb.so.1') eq '../../stow/pkg13b/lib13/libb.so.1'  
    => 'unfolding to stow links to libraries'
);
