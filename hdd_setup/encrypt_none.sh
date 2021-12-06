#!/bin/sh

HDD=/dev/sda

VG_NAME="sysvg"
VG_PVS=("${HDD}2")

SWAP_LV_NAME="swaplv"
SWAP_SIZE="2G"
SWAP_FS="linux-swap"

ROOT_LV_NAME="rootlv"
ROOT_SIZE="100%FREE"
ROOT_FS="ext4"

# Include the common helper functions.
. $(dirname "$0")/helpers.sh

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Create a new GPT partition table on the specified HDD.
make_gpt ${HDD}

# Create the EFI partition.
make_part ${HDD} 1 "vfat" "EFI" "1MiB" "512MiB"

# Make the rest of the disk and LVM physical volume.
make_pv ${HDD} 2 "100%"

# Create the system volume group.
make_vg ${VG_NAME} ${VG_PVS[@]}

# Create the swap logical volume.
make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_SIZE} ${SWAP_FS}

# Create the root logical volume.
make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_SIZE} ${ROOT_FS}

# Mount the structure of the 
mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
mount_part "/dev/${HDD}1" "/mnt/boot"

# Return 0 to indicate that the script was executed sucessfully.
exit 0
