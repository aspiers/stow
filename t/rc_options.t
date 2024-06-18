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
# Test processing of stowrc file.
#

use strict;
use warnings;

use Test::More tests => 35;

use testutil;

require 'stow';

# .stowrc files used for testing, relative to run_from/
my $CWD_RC_FILE = ".stowrc";
my $HOME_RC_FILE = "../.stowrc";
# Take the safe route and cowardly refuse to continue if there's
# already a file at $HOME_RC_FILE.
if (-e $HOME_RC_FILE) {
    die "RC file location $HOME_RC_FILE already exists!\n";
}

my ($options, $pkgs_to_delete, $pkgs_to_stow);

# Init testing directory structure and overwrite ENV{HOME} to prevent
# squashing existing .stowrc file.
init_test_dirs();

# =========== RC Loading Tests ===========
# Basic parsing and loading rc file tests.
# ========================================

my $orig_HOME = $ENV{HOME};

#
# Test no .stowrc file anywhere
#
delete $ENV{HOME};
local @ARGV = ('dummy');
cd("$TEST_DIR/run_from");
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "$ABS_TEST_DIR", "default --target with no .stowrc");
is($options->{dir}, "$ABS_TEST_DIR/run_from", "default -d with no .stowrc");

#
# Test .stowrc file in cwd with relative paths, and $HOME not defined
#
make_file($CWD_RC_FILE, <<HERE);
    -d ../stow
    --target ../target
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "../target"
   => "relative --target from \$PWD/.stowrc");
is($options->{dir}, "../stow"
   => "relative -d from \$PWD/.stowrc");

$ENV{HOME} = $orig_HOME;
remove_file($CWD_RC_FILE);

#
# Test .stowrc file in cwd with absolute paths, and $HOME not defined
#
make_file($CWD_RC_FILE, <<HERE);
    -d $ABS_TEST_DIR/stow
    --target $ABS_TEST_DIR/target
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "$ABS_TEST_DIR/target"
   => "absolute --target from \$PWD/.stowrc");
is($options->{dir}, "$ABS_TEST_DIR/stow"
   => "abs_test_dir -d from \$PWD/.stowrc");

$ENV{HOME} = $orig_HOME;
remove_file($CWD_RC_FILE);

#
# Test ~/.stowrc file with one relative option per line.
#
local @ARGV = ('dummy');
make_file($HOME_RC_FILE, <<HERE);
    -d ../stow
    --target ../target
HERE

($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "../target", "--target from \$HOME/.stowrc");
is($options->{dir}, "../stow", "-d ../stow from \$HOME/.stowrc");

#
# Test ~/.stowrc file with one absolute option per line.
#
local @ARGV = ('dummy');
make_file($HOME_RC_FILE, <<HERE);
    -d $ABS_TEST_DIR/stow
    --target $ABS_TEST_DIR/target
HERE

($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "$ABS_TEST_DIR/target"
   => "--target from \$HOME/.stowrc");
is($options->{dir}, "$ABS_TEST_DIR/stow"
   => "-d $ABS_TEST_DIR/stow from \$HOME/.stowrc");

#
# Test ~/.stowrc file with with options with paths containing spaces.
#
local @ARGV = ('dummy');
make_file($HOME_RC_FILE, <<HERE);
    -d "$ABS_TEST_DIR/stow directory"
    --target "$ABS_TEST_DIR/target"
HERE

($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{dir},  "$ABS_TEST_DIR/stow directory",
   => "-d from \$HOME/.stowrc with spaces");

#
# Test that some but not all options ~/.stowrc file are overridden by
# .stowrc in cwd.
#
local @ARGV = ('dummy');
make_file($HOME_RC_FILE, <<HERE);
    -d $ABS_TEST_DIR/stow-will-be-overridden
    --target $ABS_TEST_DIR/target-will-be-overridden
    --defer=info
HERE
make_file($CWD_RC_FILE, <<HERE);
    -d $ABS_TEST_DIR/stow
    --target $ABS_TEST_DIR/target
    --defer=man
HERE

($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "$ABS_TEST_DIR/target"
   => "--target overridden by \$PWD/.stowrc");
is($options->{dir}, "$ABS_TEST_DIR/stow"
   => "-d overridden \$PWD/.stowrc");
is_deeply($options->{defer}, [qr{\A(info)}, qr{\A(man)}],
          'defer man and info');
unlink($CWD_RC_FILE) or die "Failed to unlink $CWD_RC_FILE";

#
# Test that scalar cli option overwrites conflicting ~/.stowrc option.
#
local @ARGV = ('-d', "$ABS_TEST_DIR/stow", 'dummy');
make_file($HOME_RC_FILE, <<HERE);
    -d bad/path
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{dir}, "$ABS_TEST_DIR/stow", "cli overwrite scalar rc option.");

#
# Test that list cli option merges with conflicting .stowrc option.
# Documentation states that .stowrc options are prepended to cli options.
#
local @ARGV = (
    '--defer=man',
    'dummy'
);
make_file($HOME_RC_FILE, <<HERE);
    --defer=info
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{defer}, [qr{\A(info)}, qr{\A(man)}],
          'defer man and info');

# ======== Filepath Expansion Tests ========
# Test proper filepath expansion in rc file.
# Expansion is only applied to options that
# take a filepath, namely target and dir.
# ==========================================


#
# Test environment variable expansion function.
#
# Basic expansion
is(expand_environment('$HOME/stow'), "$ABS_TEST_DIR/stow", 'expand $HOME');
is(expand_environment('${HOME}/stow'), "$ABS_TEST_DIR/stow", 'expand ${HOME}');

delete $ENV{UNDEFINED}; # just in case
foreach my $var ('$UNDEFINED', '${UNDEFINED}') {
  eval {
    expand_environment($var, "--foo option");
  };
  is(
    $@,
    "--foo option references undefined environment variable \$UNDEFINED; " .
    "aborting!\n",
    "expand $var"
  );
}

# Expansion with an underscore.
$ENV{'WITH_UNDERSCORE'} = 'test string';
is(expand_environment('${WITH_UNDERSCORE}'), 'test string',
    'expand ${WITH_UNDERSCORE}');
delete $ENV{'WITH_UNDERSCORE'};
# Expansion with escaped $
is(expand_environment('\$HOME/stow'), '$HOME/stow', 'expand \$HOME');

#
# Test tilde (~) expansion
#
# Basic expansion
is(expand_tilde('~/path'), "$ENV{HOME}/path", 'tilde expansion to $HOME');
# Should not expand if middle of path
is(expand_tilde('/path/~/here'), '/path/~/here', 'middle ~ not expanded');
# Test escaped ~
is(expand_tilde('\~/path'), '~/path', 'escaped tilde');

#
# Test that environment variable expansion is applied unless quoted.
# Include examples from the manual
#
make_file($HOME_RC_FILE, <<'HERE');
--dir=$HOME/stow
--target="$HOME/dir with space in/file with space in"
--ignore=\\$FOO\\$
--defer="foo\\b.*bar"
--defer="\\.jpg\$"
--override=\\.png\$
--override=bin|man
--ignore='perllocal\.pod'
--ignore='\.packlist'
--ignore='\.bs'
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = get_config_file_options();
is($options->{dir}, "$ABS_TEST_DIR/stow",
    "apply environment expansion on --dir");
is($options->{target}, "$ABS_TEST_DIR/dir with space in/file with space in",
    "apply environment expansion on --target");
is_deeply($options->{ignore}, [qr{(\$FOO\$)\z}, qr{(perllocal\.pod)\z}, qr{(\.packlist)\z}, qr{(\.bs)\z}],
    'environment expansion not applied on --ignore but backslash removed');
is_deeply($options->{defer}, [qr{\A(foo\b.*bar)}, qr{\A(\.jpg$)}],
    'environment expansion not applied on --defer but backslash removed');
is_deeply($options->{override}, [qr{\A(\.png$)}, qr{\A(bin|man)}],
    'environment expansion not applied on --override but backslash removed');

#
# Test that tilde expansion is applied in correct places.
#
make_file($HOME_RC_FILE, <<'HERE');
--dir=~/stow
--target=~/stow
--ignore=~/stow
--defer=~/stow
--override=~/stow
HERE
($options, $pkgs_to_delete, $pkgs_to_stow) = get_config_file_options();
is($options->{dir}, "$ABS_TEST_DIR/stow",
    "apply tilde expansion on \$HOME/.stowrc --dir");
is($options->{target}, "$ABS_TEST_DIR/stow",
    "apply tilde expansion on \$HOME/.stowrc --target");
is_deeply($options->{ignore}, [qr{(~/stow)\z}],
    "tilde expansion not applied on --ignore");
is_deeply($options->{defer}, [qr{\A(~/stow)}],
    "tilde expansion not applied on --defer");
is_deeply($options->{override}, [qr{\A(~/stow)}],
    "tilde expansion not applied on --override");

#
# Clean up files used for testing.
#
unlink $HOME_RC_FILE or die "Unable to clean up $HOME_RC_FILE.\n";
remove_dir($ABS_TEST_DIR);
