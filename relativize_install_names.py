#!/usr/bin/env python3

import os
import subprocess
import itertools

from pathlib import Path

OPENFOAM_VERSION = int(subprocess.run(["bin/foamEtcFile", "-show-api"], stdout=subprocess.PIPE, check=True).stdout)

libs = {}

# Find names of OpenFOAM libraries
if OPENFOAM_VERSION < 2312: # References are already relative in OpenFOAM >= 2312
                            # See https://develop.openfoam.com/Development/openfoam/-/issues/2948
    MPI_LIB_PATH = list(Path("platforms").glob("*/lib/*mpi*"))[0]
    DUMMY_LIB_PTH = list(Path("platforms").glob("*/lib/dummy"))[0]

    for openfoam_lib in Path("platforms").glob("*/lib/**/*.dylib"):
        # Replace references to dummy MPI libraries with the actual MPI libraries
        if openfoam_lib.parent == DUMMY_LIB_PTH:
            libs[openfoam_lib] = MPI_LIB_PATH / openfoam_lib.name
        else:
            libs[openfoam_lib] = openfoam_lib

# Find names of dependency libraries
DEPS_PATH = Path("usr")
DEPS_PATH_RESOLVED = DEPS_PATH.resolve() # In case "usr" is a symlink
for dep_path in (DEPS_PATH_RESOLVED / "opt").iterdir():
    dep_libs = itertools.chain(dep_path.rglob("*.so"), dep_path.rglob("*.dylib"))
    for dep_lib in dep_libs:
        libs[dep_lib] = DEPS_PATH / dep_lib.relative_to(DEPS_PATH_RESOLVED)


def relativize_install_names(file):
    otool_stdout = subprocess.run(["otool", "-L", file], stdout=subprocess.PIPE, check=True).stdout.decode()
    for old_path,new_path in libs.items():
        if str(old_path.absolute()) in otool_stdout:
            new_relative_path = os.path.relpath(new_path, start=file.parent)
            subprocess.run(["install_name_tool",
                            "-change",
                                old_path.absolute(),
                                f"@loader_path/{new_relative_path}",
                            file])


for lib in Path("platforms").glob("*/lib/**/*.dylib"):
    relativize_install_names(lib)

for bin in Path("platforms").glob("*/bin/*"):
    relativize_install_names(bin)
