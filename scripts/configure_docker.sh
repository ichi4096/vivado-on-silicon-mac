#!/bin/zsh

# Attempts to configure Docker by enabling Rosetta and increasing swap

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

function cannot_setup_docker {
    f_echo "Unfortunately, the script could not configure Docker automatically."
    f_echo "This means that you have to change the settings in the Docker Dashboard yourself:"
    f_echo "Enable the Virtualization Framework, Rosetta emulation and raise Swap as high as Docker Desktop allows."
    f_echo "Restart Docker after applying the changes and then continue with the installation."
    wait_for_user_input
    exit 1
}

docker_backend_sock="$HOME/Library/Containers/com.docker.docker/Data/backend.sock"
docker_settings_file="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
preferredSwapMiB=8192

function get_flat_settings {
    curl -s --unix-socket "$docker_backend_sock" http://localhost/app/settings/flat
}

if [ -S "$docker_backend_sock" ]
then
    flat_settings=$(get_flat_settings)
    if [ -n "$flat_settings" ]
    then
        current_swap=$(printf '%s' "$flat_settings" | python3 -c 'import json,sys; print(json.load(sys.stdin)["swapMiB"])')
        use_vf=$(printf '%s' "$flat_settings" | python3 -c 'import json,sys; print(str(json.load(sys.stdin)["useVirtualizationFramework"]).lower())')
        use_rosetta=$(printf '%s' "$flat_settings" | python3 -c 'import json,sys; print(str(json.load(sys.stdin)["useVirtualizationFrameworkRosetta"]).lower())')

        grouped_settings=$(curl -s --unix-socket "$docker_backend_sock" http://localhost/app/settings/grouped)
        max_swap=$(printf '%s' "$grouped_settings" | python3 -c 'import json,sys; print(json.load(sys.stdin)["vm"]["resources"]["swapMiB"]["max"])')

        target_swap=$preferredSwapMiB
        if [ "$max_swap" -lt "$target_swap" ]
        then
            target_swap=$max_swap
        fi

        if [ "$target_swap" -lt 4096 ]
        then
            f_echo "Docker Desktop only allows $target_swap MiB of swap on this machine."
        fi

        if [ "$current_swap" -lt "$target_swap" ] || [ "$use_vf" != "true" ] || [ "$use_rosetta" != "true" ]
        then
            payload=$(python3 - <<PY
import json
print(json.dumps({
    "desktop": {
        "useVirtualizationFramework": True,
        "useVirtualizationFrameworkRosetta": {"value": True},
    },
    "vm": {
        "resources": {
            "swapMiB": {"value": $target_swap},
        }
    }
}))
PY
)

            if ! curl -s -X POST --unix-socket "$docker_backend_sock" \
                http://localhost/app/settings \
                -H "Content-Type: application/json" \
                -d "$payload" > /dev/null
            then
                cannot_setup_docker
            fi

            docker desktop restart > /dev/null
        fi

        f_echo "Configured Docker successfully"
        exit 0
    fi
fi

if [ -f "$docker_settings_file" ]
then
    current_swap=$(python3 -c 'import json, pathlib; p=pathlib.Path("'"$docker_settings_file"'"); data=json.loads(p.read_text()); print(data.get("SwapMiB", data.get("swapMiB", 0)))')
    if [ "$current_swap" -lt 4096 ]
    then
        python3 - <<PY
import json
from pathlib import Path

path = Path("$docker_settings_file")
data = json.loads(path.read_text())
data["SwapMiB"] = max(int(data.get("SwapMiB", data.get("swapMiB", 0))), 4096)
path.write_text(json.dumps(data, indent=2) + "\n")
PY
    fi

    f_echo "Configured Docker successfully"
    exit 0
fi

cannot_setup_docker
