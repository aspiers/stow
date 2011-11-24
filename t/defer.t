#!/usr/local/bin/perl

#
# Testing defer().
#

use strict;
use warnings;

use testutil;

use Test::More tests => 4;

init_test_dirs();
cd("$OUT_DIR/target");

my $stow;

$stow = new_Stow(defer => [ 'man' ]);
ok($stow->defer('man/man1/file.1') => 'simple success');

$stow = new_Stow(defer => [ 'lib' ]);
ok(! $stow->defer('man/man1/file.1') => 'simple failure');

$stow = new_Stow(defer => [ 'lib', 'man', 'share' ]);
ok($stow->defer('man/man1/file.1') => 'complex success');

$stow = new_Stow(defer => [ 'lib', 'man', 'share' ]);
ok(! $stow->defer('bin/file') => 'complex failure');
