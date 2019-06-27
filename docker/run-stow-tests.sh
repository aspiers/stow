#!/bin/bash
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

# Load perlbrew environment
# Load before setting safety to keep
# perlbrew scripts from breaking due to
# unset variables.
. /usr/local/perlbrew/etc/bashrc

# Standard safety protocol
set -euf -o pipefail
IFS=$'\n\t'

for p_version in $(perlbrew list | sed 's/ //g'); do
    perlbrew use $p_version

    echo $(perl --version)

    # Install stow
    autoreconf --install
    eval `perl -V:siteprefix`
    ./configure --prefix=$siteprefix && make
    make cpanm

    # Run tests
    make distcheck
    perl Build.PL && ./Build build && cover -test
    ./Build distcheck
done

make distclean
