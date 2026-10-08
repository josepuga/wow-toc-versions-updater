#!/usr/bin/env bash

# Get the last versions of differents wow clients
# By José Puga 2026. Under MIT license.

API_URL="https://blizztrack.com/api/manifest/%s/versions"
declare -a CLIENTS=(
    wow                 # Retail
    wow_classic         # Classic
    wow_classic_era     # Mist of Pandarian
    wow_anniversary     # TBC
    wow_classic_beta    # Forever
)

# Dependencies
deps=(curl jq)

# Check dependencies
deps_error=false
for n in "${deps[@]}"; do
    if ! command -v "$n" &>/dev/null; then
        echo "$n not installed." >&2
        deps_error=true
    fi
done
[[ $deps_error == true ]] && exit 1

# Converts WoW Client version to "internal" version
# i.e: 12.1.0.69933 -> 120100
sanitize_version() {
    local major minor patch build

    IFS='.' read -r major minor patch build <<< "$1"

    printf '%d%02d%02d' "$major" "$minor" "$patch"
}


for k in "${CLIENTS[@]}"; do 
    url=""
    printf -v url "$API_URL" "$k"
    if new_version=$(curl -fsS "$url" | \
        jq -er '.result.data[] | select(.region == "eu") | .version_name'); then
        echo "$k,$(sanitize_version "$new_version"),$new_version"
    else
        >&2 echo "Error getting $k @ $url"
        echo "$k,ERROR,ERROR"
    fi
done
