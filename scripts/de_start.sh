#!/bin/bash

# This script is run whenever the desktop environment has started.
# (with normal user privileges).

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux

export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0"

vivado_dir=$(find_vivado_dir)

# if Vivado is installed
if [ -n "$vivado_dir" ]
then
	# Make Vivado connect to the xvcd server running on macOS
	source "$vivado_dir/settings64.sh"
	"$vivado_dir/bin/hw_server" -e "set auto-open-servers     xilinx-xvc:host.docker.internal:2542" &
	"$vivado_dir/bin/vivado"
else
	f_echo "The installation is incomplete."
	wait_for_user_input
fi
