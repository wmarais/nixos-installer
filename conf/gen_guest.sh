#!/bin/sh

# The configuration file that will be generated.
CONF_FILE="/mnt/etc/nixos/conf/guest.nix"

# Whether the it is a virtual box guest or not.
VBOX_GUEST="false"

VMWARE_GUEST="false"

# Whether it is a x11 guest.
X11_GUEST="false"

# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --vbox=*)         VBOX_GUEST="${1#*=}"; shift 1;;
    --vmware=*)       VMWARE_GUEST="${1#*=}"; shift 1;;
    --x11=*)          X11_GUEST="${1#*=}"; shift 1;;
    *)                echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# Check if the vmware additions must be installed headless.
VMWARE_HEADLESS="true"
if [ "${X11_GUEST}" == "true" ]; then
  VMWARE_HEADLESS="false"
fi

# The template string that is used to generate the configuration.
STR_VBOX="\
{ config, pkgs, ... }:
{
  # Remove the fsck that runs at startup.
  #boot.initrd.checkJournalingFS = false;

  # Enable virtualbox guest editions.
  virtualisation.virtualbox.guest.enable = ${VBOX_GUEST};
  virtualisation.virtualbox.guest.x11 = ${X11_GUEST};

  # Enable vmware guest additions.
  virtualisation.vmware.guest = ${VMWARE_GUEST};
  virtualisation.vmware.guest.headless = ${VMWARE_HEADLESS};
}"

# Generate the virtualbox configuration.
if [ "${VBOX_GUEST}" == "true" ]; then
  echo "${STR_VBOX}" > ${CONF_FILE}
else
  echo "" > ${CONF_FILE}
fi
