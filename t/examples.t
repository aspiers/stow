#!/usr/local/bin/perl

#
# Testing examples from the documentation
#

# load as a library
BEGIN { use lib qw(.); require "t/util.pm"; require "stow"; }

use Test::More tests => 4;
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
make_dir('t/target/stow');

chdir 't/target';
$Stow_Path= 'stow';

## set up some fake packages to stow

# perl
make_dir('stow/perl/bin');
make_file('stow/perl/bin/perl');
make_file('stow/perl/bin/a2p');
make_dir('stow/perl/info');
make_file('stow/perl/info/perl');
make_dir('stow/perl/lib/perl');
make_dir('stow/perl/man/man1');
make_file('stow/perl/man/man1/perl.1');

# emacs
make_dir('stow/emacs/bin');
make_file('stow/emacs/bin/emacs');
make_file('stow/emacs/bin/etags');
make_dir('stow/emacs/info');
make_file('stow/emacs/info/emacs');
make_dir('stow/emacs/libexec/emacs');
make_dir('stow/emacs/man/man1');
make_file('stow/emacs/man/man1/emacs.1');

#
# stow perl into an empty target
# 
reset_state();
$Option{'verbose'} = 0;

make_dir('stow/perl/bin');
make_file('stow/perl/bin/perl');
make_file('stow/perl/bin/a2p');
make_dir('stow/perl/info');
make_dir('stow/perl/lib/perl');
make_dir('stow/perl/man/man1');
make_file('stow/perl/man/man1/perl.1');

stow_contents('stow/perl','./','stow/perl');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    -l 'bin' && -l 'info' && -l 'lib' && -l 'man' &&
    readlink('bin')  eq 'stow/perl/bin' &&
    readlink('info') eq 'stow/perl/info' &&
    readlink('lib')  eq 'stow/perl/lib' &&
    readlink('man')  eq 'stow/perl/man'
    => 'stow perl into an empty target' 
);


#
# stow perl into a non-empty target
#
reset_state();
$Option{'verbose'} = 0;

# clean up previous stow
remove_link('bin');
remove_link('info');
remove_link('lib');
remove_link('man');

make_dir('bin');
make_dir('lib');
make_dir('man/man1');

stow_contents('stow/perl','./','stow/perl');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    -d 'bin' && -d 'lib' && -d 'man' && -d 'man/man1' &&
    -l 'info' && -l 'bin/perl' && -l 'bin/a2p' && 
    -l 'lib/perl' && -l 'man/man1/perl.1' &&
    readlink('info')     eq 'stow/perl/info' &&
    readlink('bin/perl') eq '../stow/perl/bin/perl' &&
    readlink('bin/a2p')  eq '../stow/perl/bin/a2p' &&
    readlink('lib/perl') eq '../stow/perl/lib/perl' &&
    readlink('man/man1/perl.1')  eq '../../stow/perl/man/man1/perl.1'
    => 'stow perl into a non-empty target' 
); 


#
# Install perl into an empty target and then install emacs
#
reset_state();
$Option{'verbose'} = 0;

# clean up previous stow
remove_link('info');
remove_dir('bin');
remove_dir('lib');
remove_dir('man');

stow_contents('stow/perl', './','stow/perl');
stow_contents('stow/emacs','./','stow/emacs');
process_tasks();
ok(
    scalar(@Conflicts) == 0 &&
    -d 'bin'        && 
    -l 'bin/perl'   && 
    -l 'bin/emacs'  && 
    -l 'bin/a2p'    && 
    -l 'bin/etags'  && 
    readlink('bin/perl')    eq '../stow/perl/bin/perl'      &&
    readlink('bin/a2p')     eq '../stow/perl/bin/a2p'       &&
    readlink('bin/emacs')   eq '../stow/emacs/bin/emacs'    &&
    readlink('bin/etags')   eq '../stow/emacs/bin/etags'    &&
    
    -d 'info'       && 
    -l 'info/perl'  && 
    -l 'info/emacs' && 
    readlink('info/perl')   eq '../stow/perl/info/perl'     &&
    readlink('info/emacs')  eq '../stow/emacs/info/emacs'   &&

    -d 'man'                && 
    -d 'man/man1'           &&
    -l 'man/man1/perl.1'    &&
    -l 'man/man1/emacs.1'   &&
    readlink('man/man1/perl.1')  eq '../../stow/perl/man/man1/perl.1'   &&
    readlink('man/man1/emacs.1') eq '../../stow/emacs/man/man1/emacs.1' &&

    -l 'lib'        && 
    -l 'libexec'    &&
    readlink('lib')     eq 'stow/perl/lib'      &&
    readlink('libexec') eq 'stow/emacs/libexec' &&
    1
    => 'stow perl into an empty target, then stow emacs' 
); 

#
# BUG 1: 
# 1. stowing a package with an empty directory
# 2. stow another package with the same directory but non empty
# 3. unstow the second package
# Q. the original empty directory should remain 
# behaviour is the same as if the empty directory had nothing to do with stow
#
reset_state();
$Option{'verbose'} = 0;

make_dir('stow/pkg1a/bin1');
make_dir('stow/pkg1b/bin1');
make_file('stow/pkg1b/bin1/file1b');

stow_contents('stow/pkg1a',   './', 'stow/pkg1a');
stow_contents('stow/pkg1b',   './', 'stow/pkg1b');
unstow_contents('stow/pkg1b', './', 'stow/pkg1b');
process_tasks();

ok(
    scalar(@Conflicts) == 0 &&
    -d 'bin1'
    => 'bug 1: stowing empty dirs'
);


#
# BUG 2: split open tree-folding symlinks pointing inside different stow
# directories
#
reset_state();
$Option{'verbose'} = 0;

make_dir('stow2a/pkg2a/bin2');
make_file('stow2a/pkg2a/bin2/file2a');
make_file('stow2a/.stow');
make_dir('stow2b/pkg2b/bin2');
make_file('stow2b/pkg2b/bin2/file2b');
make_file('stow2b/.stow');

stow_contents('stow2a/pkg2a','./', 'stow2a/pkg2a');
stow_contents('stow2b/pkg2b','./', 'stow2b/pkg2b');
process_tasks();

## Finish this test
