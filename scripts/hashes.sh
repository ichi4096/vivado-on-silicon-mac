# This file contains the hashes for the different versions
# of the Vivado installer.
# The first 4 digits are the year part of the version number
# The 5th digit is the subversion, e.g. 202210 corresponds
# to the version 2022.1.

# This script needs to be sourced into other scripts or
# be run explicitly with an interpreter since it has no shebang

# hashes for the web installer
declare -A web_hashes=(
    ["9bf473b6be0b8531e70fd3d5c0fe4817"]=202220
    ["e47ad71388b27a6e2339ee82c3c8765f"]=202310
    ["b8c785d03b754766538d6cde1277c4f0"]=202320
)

# ["8b0e99a41b851b50592d5d6ef1b1263d"]=202410
# 2024.1 somehow crashes the whole Docker Engine

# hashes for the full installer
# not tested yet
declare -A sfd_hashes=()
#declare -A sfd_hashes=(
#    ["0bf810cf5eaa28a849ab52b9bfdd20a5"]=202210
#    ["4b4e84306eb631fe67d3efb469122671"]=202220
#    ["f2011ceba52b109e3551c1d3189a8c9c"]=202310
#    ["64d64e9b937b6fd5e98b41811c74aab2"]=202320
#    ["372c0b184e32001137424e395823de3c"]=202410
#)