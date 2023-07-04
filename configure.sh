#!/bin/bash -e
# -----------------------------------------------------------------------------
# Configure OpenFOAM for compilation and use within OpenFOAM.app on macOS
# -----------------------------------------------------------------------------

# Do as much as possible with foamConfigurePaths
bin/tools/foamConfigurePaths \
    -system-compiler Clang \
    -openmpi \
    -adios-path '$WM_PROJECT_DIR/usr/opt/adios2' \
    -boost-path '$WM_PROJECT_DIR/usr/opt/boost' \
    -cgal-path '$WM_PROJECT_DIR/usr/opt/cgal' \
    -fftw-path '$WM_PROJECT_DIR/usr/opt/fftw' \
    -kahip-path '$WM_PROJECT_DIR/usr/opt/kahip' \
    -metis-path '$WM_PROJECT_DIR/usr/opt/metis' \
    -scotch-path '$WM_PROJECT_DIR/usr/opt/scotch-no-pthread'


# Set path to the MPI install
MPI_PATH='$WM_PROJECT_DIR/usr/opt/open-mpi'

echo 'export FOAM_MPI=openmpi' >> etc/config.sh/prefs.openmpi
echo 'setenv FOAM_MPI openmpi' >> etc/config.csh/prefs.openmpi

echo "export MPI_ARCH_PATH=\"$MPI_PATH\"" >> etc/config.sh/prefs.openmpi
echo "setenv MPI_ARCH_PATH \"$MPI_PATH\"" >> etc/config.csh/prefs.openmpi


# Set paths of GMP and MPFR (dependencies of CGAL)
GMP_PATH='$WM_PROJECT_DIR/usr/opt/gmp'
MPFR_PATH='$WM_PROJECT_DIR/usr/opt/mpfr'

sed -i '' "s|\# export GMP_ARCH_PATH=...|export GMP_ARCH_PATH=\"$GMP_PATH\"|" etc/config.sh/CGAL
sed -i '' "s|\# setenv GMP_ARCH_PATH ...|setenv GMP_ARCH_PATH \"$GMP_PATH\"|" etc/config.csh/CGAL

sed -i '' "s|\# export MPFR_ARCH_PATH=...|export MPFR_ARCH_PATH=\"$MPFR_PATH\"|" etc/config.sh/CGAL
sed -i '' "s|\# setenv MPFR_ARCH_PATH ...|setenv MPFR_ARCH_PATH \"$MPFR_PATH\"|" etc/config.csh/CGAL


# OpenMP support
OPENMP_PATH='$WM_PROJECT_DIR/usr/opt/libomp'

if [ -f "$OPENMP_PATH/include/omp.h" ]; then
    echo "export CPATH=\"$OPENMP_PATH/include\${CPATH+:\$CPATH}\"" >> etc/prefs.sh
    echo "setenv CPATH \"$OPENMP_PATH/include\`[ \${?CPATH} == 1 ] && echo \":\${CPATH}\"\`\"" >> etc/prefs.csh

    echo "export LIBRARY_PATH=\"$OPENMP_PATH/lib\${LIBRARY_PATH+:\$LIBRARY_PATH}\"" >> etc/prefs.sh
    echo "setenv LIBRARY_PATH \"$OPENMP_PATH/lib\`[ \${?LIBRARY_PATH} == 1 ] && echo \":\${LIBRARY_PATH}\"\`\"" >> etc/prefs.csh
else
    echo "OpenMP not found at $OPENMP_PATH. Disabling OpenMP support" >&2
    echo "export WM_COMPILE_CONTROL=\"\$WM_COMPILE_CONTROL ~openmp\"" >> etc/prefs.sh
    echo "setenv WM_COMPILE_CONTROL \"\$WM_COMPILE_CONTROL ~openmp\"" >> etc/prefs.csh
fi


# Use bundled Bash
BASH_PATH='$WM_PROJECT_DIR/usr/opt/bash'

echo "export PATH=\"$BASH_PATH/bin\${PATH+:\$PATH}\"" >> etc/prefs.sh
echo "setenv PATH $BASH_PATH/bin:\$PATH" >> etc/prefs.csh

echo "export MANPATH=\"$BASH_PATH/share/man\${MANPATH+:\$MANPATH}:\"" >> etc/prefs.sh
echo "setenv MANPATH $BASH_PATH/share/man\`[ \${?MANPATH} == 1 ] && echo \":\${MANPATH}\"\`:" >> etc/prefs.csh

echo "export INFOPATH=\"$BASH_PATH/share/info:\${INFOPATH:-}\"" >> etc/prefs.sh
echo "setenv INFOPATH $BASH_PATH/share/info\`[ \${?INFOPATH} == 1 ] && echo \":\${INFOPATH}\"\`" >> etc/prefs.csh


# Disable floating point exception trapping when on Apple silicon
# (Prevents confusing output that says it's enabled, as it doesn't work yet)
# https://develop.openfoam.com/Development/openfoam/-/issues/2240
[ $(uname -m) != 'arm64' ] || echo 'export FOAM_SIGFPE=false' >> etc/prefs.sh
[ $(uname -m) != 'arm64' ] || echo 'setenv FOAM_SIGFPE false' >> etc/prefs.csh


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/1664
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc


# Workaround for https://develop.openfoam.com/Community/integration-cfmesh/-/issues/8
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || sed -i '' 's|LIB_LIBS =|& $(LINK_OPENMP) |' modules/cfmesh/meshLibrary/Make/options


# Backport of https://develop.openfoam.com/Development/openfoam/-/issues/2555
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || patch src/meshTools/triSurface/triSurfaceTools/geompack/geompack.C <<EOF
@@ -6,6 +6,10 @@
 # include <ctime>
 # include <cstring>
 
+#if defined(__APPLE__) && defined(__clang__)
+#pragma clang fp exceptions(ignore)
+#endif
+
 using namespace std;
 
 # include "geompack.H"
EOF


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2668
[ $(bin/foamEtcFile -show-api) -ne 2212 ] || [ $(bin/foamEtcFile -show-patch) -ge 230612 ] || sed -i '' '\|/\* \${CGAL_LIBS} \*/|d' applications/utilities/preProcessing/viewFactorsGen/Make/options


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2664
[ $(bin/foamEtcFile -show-api) -gt 2212 ] || [ $(bin/foamEtcFile -show-patch) -ge 230612 ] || rm -f wmake/rules/darwin64Clang/cgal

# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2665
[ $(bin/foamEtcFile -show-api) -gt 2212 ] || [ $(bin/foamEtcFile -show-patch) -ge 230612 ] || sed -i '' 's|Robust_circumcenter_filtered_traits_3|Robust_weighted_circumcenter_filtered_traits_3|' applications/utilities/mesh/generation/foamyMesh/conformalVoronoiMesh/conformalVoronoiMesh/CGALTriangulation3DKernel.H
