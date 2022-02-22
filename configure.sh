#!/bin/bash -e

echo 'export WM_COMPILER=Clang' >> etc/prefs.sh
echo 'export CPATH=$(brew --prefix libomp)/include' >> etc/prefs.sh
echo 'export LIBRARY_PATH=$(brew --prefix libomp)/lib' >> etc/prefs.sh
bin/tools/foamConfigurePaths \
    -adios-path '$(brew --prefix adios2)' \
    -boost-path '$(brew --prefix boost)' \
    -cmake-path '$(brew --prefix cmake)' \
    -fftw-path '$(brew --prefix fftw)' \
    -kahip-path '$(brew --prefix kahip)' \
    -metis-path '$(brew --prefix metis)' \
    -scotch-path '$(brew --prefix scotch-no-pthread)'
echo 'export FOAM_DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH"' >> etc/bashrc
