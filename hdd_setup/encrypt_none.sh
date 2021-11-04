#!/bin/sh

HDD=/dev/sda
SWAP_SIZE="2G"
ROOT_SIZE="100%FREE"

VG_NAME="sysvg"
SWAP_LV_NAME="swaplv"
ROOT_LV_NAME="rootlv"


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
make_vg ${HDD} 2 "sysvg"

# Create the swap logical volume.
make_lv ${SWAP_SIZE} ${SWAP_LV_NAME} ${VG_NAME} "linux-swap"

# Create the root logical volume.
make_lv ${ROOT_SIZE} ${ROOT_LV_NAME} ${VG_NAME} "ext4"





