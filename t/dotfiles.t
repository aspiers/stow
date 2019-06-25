#!/usr/local/bin/perl

#
# Test case for dotfiles special processing
#

use strict;
use warnings;

use testutil;

use Test::More tests => 6;
use English qw(-no_match_vars);

use testutil;

init_test_dirs();
cd("$OUT_DIR/target");

my $stow;

#
# process a dotfile marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_dir('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.foo'),
    '../stow/dotfiles/dot-foo',
    => 'processed dotfile'
);

#
# ensure that turning off dotfile processing links files as usual
#

$stow = new_Stow(dir => '../stow', dotfiles => 0);

make_dir('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('dot-foo'),
    '../stow/dotfiles/dot-foo',
    => 'unprocessed dotfile'
);


#
# process folder marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_dir('../stow/dotfiles/dot-emacs');
make_file('../stow/dotfiles/dot-emacs/init.el');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.emacs'),
    '../stow/dotfiles/dot-emacs',
    => 'processed dotfile folder'
);

#
# corner case: paths that have a part in them that's just "$DOT_PREFIX" or
# "$DOT_PREFIX." should not have that part expanded.
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_dir('../stow/dotfiles');
make_file('../stow/dotfiles/dot-');

make_dir('../stow/dotfiles/dot-.');
make_file('../stow/dotfiles/dot-./foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('dot-'),
    '../stow/dotfiles/dot-',
    => 'processed dotfile'
);
is(
    readlink('dot-.'),
    '../stow/dotfiles/dot-.',
    => 'unprocessed dotfile'
);

#
# simple unstow scenario
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_dir('../stow/dotfiles');
make_file('../stow/dotfiles/dot-bar');
make_link('.bar', '../stow/dotfiles/dot-bar');

$stow->plan_unstow('dotfiles');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/dotfiles/dot-bar' && ! -e '.bar'
    => 'unstow a simple dotfile'
);
