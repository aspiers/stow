#!/usr/bin/env bash

# Test Stow across multiple Perl versions, by executing the
# Docker image built via build-docker.sh.
#
# Usage: ./test-docker.sh [list | PERL_VERSION]
#
# If the first argument is 'list', list available Perl versions.
# If the first argument is a Perl version, test just that version interactively.
# If no arguments are given test all available Perl versions non-interactively.

version=$( tools/get-version )

if [ -z "$1" ]; then
    # Normal non-interactive run
    docker run --rm -it \
           -v $(pwd):$(pwd) \
           -w $(pwd) \
           stowtest:$version
elif [ "$1" == list ]; then
    # List available Perl versions
    docker run --rm -it \
           -v $(pwd):$(pwd) \
           -v $(pwd)/docker/run-stow-tests.sh:/run-stow-tests.sh \
           -w $(pwd) \
           -e LIST_PERL_VERSIONS=1 \
           stowtest:$version
else
    # Interactive run for testing / debugging a particular version
    perl_version="$1"
    docker run --rm -it \
           -v $(pwd):$(pwd) \
           -v $(pwd)/docker/run-stow-tests.sh:/run-stow-tests.sh \
           -w $(pwd) \
           -e PERL_VERSION=$perl_version \
           stowtest:$version
fi
