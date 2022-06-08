#!/bin/sh
# This script is is used to configure an encyrpted HDD configuraion. It is best
# used for Virtual Machines where the host is encrypted or machines that have
# strong physical security. Only uses this for non-sensitive applications.

# The storage device to create the partitions on.
NI_DISK=""

# The configuration of the EFI partition.
EFI_PART_NAME="EFI"
EFI_PART_TYPE="efi"
EFI_PART_START="1MiB"
EFI_PART_END="500MiB"

# The configuration of the LVM Physical Partition.
PV_PART_NAME="system-pv"
PV_PART_TYPE="lvm"
PV_PART_START="501MiB"
PV_PART_END="100%"

# The LVM Volume Group configuration.
VG_NAME="system-vg"
VG_PVS=("/dev/disk/by-partlabel/${PV_PART_NAME}")

# The Swap Logical Volume.
SWAP_LV_NAME="swap-lv"
SWAP_LV_SIZE="2G"
SWAP_LV_FS="swap"

# The Root Logical Volume.
ROOT_LV_NAME="root-lv"
ROOT_LV_SIZE="100%FREE"
ROOT_LV_FS="ext4"

# The name of this file which is used for debug printing.
ENC_NONE_FILE_NAME="hdd_setup/encrypt_none.sh"


# The path to the scripts.
SCRIPTS_PATH=$(dirname "$0")

# Include the common helper functions.
. ${SCRIPTS_PATH}/func_lib.sh

NI_PV_SIZE="100%FREE"

NI_BOOT_SIZE="1024MiB"

HOME_SIZE=""
SWAP_SIZE=""
ROOT_SIZE=""
NIX_SIZE=""


validate_args() {
  # Check if the specified disk exist.
  disk_exists "${NI_DISK}"
  check_error "${LINENO}" "Disk: ${NI_DISK} does not exist."
}

print_summary() {
  echo "Disk: ${NI_DISK}"
  echo "Capacity: ${NI_DISK_SIZE}"
  echo "Remaining: ${NI_DISK_REMAINING}"
  echo "Boot: ${NI_BOOT_START} to ${NI_BOOT_END}"
  echo "LVM PV: ${NI_PV_START} to ${NI_PV_END}"
}

################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --disk=*)         NI_DISK="${1#*=}"; shift 1;;
    --boot-size)      NI_BOOT_SIZE="${1#*=}"; shift 1;;
    --swap-size)      NI_SWAP_SIZE="${1#*=}"; shift 1;;
    --root-size)      NI_ROOT_SIZE="${1#*=}"; shift 1;;
    --nix-size)       NI_NIX_SIZE="${1#*=}"; shift 1;;
    --var-size)       NI_VAR_SIZE="${1#*=}"; shift 1;;
    --home-size)      NI_HOME_SIZE="${1#*=}"; shift 1;;
    *) echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# Check that the supplied aguments are meaningful.
validate_args

NI_DISK_SIZE=$(size_of_disk ${NI_DISK})
NI_DISK_REMAINING=${NI_DISK_SIZE}

# Calculate the boundary of the boot partition.
NI_BOOT_START="1MiB"
NI_BOOT_END=$(calc_part_end ${NI_BOOT_START} ${NI_BOOT_SIZE} \
  ${NI_DISK_SIZE} ${NI_DISK_REMAINING})
check_error "${LINENO}" "Failed to calculate Boot Partition boundaries."
NI_DISK_REMAINING=$(subtract_size ${NI_DISK_SIZE} ${NI_BOOT_END})
NI_DISK_REMAINING=$(subtract_size ${NI_DISK_REMAINING} 1MiB)

# Calculate the LVM PV boundary. All other partitions live ontop of LVM so that
# it is a bit easier to handle future resizes etc.
NI_PV_START=$(add_size ${NI_BOOT_END} 1MiB)
check_error "${LINENO}" "Failed to calculate LVM PV boundaries."
NI_PV_END=$(calc_part_end ${NI_PV_START} ${NI_PV_SIZE} \
  ${NI_DISK_SIZE} ${NI_DISK_REMAINING})
NI_DISK_REMAINING=$(subtract_size ${NI_DISK_SIZE} ${NI_PV_END})

print_summary


# # Include the common helper functions.
# . ${SCRIPTS_DIR}/func_lib.sh

# # Make sure the script is executed as root.
# must_be_root ${LINENO}

# # Create a new GPT partition table on the specified HDD.
# ${SCRIPTS_DIR}/make_gpt.sh --device=${HDD}
# check_error ${LINENO} "HDD setup failed."

# # Create the EFI partition.
# ${SCRIPTS_DIR}/make_part.sh --device=${HDD} --name=${EFI_PART_NAME} \
#   --type=${EFI_PART_TYPE} --start=${EFI_PART_START} \
#   --end=${EFI_PART_END}
# check_error ${LINENO} "HDD setup failed."

# # Create the partition that will be used of the LVM physical volume.
# ${SCRIPTS_DIR}/make_part.sh ${HDD} ${PV_PART_NAME} ${PV_PART_TYPE} ${PV_PART_START} \
#   ${PV_PART_END}--home-size)      NI_HOME_SIZE="${1#*=}"; shift 1;;

# # Create the LVM physical volume.
# make_pv "/dev/disk/by-partlabel/${PV_PART_NAME}"

# # Create the system volume group.
# make_vg ${VG_NAME} ${VG_PVS[@]}

# # Create the swap logical volume.
# make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_LV_FS} ${SWAP_LV_SIZE} 

# # Create the root logical volume.
# make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_LV_FS} ${ROOT_LV_SIZE}size

# # Mount the partition for installation.
# mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
# mount_part "/dev/disk/by-partlabel/${EFI_PART_NAME}" "/mnt/boot/efi"

# # Write the filesystem configuration. This includes the grub configuration.
# $(dirname "$0")/gen_fs_conf.sh "encrypt_none" ${EFI_PART_NAME} \
#   ${PV_PART_NAME} ${VG_NAME} ${SWAP_LV_NAME} ${ROOT_LV_NAME}

# exit 0
