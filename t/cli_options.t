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
# Test processing of CLI options.
#

use strict;
use warnings;

use Test::More tests => 10;

use testutil;

require 'stow';

init_test_dirs();

local @ARGV = (
    '-v',
    '-d', "$TEST_DIR/stow",
    '-t', "$TEST_DIR/target",
    'dummy'
);

my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();

is($options->{verbose}, 1, 'verbose option');
is($options->{dir}, "$TEST_DIR/stow", 'stow dir option');

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
is_deeply($options->{defer}, [ qr{\A(man)}, qr{\A(info)} ] => 'defer man and info');

#
# Check setting override paths
#
local @ARGV = (
    '--override=man',
    '--override=info',
    'dummy'
);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{override}, [qr{\A(man)}, qr{\A(info)}] => 'override man and info');

#
# Check setting ignored paths
#
local @ARGV = (
    '--ignore=~',
    '--ignore=\.#.*',
    'dummy'
);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{ignore}, [ qr{(~)\z}, qr{(\.#.*)\z} ] => 'ignore temp files');

#
# Check that expansion not applied.
#
local @ARGV = (
    "--target=$TEST_DIR/".'$HOME',
    'dummy'
);
make_path("$TEST_DIR/".'$HOME');
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target}, "$TEST_DIR/".'$HOME', 'no expansion');
remove_dir("$TEST_DIR/".'$HOME');

# vim:ft=perl
