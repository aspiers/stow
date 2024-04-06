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
# Testing join_paths();
#

use strict;
use warnings;

use Stow::Util qw(join_paths set_debug_level);

#set_debug_level(4);

use Test::More tests => 22;

my @TESTS = (
  [['a/b/c', 'd/e/f'], 'a/b/c/d/e/f' => 'simple'],
  [['a/b/c', '/d/e/f'], '/d/e/f' => 'relative then absolute'],
  [['/a/b/c', 'd/e/f'], '/a/b/c/d/e/f' => 'absolute then relative'],
  [['/a/b/c', '/d/e/f'], '/d/e/f' => 'two absolutes'],
  [['/a/b/c/', '/d/e/f/'], '/d/e/f' => 'two absolutes with trailing /'],
  [['///a/b///c//', '/d///////e/f'], '/d/e/f' => "multiple /'s, absolute"],
  [['///a/b///c//', 'd///////e/f'], '/a/b/c/d/e/f' => "multiple /'s, relative"],
  [['', 'a/b/c'], 'a/b/c' => 'first empty'],
  [['a/b/c', ''], 'a/b/c' => 'second empty'],
  [['/', 'a/b/c'], '/a/b/c' => 'first is /'],
  [['a/b/c', '/'], '/' => 'second is /'],
  [['../a1/b1/../c1/', 'a2/../b2/e2'], '../a1/c1/b2/e2' => 'relative with ../'],
  [['../a1/b1/../c1/', '/a2/../b2/e2'], '/b2/e2' => 'absolute with ../'],
  [['../a1/../../c1', 'a2/../../'], '../..' => 'lots of ../'],
  [['./', '../a2'], '../a2' => 'drop any "./"'],
  [['./a1', '../../a2'], '../a2' => 'drop any "./foo"'],
  [['a/b/c', '.'], 'a/b/c' => '. on RHS'],
  [['a/b/c', '.', 'd/e'], 'a/b/c/d/e' => '. in middle'],
  [['0', 'a/b'], '0/a/b' => '0 at start'],
  [['/0', 'a/b'], '/0/a/b' => '/0 at start'],
  [['a/b/c', '0', 'd/e'], 'a/b/c/0/d/e' => '0 in middle'],
  [['a/b', '0'], 'a/b/0' => '0 at end'],
);

for my $test (@TESTS) {
  my ($inputs, $expected, $scenario) = @$test;
  my $got = join_paths(@$inputs);
  my $descr = "$scenario: in=[" . join(', ', map "'$_'", @$inputs) . "] exp=[$expected] got=[$got]";
  is($got, $expected, $descr);
}
