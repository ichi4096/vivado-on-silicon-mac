#!/bin/zsh

# Attempts to configure Docker by enabling Rosetta and increasing swap.
# Tested on Apple Silicon (M1/M2/M3/M4) running macOS 13–15.
#
# Supports both Docker Desktop settings file formats:
#   Legacy : settings.json      (keys: camelCase,  e.g. useVirtualizationFramework)
#   Current: settings-store.json (keys: PascalCase, e.g. UseVirtualizationFramework)

script_dir=$(dirname -- "$(readlink -nf $0)";)
source "$script_dir/header.sh"
validate_macos

function cannot_setup_docker {
    f_echo "Unfortunately, the script could not configure Docker automatically."
    f_echo "Please change the settings in Docker Desktop manually:"
    f_echo "  Settings → General  → 'Use Virtualization Framework'  → ON"
    f_echo "  Settings → Features → 'Use Rosetta for x86/amd64 emulation' → ON"
    f_echo "  Settings → Resources → Swap → at least 8 GiB"
    f_echo "Restart Docker after applying the changes, then continue."
    wait_for_user_input
    exit 1
}

# Locate the settings file — Docker Desktop 4.x moved to settings-store.json
docker_settings_file=""
for candidate in \
    "$HOME/Library/Group Containers/group.com.docker/settings-store.json" \
    "$HOME/Library/Group Containers/group.com.docker/settings.json"
do
    if [ -f "$candidate" ]; then
        docker_settings_file="$candidate"
        break
    fi
done

if [ -z "$docker_settings_file" ]; then
    cannot_setup_docker
fi

stop_docker

# Use Python to safely update the JSON settings regardless of key casing.
# This handles both the legacy camelCase format and the newer PascalCase format.
python3 - "$docker_settings_file" <<'PYEOF'
import sys, json

path = sys.argv[1]
with open(path, 'r') as f:
    data = json.load(f)

min_swap = 8192

# Build a normalised key map so we can match regardless of case
key_map = {k.lower(): k for k in data}

def set_key(logical_lower, pascal_key, camel_key, value):
    """Set a value using whichever key variant already exists, or add PascalCase."""
    existing = key_map.get(logical_lower)
    if existing:
        data[existing] = value
    else:
        # Key doesn't exist yet — add it in PascalCase (current Docker format)
        data[pascal_key] = value

set_key('usevirtualizationframework',       'UseVirtualizationFramework',       'useVirtualizationFramework',       True)
set_key('usevirtualizationframeworkrosetta','UseVirtualizationFrameworkRosetta', 'useVirtualizationFrameworkRosetta', True)

# Only increase swap, never decrease
swap_key = key_map.get('swapmib', 'SwapMiB')
current_swap = data.get(swap_key, 0)
if current_swap < min_swap:
    data[swap_key] = min_swap

with open(path, 'w') as f:
    json.dump(data, f, indent=4)

print(f"  UseVirtualizationFramework       = {data.get(key_map.get('usevirtualizationframework', 'UseVirtualizationFramework'))}")
print(f"  UseVirtualizationFrameworkRosetta = {data.get(key_map.get('usevirtualizationframeworkrosetta', 'UseVirtualizationFrameworkRosetta'))}")
print(f"  SwapMiB                           = {data.get(swap_key)}")
PYEOF

if [ $? -ne 0 ]; then
    f_echo "Failed to update Docker settings automatically."
    cannot_setup_docker
fi

f_echo "Configured Docker successfully (file: $docker_settings_file)"
