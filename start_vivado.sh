#!/bin/bash
cd /home/user
export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libselinux.so.1 /lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0"
export JAVA_TOOL_OPTIONS="-Dsun.java2d.xrender=false"
export JAVA_OPTS="-Dsun.java2d.xrender=false"
export DISPLAY="host.docker.internal:0"
/home/user/Xilinx/Vivado/*/bin/hw_server -e "set auto-open-servers     xilinx-xvc:host.docker.internal:2542" &
/home/user/Xilinx/Vivado/*/settings64.sh
/home/user/Xilinx/Vivado/*/bin/vivado
