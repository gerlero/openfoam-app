#!/bin/bash -e

SYSTEM_COMPILER="Clang"

ADIOS_PATH=$(brew --prefix --installed adios2)
BOOST_PATH=$(brew --prefix --installed boost)
CGAL_PATH=$(brew --prefix --installed cgal@4)
FFTW_PATH=$(brew --prefix --installed fftw)
KAHIP_PATH=$(brew --prefix --installed kahip)
METIS_PATH=$(brew --prefix --installed metis)
SCOTCH_PATH=$(brew --prefix --installed scotch-no-pthread)

LIBOMP_PATH=$(brew --prefix --installed libomp)
GMP_PATH=$(brew --prefix --installed gmp)
MPFR_PATH=$(brew --prefix --installed mpfr)


bin/tools/foamConfigurePaths \
    -system-compiler "$SYSTEM_COMPILER" \
    -adios-path "$ADIOS_PATH"  \
    -boost-path "$BOOST_PATH"  \
    -cgal-path "$CGAL_PATH"  \
    -fftw-path "$FFTW_PATH"  \
    -kahip-path "$KAHIP_PATH"  \
    -metis-path "$METIS_PATH"  \
    -scotch-path "$SCOTCH_PATH"

CPATH="$LIBOMP_PATH/include:$GMP_PATH/include:$MPFR_PATH/include"
LIBRARY_PATH="$LIBOMP_PATH/lib:$GMP_PATH/lib:$MPFR_PATH/lib"

echo "export CPATH=\"$CPATH\"" >> etc/prefs.sh
echo "setenv CPATH \"$CPATH\"" >> etc/prefs.csh
echo "export LIBRARY_PATH=\"$LIBRARY_PATH\"" >> etc/prefs.sh
echo "setenv LIBRARY_PATH \"$LIBRARY_PATH\"" >> etc/prefs.csh

echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc
