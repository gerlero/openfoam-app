[<img src="icon.png" width="150">](#)

# OpenFOAM.app: OpenFOAM for macOS

**Native OpenFOAM v2112 as a Mac app**, with binaries compiled from the [OpenFOAM source code](https://develop.openfoam.com/Development/openfoam/-/blob/master/doc/Build.md). Intel and Apple silicon variants.

[![CI](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml) [![Release](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml) [![homebrew cask](https://img.shields.io/badge/homebrew%20cask-gerlero%2Fopenfoam%2Fopenfoam2112-informational)](https://github.com/gerlero/homebrew-openfoam) ![GitHub all releases](https://img.shields.io/github/downloads/gerlero/openfoam-app/total)

## ⬇️ Install

The preferred method of installation is to use [Homebrew](https://brew.sh). With Homebrew installed on your Mac, run the following command in the Terminal:

```sh
brew install --no-quarantine gerlero/openfoam/openfoam2112
```

The command will automatically pick the appropriate variant for your hardware, and will also collect all necessary dependencies. The ``--no-quarantine`` option tells macOS Gatekeeper to allow running this app despite the fact that it is not currently signed (you can also override Gatekeeper manually on the first launch via Finder right-click + Open). After the command finishes, you should see a new **OpenFOAM-v2112** app installed on your Mac.

**📈 ParaView**: if you need ParaView for visualization, you can install it with Homebrew as well:

```sh
brew install paraview
```

You should install ParaView this way if you want to be able to launch it using OpenFOAM's `paraFoam` command.

## 🧑‍💻 Use

Just launch the **OpenFOAM-v2112** app to activate an OpenFOAM session in a new Terminal window.

<img src="screenshot.png" width="650">

A useful terminal command to activate the OpenFOAM environment is also available after installing with Homebrew:

```sh
openfoam2112
```

That's it! When using OpenFOAM, an `OpenFOAM-v2112` read-only volume will be loaded and visible in the Finder. The OpenFOAM installation lives inside this virtual disk. When you're not actively using OpenFOAM, you can safely "eject" the volume from the Finder sidebar.

**🔠 A note on case sensitivity:** while in many situations OpenFOAM will work okay regardless (this mostly depends on the specific field names used by the different solvers), it is recommended that users format a separate drive or partition with a case-sensitive filesystem, or create a case-sensitive disk image (both of which can be accomplished with the built-in macOS Disk Utility) to store OpenFOAM-related user files (e.g. OpenFOAM cases).

## ⚙️ How it works

As of OpenFOAM v2112, [it is possible to compile OpenFOAM for macOS without code patches](https://develop.openfoam.com/Development/openfoam/-/wikis/building#darwin-mac-os). However, the build process is not completely straightforward–mainly because OpenFOAM itself requires a case-sensitive filesystem, which is standard on Linux but not on macOS. Building a working **OpenFOAM-v2112.app** means creating a case-sensitive disk image for OpenFOAM and compiling it there, with third-party dependencies obtained with Homebrew. The disk image is then shrunk, write-protected, and packaged inside the app for easier distribution and use.

## 🔨 Build

If you need to, building the **OpenFOAM-v2112** application yourself is easy as cloning this repo and running `make`:

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
