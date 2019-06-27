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
. /usr/local/perlbrew/etc/bashrc

# For each perl version installed.
for p_version in $(perlbrew list | sed 's/ //g'); do
    # Switch to it.
    perlbrew use $p_version
    # and install the needed modules.
    /usr/local/perlbrew/bin/cpanm -n Devel::Cover::Report::Coveralls Test::More Test::Output
done

# Cleanup to remove any temp files.
perlbrew clean
