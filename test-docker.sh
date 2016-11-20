#!/bin/bash

# Test Stow across multiple Perl versions, by executing the
# Docker image built via build-docker.sh.

version=$( git describe --match v* --abbrev=0 )

docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stowtest:$version
