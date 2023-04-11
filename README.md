# vivado-on-silicon-mac
This is a tool for installing [Xilinx Vivado™](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html) on Arm®-based Apple silicon Macs (Tested on M2 MacBook Air with 2022 Edition of Vivado). It is in no way associated with Xilinx.

## How to install
Expect the installation process to last about one to two hours.
### Preparations
You first need to install [XQuartz](https://www.xquartz.org/) and [Docker®](https://www.docker.com/products/docker-desktop/) (make sure to choose "Apple Chip" instead of "Intel Chip"). Then you need to
* open Docker, 
* go to settings,
* check "Use Virtualization Framework",
* uncheck "Open Docker Dashboard at startup",
* go to "Features in Development" and
* check "Use Rosetta for x86/amd64 emulation on Apple Silicon".

These steps cannot be skipped.

Additionally make sure to download the *Linux Self Extracting Web Installer* from the [Xilinx Website](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html).
### Installation
1. Download this [tool](https://github.com/ichi4096/vivado-on-silicon-mac/archive/refs/heads/main.zip).
2. Extract the ZIP by double-clicking it.
Open a terminal. Then copy & paste:
```
cd Downloads/vivado-on-silicon-mac-main
caffeinate -dim ./install.sh
```
3. Follow the instructions (in yellow) from the terminal. If a window pops up, close it.
4. Drag and drop the "Launch_Vivado" App into the Applications folder.
5. Open the Launch_Vivado app. It will fail to launch, which is why you need to open Settings and trust the app in the "Privacy & Security" section.
6. Open it again and go to Settings again and trust xvcd.

### Usage
To start Vivado, simply open the Launch_Vivado app. It might take a while for the Docker container to start in the background and for Vivado to launch. Additionally, a terminal window will launch. It runs the XVC server as described below and is necessary for programming the FPGAs and closes when Vivado is closed.

If you want to exchange files with the Vivado instance, you need to store them inside the "vivado-on-silicon-mac-main" folder. Inside Vivado, the files will be accessible via the "/home/user" folder.

Clipboard copy & paste works with Ctrl-C and Ctrl-V.

## How it works
### Docker & XQuartz
This script creates an x64 Docker container running Linux® that is accelerated by [Rosetta 2](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment) via the Apple Virtualization framework. The container has all the necessary libraries preinstalled for running Vivado. It is installed automatically given an installer file that the user must provide. GUI functionality is provided by XQuartz.

### USB connection
A drawback of the Apple Virtualization framework is that there is no implementation for USB forwarding as of when I'm writing this. Therefore, these scripts set up the Xilinx Virtual Cable protocol. Intended to let a computer connect to an FPGA plugged into a remote computer, it allows for the host system to run an XVC server (in this case a software called [xvcd](https://github.com/tmbinc/xvcd)), to which the docker container can connect.

xvcd is contained in this repository, but with slight changes to make it compile on modern day macOS (compilation requires libusb and libftdi installed via homebrew, though there is a compiled version included). It runs continuously while the docker container is running.

This version of xvcd only supports the FT2232C chip. Other chips could be supported if xvcd were modified accordingly.

### Environment variables
A few environment variables are set such that

1. the GUI is displayed correctly.
2. Vivado doesn't crash (maybe due to emulation?)

## License, copyright and trademark information
The repository's contents are licensed under the Creative Commons Zero v1.0 Universal license.

Note that the scripts are configured such that you automatically agree to Xilinx' and 3rd party EULAs (which can be obtained by extracting the installer yourself) by running them. You also automatically agree to [Apple's software licence agreement](https://www.apple.com/legal/sla/) for Rosetta 2.

This repository contains the modified source code of [xvcd](https://github.com/tmbinc/xvcd) as well as a compiled version which is statically linked against [libusb](https://libusb.info/) and [libftdi](https://www.intra2net.com/en/developer/libftdi/). This is in accordance to the [LGPL Version 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html), under which both of those libraries are licensed.

Vivado and Xilinx are trademarks of Xilinx, Inc.

Arm is a registered trademark of Arm Limited (or its subsidiaries) in the US and/or elsewhere.

Apple, Mac, MacBook, MacBook Air, macOS and Rosetta are trademarks of Apple Inc., registered in the U.S. and other countries and regions.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc. in the United States and/or other countries. Docker, Inc. and other parties may also have trademark rights in other terms used herein.

Intel and the Intel logo are trademarks of Intel Corporation or its subsidiaries.

Linux® is the registered trademark of Linus Torvalds in the U.S. and other countries.

Oracle, Java, MySQL, and NetSuite are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of their respective owners.

X Window System is a trademark of the Massachusetts Institute of Technology.
