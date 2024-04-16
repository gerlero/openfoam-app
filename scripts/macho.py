"""
Utility functions for working with macOS Mach-O files.
"""
import subprocess
import platform
import sys

if sys.version_info < (3, 12):
    import os

from pathlib import Path

def _codesign(file):
    subprocess.run(["codesign", "--sign", "-", "--force", "--preserve-metadata=entitlements,requirements,flags,runtime", file], check=True)

def change_dylib_id(lib, id):
    subprocess.run(["install_name_tool", "-id", id, lib], check=True)
    if platform.machine() == "arm64":
        _codesign(lib)

def get_install_names(file):
    otool_stdout = subprocess.run(["otool", "-L", file], stdout=subprocess.PIPE, check=True).stdout.decode()
    install_names = [Path(line.rpartition(" (compatibility version ")[0].strip()) for line in otool_stdout.splitlines()[1:]]
    return install_names

def change_install_name(file, old_install_name, new_install_name, *, relative=False):
    file = Path(file)
    if relative:
        new_install_name = Path(new_install_name)
        assert new_install_name.is_absolute()
        if sys.version_info >= (3, 12):
            new_install_name = new_install_name.relative_to(file.parent, walk_up=True)
        else: # No walk_up parameter in Python < 3.12
            new_install_name = Path(os.path.relpath(new_install_name, start=file.parent))
        new_install_name = "@loader_path" / new_install_name
    subprocess.run(["install_name_tool", "-change", old_install_name, new_install_name, file], check=True)
    if platform.machine() == "arm64":
        _codesign(file)
