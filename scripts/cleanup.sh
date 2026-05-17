#!/bin/zsh

# Cleans up the folder, removing any Vivado installation

script_dir=$(dirname -- "$(readlink -nf $0)";)
source $script_dir/header.sh
validate_macos

cd $script_dir/..

to_remove=(".cache" ".dbus" ".local" ".vnc" "Xilinx" ".Xilinx"
"Desktop" "installer" ".bash_history" ".lesshst" ".sudo_as_admin_successful"
".Xauthority" ".xsession-errors" ".XIC.lock" ".mozilla" ".java" ".config"
".fontconfig" )

removed=0
for file in ${to_remove[@]}
do
    if [ -e "$file" ] || [ -L "$file" ]; then
        f_echo "Removing: $file"
        rm -rf "$file"
        removed=$((removed + 1))
    fi
done

# Also clean setup artifacts written by setup.sh
for artifact in "scripts/install_bin" "scripts/vnc_resolution"; do
    if [ -f "$artifact" ]; then
        f_echo "Removing setup artifact: $artifact"
        rm -f "$artifact"
        removed=$((removed + 1))
    fi
done

if [ "$removed" -eq 0 ]; then
    f_echo "Nothing to clean — directory is already fresh."
else
    f_echo "Cleanup complete. Removed $removed item(s)."
fi