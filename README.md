# WoW TOC Versions Updater

Bash scripts to update the compatibility versions of **World of Warcraft addons**, preventing outdated addon warnings when Blizzard releases new game client versions.

The process is divided into two independent scripts:

## 1. `get-versions.sh`

Queries the [BlizzTrack](https://blizztrack.com/) API to retrieve the latest versions of the different World of Warcraft clients.

Produces CSV output that can be redirected to a file:

```bash
./get-versions.sh > versions.csv
```

Each line contains three fields:

`CLIENT,INTERFACE,PUBLIC_VERSION`

Example:

```csv
wow,120100,12.1.0.69933
wow_classic,50504,5.5.4.70032
wow_classic_era,11509,1.15.9.70003
wow_anniversary,20506,2.5.6.69795
wow_classic_beta,16001,1.60.1.70245
```

- **CLIENT:** BlizzTrack identifier for the WoW client.
- **INTERFACE:** Version number used by WoW addon `.toc` files.
- **PUBLIC_VERSION:** Full game client version, including the build number, as commonly referenced in changelogs, forums, and release notes.

If a version cannot be retrieved, `ERROR` is used as its value.

This script only needs to be run when you want to refresh the WoW client version information.

## 2. `update-toc.sh`

Updates an addon's `.toc` file using the versions previously retrieved by `get-versions.sh`.

**Usage:**

```bash
./update-toc.sh path/to/AddonName.toc versions.csv
```

The script compares the versions in the CSV file against those declared in the addon's `.toc` file.

**If changes are detected:**

- Updates `## Interface:` with the latest compatibility versions.
- Increments the addon's **PATCH** version (`MAJOR.MINOR.PATCH`) in `## Version:`.
- Preserves existing Interface versions when updated information is unavailable.
- Updates `## TAG_ORDER:` to maintain the correct correspondence between clients and Interface versions.
- Creates a backup of the original `.toc` file with a `.bak` extension.

**If no changes are detected**, the `.toc` file remains untouched.

The script also displays a warning if the CSV file is more than seven days old.

## Required TOC Configuration: `TAG_ORDER`

The `update-toc.sh` script requires an additional metadata field in the addon's `.toc` file:

```toc
## TAG_ORDER: wow wow_classic wow_classic_era wow_anniversary wow_classic_beta
## Interface: 120100, 50504, 11509, 20506, 16001
```

**`TAG_ORDER` is a custom metadata field**, not a standard Blizzard TOC directive. It tells the script which WoW client corresponds to each `Interface` version.

The relationship is positional:

| TAG_ORDER | Interface | WoW Client |
|---|---|---|
| `wow` | `120100` | Retail |
| `wow_classic` | `50504` | Progressive Classic |
| `wow_classic_era` | `11509` | Classic Era |
| `wow_anniversary` | `20506` | Anniversary |
| `wow_classic_beta` | `16001` | Classic Beta |

**Important:**

- The number of entries in `TAG_ORDER` must match the number of versions in `## Interface`.
- Both fields must follow the same order.
- The order itself is arbitrary, as long as both fields remain aligned.
- You only need to include the WoW clients supported by your addon.

The script automatically updates both fields when necessary, preserving their positional relationship even if the order changes.

Without `## TAG_ORDER`, the script cannot identify which Interface version belongs to which WoW client and will not update the `.toc` file.

## How It Works

Both scripts operate independently:

1. Run `get-versions.sh` to retrieve the latest WoW client versions and save them to a CSV file.
2. Add the required `## TAG_ORDER` field to each addon's `.toc` file.
3. Run `update-toc.sh` for each addon you want to update.

Example:

```bash
./get-versions.sh > versions.csv

./update-toc.sh PugaLib/PugaLib.toc versions.csv
./update-toc.sh PugaMemories/PugaMemories.toc versions.csv
```

This allows you to retrieve WoW client versions once and reuse the same CSV file to update as many addons as needed, without making additional API requests.

The CSV file can be refreshed whenever desired; it does not need to be updated daily.

Updating `.toc` files is performed locally and does not require an Internet connection.

## Requirements

- Bash
- `curl` and `jq` (for `get-versions.sh`)
- Standard GNU/Linux command-line utilities (for `update-toc.sh`)

## Important Note

Updating `## Interface` prevents outdated addon warnings, but **does not guarantee that an addon is compatible with changes to Blizzard's API**.

Actual compatibility must still be verified.

## License

MIT License.

Copyright (c) 2026 José Puga.