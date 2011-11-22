#!/usr/local/bin/perl

#
# Testing parent()
#

use strict;
use warnings;

use Stow::Util qw(parent);

use Test::More tests => 5;

is(
    parent('a/b/c'),
    'a/b'
    => 'no leading or trailing /'
);

is(
    parent('/a/b/c'),
    '/a/b'
    => 'leading /'
);

is(
    parent('a/b/c/'),
    'a/b'
    => 'trailing /'
);

is(
    parent('/////a///b///c///'),
    '/a/b'
    => 'multiple /'
);

is (
    parent('a'),
    ''
    => 'empty parent'
);

