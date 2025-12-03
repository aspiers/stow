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

use Test::More tests => 5;
use English qw(-no_match_vars);

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

subtest('setup fake packages', sub {
    plan tests => 1;

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

    ok(1, 'created fake packages');
});

subtest('stow perl into an empty target', sub {
    plan tests => 9;

    $stow = new_Stow(dir => 'stow');
    $stow->plan_stow('perl');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'no conflicts');
    ok(-l 'bin', 'bin is a symlink');
    ok(-l 'info', 'info is a symlink');
    ok(-l 'lib', 'lib is a symlink');
    ok(-l 'man', 'man is a symlink');
    is(readlink('bin'), 'stow/perl/bin', 'bin points to stow/perl/bin');
    is(readlink('info'), 'stow/perl/info', 'info points to stow/perl/info');
    is(readlink('lib'), 'stow/perl/lib', 'lib points to stow/perl/lib');
    is(readlink('man'), 'stow/perl/man', 'man points to stow/perl/man');
});

subtest('stow perl into a non-empty target', sub {
    plan tests => 15;

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
    is($stow->get_conflict_count, 0, 'no conflicts');
    ok(-d 'bin', 'bin is a directory');
    ok(-d 'lib', 'lib is a directory');
    ok(-d 'man', 'man is a directory');
    ok(-d 'man/man1', 'man/man1 is a directory');
    ok(-l 'info', 'info is a symlink');
    ok(-l 'bin/perl', 'bin/perl is a symlink');
    ok(-l 'bin/a2p', 'bin/a2p is a symlink');
    ok(-l 'lib/perl', 'lib/perl is a symlink');
    ok(-l 'man/man1/perl.1', 'man/man1/perl.1 is a symlink');
    is(readlink('info'), 'stow/perl/info', 'info points to stow/perl/info');
    is(readlink('bin/perl'), '../stow/perl/bin/perl', 'bin/perl points correctly');
    is(readlink('bin/a2p'), '../stow/perl/bin/a2p', 'bin/a2p points correctly');
    is(readlink('lib/perl'), '../stow/perl/lib/perl', 'lib/perl points correctly');
    is(readlink('man/man1/perl.1'), '../../stow/perl/man/man1/perl.1', 'man/man1/perl.1 points correctly');
});

subtest('install perl into empty target and then install emacs', sub {
    plan tests => 25;

    # clean up previous stow
    remove_link('info');
    remove_dir('bin');
    remove_dir('lib');
    remove_dir('man');

    $stow = new_Stow(dir => 'stow');
    $stow->plan_stow('perl', 'emacs');
    $stow->process_tasks();
    is($stow->get_conflict_count, 0, 'no conflicts');
    ok(-d 'bin', 'bin is a directory');
    ok(-l 'bin/perl', 'bin/perl is a symlink');
    ok(-l 'bin/emacs', 'bin/emacs is a symlink');
    ok(-l 'bin/a2p', 'bin/a2p is a symlink');
    ok(-l 'bin/etags', 'bin/etags is a symlink');
    is(readlink('bin/perl'), '../stow/perl/bin/perl', 'bin/perl points correctly');
    is(readlink('bin/a2p'), '../stow/perl/bin/a2p', 'bin/a2p points correctly');
    is(readlink('bin/emacs'), '../stow/emacs/bin/emacs', 'bin/emacs points correctly');
    is(readlink('bin/etags'), '../stow/emacs/bin/etags', 'bin/etags points correctly');
    ok(-d 'info', 'info is a directory');
    ok(-l 'info/perl', 'info/perl is a symlink');
    ok(-l 'info/emacs', 'info/emacs is a symlink');
    is(readlink('info/perl'), '../stow/perl/info/perl', 'info/perl points correctly');
    is(readlink('info/emacs'), '../stow/emacs/info/emacs', 'info/emacs points correctly');
    ok(-d 'man', 'man is a directory');
    ok(-d 'man/man1', 'man/man1 is a directory');
    ok(-l 'man/man1/perl.1', 'man/man1/perl.1 is a symlink');
    ok(-l 'man/man1/emacs.1', 'man/man1/emacs.1 is a symlink');
    is(readlink('man/man1/perl.1'), '../../stow/perl/man/man1/perl.1', 'man/man1/perl.1 points correctly');
    is(readlink('man/man1/emacs.1'), '../../stow/emacs/man/man1/emacs.1', 'man/man1/emacs.1 points correctly');
    ok(-l 'lib', 'lib is a symlink');
    ok(-l 'libexec', 'libexec is a symlink');
    is(readlink('lib'), 'stow/perl/lib', 'lib points correctly');
    is(readlink('libexec'), 'stow/emacs/libexec', 'libexec points correctly');
});

subtest('bug fixes', sub {
    plan tests => 6;

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
});
