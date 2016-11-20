#!/bin/bash

set -eu

version=$( git describe --match v* --abbrev=0 )
imagename=stowtest
image=$imagename:$version

pushd docker
echo "Building Docker image $image ..."
docker build -t $image .
popd
