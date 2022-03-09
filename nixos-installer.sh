#!/bin/sh

HDD="/dev/sda"
USER=""
PASSWORD=""
HOST_NAME=""
ENCRYPT=""
KEY=""
TYPE=""

# The timezone of the host.
TIME_ZONE="Australia/Adelaide"

AUTO_GC="false"
AUTO_DEDUP="false"
AUTO_UPDATE="false"
AUTO_REBOOT="false"

# The WiFi configuration.
ETH_DHCP=""
WIFI_ENABLE="false"
WIFI_SSID=""
WIFI_PASSWD=""

# Guest Additions.
VBOX_GUEST="false"
VMWARE_GUEST="false"
X11_GUEST="false"

# Include the common helper functions.
. $(dirname "$0")/hdd_setup/helpers.sh

# Path to the generators.
GEN_PATH=$(dirname "$0")/conf

FILE_NAME="${0##*/}"

################################################################################
# Check whether the combination of arguments look sensible.
################################################################################
validate_args() {
  if [[ ${ENCRYPT} == "full" || ${ENCRYPT} == "root" ]]; then
    if [ ${KEY} == "" ]; then
      ehco "An ecryption key must be specified using -k or --key."
    fi
  fi
}

################################################################################
# Prepare for installation. This has to perform three actions:
#  1. Disable all swap.
#  2. Umount everything on /mnt.
#  3. Remove all LVM volume groups.
################################################################################
prepare() {
  # Disable all swap.
  swapoff --all

  # Unmount anything on /mnt.
  umount -A --recursive /mnt >/dev/null 2>&1
  #check_error "$?" "${FILE_NAME}" ${LINENO} "Failed to unmount /mnt."

  # Get a list of all the volume groups.
  VGS=(`vgdisplay | grep "VG Name" | awk '{print $3}'`)

  # Delete all the logical volumes associated with each volume group.
  for vg in ${VGS[@]}; do
    lvremove -q -f ${vg} >/dev/null 2>&1
    vgremove -q -f ${vg} >/dev/null 2>&1
  done

  # Get a list of all the physical volumes.
  PVS=(`pvdisplay | grep "PV Name" | awk '{print $3}'`)

  # Delete all the physical volumes.
  for pv in ${PVS[@]}; do 
    pvremove -q -f ${pv} >/dev/null 2>&1
  done
}

################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --hdd=*)          HDD="${1#*=}"; shift 1;;
    --user=*)         USER="${1#*=}"; shift 1;;
    --password=*)     PASSWORD="${1#*=}"; shift 1;;
    --host-name=*)    HOST_NAME="${1#*=}"; shift 1;;
    --encrypt=*)      ENCRYPT="${1#*=}"; shift 1;;
    --key=*)          KEY="${1#*=}"; shift 1;;
    --type=*)         TYPE="${1#*=}"; shift 1;;
    --time-zone=*)    TIME_ZONE="${1#*=}"; shift 1;;

    --eth-dhcp=*)     ETH_DHCP="${1#*=}"; shift 1;;
    --wifi-enable)    WIFI_ENABLE="true"; shift 1;;
    --wifi-ssid=*)    WIFI_SSID="${1#*=}"; shift 1;;
    --wifi-passwd=*)  WIFI_PASSWD="${1#*=}"; shift 1;;
 
    --auto-gc)        AUTO_GC="true"; shift 1;;
    --auto-dedup)     AUTO_DEDUP="true"; shift 1;;
    --auto-update)    AUTO_UPDATE="true"; shift 1;;
    --auto-reboot)    AUTO_REBOOT="true"; shift 1;;

    --vbox)           VBOX_GUEST="true"; shift 1;;
    --vmware)         VMWARE_GUEST="true"; shift 1;;

    *) echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# Makre sure the script is run as root.
must_be_root ${LINENO}

# Check that the script args are valid.
validate_args

# Prepare the host for installation / reinstallation.
prepare

# Configure the hard-drive.
case ${ENCRYPT} in
  "full")
    . $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD} ${KEY}
    ;;
  
  "root")
    . $(dirname "$0")/hdd_setup/encrypt_root.sh ${HDD} ${KEY}
    ;;

  *)
    . $(dirname "$0")/hdd_setup/encrypt_none.sh ${HDD}
    ;;
esac

# Generate the hardware configuration without the filesystems section since this
# is done automatically by the hdd_setup scripts.
nixos-generate-config --root /mnt --no-filesystems

# Copy the configuration of the system.
cp -f $(dirname "$0")/conf/configuration.nix "/mnt/etc/nixos/"
check_error "$?" "${FILE_NAME}" ${LINENO} "Failed to copy default configuration file."

# Generate the desktop configuration.
${GEN_PATH}/gen_desktop.sh --type=${TYPE}

# Generate the network configuration.
${GEN_PATH}/gen_network.sh --host-name=${HOST_NAME} \
  --eth-dhcp=${ETH_DHCP} --wifi-enable=${WIFI_ENABLE} \
  --wifi-ssid=${WIFI_SSID} --wifi-passwd=${WIFI_PASSWD}

# Generate the user configuration.
${GEN_PATH}/gen_users.sh --user=${USER} --password=${PASSWORD}

# Generate the maintenance configuration.
${GEN_PATH}/gen_maintenance.sh --auto-gc=${AUTO_GC} --auto-dedup=${AUTO_DEDUP} \
  --auto-update=${AUTO_UPDATE} --auto-reboot=${AUTO_REBOOT}

# Configure any guest additions for VBox or Vmware.
if [ ${TYPE} == "desktop" ]; then
  X11_GUEST="true"
fi
${GEN_PATH}/gen_guest.sh --vbox=${VBOX_GUEST} --vmware=${VMWARE_GUEST} \
  --x11=${X11_GUEST}

# Rebuild the distribution.
nixos-install --no-root-passwd

exit 0
