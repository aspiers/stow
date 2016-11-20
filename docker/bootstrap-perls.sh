#!/bin/bash

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
