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
set -ef -o pipefail
IFS=$'\n\t'

test_perl_version () {
    perl_version="$1"
    perlbrew use $perl_version

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
}

if [[ -n "$LIST_PERL_VERSIONS" ]]; then
    echo "Listing Perl versions available from perlbrew ..."
    perlbrew list
elif [[ -z "$PERL_VERSION" ]]; then
    echo "Testing all versions ..."
    for perl_version in $(perlbrew list | sed 's/ //g'); do
        test_perl_version $perl_version
    done
    make distclean
else
    echo "Testing with Perl $PERL_VERSION"
    # Test a specific version requested via $PERL_VERSION environment
    # variable.  Make sure set -e doesn't cause us to bail on failure
    # before we start an interactive shell.
    test_perl_version $PERL_VERSION || :
    # N.B. Don't distclean since we probably want to debug this Perl
    # version interactively.
    cat <<EOF
To run a specific test, type something like:

perl -Ilib -Ibin -It t/cli_options.t

Code can be edited on the host and will immediately take effect inside
this container.

EOF
    bash
fi
