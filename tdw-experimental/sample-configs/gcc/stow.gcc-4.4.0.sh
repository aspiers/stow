#!/bin/bash
set -o errexit
VERSION='4.4.0'

do_configure () {
    mkdir ../gcc-build && cd ../gcc-build
    ../gcc-4.4.0/configure --prefix=/usr/local
}

do_build () {
    make
    sudo make DESTDIR=/stow/gcc-${VERSION} install
}

do_package () {
    cd /stow
    sudo tar -cjvf gcc-${VERSION}.stow.tar.bz2 gcc-${VERSION}
    sudo mkdir --parent STOWBALLS
    sudo mv --verbose gcc-${VERSION}.stow.tar.bz2 STOWBALLS
    echo "Remember to stow and /sbin/ldconfig"
}

do_configure
do_build
do_package
