#!/bin/sh
# This script is is used to configure an encyrpted HDD configuraion. It is best
# used for Virtual Machines where the host is encrypted or machines that have
# strong physical security. Only uses this for non-sensitive applications.
HDD=$1

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
SCRIPTS_DIR=$(dirname "$0")


EFI_SIZE=""
BOOT_SIZE=""
SWAP_SIZE=""
ROOT_SIZE=""
NIX_SIZE=""


# Calculate the boundary of the EFI Partition.
EFI_START="1MiB"
EFI_END=$(expr $(to_mib ${EFI_START}) + $(to_mib ${EFI_SIZE}))

# Calculate the boundary of the BOOT partition.




# Include the common helper functions.
. ${SCRIPTS_DIR}/func_lib.sh

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Create a new GPT partition table on the specified HDD.
${SCRIPTS_DIR}/make_gpt.sh --device=${HDD}
check_error ${LINENO} "HDD setup failed."

# Create the EFI partition.
${SCRIPTS_DIR}/make_part.sh --device=${HDD} --name=${EFI_PART_NAME} \
  --type=${EFI_PART_TYPE} --start=${EFI_PART_START} \
  --end=${EFI_PART_END}
check_error ${LINENO} "HDD setup failed."

# Create the partition that will be used of the LVM physical volume.
${SCRIPTS_DIR}/make_part.sh ${HDD} ${PV_PART_NAME} ${PV_PART_TYPE} ${PV_PART_START} \
  ${PV_PART_END}

# Create the LVM physical volume.
make_pv "/dev/disk/by-partlabel/${PV_PART_NAME}"

# Create the system volume group.
make_vg ${VG_NAME} ${VG_PVS[@]}

# Create the swap logical volume.
make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_LV_FS} ${SWAP_LV_SIZE} 

# Create the root logical volume.
make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_LV_FS} ${ROOT_LV_SIZE}

# Mount the partition for installation.
mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
mount_part "/dev/disk/by-partlabel/${EFI_PART_NAME}" "/mnt/boot/efi"

# Write the filesystem configuration. This includes the grub configuration.
$(dirname "$0")/gen_fs_conf.sh "encrypt_none" ${EFI_PART_NAME} \
  ${PV_PART_NAME} ${VG_NAME} ${SWAP_LV_NAME} ${ROOT_LV_NAME}

exit 0
