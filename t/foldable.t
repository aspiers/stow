#!/usr/local/bin/perl

#
# Testing foldable()
#

# load as a library
BEGIN { use lib qw(.); require "t/util.pm"; require "stow"; }

use Test::More tests => 4;
use English qw(-no_match_vars);

### setup 
# be very careful with these
eval { remove_dir('t/target'); };
eval { remove_dir('t/stow');   };
make_dir('t/target');
make_dir('t/stow');

chdir 't/target';
$Stow_Path= '../stow';

# Note that each of the following tests use a distinct set of files

#
# can fold a simple tree
#

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_dir('bin1');
make_link('bin1/file1','../../stow/pkg1/bin1/file1');

is( foldable('bin1'), '../stow/pkg1/bin1' => q(can fold a simple tree) );

#
# can't fold an empty directory 
# 

make_dir('../stow/pkg2/bin2');
make_file('../stow/pkg2/bin2/file2');
make_dir('bin2');

is( foldable('bin2'), '' => q(can't fold an empty directory) );

#
# can't fold if dir contains a non-link
#

make_dir('../stow/pkg3/bin3');
make_file('../stow/pkg3/bin3/file3');
make_dir('bin3');
make_link('bin3/file3','../../stow/pkg3/bin3/file3');
make_file('bin3/non-link');

is( foldable('bin3'), '' => q(can't fold a dir containing non-links) );

#
# can't fold if links point to different directories
#

make_dir('bin4');
make_dir('../stow/pkg4a/bin4');
make_file('../stow/pkg4a/bin4/file4a');
make_link('bin4/file4a','../../stow/pkg4a/bin4/file4a');
make_dir('../stow/pkg4b/bin4');
make_file('../stow/pkg4b/bin4/file4b');
make_link('bin4/file4b','../../stow/pkg4b/bin4/file4b');

is( foldable('bin4'), '' => q(can't fold if links point to different dirs) );
