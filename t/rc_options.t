#!/usr/local/bin/perl

#
# Test processing of stowrc file.
#

use strict;
use warnings;

use Test::More tests => 17;

use testutil;

require 'stow';

# stowrc file used for testing.
my $RC_FILE = "$OUT_DIR/.stowrc";
# Take the safe route and cowardly refuse to continue if there's
# already a file at $RC_FILE.
if (-e $RC_FILE) {
    die "RC file location $RC_FILE already exists!\n";
}

# Define the variable that will be used to write stowrc.
my $rc_contents;

# Init testing directory structure and overwrite ENV{HOME} to prevent
# squashing existing stowrc file.
init_test_dirs();

# =========== RC Loading Tests ===========
# Basic parsing and loading rc file tests.
# ========================================

#
# Test stowrc file with one options per line.
#
local @ARGV = ('dummy');
$rc_contents = <<HERE;
    -d $OUT_DIR/stow
    --target $OUT_DIR/target
HERE
make_file($RC_FILE, $rc_contents);
my ($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{target},  "$OUT_DIR/target", "rc options different lines");
is($options->{dir}, "$OUT_DIR/stow", "rc options different lines");

#
# Test that scalar cli option overwrites conflicting stowrc option.
#
local @ARGV = ('-d', "$OUT_DIR/stow",'dummy');
$rc_contents = <<HERE;
    -d bad/path
HERE
make_file($RC_FILE, $rc_contents);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is($options->{dir}, "$OUT_DIR/stow", "cli overwrite scalar rc option.");

#
# Test that list cli option merges with conflicting stowrc option.
# Documentation states that stowrc options are prepended to cli options.
#
local @ARGV = (
    '--defer=man',
    'dummy'
);
$rc_contents = <<HERE;
    --defer=info
HERE
make_file($RC_FILE, $rc_contents);
($options, $pkgs_to_delete, $pkgs_to_stow) = process_options();
is_deeply($options->{defer}, [qr(\Ainfo), qr(\Aman)],
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
is(expand_environment('$HOME/stow'), "$OUT_DIR/stow", 'expand $HOME');
is(expand_environment('${HOME}/stow'), "$OUT_DIR/stow", 'expand ${HOME}');
is(expand_environment('${UNDEFINED}'), '', 'expand $UNDEFINED');
# Expansion with a space.
if (exists $ENV{'WITH SPACE'}) {
    die 'Environment variable ${WITH SPACE} exists';
}
$ENV{'WITH SPACE'} = 'test string';
is(expand_environment('${WITH SPACE}'), 'test string',
    'expand ${WITH SPACE}');
delete $ENV{'WITH SPACE'};
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
# Test that environment variable expansion is applied.
#
$rc_contents = <<'HERE';
--dir=$HOME/stow
--target=$HOME/stow
--ignore=\$HOME
--defer=\$HOME
--override=\$HOME
HERE
make_file($RC_FILE, $rc_contents);
($options, $pkgs_to_delete, $pkgs_to_stow) = get_config_file_options();
is($options->{dir}, "$OUT_DIR/stow",
    "apply environment expansion on stowrc --dir");
is($options->{target}, "$OUT_DIR/stow",
    "apply environment expansion on stowrc --target");
is_deeply($options->{ignore}, [qr(\$HOME\z)],
    "environment expansion not applied on --ignore");
is_deeply($options->{defer}, [qr(\A\$HOME)],
    "environment expansion not applied on --defer");
is_deeply($options->{override}, [qr(\A\$HOME)],
    "environment expansion not applied on --override");

# Clean up files used for testing.
#
unlink $RC_FILE or die "Unable to clean up $RC_FILE.\n";
remove_dir($OUT_DIR);

