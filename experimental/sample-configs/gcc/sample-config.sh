mkdir ../gcc-build &&
cd ../gcc-build &&
../gcc-4.1.2/configure \
    --prefix=/usr \
    --libexecdir=/usr/lib \
    --enable-shared \
    --enable-threads=posix \
    --enable-__cxa_atexit \
    --enable-clocale=gnu \
    --enable-languages=c,c++
#    --enable-languages=c,c++,ada,fortran,java,objc,treelang &&
