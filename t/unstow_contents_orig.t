#!/usr/local/bin/perl

#
# Testing unstow_contents_orig()
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
eval { remove_dir('t/stow');   };
make_dir('t/target');
make_dir('t/stow');

chdir 't/target';
$Stow_Path= '../stow';

# Note that each of the following tests use a distinct set of files

#
# unstow a simple tree minimally
# 

reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_link('bin1','../stow/pkg1/bin1');

unstow_contents_orig('../stow/pkg1','.');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    -f '../stow/pkg1/bin1/file1' && ! -e 'bin1'
    => 'unstow a simple tree' 
);

#
# unstow a simple tree from an existing directory
#
reset_state();
$Option{'verbose'} = 0;

make_dir('lib2');
make_dir('../stow/pkg2/lib2');
make_file('../stow/pkg2/lib2/file2');
make_link('lib2/file2', '../../stow/pkg2/lib2/file2');
unstow_contents_orig('../stow/pkg2','.');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    -f '../stow/pkg2/lib2/file2' && -d 'lib2'
    => 'unstow simple tree from a pre-existing directory' 
);

#
# fold tree after unstowing
#
reset_state();
$Option{'verbose'} = 0;

make_dir('bin3');

make_dir('../stow/pkg3a/bin3');
make_file('../stow/pkg3a/bin3/file3a');
make_link('bin3/file3a' => '../../stow/pkg3a/bin3/file3a'); # emulate stow

make_dir('../stow/pkg3b/bin3');
make_file('../stow/pkg3b/bin3/file3b');
make_link('bin3/file3b' => '../../stow/pkg3b/bin3/file3b'); # emulate stow
unstow_contents_orig('../stow/pkg3b', '.');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    -l 'bin3' &&
    readlink('bin3') eq '../stow/pkg3a/bin3' 
    => 'fold tree after unstowing'
);

#
# existing link is owned by stow but is invalid so it gets removed anyway
#
reset_state();
$Option{'verbose'} = 0;

make_dir('bin4');
make_dir('../stow/pkg4/bin4');
make_file('../stow/pkg4/bin4/file4');
make_link('bin4/file4', '../../stow/pkg4/bin4/does-not-exist');

unstow_contents_orig('../stow/pkg4', '.');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    ! -e 'bin4/file4'
    => q(remove invalid link owned by stow)
);

#
# Existing link is not owned by stow
#
reset_state();
$Option{'verbose'} = 0;

make_dir('../stow/pkg5/bin5');
make_link('bin5', '../not-stow');

unstow_contents_orig('../stow/pkg5', '.');
#like(
#    $Conflicts[-1], qr(CONFLICT:.*can't unlink.*not owned by stow)
#    => q(existing link not owned by stow)
#);
ok(
    -l 'bin5' && readlink('bin5') eq '../not-stow'
    => q(existing link not owned by stow)
);
#
# Target already exists, is owned by stow, but points to a different package
#
reset_state();
$Option{'verbose'} = 0;

make_dir('bin6');
make_dir('../stow/pkg6a/bin6');
make_file('../stow/pkg6a/bin6/file6');
make_link('bin6/file6', '../../stow/pkg6a/bin6/file6');

make_dir('../stow/pkg6b/bin6');
make_file('../stow/pkg6b/bin6/file6');

unstow_contents_orig('../stow/pkg6b', '.');
ok(
    -l 'bin6/file6' && readlink('bin6/file6') eq '../../stow/pkg6a/bin6/file6'
    => q(existing link owned by stow but points to a different package)
);

#
# Don't unlink anything under the stow directory
#
reset_state();
$Option{'verbose'} = 0;

make_dir('stow'); # make out stow dir a subdir of target
$Stow_Path = 'stow';

# emulate stowing into ourself (bizarre corner case or accident)
make_dir('stow/pkg7a/stow/pkg7b');
make_file('stow/pkg7a/stow/pkg7b/file7b');
make_link('stow/pkg7b', '../stow/pkg7a/stow/pkg7b');

unstow_contents_orig('stow/pkg7b', '.');
stderr_like(
  sub { process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process when unstowing pkg7b'
);
ok(
    scalar(@Conflicts) == 0 &&
    -l 'stow/pkg7b' &&
    readlink('stow/pkg7b') eq '../stow/pkg7a/stow/pkg7b'
    => q(don't unlink any nodes under the stow directory)
);

#
# Don't unlink any nodes under another stow directory
#
reset_state();
$Option{'verbose'} = 0;

make_dir('stow'); # make out stow dir a subdir of target
$Stow_Path = 'stow';

make_dir('stow2'); # make our alternate stow dir a subdir of target
make_file('stow2/.stow');

# emulate stowing into ourself (bizarre corner case or accident)
make_dir('stow/pkg8a/stow2/pkg8b');
make_file('stow/pkg8a/stow2/pkg8b/file8b');
make_link('stow2/pkg8b', '../stow/pkg8a/stow2/pkg8b');

unstow_contents_orig('stow/pkg8a', '.');
stderr_like(
  sub { process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process when unstowing pkg8a'
);
ok(
    scalar(@Conflicts) == 0 &&
    -l 'stow2/pkg8b' &&
    readlink('stow2/pkg8b') eq '../stow/pkg8a/stow2/pkg8b'
    => q(don't unlink any nodes under another stow directory)
);

#
# overriding already stowed documentation
#
reset_state();
$Stow_Path = '../stow';
$Option{'verbose'} = 0;
$Option{'override'} = ['man9', 'info9'];

make_dir('../stow/pkg9a/man9/man1');
make_file('../stow/pkg9a/man9/man1/file9.1');
make_dir('man9/man1');
make_link('man9/man1/file9.1' => '../../../stow/pkg9a/man9/man1/file9.1'); # emulate stow

make_dir('../stow/pkg9b/man9/man1');
make_file('../stow/pkg9b/man9/man1/file9.1');
unstow_contents_orig('../stow/pkg9b', '.');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    !-l 'man9/man1/file9.1'
    => 'overriding existing documentation files'
);

#
# deferring to already stowed documentation
#
reset_state();
$Option{'verbose'} = 0;
$Option{'defer'} = ['man10', 'info10'];

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
unstow_contents_orig('../stow/pkg10c', '.');
stderr_like(
  sub { process_tasks(); },
  qr/There are no outstanding operations to perform/,
  'no tasks to process when unstowing pkg8a'
);
ok( 
    scalar(@Conflicts) == 0 &&
    readlink('man10/man1/file10a.1') eq '../../../stow/pkg10a/man10/man1/file10a.1' 
    => 'defer to existing documentation files'
);

#
# Ignore temp files
#
reset_state();
$Option{'verbose'} = 0;
$Option{'ignore'} = ['~', '\.#.*'];

make_dir('../stow/pkg12/man12/man1');
make_file('../stow/pkg12/man12/man1/file12.1');
make_file('../stow/pkg12/man12/man1/file12.1~');
make_file('../stow/pkg12/man12/man1/.#file12.1');
make_dir('man12/man1');
make_link('man12/man1/file12.1'  => '../../../stow/pkg12/man12/man1/file12.1');

unstow_contents_orig('../stow/pkg12', '.');
process_tasks();
ok( 
    scalar(@Conflicts) == 0 &&
    !-e 'man12/man1/file12.1'
    => 'ignore temp files'
);

# Todo
#
# Test cleaning up subdirs with --paranoid option

