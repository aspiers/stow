#!/usr/local/bin/perl

#
# Testing cleanup_invalid_links()
#

# load as a library
BEGIN { use lib qw(.); require "t/util.pm"; require "stow"; }

use Test::More tests => 3;
use English qw(-no_match_vars);

### setup 
eval { remove_dir('t/target'); };
eval { remove_dir('t/stow');   };
make_dir('t/target');
make_dir('t/stow');

chdir 't/target';
$Stow_Path= '../stow';

# Note that each of the following tests use a distinct set of files

#
# nothing to clean in a simple tree
# 
reset_state();

make_dir('../stow/pkg1/bin1');
make_file('../stow/pkg1/bin1/file1');
make_link('bin1','../stow/pkg1/bin1');

cleanup_invalid_links('./');
is(
   scalar @Tasks, 0
    => 'nothing to clean' 
);

#
# cleanup a bad link in a simple tree
# 
reset_state();

make_dir('bin2');
make_dir('../stow/pkg2/bin2');
make_file('../stow/pkg2/bin2/file2a');
make_link('bin2/file2a','../../stow/pkg2/bin2/file2a');
make_link('bin2/file2b','../../stow/pkg2/bin2/file2b');

cleanup_invalid_links('bin2');
ok(
    scalar(@Conflicts) == 0 &&
    scalar @Tasks == 1 &&
    $Link_Task_For{'bin2/file2b'}->{'action'} eq 'remove'
    => 'cleanup a bad link' 
);

#use Data::Dumper;
#print Dumper(\@Tasks,\%Link_Task_For,\%Dir_Task_For);

#
# dont cleanup a bad link not owned by stow
# 
reset_state();

make_dir('bin3');
make_dir('../stow/pkg3/bin3');
make_file('../stow/pkg3/bin3/file3a');
make_link('bin3/file3a','../../stow/pkg3/bin3/file3a');
make_link('bin3/file3b','../../empty');

cleanup_invalid_links('bin3');
ok(
    scalar(@Conflicts) == 0 &&
    scalar @Tasks == 0 
    => 'dont cleanup a bad link not owned by stow' 
);


