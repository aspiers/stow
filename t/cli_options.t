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

use Test::More tests => 6;

use testutil;

require 'stow';

init_test_dirs();

subtest('basic CLI options', sub {
    plan tests => 4;

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
});

subtest('mixed up package options', sub {
    plan tests => 2;

    local @ARGV = (
        '-v',
        '-D', 'd1', 'd2',
        '-S', 's1',
        '-R', 'r1',
        '-D', 'd3',
        '-S', 's2', 's3',
        '-R', 'r2',
    );

    my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
    is_deeply($pkgs_to_delete, [ 'd1', 'd2', 'r1', 'd3', 'r2' ] => 'mixed deletes');
    is_deeply($pkgs_to_stow,   [ 's1', 'r1', 's2', 's3', 'r2' ] => 'mixed stows');
});

subtest('setting deferred paths', sub {
    plan tests => 1;

    local @ARGV = (
        '--defer=man',
        '--defer=info',
        'dummy'
    );
    my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
    is_deeply($options->{defer}, [ qr{\A(man)}, qr{\A(info)} ] => 'defer man and info');
});

subtest('setting override paths', sub {
    plan tests => 1;

    local @ARGV = (
        '--override=man',
        '--override=info',
        'dummy'
    );
    my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
    is_deeply($options->{override}, [qr{\A(man)}, qr{\A(info)}] => 'override man and info');
});

subtest('setting ignored paths', sub {
    plan tests => 1;

    local @ARGV = (
        '--ignore=~',
        '--ignore=\.#.*',
        'dummy'
    );
    my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
    is_deeply($options->{ignore}, [ qr{(~)\z}, qr{(\.#.*)\z} ] => 'ignore temp files');
});

subtest('no expansion of environment variables', sub {
    plan tests => 1;

    local @ARGV = (
        "--target=$TEST_DIR/".'$HOME',
        'dummy'
    );
    make_path("$TEST_DIR/".'$HOME');
    my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
    is($options->{target}, "$TEST_DIR/".'$HOME', 'no expansion');
    remove_dir("$TEST_DIR/".'$HOME');
});

# vim:ft=perl
