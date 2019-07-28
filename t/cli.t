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

use File::Basename;
use Test::More tests => 3;

use testutil;

#init_test_dirs();

# Since here we're doing black-box testing on the stow executable,
# this looks like it should be robust:
#
#my $STOW = dirname(__FILE__) . '/../bin/stow';
#
# but unfortunately it breaks things like "make distcheck", which
# builds the stow script into a separate path like
#
#    stow-2.3.0/_build/sub/bin
#
# before cd'ing to something like
#
#    stow-2.3.0/_build/sub
#
# and then running the tests via:
#
#    make  check-TESTS
#    make[2]: Entering directory '/path/to/stow/src/stow-2.3.0/_build/sub'
#    dir=../../t; \
#    /usr/bin/perl -Ibin -Ilib -I../../t -MTest::Harness -e 'runtests(@ARGV)' "${dir#./}"/*.t
#
# So the simplest solution is to hardcode an assumption that we run
# tests either from somewhere like this during distcheck:
#
#    stow-2.3.0/_build/sub
#
# or from the top of the source tree during development.  This can be done
# via the following, which also follows the KISS principle:
my $STOW = "$^X bin/stow";

`$STOW --help`;
is($?, 0, "--help should return 0 exit code");

my $err = `$STOW --foo 2>&1`;
is($? >> 8, 1, "unrecognised option should return 1 exit code");
like($err, qr/^Unknown option: foo$/m, "unrecognised option should be listed");

# vim:ft=perl
