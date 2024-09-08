#!/bin/bash

# This runs the Vivado installer in batch mode.

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_linux


install_bin_path=$(tr -d "\n\r\t " < "/home/user/scripts/install_bin")

file_hash=($(md5sum "$install_bin_path"))
set_vivado_version_from_hash "$file_hash"

# Extract installer
f_echo "Extracting installer"
eval "$install_bin_path --target /home/user/installer --noexec"

# Get AuthToken by repeating the following command until it succeeds
f_echo "Log into your Xilinx account to download the necessary files."
while ! /home/user/installer/xsetup -b AuthTokenGen
do
	f_echo "Your account information seems to be wrong. Please try logging in again."
	sleep 1
done

# Run installer
f_echo "You successfully logged into your account. The installation will begin now."
eula_args="XilinxEULA,3rdPartyEULA"

# Check if the version is 202110 to include WebTalk terms
if [ "$vivado_version" = "202110" ]; then
    eula_args="${eula_args},WebTalkTerms"
    f_echo "Note: The 2021.1 version enables WebTalk data collection and agrees automatically to the corresponding terms."
    f_echo "For more information, see: https://docs.amd.com/r/2021.1-English/ug973-vivado-release-notes-install-license/WebTalk-Participation"
    wait_for_user_input
fi

if /home/user/installer/xsetup -c "/home/user/scripts/install_configs/${vivado_version}.txt" -b Install -a "${eula_args}"
then
    f_echo "Vivado was successfully installed."
    f_echo "Run start_container.sh to launch it."
else
    f_echo "An error occurred during installation. Please run cleanup.sh and try again."
    exit 1
fi