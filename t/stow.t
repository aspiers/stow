#!/usr/local/bin/perl 

#
# Testing core application
#

# load as a library 
BEGIN { use lib qw(.); require "t/util.pm"; require "stow"; }

use Test::More tests => 10;

local @ARGV = (
    '-v',
    '-d t/stow',
    '-t t/target',
    'dummy'
);

### setup 
eval { remove_dir('t/target'); };
eval { remove_dir('t/stow');   };
make_dir('t/target');
make_dir('t/stow');

ok eval {process_options(); 1} => 'process options';
ok eval {set_stow_path();   1} => 'set stow path';

is($Stow_Path,"../stow"               => 'stow dir');
is_deeply(\@Pkgs_To_Stow, [ 'dummy' ] => 'default to stow');


#
# Check mixed up package options
#
%Option=();
local @ARGV = (
    '-v',
    '-D', 'd1', 'd2',
    '-S', 's1',
    '-R', 'r1',
    '-D', 'd3',
    '-S', 's2', 's3',
    '-R', 'r2',
);

@Pkgs_To_Stow = ();
@Pkgs_To_Delete = ();
process_options();
is_deeply(\@Pkgs_To_Delete, [ 'd1', 'd2', 'r1', 'd3', 'r2' ] => 'mixed deletes');
is_deeply(\@Pkgs_To_Stow,   [ 's1', 'r1', 's2', 's3', 'r2' ] => 'mixed stows');

#
# Check setting defered paths
#
%Option=();
local @ARGV = (
    '--defer=man',
    '--defer=info'
);
process_options();
is_deeply($Option{'defer'}, [ qr(\Aman), qr(\Ainfo) ] => 'defer man and info');

#
# Check setting override paths
#
%Option=();
local @ARGV = (
    '--override=man',
    '--override=info'
);
process_options();
is_deeply($Option{'override'}, [qr(\Aman), qr(\Ainfo)] => 'override man and info');

#
# Check stripping any matched quotes
#
%Option=();
local @ARGV = (
    "--override='man'",
    '--override="info"',
);
process_options();
is_deeply($Option{'override'}, [qr(\Aman), qr(\Ainfo)] => 'strip shell quoting');

#
# Check setting ignored paths
#
%Option=();
local @ARGV = (
    '--ignore="~"',
    '--ignore="\.#.*"'
);
process_options();
is_deeply($Option{'ignore'}, [ qr(~\z), qr(\.#.*\z) ] => 'ignore temp files');


# vim:ft=perl
