# vivado-on-arm-mac
This is a collection of scripts to install Xilinx Vivado on ARM-based Macs. (Tested on M2 MacBook Air with 2022 Edition of Vivado)

## How to install

## How does it work
### Docker & XQuartz
This script creates an x64 Docker container that is accelerated by Rosetta 2 via the Apple Virtualization framework. The container has all the necessary libraries preinstalled for running Vivado. It is installed automatically given an installer file that the user must provide. GUI functionality is provided by XQuartz.

### USB connection
A drawback of the Apple Virtualization framework is that there is no implementation for USB forwarding as of when I'm writing this. Therefore, these scripts set up the Xilinx Virtual Cable protocol. Intended to let a computer connect to an FPGA plugged into a remote computer, it allows for the host system to run a XVC server (in this case a software called [xvcd](https://github.com/tmbinc/xvcd)), to which the docker container can connect.

xvcd is contained in this repository, but with slight changes to make it compile on modern day macOS (compilation requires libusb and libftdi installed via homebrew, though there is a compiled version included). It runs continuously while the docker container is running.

### Environment variables
A few environment variables are set such that

1. the GUI is displayed correctly.
2. Vivado doesn't crash (maybe due to emulation?)

## License information
The repository's contents are licensed under the Creative Commons Zero v1.0 Universal license.
Note that the scripts are configured such that you automatically agree to Xilinx' and 3rd party EULAs (which can be obtained by extracting the installer yourself) by running them.
You also automatically agree to [Apple's software licence agreement](https://www.apple.com/legal/sla/) for Rosetta 2.
This repository contains the modified source code of [xvcd](https://github.com/tmbinc/xvcd) as well as a compiled version which is statically linked against libusb and libftdi. This is in accordance to the [LGPL Version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html), under which both of those libraries are licensed.
