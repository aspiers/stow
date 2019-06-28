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
# Testing foldable()
#

use strict;
use warnings;

use testutil;

use Test::More tests => 4;
use English qw(-no_match_vars);

init_test_dirs();
cd("$TEST_DIR/target");

my $stow = new_Stow(dir => '../stow');

# Note that each of the following tests use a distinct set of files

#
# can fold a simple tree
#

make_path('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_path('bin1');
make_link('bin1/file1','../../stow/pkg1/bin1/file1');

is( $stow->foldable('bin1'), '../stow/pkg1/bin1' => q(can fold a simple tree) );

#
# can't fold an empty directory 
# 

make_path('../stow/pkg2/bin2');
make_file('../stow/pkg2/bin2/file2');
make_path('bin2');

is( $stow->foldable('bin2'), '' => q(can't fold an empty directory) );

#
# can't fold if dir contains a non-link
#

make_path('../stow/pkg3/bin3');
make_file('../stow/pkg3/bin3/file3');
make_path('bin3');
make_link('bin3/file3','../../stow/pkg3/bin3/file3');
make_file('bin3/non-link');

is( $stow->foldable('bin3'), '' => q(can't fold a dir containing non-links) );

#
# can't fold if links point to different directories
#

make_path('bin4');
make_path('../stow/pkg4a/bin4');
make_file('../stow/pkg4a/bin4/file4a');
make_link('bin4/file4a','../../stow/pkg4a/bin4/file4a');
make_path('../stow/pkg4b/bin4');
make_file('../stow/pkg4b/bin4/file4b');
make_link('bin4/file4b','../../stow/pkg4b/bin4/file4b');

is( $stow->foldable('bin4'), '' => q(can't fold if links point to different dirs) );
