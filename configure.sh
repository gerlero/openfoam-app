#!/bin/zsh -e

bin/tools/foamConfigurePaths \
    -system-compiler 'Clang' \
    -adios-path $PWD/usr/opt/adios2 \
    -boost-path $PWD/usr/opt/boost \
    -cgal-path $PWD/usr/opt/cgal\\\@4 \
    -fftw-path $PWD/usr/opt/fftw \
    -kahip-path $PWD/usr/opt/kahip \
    -metis-path $PWD/usr/opt/metis \
    -scotch-path $PWD/usr/opt/scotch-no-pthread


echo "export PATH=\"$PWD/usr/bin:\${PATH+:\$PATH}\"" >> etc/prefs.sh
echo "setenv PATH $PWD/usr/bin:\$PATH;" >> etc/prefs.csh


LIBOMP_PATH="$PWD/usr/opt/libomp"
GMP_PATH="$PWD/usr/opt/gmp"
MPFR_PATH="$PWD/usr/opt/mpfr"

CPATH="$LIBOMP_PATH/include:$GMP_PATH/include:$MPFR_PATH/include"
LIBRARY_PATH="$LIBOMP_PATH/lib:$GMP_PATH/lib:$MPFR_PATH/lib"

echo "export CPATH=\"$CPATH\"" >> etc/prefs.sh
echo "setenv CPATH \"$CPATH\"" >> etc/prefs.csh
echo "export LIBRARY_PATH=\"$LIBRARY_PATH\"" >> etc/prefs.sh
echo "setenv LIBRARY_PATH \"$LIBRARY_PATH\"" >> etc/prefs.csh


echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc
