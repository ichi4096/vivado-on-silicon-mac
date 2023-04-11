#!/bin/bash
cd /home/user
/home/user/Xilinx/Vivado/*/bin/hw_server -e "set auto-open-servers     xilinx-xvc:host.docker.internal:2542" &
/home/user/Xilinx/Vivado/*/bin/vivado