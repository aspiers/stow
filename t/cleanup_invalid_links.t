#!/usr/local/bin/perl

#
# Testing cleanup_invalid_links()
#

use strict;
use warnings;

use Test::More tests => 6;
use English qw(-no_match_vars);

use testutil;

init_test_dirs();
cd("$OUT_DIR/target");

my $stow;

# Note that each of the following tests use a distinct set of files

#
# nothing to clean in a simple tree
# 


make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_link('bin1', '../stow/pkg1/bin1');

$stow = new_Stow();
$stow->cleanup_invalid_links('./');
is(
   scalar($stow->get_tasks), 0
    => 'nothing to clean' 
);

#
# cleanup a bad link in a simple tree
# 
make_dir('bin2');
make_dir('../stow/pkg2/bin2');
make_file('../stow/pkg2/bin2/file2a');
make_link('bin2/file2a', '../../stow/pkg2/bin2/file2a');
make_invalid_link('bin2/file2b', '../../stow/pkg2/bin2/file2b');

$stow = new_Stow();
$stow->cleanup_invalid_links('bin2');
is($stow->get_conflict_count, 0, 'no conflicts cleaning up bad link');
is(scalar($stow->get_tasks),     1, 'one task cleaning up bad link');
is($stow->link_task_action('bin2/file2b'), 'remove', 'removal task for bad link');

#
# dont cleanup a bad link not owned by stow
# 

make_dir('bin3');
make_dir('../stow/pkg3/bin3');
make_file('../stow/pkg3/bin3/file3a');
make_link('bin3/file3a', '../../stow/pkg3/bin3/file3a');
make_invalid_link('bin3/file3b', '../../empty');

$stow = new_Stow();
$stow->cleanup_invalid_links('bin3');
is($stow->get_conflict_count, 0, 'no conflicts cleaning up bad link not owned by stow');
is(scalar($stow->get_tasks),     0, 'no tasks cleaning up bad link not owned by stow');
