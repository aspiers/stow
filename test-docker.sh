#!/usr/bin/env bash

# Test Stow across multiple Perl versions, by executing the
# Docker image built via build-docker.sh.

version=$( tools/get-version )

docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stowtest:$version
