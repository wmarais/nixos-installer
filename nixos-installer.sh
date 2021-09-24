#!/bin/sh

HDD=/dev/sda

EFI_PART_SIZE=512MiB

BOOT_PART_SIZE=512MiB

EFI_PART_START=1MiB
EFI_PART_END=512MiB

BOOT_PART_START=513MiB
BOOT_PART_END=1024MiB

LUKS_PART_START=1025MiB
LUKS_PART_END=100%FREE
LUKS_PART_NAME=part-luks
LUKS_VOL_NAME=crypt3

LUKS_KEY="luks_key.txt"

SWAP_SIZE=2G
ROOT_SIZE=100%


LVM_VG_POOL_NAME=sysvg
LVM_SWAP_LV_NAME=swaplv
LVM_ROOT_LV_NAME=rootlv


check_error() {
  if [ $? -ne 0 ]; then
    >&2 echo "ERROR - $1"
    exit 1
  fi
}

# Create the partition table on the HDD.
parted -s -a optimal ${HDD} mklabel gpt
check_error "Failed to create partition table."

# Create the EFI partition.
parted -s -a optimal ${HDD} mkpart ESP fat32 ${EFI_PART_START} ${EFI_PART_END}
check_error "Failed to create EFI partition."

parted -s ${HDD} set 1 esp on
check_error "Failed to set the esp flag on the EFI partition."

# Create the Boot (/boot) partition.
parted -s -a optimal ${HDD} mkpart primary ext4 ${BOOT_PART_START} ${BOOT_PART_END}
check_error "Failed to create Boot (/boot) partition."

# Create the encrypted partition.
parted -s -a optimal ${HDD} mkpart primary ${LUKS_PART_START} ${LUKS_PART_END}
check_error "Failed to create encrypted partition."

# Mount the encrypted partition.
cryptsetup -q luksFormat /dev/sda3 ${LUKS_KEY}
check_error "Failed to format encrypted partition."

cryptsetup -q luksOpen /dev/sda3 ${LUKS_VOL_NAME} --key-file ${LUKS_KEY}
check_error "Failed to open encrypted partition."

# Create the LVM physical volume and volume group.
pvcreate /dev/mapper/${LUKS_VOL_NAME} 
vgcreate ${LVM_VG_POOL_NAME} /dev/mapper/${LUKS_VOL_NAME}

# Create the swap partition.
lvcreate -L ${SWAP_SIZE} -n ${LVM_SWAP_LV_NAME} ${LVM_VG_POOL_NAME}
mkswap /dev/${LVM_VG_POOL_NAME}/${LVM_SWAP_LV_NAME}

lvcreate -l ${ROOT_SIZE} -n ${LVM_ROOT_LV_NAME} ${LVM_VG_POOL_NAME}
mkfs.ext4 -L nixos /dev/sda3


