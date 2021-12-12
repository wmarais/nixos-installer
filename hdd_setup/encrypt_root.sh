#!/bin/sh
# This script is used to encrypt only the root and swap partitions and leave
# the efi and /boot partitions unencrypted. This is generally the fastest
# booting encrypted configuration that is best most for most 90% of laptops in
# the wilderness.
HDD=$1
SYS_PART_PASSWD=$2

# Configure information for the EFI partition.
EFI_PART_NAME="efi"
EFI_PART_TYPE="efi"
EFI_PART_START="1MiB"
EFI_PART_END="500MiB"

BOOT_PART_NAME="boot"
BOOT_PART_TYPE="boot"
BOOT_PART_START="501MiB"
BOOT_PART_END="1000MiB"

# Configuration information for the system partition. All other space on the
# HDD is allocated to the system partition.
SYS_PART_NAME="system-crypt"
SYS_PART_TYPE="crypt"
SYS_PART_START="1001MiB"
SYS_PART_END="100%"

# The configuration of the LVM volume group.
VG_NAME="system-vg"

# The configuration of the swap LVM logical volume.
SWAP_LV_NAME="swap-lv"
SWAP_LV_SIZE="2GiB"
SWAP_LV_FS="swap"

# The configuration of the root LVM logical volume.
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

# Create the boot partition.
make_part ${HDD} ${BOOT_PART_NAME} ${BOOT_PART_TYPE} ${BOOT_PART_START} \
  ${BOOT_PART_END}

# Create the encrypted partition.
make_part ${HDD} ${SYS_PART_NAME} ${SYS_PART_TYPE} ${SYS_PART_START} \
  ${SYS_PART_END} ${SYS_PART_PASSWD}

# Make the LVM physical volume ontop of the encrypted partition.
make_pv "/dev/mapper/${SYS_PART_NAME}"

# Make the volume group using the specific physical volume.
make_vg ${VG_NAME} "/dev/mapper/${SYS_PART_NAME}"

# Create the swap and root partition for the system.
make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_LV_FS} ${SWAP_LV_SIZE}
make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_LV_FS} ${ROOT_LV_SIZE}

# Mount the partition for installation.
mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
mount_part "/dev/disk/by-label/${BOOT_PART_NAME}" "/mnt/boot"
mount_part "/dev/disk/by-label/${EFI_PART_NAME}" "/mnt/boot/efi"

# If this point was reached, the script was successfully executed.
exit 0
