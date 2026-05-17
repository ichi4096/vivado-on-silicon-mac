#!/bin/bash

# This script is run whenever the desktop environment has started.
# (with normal user privileges).

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux

# Resolve the libgdk path at runtime — it moved from /lib to /usr/lib in
# Ubuntu 24.04 (libgtk2.0-0t64 package from the 64-bit time_t transition).
GDK_LIB=$(find /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu \
               -name "libgdk-x11-2.0.so.0" 2>/dev/null | head -1)

export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libz.so.1${GDK_LIB:+ $GDK_LIB}"

# if Vivado is installed
if [ -d "/home/user/Xilinx" ]
then
	# Make Vivado connect to the xvcd server running on macOS
	/home/user/Xilinx/Vivado/*/bin/hw_server -e "set auto-open-servers     xilinx-xvc:host.docker.internal:2542" &
	/home/user/Xilinx/Vivado/*/settings64.sh
	/home/user/Xilinx/Vivado/*/bin/vivado
else
	f_echo "The installation is incomplete."
	wait_for_user_input
fi