#!/usr/bin/env python3
"""
Copy Homebrew dependencies installed with Homebrew Bundle.
"""
import subprocess
import shutil

from pathlib import Path

import macho

SRC_PREFIX = Path(subprocess.run(["brew", "--prefix"], stdout=subprocess.PIPE, text=True, check=True).stdout.strip())

def bundle_list():
    return subprocess.run(["brew", "bundle", "list"], stdout=subprocess.PIPE, text=True, check=True).stdout.splitlines()

def deps(*formulae, union=False):
    cmd = ["brew", "deps"]
    if union:
        cmd.append("--union")
    return subprocess.run([*cmd, *formulae], stdout=subprocess.PIPE, text=True, check=True).stdout.splitlines()

def copy_installed_formula(formula, dst_prefix, *, relative_install_names=False):
    dst_prefix = Path(dst_prefix)

    _, _, name = formula.rpartition("/")

    src_opt = SRC_PREFIX / "opt" / name
    dst_opt = dst_prefix / "opt" / name

    src_cellar = SRC_PREFIX / "Cellar" / name
    dst_cellar = dst_prefix /  "Cellar" / name

    shutil.copytree(src_cellar, dst_cellar)

    dst_opt.parent.mkdir(exist_ok=True)
    shutil.copy(src_opt, dst_opt, follow_symlinks=False)

    # Relocate binaries
    for file in dst_cellar.rglob("*"):
        if not file.is_file():
            continue
        if (file.suffix == ".dylib" or file.suffix == ".so"):
            macho.change_dylib_id(file, dst_opt.absolute() / Path(*file.relative_to(dst_cellar).parts[1:]))
        if (file.suffix == "" or file.suffix == ".dylib" or file.suffix == ".so"):
            for install_name in macho.get_install_names(file):
                if install_name.is_absolute() and install_name.is_relative_to(SRC_PREFIX):
                    if install_name.is_relative_to(SRC_PREFIX):
                        new_install_name = dst_prefix.absolute() / install_name.relative_to(SRC_PREFIX)
                        macho.change_install_name(file, install_name, new_install_name, relative=relative_install_names)


dst_prefix = Path("usr")
formulae = bundle_list()

for formula in formulae:
    print(f"Bundling {formula}")
    copy_installed_formula(formula, dst_prefix, relative_install_names=True)

for formula in deps(*formulae, union=True):
    if formula not in formulae:
        print(f"Bundling {formula} (indirect dependency)")
        copy_installed_formula(formula, dst_prefix, relative_install_names=True)
