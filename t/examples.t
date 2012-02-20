#!/usr/local/bin/perl

#
# Testing examples from the documentation
#

use strict;
use warnings;

use testutil;

use Test::More tests => 67;
use English qw(-no_match_vars);

init_test_dirs();
cd("$OUT_DIR/target");

my $stow;

## set up some fake packages to stow

sub setup_perl {
    my ($stow_path) = @_;
    make_dir ("$stow_path/perl/bin");
    make_file("$stow_path/perl/bin/perl");
    make_file("$stow_path/perl/bin/a2p");
    make_dir ("$stow_path/perl/share/info");
    make_file("$stow_path/perl/share/info/perl");
    make_dir ("$stow_path/perl/lib/perl");
    make_dir ("$stow_path/perl/share/man/man1");
    make_file("$stow_path/perl/share/man/man1/perl.1");
}

sub setup_emacs {
    my ($stow_path) = @_;
    make_dir ("$stow_path/emacs/bin");
    make_file("$stow_path/emacs/bin/emacs");
    make_file("$stow_path/emacs/bin/etags");
    make_dir ("$stow_path/emacs/share/info");
    make_file("$stow_path/emacs/share/info/emacs");
    make_dir ("$stow_path/emacs/libexec/emacs");
    make_dir ("$stow_path/emacs/share/man/man1");
    make_file("$stow_path/emacs/share/man/man1/emacs.1");
}

setup_perl('stow');
setup_emacs('stow');

#
# stow perl into an empty target
# 

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl');
$stow->process_tasks();
ok($stow->get_conflict_count == 0);
is_link('bin', 'stow/perl/bin');
is_link('share', 'stow/perl/share');
is_link('lib', 'stow/perl/lib');

#
# stow perl into a non-empty target
#

# clean up previous stow
remove_link('bin');
remove_link('share');
remove_link('lib');

make_dir('bin');
make_dir('lib');
make_dir('share/info');
make_dir('share/man/man1');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl');
$stow->process_tasks();
ok($stow->get_conflict_count == 0);
is_dir_not_symlink('bin');
is_dir_not_symlink('lib');
is_dir_not_symlink('share');
is_dir_not_symlink('share/info');
is_dir_not_symlink('share/man');
is_dir_not_symlink('share/man/man1');
is_link('bin/perl', '../stow/perl/bin/perl');
is_link('bin/a2p', '../stow/perl/bin/a2p');
is_link('lib/perl', '../stow/perl/lib/perl');
is_link('share/info/perl', '../../stow/perl/share/info/perl');
is_link('share/man/man1/perl.1', '../../../stow/perl/share/man/man1/perl.1');


#
# Install perl into an empty target and then install emacs
#

# clean up previous stow
remove_dir('bin');
remove_dir('lib');
remove_dir('share');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('perl', 'emacs');
$stow->process_tasks();
is($stow->get_conflict_count, 0, 'no conflicts');
is_dir_not_symlink('bin');
is_link('bin/perl', '../stow/perl/bin/perl');
is_link('bin/a2p', '../stow/perl/bin/a2p');
is_link('bin/emacs', '../stow/emacs/bin/emacs');
is_link('bin/etags', '../stow/emacs/bin/etags');

is_dir_not_symlink('share/info');
is_link('share/info/perl',  '../../stow/perl/share/info/perl');
is_link('share/info/emacs', '../../stow/emacs/share/info/emacs');

is_dir_not_symlink('share/man');
is_dir_not_symlink('share/man/man1');
is_link('share/man/man1/perl.1', '../../../stow/perl/share/man/man1/perl.1');
is_link('share/man/man1/emacs.1', '../../../stow/emacs/share/man/man1/emacs.1');

is_link('lib', 'stow/perl/lib');
is_link('libexec', 'stow/emacs/libexec');

#
# BUG 1: 
# 1. stowing a package with an empty directory
# 2. stow another package with the same directory but non empty
# 3. unstow the second package
# Q. the original empty directory should remain 
# behaviour is the same as if the empty directory had nothing to do with stow
#

make_dir('stow/pkg1a/bin1');
make_dir('stow/pkg1b/bin1');
make_file('stow/pkg1b/bin1/file1b');

$stow = new_Stow(dir => 'stow');
$stow->plan_stow('pkg1a', 'pkg1b');
$stow->plan_unstow('pkg1b');
$stow->process_tasks();
is($stow->get_conflict_count, 0, 'no conflicts stowing empty dirs');
is_dir_not_symlink('bin1' => 'bug 1: stowing empty dirs');

#
# BUG 2: split open tree-folding symlinks pointing inside different stow
# directories
#
make_dir('stow2a/pkg2a/bin2');
make_file('stow2a/pkg2a/bin2/file2a');
make_file('stow2a/.stow');
make_dir('stow2b/pkg2b/bin2');
make_file('stow2b/pkg2b/bin2/file2b');
make_file('stow2b/.stow');

$stow = new_Stow(dir => 'stow2a');
$stow->plan_stow('pkg2a');
$stow->set_stow_dir('stow2b');
$stow->plan_stow('pkg2b');
$stow->process_tasks();

is($stow->get_conflict_count, 0, 'no conflicts splitting tree-folding symlinks');
is_dir_not_symlink('bin2' => 'tree got split by packages from multiple stow directories');
ok(-f 'bin2/file2a' => 'file from 1st stow dir');
ok(-f 'bin2/file2b' => 'file from 2nd stow dir');

## Finish this test
