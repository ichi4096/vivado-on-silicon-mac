#!/bin/bash

# echo with color
function f_echo {
	echo -e "\e[1m\e[33m$1\e[0m"
}

# Check for previous installation
if [ -d "/home/user/Xilinx/" ]
	then
		f_echo "Previous installation found. To continue, please remove the Xilinx directory."
		exit 1
fi

if [ -d "/home/user/installer/" ]
	then
		f_echo "Installer was previously extracted. Removing the extracted directory."
		rm -rf /home/user/installer
fi

# Check if the Web Installer is present
numberOfInstallers=0

for f in /home/user/Xilinx*.bin; do
	((numberOfInstallers++))
done

if [[ $numberOfInstallers -eq 1 ]]
	then
		f_echo "Found Installer"
	else
		f_echo "Installer file was not found or there are multiple installer files!"
		f_echo "Make sure to download the Linux Self Extracting Web Installer and place it in this directory."
		exit 1
fi

cd /home/user

# Extract installer
f_echo "Extracting installer"
chmod +x /home/user/Xilinx*.bin
/home/user/Xilinx*.bin --target /home/user/installer --noexec

# Get AuthToken by repeating the following command until it succeeds
f_echo "Log into your Xilinx account to download the necessary files."
while ! /home/user/installer/xsetup -b AuthTokenGen
do
	f_echo "Your account information seems to be wrong. Please try logging in again."
	sleep 1
done

# Run installer
f_echo "You successfully logged into your account. The installation will begin now."
f_echo "If a window pops up, simply close it to finish the installation."
/home/user/installer/xsetup -c /home/user/install_config.txt -b Install -a XilinxEULA,3rdPartyEULA
