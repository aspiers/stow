#!/bin/bash

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
