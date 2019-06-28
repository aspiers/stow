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
# Testing examples from the documentation
#

use strict;
use warnings;

use testutil;

use Test::More tests => 10;
use English qw(-no_match_vars);

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

## set up some fake packages to stow

# perl
make_path('stow/perl/bin');
make_file('stow/perl/bin/perl');
make_file('stow/perl/bin/a2p');
make_path('stow/perl/info');
make_file('stow/perl/info/perl');
make_path('stow/perl/lib/perl');
make_path('stow/perl/man/man1');
make_file('stow/perl/man/man1/perl.1');

# emacs
make_path('stow/emacs/bin');
make_file('stow/emacs/bin/emacs');
make_file('stow/emacs/bin/etags');
make_path('stow/emacs/info');
make_file('stow/emacs/info/emacs');
make_path('stow/emacs/libexec/emacs');
make_path('stow/emacs/man/man1');
make_file('stow/emacs/man/man1/emacs.1');

#
# stow perl into an empty target
# 

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
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

# clean up previous stow
remove_link('bin');
remove_link('info');
remove_link('lib');
remove_link('man');

make_path('bin');
make_path('lib');
make_path('man/man1');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
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

# clean up previous stow
remove_link('info');
remove_dir('bin');
remove_dir('lib');
remove_dir('man');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl', 'emacs');
$stow->process_tasks();
is($stow->get_conflict_count, 0, 'no conflicts');
ok(
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

make_path('stow/pkg1a/bin1');
make_path('stow/pkg1b/bin1');
make_file('stow/pkg1b/bin1/file1b');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('pkg1a', 'pkg1b');
$stow->plan_unstow('pkg1b');
$stow->process_tasks();
is($stow->get_conflict_count, 0, 'no conflicts stowing empty dirs');
ok(-d 'bin1' => 'bug 1: stowing empty dirs');

#
# BUG 2: split open tree-folding symlinks pointing inside different stow
# directories
#
make_path('stow2a/pkg2a/bin2');
make_file('stow2a/pkg2a/bin2/file2a');
make_file('stow2a/.stow');
make_path('stow2b/pkg2b/bin2');
make_file('stow2b/pkg2b/bin2/file2b');
make_file('stow2b/.stow');

$stow = new_Stow(dir => 'stow2a');
$stow->plan_stow('pkg2a');
$stow->set_stow_dir('stow2b');
$stow->plan_stow('pkg2b');
$stow->process_tasks();

is($stow->get_conflict_count, 0, 'no conflicts splitting tree-folding symlinks');
ok(-d 'bin2' => 'tree got split by packages from multiple stow directories');
ok(-f 'bin2/file2a' => 'file from 1st stow dir');
ok(-f 'bin2/file2b' => 'file from 2nd stow dir');

## Finish this test
