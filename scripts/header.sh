# general functions and definitions used by the other scripts

# This script needs to be sourced into other scripts or
# be run explicitly with an interpreter since it has no shebang

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/hashes.sh"

# echo with color
function f_echo {
	echo -e "\e[1m\e[33m$1\e[0m"
}

# aborts the script if it isn't run on macOS
function validate_macos {
    if [[ $(uname) == *Darwin* ]]
    then
        :
    else
        f_echo "Make sure to run this script on macOS."
        exit 1
    fi
}

# aborts the script if it isn't run inside the Docker container
function validate_linux {
    if [[ $(uname) == *Linux* ]]
    then
        :
    else
        f_echo "Make sure to run this script on Linux."
        exit 1
    fi
}

function validate_internet {
    if ! ping -q -c1 google.com &>/dev/null
    then
        f_echo "Internet connection required."
        exit 1
    fi
}

function wait_for_user_input {
    f_echo "Press Enter to continue..."
    read
}

function start_docker {
    # check if Docker is installed
    if ! which docker &> /dev/null
    then
        f_echo "You need to install Docker Desktop first."
        exit 1
    fi

    # Launch Docker daemon
    f_echo "Launching Docker daemon..."
    sleep 2
    # Wait for Docker to start
    while ! docker ps &> /dev/null
    do
        open -a Docker
        sleep 5
    done
    sleep 2
}

function stop_docker {
    curl -s -X POST -H 'Content-Type: application/json' -d '{ "openContainerView": true }' -kiv --unix-socket "$HOME/Library/Containers/com.docker.docker/Data/backend.sock" http://localhost/engine/stop &> /dev/null
    osascript -e 'quit app "Docker Desktop"'
    sleep 2
}

vivado_version=""

function set_vivado_version_from_hash {
    if [[ -v web_hashes[$1] ]]
    then
        vivado_version=${web_hashes[$1]}
    elif [[ -v sfd_hashes[$1] ]]
    then
        vivado_version=${sfd_hashes[$1]}
    else
        f_echo "Invalid installer hash"
        exit 1
    fi
    return 0
}

# The actual resolution is stored in the file vnc_resolution
vnc_default_resolution="1920x1080"

current_user=$(whoami)
