#!/bin/bash
set -o errexit
VERSION='4.4.0'
BUILD_DIR='gcc-build'

do_configure () {
    mkdir ../${BUILD_DIR} &&
    cd ../${BUILD_DIR} &&
    ../gcc-${VERSION}/configure \
	--prefix=/usr \
#	--libexecdir=/usr/lib \
        --enable-shared \
	--enable-threads=posix \
	--enable-__cxa_atexit \
	--enable-clocale=gnu \
#       --enable-languages=c,c++,ada,fortran,java,objc,treelang
	--enable-languages=c,c++ &&
    cd -
}

do_build () {
    cd ../${BUILD_DIR}
    make
    sudo make DESTDIR=/stow/gcc-${VERSION} install
    cd -
}

do_package () {
    cd /stow
    tar -cjvf gcc-${VERSION}.stow.tar.bz2 gcc-${VERSION}
    mkdir --parent STOWBALLS
    mv tar -cjvf gcc-${VERSION}.stow.tar.bz2 STOWBALLS
    cd -
}

do_configure
do_build
do_package
