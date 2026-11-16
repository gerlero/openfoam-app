#!/bin/bash -e
# -----------------------------------------------------------------------------
# Configure OpenFOAM for compilation and use within OpenFOAM.app on macOS
# -----------------------------------------------------------------------------

# Do as much as possible with foamConfigurePaths
bin/tools/foamConfigurePaths \
    -system-compiler Clang \
    -openmpi \
    -adios-path '$WM_PROJECT_DIR/env' \
    -boost-path '$WM_PROJECT_DIR/env' \
    -cgal-path '$WM_PROJECT_DIR/env' \
    -fftw-path '$WM_PROJECT_DIR/env' \
    -gmp-path '$WM_PROJECT_DIR/env' \
    -kahip-path '$WM_PROJECT_DIR/env' \
    -metis-path '$WM_PROJECT_DIR/env' \
    -mpfr-path '$WM_PROJECT_DIR/env' \
    -scotch-path '$WM_PROJECT_DIR/env'


# Set path to the MPI install
echo 'export FOAM_MPI=openmpi' >> etc/config.sh/prefs.openmpi
echo 'setenv FOAM_MPI openmpi' >> etc/config.csh/prefs.openmpi

echo 'export MPI_ARCH_PATH="$WM_PROJECT_DIR/env"' >> etc/config.sh/prefs.openmpi
echo 'setenv MPI_ARCH_PATH "$WM_PROJECT_DIR/env"' >> etc/config.csh/prefs.openmpi


# OpenMP support
echo 'export FOAM_EXTRA_CFLAGS="-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CFLAGS"' >> etc/prefs.sh
echo 'setenv FOAM_EXTRA_CFLAGS "-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CFLAGS"' >> etc/prefs.csh

echo 'export FOAM_EXTRA_CXXFLAGS="-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CXXFLAGS"' >> etc/prefs.sh
echo 'setenv FOAM_EXTRA_CXXFLAGS "-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CXXFLAGS"' >> etc/prefs.csh

echo 'export FOAM_EXTRA_LDFLAGS="-L$WM_PROJECT_DIR/env/lib $FOAM_EXTRA_LDFLAGS"' >> etc/prefs.sh
echo 'setenv FOAM_EXTRA_LDFLAGS "-L$WM_PROJECT_DIR/env/lib $FOAM_EXTRA_LDFLAGS"' >> etc/prefs.csh


# Use bundled Bash
echo 'export PATH="$WM_PROJECT_DIR/env/bin${PATH+:$PATH}"' >> etc/prefs.sh
echo 'setenv PATH $WM_PROJECT_DIR/env/bin:$PATH' >> etc/prefs.csh

echo 'export MANPATH="$WM_PROJECT_DIR/env/share/man${MANPATH+:$MANPATH}:"' >> etc/prefs.sh
echo 'setenv MANPATH "$WM_PROJECT_DIR/env/share/man`[ ${?MANPATH} == 1 ] && echo ":${MANPATH}"`"' >> etc/prefs.csh

echo 'export INFOPATH="$WM_PROJECT_DIR/envshare/info:${INFOPATH:-}"' >> etc/prefs.sh
echo 'setenv INFOPATH "$WM_PROJECT_DIR/env/share/info`[ ${?INFOPATH} == 1 ] && echo ":${INFOPATH}"`"' >> etc/prefs.csh


# Set RPATH to find bundled libraries
echo 'PROJECT_RPATH += -rpath @loader_path/../../../env/lib' >> wmake/rules/darwin64/rpath


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2958
sed -i '' 's|-ftrapping-math|-ftrapping-math -ffp-contract=off|' wmake/rules/darwin64Clang/c
sed -i '' 's|-ftrapping-math|-ftrapping-math -ffp-contract=off|' wmake/rules/darwin64Clang/c++
