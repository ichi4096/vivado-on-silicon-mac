#!/bin/zsh

# Initial setup on host (macOS) side

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
# Make sure that the script is run in macOS and not the Docker container
validate_macos

# Check if Rosetta is installed
if /usr/bin/pgrep -q oahd || /usr/bin/pgrep -q oahd-bin
then
  f_echo "Rosetta is installed! If there's illegal instruction compile error, try reinstall!"
else
  f_echo "Rosetta is not installed!"
  # Check the consent of the user
  f_echo "Do you want to install Rosetta?"
  f_echo "1. Yes"
  f_echo "2. No"
  read rosetta_install
  case $rosetta_install in
    1)
      f_echo "Installing Rosetta..."
      if ! softwareupdate --install-rosetta
      then
        f_echo "Error installing Rosetta."
        exit 1
      fi
      f_echo "Rosetta was successfully installed."
      ;;
    2)
      f_echo "Rosetta is required to run the Docker container."
      f_echo "Please install Rosetta and run this script again."
      exit 1
      ;;
    *)
      f_echo "Invalid option."
      exit 1
      ;;
  esac
fi

# Make sure there are no previous installations in this folder
if [ -d "$script_dir/../Xilinx" ]
then
	f_echo "A previous installation was found. To reinstall, remove the Xilinx folder."
	exit 1
fi

# Make sure permissions are right
if [[ "$current_user" == "root" ]]
then
	f_echo "Do not execute this script as root."
	exit 1
fi

# Get Vivado installation file
f_echo "You need to put the Vivado installation file into this folder if you have not done so already."
installation_binary=""
while true
do
	installation_binary=""
	# Get the absolute path to the file
	f_echo "Then, drag and drop the Vivado installation binary into this terminal window and press Enter: "
	read installation_binary
	# check if it is accessible from the container
	parent_dir=$(dirname "$script_dir")
	if ! [[ $installation_binary == $parent_dir/* ]]
	then
		f_echo "You need to move the installation binary into the folder!"
		continue
	fi
	# check file hash
	file_hash=$(md5 -q "$installation_binary")
	set_vivado_version_from_hash "$file_hash"
	if [ "$?" -eq 0 ]
	then
		f_echo "Valid file provided. Detected version $vivado_version"
		break
	else
		f_echo "File corrupted or version not supported."
		continue
	fi
done

# write file path to "install_bin"
install_bin_path="${installation_binary#$parent_dir}"
install_bin_path="/home/user$install_bin_path"
echo -n "$install_bin_path" > "$script_dir/install_bin"

# Make the user own the whole folder
if ! chown -R $current_user "$script_dir/.."
then
	f_echo "Higher privileges are required to make the folder owned by the user."
	if ! sudo chown -R $current_user "$script_dir/.."
	then
		f_echo "Error setting $current_user as owner of this folder."
		exit 1
	fi
fi

# Make the scripts executable
if ! xattr -d com.apple.quarantine "$script_dir/xvcd/bin/xvcd"
then
	f_echo "You need to remove the quarantine attribute from $script_dir/xvcd/bin/xvcd manually."
	wait_for_user_input
fi

if ! chmod +x "$script_dir"/*.sh "$script_dir/xvcd/bin/xvcd" "$installation_binary"
then
	f_echo "Error making the scripts executable."
	exit 1
fi

# make sure that Docker is installed
start_docker

# Attempt to enable Rosetta and set swap to at least 2GiB in Docker
eval "$script_dir/configure_docker.sh"

# Generate the Docker image
if ! eval "$script_dir/gen_image.sh"
then
	exit 1
fi

# Set VNC resolution
f_echo "Set the resolution of the container. Keep in mind that high resolutions might make text and images appear small."
f_echo "You can change the resolution manually in the vnc_resolution file later."
f_echo "Press enter to leave the default (1920x1080) or type in your preference:"
read resolution
# if resolution has the right format
if [[ $resolution =~ "^[0-9]+x[0-9]+$" ]]
then
	f_echo "Setting $resolution as resolution"
	echo "$resolution" > "$script_dir/vnc_resolution"
else
	f_echo "Setting the default of $vnc_default_resolution"
	echo "$vnc_default_resolution" > "$script_dir/vnc_resolution"
fi
echo ""

# copy de_start.desktop autostart file
mkdir -p "$script_dir/../.config/autostart"
cp "$script_dir/de_start.desktop" "$script_dir/../.config/autostart/de_start.desktop"
mkdir "$script_dir/../Desktop"

# Start container
f_echo "Now, the container is started (only terminal, no GUI) and the actual installation process begins."
docker run --init -it --rm --name vivado_container --mount type=bind,source="$script_dir/..",target="/home/user" -p 127.0.0.1:5901:5901 --platform linux/amd64 x64-linux sudo -H -u user bash /home/user/scripts/install_vivado.sh
