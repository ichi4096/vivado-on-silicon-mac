#!/bin/zsh

# Attempts to configure Docker by enabling Rosetta and increasing swap

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

function cannot_setup_docker {
    f_echo "Unfortunately, the script could not configure Docker automatically."
    f_echo "This means that you have to change the settings in the Docker Dashboard yourself:"
    f_echo "Enable the Virtualization Framework, Rosetta emulation and set Swap to at least 2 GiB."
    f_echo "Restart Docker after applying the changes and then continue with the installation."
    wait_for_user_input
    exit 1
}

docker_settings_file="$HOME/Library/Group Containers/group.com.docker/settings.json"

stop_docker

# check if the settings file is in the expected place
if ! [ -f "$docker_settings_file" ]
then
    cannot_setup_docker
fi

# check if the attributes to be modified exist
if grep "\"useVirtualizationFramework\":" "$docker_settings_file" > /dev/null \
&& grep "\"useVirtualizationFrameworkRosetta\":" "$docker_settings_file" > /dev/null \
&& grep "\"swapMiB\":" "$docker_settings_file" > /dev/null
then
    :
else
    cannot_setup_docker
fi

# enable Virtualization Framework
sed -i "" "s/\"useVirtualizationFramework\": false/\"useVirtualizationFramework\": true/" "$docker_settings_file"

# enable Rosetta emulation
sed -i "" "s/\"useVirtualizationFrameworkRosetta\": false/\"useVirtualizationFrameworkRosetta\": true/" "$docker_settings_file"

# set swap to minimum 4 GiB
minSwap=4096
swapMiB=$(cat "$docker_settings_file" | grep "\"swapMiB\"" | sed "s/[^0-9]//g")
if [ "$swapMiB" -lt "$minSwap" ]
then
    sed -i "" "s/\"swapMiB\": [0-9]*/\"swapMiB\": $minSwap/" "$docker_settings_file"
fi

f_echo "Configured Docker successfully"