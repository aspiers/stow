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
# Test case for dotfiles special processing
#

use strict;
use warnings;

use testutil;

use Test::More tests => 10;
use English qw(-no_match_vars);

use testutil;

init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

#
# process a dotfile marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
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

make_path('../stow/dotfiles');
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

make_path('../stow/dotfiles/dot-emacs');
make_file('../stow/dotfiles/dot-emacs/init.el');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.emacs'),
    '../stow/dotfiles/dot-emacs',
    => 'processed dotfile folder'
);

#
# process folder marked with 'dot' prefix
# when directory exists is target
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-emacs.d');
make_file('../stow/dotfiles/dot-emacs.d/init.el');
make_path('.emacs.d');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.emacs.d/init.el'),
    '../../stow/dotfiles/dot-emacs.d/init.el',
    => 'processed dotfile folder when folder exists (1 level)'
);

#
# process folder marked with 'dot' prefix
# when directory exists is target (2 levels)
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-emacs.d/dot-emacs.d');
make_file('../stow/dotfiles/dot-emacs.d/dot-emacs.d/init.el');
make_path('.emacs.d');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('.emacs.d/.emacs.d'),
    '../../stow/dotfiles/dot-emacs.d/dot-emacs.d',
    => 'processed dotfile folder exists (2 levels)'
);

#
# process folder marked with 'dot' prefix
# when directory exists is target
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-one/dot-two');
make_file('../stow/dotfiles/dot-one/dot-two/three');
make_path('.one/.two');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    readlink('./.one/.two/three'),
    '../../../stow/dotfiles/dot-one/dot-two/three',
    => 'processed dotfile 2 folder exists (2 levels)'
);


#
# corner case: paths that have a part in them that's just "$DOT_PREFIX" or
# "$DOT_PREFIX." should not have that part expanded.
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-');

make_path('../stow/dotfiles/dot-.');
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

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-bar');
make_link('.bar', '../stow/dotfiles/dot-bar');

$stow->plan_unstow('dotfiles');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/dotfiles/dot-bar' && ! -e '.bar'
    => 'unstow a simple dotfile'
);

#
# unstow process folder marked with 'dot' prefix
# when directory exists is target
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-emacs.d');
make_file('../stow/dotfiles/dot-emacs.d/init.el');
make_path('.emacs.d');
make_link('.emacs.d/init.el', '../../stow/dotfiles/dot-emacs.d/init.el');

$stow->plan_unstow('dotfiles');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/dotfiles/dot-emacs.d/init.el' &&
    ! -e '.emacs.d/init.el' &&
    -d '.emacs.d/'
    => 'unstow dotfile folder when folder already exists'
);
