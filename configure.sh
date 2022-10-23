#!/bin/bash -e

bin/tools/foamConfigurePaths \
    -system-compiler 'Clang' \
    -adios-path $PWD/usr/opt/adios2 \
    -boost-path $PWD/usr/opt/boost \
    -cgal-path $PWD/usr/opt/cgal\\\@4 \
    -fftw-path $PWD/usr/opt/fftw \
    -kahip-path $PWD/usr/opt/kahip \
    -metis-path $PWD/usr/opt/metis \
    -scotch-path $PWD/usr/opt/scotch-no-pthread


OPENMPI_PATH="$PWD/usr/opt/open-mpi"
BASH_PATH="$PWD/usr/opt/bash"

PATH_EXTRA="$BASH_PATH/bin:$OPENMPI_PATH/bin"
echo "export PATH=\"$PATH_EXTRA\${PATH+:\$PATH}\"" >> etc/prefs.sh
echo "setenv PATH $PATH_EXTRA:\$PATH" >> etc/prefs.csh

MANPATH_EXTRA="$BASH_PATH/share/man:$OPENMPI_PATH/share/man"
echo "export MANPATH=\"$MANPATH_EXTRA\${MANPATH+:\$MANPATH}:\"" >> etc/prefs.sh
echo "setenv MANPATH $MANPATH_EXTRA\`[ \${?MANPATH} == 1 ] && echo \":\${MANPATH}\"\`:" >> etc/prefs.csh

INFOPATH_EXTRA="$BASH_PATH/share/info:$OPENMPI_PATH/share/info"
echo "export INFOPATH=\"$INFOPATH_EXTRA:\${INFOPATH:-}\"" >> etc/prefs.sh
echo "setenv INFOPATH $INFOPATH_EXTRA\`[ \${?INFOPATH} == 1 ] && echo \":\${INFOPATH}\"\`" >> etc/prefs.csh


LIBOMP_PATH="$PWD/usr/opt/libomp"
GMP_PATH="$PWD/usr/opt/gmp"
MPFR_PATH="$PWD/usr/opt/mpfr"

CPATH_EXTRA="$LIBOMP_PATH/include:$GMP_PATH/include:$MPFR_PATH/include"
LIBRARY_PATH_EXTRA="$LIBOMP_PATH/lib:$GMP_PATH/lib:$MPFR_PATH/lib"

echo "export CPATH=\"$CPATH_EXTRA:\${CPATH+:\$CPATH}\"" >> etc/prefs.sh
echo "setenv CPATH \"$CPATH_EXTRA\`[ \${?CPATH} == 1 ] && echo \":\${CPATH}\"\`\"" >> etc/prefs.csh

echo "export LIBRARY_PATH=\"$LIBRARY_PATH_EXTRA:\${LIBRARY_PATH+:\$LIBRARY_PATH}\"" >> etc/prefs.sh
echo "setenv LIBRARY_PATH \"$LIBRARY_PATH_EXTRA\`[ \${?LIBRARY_PATH} == 1 ] && echo \":\${LIBRARY_PATH}\"\`\"" >> etc/prefs.csh


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/1664
echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc


# Workaround for https://develop.openfoam.com/Community/integration-cfmesh/-/issues/8
sed -i '' 's|LIB_LIBS =|& $(LINK_OPENMP) |' modules/cfmesh/meshLibrary/Make/options
