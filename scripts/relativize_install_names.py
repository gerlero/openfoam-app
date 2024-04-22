#!/usr/bin/env python3
"""
Replace absolute references to dylibs in OpenFOAM binaries with relative references.
"""

import subprocess

from pathlib import Path

import macho

def relativize_install_names(file, lib_dirs):
    for install_name in macho.get_install_names(file):
        if install_name.is_absolute():
            for lib_dir,new_lib_dir in lib_dirs.items():
                lib_dir = lib_dir.absolute()
                if install_name.is_relative_to(lib_dir):
                    new_install_name = new_lib_dir.absolute() / install_name.relative_to(lib_dir)
                    macho.change_install_name(file, install_name, new_install_name, relative=True)
                    break

# Replace references to dependencies
lib_dirs = {Path("usr").resolve(): Path("usr")} # In case "usr" is a symlink

# Replace references to OpenFOAM libraries if necessary
OPENFOAM_VERSION = int(subprocess.run(["bin/foamEtcFile", "-show-api"], stdout=subprocess.PIPE, text=True, check=True).stdout)
if OPENFOAM_VERSION < 2312:
    # References are already relative in OpenFOAM >= 2312
    # See https://develop.openfoam.com/Development/openfoam/-/issues/2948
    LIB_DIR, = list(Path("platforms").glob("*/lib"))
    MPI_LIB_DIR, = list(Path("platforms").glob("*/lib/*mpi*"))
    DUMMY_LIB_DIR, = list(Path("platforms").glob("*/lib/dummy"))
    lib_dirs[DUMMY_LIB_DIR] = MPI_LIB_DIR # Replace references to dummy MPI libraries with the actual MPI libraries
    lib_dirs[LIB_DIR] = LIB_DIR


for lib in Path("platforms").glob("*/lib/**/*.dylib"):
    relativize_install_names(lib, lib_dirs)

for bin in Path("platforms").glob("*/bin/*"):
    relativize_install_names(bin, lib_dirs)
