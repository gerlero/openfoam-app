[<img src="icon.png" width="150">](#)

# **OpenFOAM.app**: OpenFOAM for macOS

| 🎉  [OpenFOAM v2206 is now available!](#-install) |
| ---- |

**Native OpenFOAM as a Mac app**, with binaries compiled from the [OpenFOAM source code](https://develop.openfoam.com/Development/openfoam/-/blob/master/doc/Build.md). Intel and Apple silicon variants.

[![CI](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/ci.yml) [![Release](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml/badge.svg)](https://github.com/gerlero/openfoam-app/actions/workflows/release.yml) [![GitHub all releases](https://img.shields.io/github/downloads/gerlero/openfoam-app/total)](https://github.com/gerlero/openfoam-app/releases)
[![homebrew cask](https://img.shields.io/badge/homebrew%20cask-gerlero%2Fopenfoam%2Fopenfoam2206-informational)](https://github.com/gerlero/homebrew-openfoam) [![homebrew cask](https://img.shields.io/badge/homebrew%20cask-gerlero%2Fopenfoam%2Fopenfoam2112-informational)](https://github.com/gerlero/homebrew-openfoam)

## 🖥 Prerequisites

* An Intel or Apple silicon Mac
* A recent version of macOS
    * Intel: macOS 11 or later (older macOS versions might work, but are not tested)
    * Apple silicon: macOS 12 (macOS 11 should also work, but is not tested)

## 📦 Install

Install in one of two ways:

### ➡️ Install with Homebrew

With [Homebrew](https://brew.sh) installed on your Mac, run any of the following commands in a terminal, depending on which version(s) of OpenFOAM you want:

* **OpenFOAM v2206**

    ```sh
    brew install --no-quarantine gerlero/openfoam/openfoam2206
    ```

* **OpenFOAM v2112**

    ```sh
    brew install --no-quarantine gerlero/openfoam/openfoam2112
    ```

The commands will automatically pick the appropriate variant for your hardware, and will also collect all necessary dependencies. The ``--no-quarantine`` option tells macOS Gatekeeper to allow running the apps despite the fact that they are not currently notarized by Apple (you can also override Gatekeeper manually on the first launch—see below). After the install command finishes, you should see a new **OpenFOAM** app installed on your Mac.

**👁 ParaView**: if you need [ParaView](https://www.paraview.org) for visualization, you can install it with Homebrew as well (recommended if you want to be able to launch Paraview with OpenFOAM's `paraFoam` command):

```sh
brew install paraview
```

**🗑 Uninstall**: to uninstall, run `brew uninstall openfoam2206` (replace the `openfoam2206` name accordingly). After that, you can run [`brew autoremove`](https://docs.brew.sh/Manpage#autoremove---dry-run) to also remove installed dependencies that are no longer required.

### ➡️ Manual download and install (standalone version)

You can download an appropriate release file from the [Releases page](https://github.com/gerlero/openfoam-app/releases). Note that these standalone variants are available on an experimental basis.

Choose the right variant for your computer:

* Intel-based Mac: pick a file that says `standalone-x86_64`
* Mac with Apple silicon: pick a file that says `standalone-arm64`

The number after `openfoam` in the filenames refers to the version of OpenFOAM they contain.

Download the chosen release file (and extract it, if it doesn't happen automatically) to get the app. Optionally, you can move the app into your Applications folder for convenience.

**👁 ParaView**: download it from the [official site](https://www.paraview.org) if you need it.

**🏗 Development tools**: the standalone apps do not bundle or require a compiler or any other development tools. If you attempt to do something with OpenFOAM that would require a compiler (and you do not have Xcode or the Xcode Command Line Tools already installed), you should be prompted by the system to install the necessary tools from Apple.

**🗑 Uninstall**: the standalone apps are self-contained. To uninstall, just drag them into your Trash.

## 🧑‍💻 Use

Just launch the **OpenFOAM** app to start an OpenFOAM session in a new Terminal window.

<img src="screenshot.png" width="650">

That's it! When using OpenFOAM, a read-only volume will be loaded and visible in the Finder. The OpenFOAM installation lives inside this virtual disk. When you're not actively using OpenFOAM, it is safe to "eject" the volume from the Finder sidebar.

**🛡 Gatekeeper**: given that the app is not notarized by Apple, you may see a macOS Gatekeeper dialog that prevents you from initially launching the downloaded app. The simplest way to override this warning for this app only is to right-click on the app in a Finder window and select Open from the context menu. You only need to do this for the first launch.

**⌨️ From the terminal**: when installed with Homebrew, the app includes a terminal command that starts an OpenFOAM session. For example, **OpenFOAM-v2206.app** provides the command:

```sh
openfoam2206
```

If you did not install with Homebrew, you can get the same by invoking the following command (replace the path and app name as needed):

```sh
/Applications/OpenFOAM-v2206.app/Contents/MacOS/openfoam
```

**🔠 A note on case sensitivity:** while in many situations OpenFOAM will work okay regardless (this mostly depends on the specific field names used by the different solvers), it is recommended that users format a separate drive or partition with a case-sensitive filesystem, or create a case-sensitive disk image (both of which can be accomplished with the built-in macOS Disk Utility) to store OpenFOAM-related user files (e.g. OpenFOAM cases).

## ⚙️ Background

Starting with OpenFOAM v2112, [it is possible to compile OpenFOAM for macOS without code patches](https://develop.openfoam.com/Development/openfoam/-/wikis/building#darwin-mac-os). However, the build process is not completely straightforward–mainly because OpenFOAM itself requires a case-sensitive filesystem, which is standard on Linux but not on macOS. Making a working **OpenFOAM.app** means creating a case-sensitive disk image for OpenFOAM and compiling it there, with third-party dependencies obtained with Homebrew. The disk image is then shrunk, write-protected, and packaged as a Mac application for easier distribution and use.

## 🔨 Building from source

If you need to, building an **OpenFOAM.app** entirely from source is easy as cloning this repo and running `make`, i.e.:

```sh
git clone https://github.com/gerlero/openfoam-app.git
cd openfoam-app
make
```

See the available configuration variables and alternative targets for `make` in the [`Makefile`](Makefile). Note that the compilation of OpenFOAM from source may take a while.

## 📄 Legal notices

### Disclaimer

This offering is not approved or endorsed by OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com, and owner of the OPENFOAM®  and OpenCFD® trade marks.

### Trademark acknowledgement

OPENFOAM® is a registered trade mark of OpenCFD Limited, producer and distributor of the OpenFOAM software via www.openfoam.com.
