#!/bin/bash

set -eu

pushd docker
docker build -t stowtest .
popd
