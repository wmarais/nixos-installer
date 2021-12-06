#!/bin/sh
# This script is used to encyrpt the entire hardisk with exception of the EFI
# partition. That is the root parttition (including /boot) and swap partition
# is fully encrypted.
HDD=$1
SYS_PART_PASSWD=$2

# Configure information for the EFI partition.
EFI_PART_NAME="EFI"
EFI_PART_TYPE="efi"
EFI_PART_START="1MiB"
EFI_PART_END="512MiB"

# Configuration information for the system partition. All other space on the
# HDD is allocated to the system partition.
SYS_PART_NAME="system-crypt"
SYS_PART_TYPE="crypt"
SYS_PART_START="513MiB"
SYS_PART_END="100%"

# The configuration of the LVM logical volume that sits ontop of the encrypted
# volume.
PV_NAME="system-pv"
PV_TYPE="lvm"
PV_START="0%"
PV_END="100%"

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

# Create the encrypted partition.
make_part ${HDD} ${SYS_PART_NAME} ${SYS_PART_TYPE} ${SYS_PART_START} \
  ${SYS_PART_END} ${SYS_PART_PASSWD}

# Make the LVM physical volume ontop of the encrypted partition.
make_part "/dev/mapper/${SYS_PART_NAME}" ${PV_NAME} ${PV_TYPE} ${PV_START} \
  ${PV_END}

# Make the Volume group using the specific physical volume.
make_vg ${LVM_VG_NAME} ${LVM_PV_NAME}

# Create the swap and root partition for the system.
make_lv ${SWAP_LV_NAME} ${VG_NAME} ${SWAP_LV_FS} ${SWAP_LV_SIZE}
make_lv ${ROOT_LV_NAME} ${VG_NAME} ${ROOT_LV_FS} ${ROOT_LV_SIZE}

# Mount the partition for installation.
mount_part "/dev/${VG_NAME}/${ROOT_LV_NAME}" "/mnt"
mount_part "/dev/disk/by-label/${EFI_PART_NAME}" "/mnt/boot/efi"

# Write the hardware configuration.
$(dirname "$0")/encrypt_full_hw_config.sh ${EFI_PART_NAME} ${SWAP_LV_NAME} \
  ${ROOT_LV_NAME}

# If this point was reached, the script was successfully executed.
exit 0
