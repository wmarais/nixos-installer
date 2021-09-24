#!/bin/sh

HDD=/dev/sda


EFI_PART_NUM=1
EFI_PART_NAME=efi
EFI_PART_TYPE=EPS
EFI_PART_FS=fat32
EFI_PART_START=1MiB
EFI_PART_END=512MiB

BOOT_PART_NUM=2
BOOT_PART_NAME=boot
BOOT_PART_TYPE=primary
BOOT_PART_FS=ext4
BOOT_PART_START=513MiB
BOOT_PART_END=1024MiB

LUKS_PART_NUM=3
LUKS_PART_NAME=part-luks
LUKS_PART_TYPE=primary
LUKS_PART_FS=ext4
LUKS_PART_START=1025MiB
LUKS_PART_END=100%

LUKS_KEY="luks_key.txt"

SWAP_SIZE=2G
ROOT_SIZE=100%FREE


LVM_VG_POOL_NAME=sysvg
LVM_SWAP_LV_NAME=swaplv
LVM_ROOT_LV_NAME=rootlv


check_error() {
  if [ $? -ne 0 ]; then
    >&2 echo "ERROR - $1"
    exit 1
  fi
}

################################################################################
# Create a new partition on the hard drive.
#
#		$1 = Hard Drive Path.
################################################################################
create_partition_table() {
	# Create the partition table on the HDD.
	parted -s -a optimal $1 mklabel gpt
	check_error "Failed to create partition table on $1."
}

################################################################################
# Set the name of the partition, where:
#
#		$1 = Hard Drive Path
#  	$2 = Partition Number
#  	$3 = Partition Name
################################################################################
set_partition_name() {
	parted -s $1$2 name $3
	check_error "Failed to set name of $1$2 to $3"
}

################################################################################
# Create the boot partition. This is where the /boot data will be installed to
# enable full-disk encrypted boots.
#
#		$1 = Hard Drive Path
#		$2 = Partition Number
#		$3 = Partition Name
#   $4 = Partition Type
#   $5 = Partition File System
#   $6 = Partition Start
#   $7 = Partition End
################################################################################
create_partition() {
	# Create the partition.
	parted -s -a optimal $1 mkpart $4 $5 $6 $7
	check_error "Failed to create partition: Path=$1/$2, Name=$3, Type=$4, FS=$5, Start=$6, End=$7"
	
	set_partition_name $1 $2 $3
	
	if [ $4 -eq EPS ]; then
		parted -s $1 set $2 esp on
		check_error "Failed to set the esp flag on the EFI partition."
	fi
}

create_partition_table ${HDD}

# Create and configure the EFI partition.
create_partition ${HDD} ${EFI_PART_NUM} ${EFI_PART_NAME} ${EFI_PART_TYPE} \
	${EFI_PART_FS} ${EFI_PART_START} ${EFI_PART_END}

# Create the /boot partition.
create_partition ${HDD} ${BOOT_PART_NUM} ${BOOT_PART_NAME} ${BOOT_PART_TYPE} \
	${BOOT_PART_FS} ${BOOT_PART_START} ${BOOT_PART_END}

# Create the LUKS partition.
create_partition ${HDD} ${LUKS_PART_NUM} ${LUKS_PART_NAME} ${LUKS_PART_TYPE} \
	${LUKS_PART_FS} ${LUKS_PART_START} ${LUKS_PART_END}


# Create the encrypted partition.
parted -s -a optimal ${HDD} mkpart primary ${LUKS_PART_START} ${LUKS_PART_END}
check_error "Failed to create encrypted partition."

## Mount the encrypted partition.
#cryptsetup -q luksFormat /dev/sda3 ${LUKS_KEY}
#check_error "Failed to format encrypted partition."

#cryptsetup -q luksOpen /dev/sda3 ${LUKS_VOL_NAME} --key-file ${LUKS_KEY}
#check_error "Failed to open encrypted partition."

## Create the LVM physical volume and volume group.
#pvcreate /dev/mapper/${LUKS_VOL_NAME} 
#vgcreate ${LVM_VG_POOL_NAME} /dev/mapper/${LUKS_VOL_NAME}

## Create the swap partition.
#lvcreate -L ${SWAP_SIZE} -n ${LVM_SWAP_LV_NAME} ${LVM_VG_POOL_NAME}
#mkswap -L swap /dev/${LVM_VG_POOL_NAME}/${LVM_SWAP_LV_NAME}

#lvcreate -l ${ROOT_SIZE} -n ${LVM_ROOT_LV_NAME} ${LVM_VG_POOL_NAME}
#mkfs.ext4 -L nixos /dev/${LVM_VG_POOL_NAME}/${LVM_ROOT_LV_NAME}


