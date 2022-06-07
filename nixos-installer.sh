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

# Indicates whether Auto Garbage Collection should be enabled or not. It is not
# critical to have enabled, but it is is nice to keep the used space to a
# minimum by deleting unused packages.
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

HOME_SIZE="0MiB"
ROOT_SIZE="0MiB"
NIX_SIZE="0MiB"
VAR_SIZE="0MiB"
SWAP_SIZE="2GiB"
BOOT_SIZE="1GiB"


SCRIPTS_PATH=$(dirname "$0")/scripts

# Include the common helper functions.
. ${SCRIPTS_PATH}/func_lib.sh

# Path to the generators.
GEN_PATH=$(dirname "$0")/generators

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

  # Get a list of all the open encrypted volumes.
  EVS=(`dmsetup ls --target crypt | awk '{print $1}'`)
  for ev in ${EVS[@]}; do
    cryptsetup luksClose ${ev}
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

    --home-size)      HOME_SIZE="${1#*=}"; shift 1;;
    --root-size)      ROOT_SIZE="${1#*=}"; shift 1;;
    --nix-size)       NIX_SIZE="${1#*=}"; shift 1;;
    --var-size)       VAR_SIZE="${1#*=}"; shift 1;;
    --swap-size)      SWAP_SIZE="${1#*=}"; shift 1;;
    --boot-size)      BOOT_SIZE="${1#*=}"; shift 1;;

    *) echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# Make sure the script is run as root.
must_be_root ${LINENO}

# Check that the script args are valid.
validate_args

# Prepare the host for installation / re-installation.
prepare

# Configure the hard-drive.
case ${HDD_CONF} in
  "lvm2-full-enc")
    ERR=$(${SCRIPTS_PATH}/lvm2-full-enc.sh --hdd=${HDD} --key=${KEY} \
      --home-size=${HOME_SIZE} --root-size=${ROOT_SIZE} --nix-size=${NIX_SIZE} \
      --var-size=${VAR_SIZE} --swap-size=${SWAP_SIZE} --boot-size=${BOOT_SIZE} \
      2>&1 >/dev/null)
    check_error "${LINENO}" "Installation failed because:\n\n${ERR}\n\n"
    ;;

  "lvm2-part-enc")
    ERR=$(${SCRIPTS_PATH}/lvm2-part-enc.sh --hdd=${HDD} --key=${KEY} \
      --home-size=${HOME_SIZE} --root-size=${ROOT_SIZE} --nix-size=${NIX_SIZE} \
      --var-size=${VAR_SIZE} --swap-size=${SWAP_SIZE} --boot-size=${BOOT_SIZE} \
      2>&1 >/dev/null)
    check_error "${LINENO}" "Installation failed because:\n\n${ERR}\n\n"
    ;;

  "lvm2-no-enc")
    ERR=$(${SCRIPTS_PATH}/lvm2-no-enc.sh --hdd=${HDD} 2>&1 >/dev/null)
      --home-size=${HOME_SIZE} --root-size=${ROOT_SIZE} --nix-size=${NIX_SIZE} \
      --var-size=${VAR_SIZE} --swap-size=${SWAP_SIZE} --boot-size=${BOOT_SIZE} \
    check_error "${LINENO}" "Installation failed because:\n\n${ERR}\n\n"
    ;;

  "zfs-no-enc")
    ERR=$(${SCRIPTS_PATH}/zfs-no-enc.sh --hdd=${HDD} 2>&1 >/dev/null)
      --home-size=${HOME_SIZE} --root-size=${ROOT_SIZE} --nix-size=${NIX_SIZE} \
      --var-size=${VAR_SIZE} --swap-size=${SWAP_SIZE} --boot-size=${BOOT_SIZE} \
    check_error "${LINENO}" "Installation failed because:\n\n${ERR}\n\n"
    ;;

  "zfs-enc")
    ERR=$(${SCRIPTS_PATH}/zfs-enc.sh --hdd=${HDD} --${KEY} 2>&1 >/dev/null)
      --home-size=${HOME_SIZE} --root-size=${ROOT_SIZE} --nix-size=${NIX_SIZE} \
      --var-size=${VAR_SIZE} --swap-size=${SWAP_SIZE} --boot-size=${BOOT_SIZE} \
    check_error "${LINENO}" "Installation failed because:\n\n${ERR}\n\n"
    ;;
esac

# Generate the hardware configuration without the filesystems section since this
# is done automatically by the hdd_setup scripts.
ERR=$(nixos-generate-config --root /mnt --no-filesystems 2>&1)
check_error "${LINENO}" "Failed to generate NixOS config because:\n\n${ERR}\n\n"

# Copy the configuration of the system.
ERR=$(cp -r -f $(dirname "$0")/configuration/. "/mnt/etc/nixos/"
check_error "${LINENO}" \
  "Failed to copy default configuration file because:\n\n${ERR}\n\n"

mkdir -p /mnt/etc/nixos/host
mkdir -p /mnt/etc/nixos/security
mkdir -p /mnt/etc/nixos/applications

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
${GEN_PATH}/gen_vm_guest.sh --vbox=${VBOX_GUEST} --vmware=${VMWARE_GUEST} \
  --x11=${X11_GUEST}

# Rebuild the distribution.
print_info "${FILE_NAME}" "${LINENO}" "Installing NixOS....."
ERR=$(nixos-install --no-root-passwd 2>&1)
check_error "$?" "${FILE_NAME}" "${LINENO}" \
  "Failed to install NixOS because:\n\n${ERR}"

# If deploying a desktop, manually copy the /etc/skel files for the created
# user account.
if [ "${TYPE}" == "desktop" ]; then
  cp -r ./generators/skel/.config "/mnt/home/${USER}"
  chown -R nixos:users /mnt/home/${USER}/.config
  chmod -R 700 /mnt/home/${USER}/.config
fi

print_info "${FILE_NAME}" "${LINENO}" "Done! Enjoy NixOS!"

exit 0
