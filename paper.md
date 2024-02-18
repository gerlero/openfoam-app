---
title: 'OpenFOAM.app: Native OpenFOAM for macOS'
tags:
  - OpenFOAM
  - macOS
  - Arm
  - Apple silicon
  - Intel
authors:
  - name: Gabriel S. Gerlero
    orcid: 0000-0002-5138-0328
    affiliation: "1, 2" # (Multiple affiliations must be quoted)
affiliations:
 - name: Centro de Investigación en Métodos Computacionales (CIMEC, UNL-CONICET), Argentina
   index: 1
 - name: Universidad Nacional de Rafaela (UNRaf), Argentina
   index: 2
date: 18 February 2024
bibliography: paper.bib
---

# Summary

**OpenFOAM.app** provides pre-built binaries of the OpenFOAM CFD software package for macOS. It offers a native OpenFOAM experience for Mac users, by making pre-built binaries available in the form of a standard macOS application. Both Intel and Apple silicon (i.e., Arm-based M-series) CPUs used by Macs are supported. The project has been successful in providing a seamless OpenFOAM experience for Mac users, and has been well-received by the community.

# Statement of need

OpenFOAM [@openfoam] is a popular open-source CFD software package that has seen wide adoption in academia and industry. However, its installation and use on macOS has been challenging, as, while OpenFOAM can be compiled from source on that operating system, it requires special considerations—including the procurement and configuration of dependencies, the use of a case-sensitive filesystem, and allowing for the relatively long compile times—and no official pre-compiled binaries are available for it. Alternatively, macOS users can run Linux-based OpenFOAM using Docker Desktop or a regular virtual machine, but these solutions involve virtualization, which can be cumbersome and adds unnecessary overhead to the execution.

Over the course of its two-year existence since its first launch in February 2022, the **OpenFOAM.app** project [@openfoam-app] has seen over 5000 total downloads, received over 100 stars on GitHub, had more than 30 issues opened, and offered five different major versions of OpenFOAM.

# Details

**OpenFOAM.app** offers OpenFOAM as distributed by OpenCFD Ltd. (www.openfoam.com). As of this paper, the last two versions of OpenFOAM (currently v2312 and v2306) are offered in the latest release. Older OpenFOAM versions are still available via previous releases of the project, but are not updated or supported.

By default, dependencies are obtained using a custom-prefix Homebrew installation whose contents are then bundled with the app (although users compiling from source can also choose other options for handling dependencies). The project fetches the OpenFOAM source code, applies the necessary configuration and patches (the majority of which has been upstreamed), and performs the compilation. Case-sensitivity issues on macOS are eliminated by using a case-sensitive filesystem in a disk image.

The project uses continuous integration to automatically build and test the apps. Besides the current OpenFOAM versions, the upstream development branches are also regularly tested in order to anticipate any issues; this has allowed the project to offer new OpenFOAM versions within days of their official release. **OpenFOAM.app** has also been tested with various third-party extensions to OpenFOAM [@electromicrotransport; @porousmultiphasefoam; @porousmicrotransport].

With GitHub's new offering of free Apple silicon-based macOS runners for open-source projects, all releases of **OpenFOAM.app** are now built online in fully reproducible workflows. For users who want to build the app themselves, the project offers a GNU Make–based build system that can compile the app with a single command, while also allowing for some customizations.

# Acknowledgements

I would like to acknowledge the fruitful interactions with members the OpenFOAM Mac community, including Guanyang Xue, Alexey Matveichev and Andrew Janke; as well as everyone who has opened issues in the **OpenFOAM.app** repository. I also want to acknowledge the upstream OpenFOAM developer team, and Mark Olesen in particular, for their fast response to issues raised in their repository that affect macOS.

# References
