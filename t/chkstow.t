#!/usr/local/bin/perl

#
# Testing cleanup_invalid_links()
#

use strict;
use warnings;

use testutil;
require "chkstow";

use Test::More tests => 7;
use Test::Output;
use English qw(-no_match_vars);

init_test_dirs();
cd("$OUT_DIR/target");

# setup stow directory
make_dir('stow');
make_file('stow/.stow');
# perl
make_dir('stow/perl/bin');
make_file('stow/perl/bin/perl');
make_file('stow/perl/bin/a2p');
make_dir('stow/perl/info');
make_file('stow/perl/info/perl');
make_dir('stow/perl/lib/perl');
make_dir('stow/perl/man/man1');
make_file('stow/perl/man/man1/perl.1');
# emacs
make_dir('stow/emacs/bin');
make_file('stow/emacs/bin/emacs');
make_file('stow/emacs/bin/etags');
make_dir('stow/emacs/info');
make_file('stow/emacs/info/emacs');
make_dir('stow/emacs/libexec/emacs');
make_dir('stow/emacs/man/man1');
make_file('stow/emacs/man/man1/emacs.1');

#setup target directory
make_dir('bin');
make_link('bin/a2p', '../stow/perl/bin/a2p');
make_link('bin/emacs', '../stow/emacs/bin/emacs');
make_link('bin/etags', '../stow/emacs/bin/etags');
make_link('bin/perl', '../stow/perl/bin/perl');

make_dir('info');
make_link('info/emacs', '../stow/emacs/info/emacs');
make_link('info/perl', '../stow/perl/info/perl');

make_link('lib', 'stow/perl/lib');
make_link('libexec', 'stow/emacs/libexec');

make_dir('man');
make_dir('man/man1');
make_link('man/man1/emacs', '../../stow/emacs/man/man1/emacs.1');
make_link('man/man1/perl', '../../stow/perl/man/man1/perl.1');

sub run_chkstow() {
    process_options();
    check_stow();
}

local @ARGV = ('-t', '.', '-b');
stderr_like(
    \&run_chkstow,
    qr{\Askipping .*stow.*\z}xms,
    "Skip directories containing .stow");
      
# squelch warn so that check_stow doesn't carp about skipping .stow all the time
$SIG{__WARN__} = sub { };

@ARGV = ('-t', '.', '-l');
stdout_like(
    \&run_chkstow,
    qr{emacs\nperl\nstow\n}xms,
    "List packages");

@ARGV = ('-t', '.', '-b');
stdout_like(
    \&run_chkstow,
    qr{\A\z}xms,
    "No bogus links exist");

@ARGV = ('-t', '.', '-a');
stdout_like(
    \&run_chkstow,
    qr{\A\z}xms,
    "No aliens exist");

# Create an alien
make_file('bin/alien');
@ARGV = ('-t', '.', '-a');
stdout_like(
    \&run_chkstow,
    qr{Unstowed\ file:\ ./bin/alien}xms,
    "Aliens exist");

make_invalid_link('bin/link', 'ireallyhopethisfiledoesn/t.exist');
@ARGV = ('-t', '.', '-b');
stdout_like(
    \&run_chkstow,
    qr{Bogus\ link:\ ./bin/link}xms,
    "Bogus links exist");

@ARGV = ('-b');
process_options();
our $Target;
ok($Target == q{/usr/local},
    "Default target is /usr/local/");
