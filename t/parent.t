#!/usr/local/bin/perl

#
# Testing parent()
#

# load as a library
BEGIN { use lib qw(. ..); require "stow"; }

use Test::More tests => 5;

is(
    parent('a/b/c'),
    'a/b',
    => 'no leading or trailing /'
);

is(
    parent('/a/b/c'),
    '/a/b',
    => 'leading /'
);

is(
    parent('a/b/c/'),
    'a/b',
    => 'trailing /'
);

is(
    parent('/////a///b///c///'),
    '/a/b',
    => 'multiple /'
);

is (
    parent('a'),
    ''
    => 'empty parent'
);

