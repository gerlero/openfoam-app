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
    -kahip-path '$WM_PROJECT_DIR/env' \
    -metis-path '$WM_PROJECT_DIR/env' \
    -scotch-path '$WM_PROJECT_DIR/env'


# Set path to the MPI install
echo 'export FOAM_MPI=openmpi' >> etc/config.sh/prefs.openmpi
echo 'setenv FOAM_MPI openmpi' >> etc/config.csh/prefs.openmpi

echo 'export MPI_ARCH_PATH="$WM_PROJECT_DIR/env"' >> etc/config.sh/prefs.openmpi
echo 'setenv MPI_ARCH_PATH "$WM_PROJECT_DIR/env"' >> etc/config.csh/prefs.openmpi


# Set paths of GMP and MPFR (dependencies of CGAL)
sed -i '' 's|# export GMP_ARCH_PATH=...|export GMP_ARCH_PATH="$WM_PROJECT_DIR/env"|' etc/config.sh/CGAL
sed -i '' 's|# setenv GMP_ARCH_PATH ...|setenv GMP_ARCH_PATH "$WM_PROJECT_DIR/env"|' etc/config.csh/CGAL

sed -i '' 's|# export MPFR_ARCH_PATH=...|export MPFR_ARCH_PATH="$WM_PROJECT_DIR/env"|' etc/config.sh/CGAL
sed -i '' 's|# setenv MPFR_ARCH_PATH ...|setenv MPFR_ARCH_PATH "$WM_PROJECT_DIR/env"|' etc/config.csh/CGAL


# OpenMP support
if [ $(bin/foamEtcFile -show-api) -lt 2212 ]; then
    echo 'export CPATH="$WM_PROJECT_DIR/env/include${CPATH+:$CPATH}"' >> etc/prefs.sh
    echo 'setenv CPATH "$WM_PROJECT_DIR/env/include`[ ${?CPATH} == 1 ] && echo ":${CPATH}"`"' >> etc/prefs.csh

    echo 'export LIBRARY_PATH="$WM_PROJECT_DIR/env/lib${LIBRARY_PATH+:$LIBRARY_PATH}"' >> etc/prefs.sh
    echo 'setenv LIBRARY_PATH "$WM_PROJECT_DIR/env/lib`[ ${?LIBRARY_PATH} == 1 ] && echo ":${LIBRARY_PATH}"`"' >> etc/prefs.csh
else
    echo 'export FOAM_EXTRA_CFLAGS="-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CFLAGS"' >> etc/prefs.sh
    echo 'setenv FOAM_EXTRA_CFLAGS "-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CFLAGS"' >> etc/prefs.csh

    echo 'export FOAM_EXTRA_CXXFLAGS="-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CXXFLAGS"' >> etc/prefs.sh
    echo 'setenv FOAM_EXTRA_CXXFLAGS "-I$WM_PROJECT_DIR/env/include $FOAM_EXTRA_CXXFLAGS"' >> etc/prefs.csh

    echo 'export FOAM_EXTRA_LDFLAGS="-L$WM_PROJECT_DIR/env/lib $FOAM_EXTRA_LDFLAGS"' >> etc/prefs.sh
    echo 'setenv FOAM_EXTRA_LDFLAGS "-L$WM_PROJECT_DIR/env/lib $FOAM_EXTRA_LDFLAGS"' >> etc/prefs.csh
fi


# Use bundled Bash
echo 'export PATH="$WM_PROJECT_DIR/env/bin${PATH+:$PATH}"' >> etc/prefs.sh
echo 'setenv PATH $WM_PROJECT_DIR/env/bin:$PATH' >> etc/prefs.csh

echo 'export MANPATH="$WM_PROJECT_DIR/env/share/man${MANPATH+:$MANPATH}:"' >> etc/prefs.sh
echo 'setenv MANPATH "$WM_PROJECT_DIR/env/share/man`[ ${?MANPATH} == 1 ] && echo ":${MANPATH}"`"' >> etc/prefs.csh

echo 'export INFOPATH="$WM_PROJECT_DIR/envshare/info:${INFOPATH:-}"' >> etc/prefs.sh
echo 'setenv INFOPATH "$WM_PROJECT_DIR/env/share/info`[ ${?INFOPATH} == 1 ] && echo ":${INFOPATH}"`"' >> etc/prefs.csh


# Set RPATH to find bundled libraries
echo 'PROJECT_RPATH += -rpath @loader_path/../../../env/lib' >> wmake/rules/darwin64Clang/rpath


# Disable floating point exception trapping when on Apple silicon
# (Prevents confusing output that says it's enabled, as it doesn't work yet)
# https://develop.openfoam.com/Development/openfoam/-/issues/2240
[ $(uname -m) != 'arm64' ] || [ $(bin/foamEtcFile -show-api) -ge 2312 ] || echo 'export FOAM_SIGFPE=false' >> etc/prefs.sh
[ $(uname -m) != 'arm64' ] || [ $(bin/foamEtcFile -show-api) -ge 2312 ] || echo 'setenv FOAM_SIGFPE false' >> etc/prefs.csh


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/1664
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || echo 'setenv FOAM_DYLD_LIBRARY_PATH "$DYLD_LIBRARY_PATH"' >> etc/cshrc


# Workaround for https://develop.openfoam.com/Community/integration-cfmesh/-/issues/8
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || sed -i '' 's|LIB_LIBS =|& $(LINK_OPENMP) |' modules/cfmesh/meshLibrary/Make/options


# Backport of https://develop.openfoam.com/Development/openfoam/-/issues/2555
[ $(bin/foamEtcFile -show-api) -ge 2212 ] || patch src/meshTools/triSurface/triSurfaceTools/geompack/geompack.C <<'EOF'
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


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/3066
[ $(bin/foamEtcFile -show-api) -ne 2312 ] || sed -i '' 's|max(len,|max(label(len),|' src/OpenFOAM/db/IOstreams/memory/memoryStreamBuffer.H


# Workaround for https://develop.openfoam.com/Development/openfoam/-/issues/2958
[ $(uname -m) != 'arm64' ] || sed -i '' 's|-ftrapping-math|-ftrapping-math -ffp-contract=off|' wmake/rules/darwin64Clang/c
[ $(uname -m) != 'arm64' ] || sed -i '' 's|-ftrapping-math|-ftrapping-math -ffp-contract=off|' wmake/rules/darwin64Clang/c++


# Backport of https://develop.openfoam.com/Development/openfoam/-/issues/3098
[ $(bin/foamEtcFile -show-api) -gt 2312 ] || sed -i '' 's|_foamAddLib  "$FOAM_USER_LIBBIN:$FOAM_SITE_LIBBIN"|_foamAddLib  "$FOAM_SITE_LIBBIN"\n_foamAddLib  "$FOAM_USER_LIBBIN"|' etc/config.sh/setup
[ $(bin/foamEtcFile -show-api) -gt 2312 ] || sed -i '' 's|_foamAddLib  "$FOAM_USER_LIBBIN:$FOAM_SITE_LIBBIN"|_foamAddLib  "$FOAM_SITE_LIBBIN"\n_foamAddLib  "$FOAM_USER_LIBBIN"|' etc/config.csh/setup
