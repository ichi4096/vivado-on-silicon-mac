#!/bin/zsh

# Generate the Docker image

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

start_docker

# Build the Docker image according to the Dockerfile
f_echo "Building Docker image..."
if ! docker build --platform linux/amd64 -t x64-linux "$script_dir"
then
	f_echo "Docker image generation failed!"
	exit 1
fi

f_echo "The Docker image was successfully generated."