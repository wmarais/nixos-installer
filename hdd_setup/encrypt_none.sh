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
SWAP_LV_FS="linux-swap"

# The Root Logical Volume.
ROOT_LV_NAME="root-lv"
ROOT_LV_SIZE="100%FREE"
ROOT_LV_FS="ext4"

# Include the common helper functions.
. $(dirname "$0")/helpers.sh

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Create a new GPT partition table on the specified HDD.
make_gpt ${HDD}

# Create the EFI partition.
make_part ${HDD} ${EFI_PART_NAME} ${EFI_PART_TYPE} ${EFI_PART_START} \
  ${EFI_PART_END}

# Create the LVM Physical Partition
make_part ${HDD} ${PV_PART_NAME} ${PV_PART_TYPE} ${PV_PART_START} \
  ${PV_PART_END}

# Create the system volume group.
make_vg ${VG_NAME} ${VG_PVS[@]}

# Create the swap logical volume.
make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_LV_FS} ${SWAP_LV_SIZE} 

# Create the root logical volume.
make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_LV_FS} ${ROOT_LV_SIZE}

# Mount the partition for installation.
mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
mount_part "/dev/${HDD}1" "/mnt/boot"

# Write the filesystem configuration. This includes the grub configuration.
$(dirname "$0")/gen_fs_conf.sh "encrypt_none" ${EFI_PART_NAME} \
  ${PV_PART_NAME} ${VG_NAME} ${SWAP_LV_NAME} ${ROOT_LV_NAME}

# Return 0 to indicate that the script was executed sucessfully.
exit 0
