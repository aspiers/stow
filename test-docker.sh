#!/bin/bash

# Run the docker image that test. 
docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stowtest
