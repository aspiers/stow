#!/usr/local/bin/perl

#
# Testing defer().
#

# load as a library
BEGIN { use lib qw(. ..); require "stow"; }

use Test::More tests => 4;

$Option{'defer'} = [ 'man' ];
ok(defer('man/man1/file.1') => 'simple success');

$Option{'defer'} = [ 'lib' ];
ok(!defer('man/man1/file.1') => 'simple failure');

$Option{'defer'} = [ 'lib', 'man', 'share' ];
ok(defer('man/man1/file.1') => 'complex success');

$Option{'defer'} = [ 'lib', 'man', 'share' ];
ok(!defer('bin/file') => 'complex failure');
