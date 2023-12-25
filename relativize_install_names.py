#!/usr/bin/env python3

import os
import subprocess

from pathlib import Path

def relativize_install_names(file, lib_dirs):
    otool_stdout = subprocess.run(["otool", "-L", file], stdout=subprocess.PIPE, check=True).stdout.decode()
    install_names = [Path(line.split(" (compatibility version ")[0].strip()) for line in otool_stdout.splitlines()[1:]]
    for install_name in install_names:
        if install_name.is_absolute():
            for lib_dir,new_lib_dir in lib_dirs.items():
                lib_dir = lib_dir.absolute()
                if install_name.is_relative_to(lib_dir):
                    new_install_name = new_lib_dir.absolute() / install_name.relative_to(lib_dir)
                    relative_install_name = Path("@loader_path") / os.path.relpath(new_install_name, start=file.parent)
                    subprocess.run(["install_name_tool", "-change", install_name, relative_install_name, file])
                    break

# Replace references to dependencies
lib_dirs = {Path("usr").resolve(): Path("usr")} # In case "usr" is a symlink

# Replace references to OpenFOAM libraries if necessary
OPENFOAM_VERSION = int(subprocess.run(["bin/foamEtcFile", "-show-api"], stdout=subprocess.PIPE, check=True).stdout)
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
