#!/usr/local/bin/perl 

#
# Test processing of CLI options.
#

use strict;
use warnings;

use Test::More tests => 9;

use testutil;

require 'stow';

init_test_dirs();

local @ARGV = (
    '-v',
    "-d $OUT_DIR/stow",
    "-t $OUT_DIR/target",
    'dummy'
);

my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();

is($options->{verbose}, 1, 'verbose option');
is($options->{dir}, "$OUT_DIR/stow", 'stow dir option');

my $stow = new_Stow(%$options);

is($stow->{stow_path}, "../stow" => 'stow dir');
is_deeply($pkgs_to_stow, [ 'dummy' ] => 'default to stow');

#
# Check mixed up package options
#
local @ARGV = (
    '-v',
    '-D', 'd1', 'd2',
    '-S', 's1',
    '-R', 'r1',
    '-D', 'd3',
    '-S', 's2', 's3',
    '-R', 'r2',
);

($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($pkgs_to_delete, [ 'd1', 'd2', 'r1', 'd3', 'r2' ] => 'mixed deletes');
is_deeply($pkgs_to_stow,   [ 's1', 'r1', 's2', 's3', 'r2' ] => 'mixed stows');

#
# Check setting deferred paths
#
local @ARGV = (
    '--defer=man',
    '--defer=info',
    'dummy'
);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{defer}, [ qr(\Aman), qr(\Ainfo) ] => 'defer man and info');

#
# Check setting override paths
#
local @ARGV = (
    '--override=man',
    '--override=info',
    'dummy'
);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{override}, [qr(\Aman), qr(\Ainfo)] => 'override man and info');

#
# Check setting ignored paths
#
local @ARGV = (
    '--ignore=~',
    '--ignore=\.#.*',
    'dummy'
);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{ignore}, [ qr(~\z), qr(\.#.*\z) ] => 'ignore temp files');


# vim:ft=perl
