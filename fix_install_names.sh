#!/bin/bash -e

# -----------------------------------------------------------------------------
# Fix install names of libraries and binaries so that they load the MPI-enabled
# variants of libraries by default (instead of the "dummy" ones that don't work
# in parallel).
#
# This makes the installation less prone to runtime errors caused by the dummy
# libraries being loaded as a consequence of the System Integrity Protection
# (SIP) feature of macOS, which can clear the $DYLD_LIBRARY_PATH set by
# OpenFOAM.
#
# Discussed at https://develop.openfoam.com/Development/openfoam/-/issues/2801
# -----------------------------------------------------------------------------

source etc/bashrc

fix_install_names() {
    for dummylib in $FOAM_LIBBIN/dummy/lib*; do
        install_name_tool \
            -change \
                "$dummylib" \
                "$FOAM_LIBBIN/$FOAM_MPI/$(basename "$dummylib")" \
            "$1"
    done
}

for lib in $FOAM_LIBBIN/lib*; do
    fix_install_names "$lib"
done

for bin in $FOAM_APPBIN/*; do
    fix_install_names "$bin"
done
