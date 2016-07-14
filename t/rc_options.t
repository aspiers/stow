#!/usr/local/bin/perl

#
# Test processing of stowrc file.
#

use strict;
use warnings;

use Test::More tests => 4;

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

# Clean up files used for testing.
#
unlink $RC_FILE or die "Unable to clean up $RC_FILE.\n";
remove_dir($OUT_DIR);

