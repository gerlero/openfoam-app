#!/bin/bash -e

bin/tools/foamConfigurePaths \
    -system-compiler 'Clang' \
    -adios-path $PWD/usr/opt/adios2 \
    -boost-path $PWD/usr/opt/boost \
    -cgal-path $PWD/usr/opt/cgal \
    -fftw-path $PWD/usr/opt/fftw \
    -kahip-path $PWD/usr/opt/kahip \
    -metis-path $PWD/usr/opt/metis \
    -scotch-path $PWD/usr/opt/scotch


GMP_PATH="$PWD/usr/opt/gmp"
MPFR_PATH="$PWD/usr/opt/mpfr"

sed -i '' "s|\# export GMP_ARCH_PATH=...|export GMP_ARCH_PATH=\"$GMP_PATH\"|" etc/config.sh/CGAL
sed -i '' "s|\# setenv GMP_ARCH_PATH ...|setenv GMP_ARCH_PATH \"$GMP_PATH\"|" etc/config.csh/CGAL

sed -i '' "s|\# export MPFR_ARCH_PATH=...|export MPFR_ARCH_PATH=\"$MPFR_PATH\"|" etc/config.sh/CGAL
sed -i '' "s|\# setenv MPFR_ARCH_PATH ...|setenv MPFR_ARCH_PATH \"$MPFR_PATH\"|" etc/config.csh/CGAL


MPI_PATH="$PWD/usr/opt/open-mpi"
BASH_PATH="$PWD/usr/opt/bash"

PATH_EXTRA="$BASH_PATH/bin:$MPI_PATH/bin"
MANPATH_EXTRA="$BASH_PATH/share/man:$MPI_PATH/share/man"
INFOPATH_EXTRA="$BASH_PATH/share/info:$MPI_PATH/share/info"

echo "export PATH=\"$PATH_EXTRA\${PATH+:\$PATH}\"" >> etc/prefs.sh
echo "setenv PATH $PATH_EXTRA:\$PATH" >> etc/prefs.csh

echo "export MANPATH=\"$MANPATH_EXTRA\${MANPATH+:\$MANPATH}:\"" >> etc/prefs.sh
echo "setenv MANPATH $MANPATH_EXTRA\`[ \${?MANPATH} == 1 ] && echo \":\${MANPATH}\"\`:" >> etc/prefs.csh

echo "export INFOPATH=\"$INFOPATH_EXTRA:\${INFOPATH:-}\"" >> etc/prefs.sh
echo "setenv INFOPATH $INFOPATH_EXTRA\`[ \${?INFOPATH} == 1 ] && echo \":\${INFOPATH}\"\`" >> etc/prefs.csh


LIBOMP_PATH="$PWD/usr/opt/libomp"

if [ -f "$LIBOMP_PATH/include/omp.h" ]; then
    echo "export CPATH=\"$LIBOMP_PATH/include\${CPATH+:\$CPATH}\"" >> etc/prefs.sh
    echo "setenv CPATH \"$LIBOMP_PATH/include\`[ \${?CPATH} == 1 ] && echo \":\${CPATH}\"\`\"" >> etc/prefs.csh

    echo "export LIBRARY_PATH=\"$LIBOMP_PATH/lib\${LIBRARY_PATH+:\$LIBRARY_PATH}\"" >> etc/prefs.sh
    echo "setenv LIBRARY_PATH \"$LIBOMP_PATH/lib\`[ \${?LIBRARY_PATH} == 1 ] && echo \":\${LIBRARY_PATH}\"\`\"" >> etc/prefs.csh
else
    echo "OpenMP not found at $LIBOMP_PATH. Disabling OpenMP support" >&2
    echo "export WM_COMPILE_CONTROL=\"\$WM_COMPILE_CONTROL ~openmp\"" >> etc/prefs.sh
    echo "setenv WM_COMPILE_CONTROL \"\$WM_COMPILE_CONTROL ~openmp\"" >> etc/prefs.csh
fi


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/1664
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc


# Workaround for https://develop.openfoam.com/Community/integration-cfmesh/-/issues/8
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || sed -i '' 's|LIB_LIBS =|& $(LINK_OPENMP) |' modules/cfmesh/meshLibrary/Make/options


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2668
[ $(bin/foamEtcFile -show-api) -ne 2212 ] || sed -i '' '\|/\* \${CGAL_LIBS} \*/|d' applications/utilities/preProcessing/viewFactorsGen/Make/options


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2664
[ $(bin/foamEtcFile -show-api) -gt 2212 ] || rm -f wmake/rules/darwin64Clang/cgal

# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2665
[ $(bin/foamEtcFile -show-api) -gt 2212 ] || sed -i '' 's|Robust_circumcenter_filtered_traits_3|Robust_weighted_circumcenter_filtered_traits_3|' applications/utilities/mesh/generation/foamyMesh/conformalVoronoiMesh/conformalVoronoiMesh/CGALTriangulation3DKernel.H
