#!/usr/bin/env bash

# Update the versions of a toc file WoW addon and
# if exists, add change log to CHANGELOG.md
# By José Puga 2026. Under MIT license.

if [ "$#" -ne 2 ]; then
    echo Sets the last client versions to a .toc file of WoW addon.
    echo This script uses the .csv file generated with get-versions.sh
    echo "USAGE: ${0##*/} path/to/AddonName.toc" path/to/versions.csv
    exit 1
fi 
[ ! -f "$1" ] && echo "$1 does not exists" && exit 1

set -eou pipefail

# Files check
toc_file="$1"
csv_file="$2"
[ ! -f "$toc_file" ] && echo "TOC File $toc_file does not exists" && exit 1
[ ! -f "$csv_file" ] && echo "CSV File $csv_file does not exists" && exit 1

if (( $(date +%s) - $(stat -c %Y "$csv_file") > 7 * 86400 )); then
    >&2 echo "WARNING: CSV older than a week" 
fi

# Extracting tags...
tags=$(grep ^"## TAG_ORDER" "$toc_file" | cut -d":" -f2)
[[ $tags == "" ]] && echo "No '## TAG_ORDER:' in $toc_file" && exit 1

# Extracting versions (in an indexed array)
# VERSIONS COUNT MUST BE == TAGS COUNT
versions=$(grep ^"## Interface" "$toc_file" | cut -d":" -f2)
declare -a iface_versions
IFS=',' read -ra iface_versions <<< "$versions"

# Create associative interface arrays and set with versions
# key = tag. value = interface version

# Old (current) values from TOC
declare -A old_interface
i=0
for tag in $tags; do
    old_interface["$tag"]="${iface_versions[$i]// /}"
    ((++i))
done

# New values from CSV
declare -A new_interface

# Avoid missing key if CSV fails
for tag in "${!old_interface[@]}"; do
    new_interface["$tag"]="${old_interface[$tag]}"
done

updated=false
while IFS=, read tag interface public_version; do
    # Process only Interface versions used in the TOC file. Key exists?
    if [[ -v old_interface["$tag"] ]]; then
        if [[ "$interface" == "ERROR" || -z "$interface" ]]; then
            >&2 echo "Tag $tag market as ERROR or empty. Ignored"
            new_interface["$tag"]="${old_interface[$tag]}"
        else
            new_interface["$tag"]="$interface"
            # Only if has changed...
            if [[ "$interface" != "${old_interface[$tag]}" ]]; then
                updated=true
            fi
        fi
    fi
done < "$csv_file"

# Show info of current versions
echo "Current versions:"
for k in "${!old_interface[@]}"; do 
    echo -e "\t$k -> ${old_interface["$k"]}"
done

# Show info of new versions
echo -e "\nNew versions:"
for k in "${!new_interface[@]}"; do 
    echo -e "\t$k -> ${new_interface["$k"]}"
done

# No changes... exit!
if [[ "$updated" == false ]]; then
    echo "No changes. Existing."
    exit 0
fi

# Create the TOC's new lines

#
# Now, we need to:
#   * Increase the Addon minor version
#   * Update de "## TAG_ORDER" and "## Interface" lines. Because Order in hash 
# arrays are not deterministic
#

# Version patch increase
line_version="## Version:"
old_ver=$(grep ^"## Version" "$toc_file" | cut -d":" -f2)
old_ver="${old_ver// /}"
declare -i patch
IFS='.' read -r major minor patch <<< "$old_ver"
((++patch))
new_ver="$major.$minor.$patch"
line_version="## Version: $new_ver"
echo -e "\nAddon Updated: $old_ver -> $new_ver"


# Interface versions
line_tag="## TAG_ORDER:"
line_iface="## Interface:"
for k in "${!new_interface[@]}"; do
    v="${new_interface["$k"]}"
    line_tag+=" $k"
    line_iface+=" $v,"
done
line_iface="${line_iface%,}" # Remove last ","

sed -i.bak \
    -e "s/^## Version:.*/$line_version/" \
    -e "s/^## TAG_ORDER:.*/$line_tag/" \
    -e "s/^## Interface:.*/$line_iface/" \
    "$toc_file"

# If exists CHANGELOG.md, add new version, and a generic text
changelog_file=$(dirname "$toc_file")/CHANGELOG.md
[ ! -f "$changelog_file" ] && >&2 echo "CHANGELOG.md not found, ignored." && exit 0

sed -i "1i\\### $new_ver\n\t- Updated Interface version.\n" "$changelog_file"

