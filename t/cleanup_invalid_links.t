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
# Testing cleanup_invalid_links()
#

use strict;
use warnings;

use Test::More tests => 4;
use English qw(-no_match_vars);

use testutil;
use Stow::Util;

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

# Note that each of the following tests use a distinct set of files

subtest('nothing to clean in a simple tree' => sub {
    plan tests => 1;

    make_path('../stow/pkg1/bin1');
    make_file('../stow/pkg1/bin1/file1');
    make_link('bin1', '../stow/pkg1/bin1');

    $stow = new_Stow();
    $stow->cleanup_invalid_links('./');
    is(
        scalar($stow->get_tasks), 0
        => 'nothing to clean'
    );
});

subtest('cleanup an orphaned owned link in a simple tree' => sub {
    plan tests => 3;

    make_path('bin2');
    make_path('../stow/pkg2/bin2');
    make_file('../stow/pkg2/bin2/file2a');
    make_link('bin2/file2a', '../../stow/pkg2/bin2/file2a');
    make_invalid_link('bin2/file2b', '../../stow/pkg2/bin2/file2b');

    $stow = new_Stow();
    $stow->cleanup_invalid_links('bin2');
    is($stow->get_conflict_count, 0, 'no conflicts cleaning up bad link');
    is(scalar($stow->get_tasks), 1, 'one task cleaning up bad link');
    is($stow->link_task_action('bin2/file2b'), 'remove', 'removal task for bad link');
});

subtest("don't cleanup a bad link not owned by stow" => sub {
    plan tests => 2;

    make_path('bin3');
    make_path('../stow/pkg3/bin3');
    make_file('../stow/pkg3/bin3/file3a');
    make_link('bin3/file3a', '../../stow/pkg3/bin3/file3a');
    make_invalid_link('bin3/file3b', '../../empty');

    $stow = new_Stow();
    $stow->cleanup_invalid_links('bin3');
    is($stow->get_conflict_count, 0, 'no conflicts cleaning up bad link not owned by stow');
    is(scalar($stow->get_tasks), 0, 'no tasks cleaning up bad link not owned by stow');
});

subtest("don't cleanup a valid link in the target not owned by stow" => sub {
    plan tests => 2;

    make_path('bin4');
    make_path('../stow/pkg4/bin4');
    make_file('../stow/pkg4/bin4/file3a');
    make_link('bin4/file3a', '../../stow/pkg4/bin4/file3a');
    make_file("unowned");
    make_link('bin4/file3b', '../unowned');

    $stow = new_Stow();
    $stow->cleanup_invalid_links('bin4');
    is($stow->get_conflict_count, 0, 'no conflicts cleaning up bad link not owned by stow');
    is(scalar($stow->get_tasks), 0, 'no tasks cleaning up bad link not owned by stow');
});
