[<img src="icon.png" width="150">](#)

# **OpenFOAM.app**: OpenFOAM for macOS

| 🎉  [OpenFOAM v2206 is now available!](#%EF%B8%8F-install) |
| ---- |

**Native OpenFOAM as a Mac app**, with binaries compiled from the [OpenFOAM source code](https://develop.openfoam.com/Development/openfoam/-/blob/master/doc/Build.md). Intel and Apple silicon variants.

[![CI](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml) [![Release](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml) [![homebrew cask](https://img.shields.io/badge/homebrew%20cask-gerlero%2Fopenfoam%2Fopenfoam2206-informational)](https://github.com/gerlero/homebrew-openfoam) [![homebrew cask](https://img.shields.io/badge/homebrew%20cask-gerlero%2Fopenfoam%2Fopenfoam2112-informational)](https://github.com/gerlero/homebrew-openfoam) ![GitHub all releases](https://img.shields.io/github/downloads/gerlero/openfoam-app/total)

## 📦 Prerequisites

* An Intel or Apple silicon Mac
* A recent version of macOS
    * Intel: macOS 10.15 or later (older macOS versions are untested)
    * Apple silicon: macOS 12 (macOS 11 should also work, but is not tested)
* The [Homebrew](https://brew.sh) package manager (will be used to manage OpenFOAM dependencies and to install/update the app itself)

## ⬇️ Install

Run any of the following commands in a terminal, depending on which version(s) of OpenFOAM you want to install:

* **OpenFOAM v2206**

    ```sh
    brew install --no-quarantine gerlero/openfoam/openfoam2206
    ```

* **OpenFOAM v2112**

    ```sh
    brew install --no-quarantine gerlero/openfoam/openfoam2112
    ```

The commands will automatically pick the appropriate variant for your hardware, and will also collect all necessary dependencies. The ``--no-quarantine`` option tells macOS Gatekeeper to allow running the apps despite the fact that they are not currently signed (you can also override Gatekeeper manually on the first launch via Finder right-click + Open). After the install command finishes, you should see a new **OpenFOAM** app installed on your Mac.

**👁 ParaView**: if you need [ParaView](https://www.paraview.org) for visualization, you can install it with Homebrew as well (recommended if you want to be able to launch Paraview with OpenFOAM's `paraFoam` command):

```sh
brew install paraview
```

**🗑 Uninstall**: to uninstall, run `brew uninstall openfoam2206` (replace the `openfoam2206` name accordingly). After that, you can run [`brew autoremove`](https://docs.brew.sh/Manpage#autoremove---dry-run) to also remove installed dependencies that are no longer required.

## 🧑‍💻 Use

Just launch the **OpenFOAM** app to start an OpenFOAM session in a new Terminal window.

<img src="screenshot.png" width="650">

Useful terminal commands to activate the OpenFOAM environments are also available after installing with Homebrew:

* **OpenFOAM v2206**

    ```sh
    openfoam2206
    ```

* **OpenFOAM v2112**

    ```sh
    openfoam2112
    ```

That's it! When using OpenFOAM, a read-only volume will be loaded and visible in the Finder. The OpenFOAM installation lives inside this virtual disk. When you're not actively using OpenFOAM, it is safe to "eject" the volume from the Finder sidebar.

**🔠 A note on case sensitivity:** while in many situations OpenFOAM will work okay regardless (this mostly depends on the specific field names used by the different solvers), it is recommended that users format a separate drive or partition with a case-sensitive filesystem, or create a case-sensitive disk image (both of which can be accomplished with the built-in macOS Disk Utility) to store OpenFOAM-related user files (e.g. OpenFOAM cases).

## ⚙️ Background

Starting from OpenFOAM v2112, [it is possible to compile OpenFOAM for macOS without code patches](https://develop.openfoam.com/Development/openfoam/-/wikis/building#darwin-mac-os). However, the build process is not completely straightforward–mainly because OpenFOAM itself requires a case-sensitive filesystem, which is standard on Linux but not on macOS. Making a working **OpenFOAM.app** means creating a case-sensitive disk image for OpenFOAM and compiling it there, with third-party dependencies obtained with Homebrew. The disk image is then shrunk, write-protected, and packaged as a Mac application for easier distribution and use.

## 🔨 Building from source

If you need to, building an **OpenFOAM.app** entirely from source is easy as cloning this repo and running `make`, i.e.:

```sh
git clone https://github.com/gerlero/openfoam-app.git
cd openfoam-app
make
```

[Homebrew](https://brew.sh) is required. See the available configuration variables and alternative targets for `make` in the [`Makefile`](Makefile). Note that the compilation of OpenFOAM from source may take a while.

## 📄 Legal notices

### Disclaimer

This offering is not approved or endorsed by OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com, and owner of the OPENFOAM®  and OpenCFD® trade marks.

### Trademark acknowledgement

OPENFOAM® is a registered trade mark of OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com.
