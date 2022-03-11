#!/bin/sh

# The configuration file that will be generated.
CONF_FILE="/mnt/etc/nixos/host/maintenance.nix"

# Automatic Garbage Collection.
AUTO_GC="false"

# Automatic Deduplication.
AUTO_DEDUP="false"

# Automatic Update.
AUTO_UPDATE="false"

# Automatic Reboot.
AUTO_REBOOT="false"

# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --auto-gc=*)        AUTO_GC="${1#*=}"; shift 1;;
    --auto-dedup=*)     AUTO_DEDUP="${1#*=}"; shift 1;;
    --auto-update=*)    AUTO_UPDATE="${1#*=}"; shift 1;;
    --auto-reboot=*)    AUTO_REBOOT="${1#*=}"; shift 1;;
    *)                  echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# The template string.
STR_MAINTENANCE="\
# These options make it so that  NixOS will automatically perform maintenance
# tasks like updating the OS, Deduplication and Garbage Collection. This is good
# for lower priority servers like personal gaming servers and NASes where it is
# more important that it stays updated and patched.
{ config, pkgs, ... }:
{
  # Enable daily garbage collection to remove unused packages.
  nix.gc.automatic = ${AUTO_GC};

  # Enable data deduplication. This is a resource intensive process when it
  # runs, so you may want to disable this.
  nix.autoOptimiseStore = ${AUTO_DEDUP};

  # Enable auto updating.
  system.autoUpgrade.enable = ${AUTO_UPDATE};

  # Allow automatic building and rebooting after updating. If this is set to
  # false, you need to manually upgrade using: nixos-rebuild switch --upgrade
  system.autoUpgrade.allowReboot = ${AUTO_REBOOT};
}"

# Generate the configuration file.
echo "${STR_MAINTENANCE}" > ${CONF_FILE}
