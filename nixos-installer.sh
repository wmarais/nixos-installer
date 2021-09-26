#!/bin/sh

HDD=/dev/sda


EFI_PART_NUM=1
EFI_PART_NAME=EFI
EFI_PART_TYPE=EPS
EFI_PART_FS=vfat
EFI_PART_START=1MiB
EFI_PART_END=512MiB

BOOT_PART_NUM=2
BOOT_PART_NAME=boot
BOOT_PART_TYPE=primary
BOOT_PART_FS=ext4
BOOT_PART_START=513MiB
BOOT_PART_END=1024MiB

LUKS_PART_NUM=3
LUKS_PART_NAME=luks
LUKS_PART_TYPE=primary
LUKS_PART_FS=ext4
LUKS_PART_START=1025MiB
LUKS_PART_END=100%

LVM_PV_NAME=syspv
LVM_VG_NAME=sysvg

LVM_SWAP_LV_NAME=swaplv
SWAP_FS=swap
SWAP_SIZE=2G

LVM_ROOT_LV_NAME=rootlv
ROOT_FS=ext4
ROOT_SIZE=100%FREE


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
	parted -s $1 mklabel gpt
	check_error "Line($LINENO): Failed to create partition table on $1."
}

################################################################################
# Set the name of the partition, where:
#
#		$1 = Hard Drive Path
#  	$2 = Partition Number
#  	$3 = Partition Name
################################################################################
set_partition_name() {
	parted -s $1 name $2 $3
	check_error "Line($LINENO): Failed to set name of $1$2 to $3"
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
	check_error "Line($LINENO): Failed to create partition: Path=$1/$2, Name=$3, Type=$4, FS=$5, Start=$6, End=$7"
	
	set_partition_name $1 $2 $3
	
	if [ "$4" == "EPS" ]; then
		mke2fs -t vfat -L $3 $1$2
		check_error "Line($LINENO): Failed to create filesystem of type: $5, and name:$3, on $1$2."
		parted -s $1 set $2 esp on
		check_error "Line($LINENO): Failed to set the esp flag on the EFI partition."
	else
		# Create the file system for the partition.
		mke2fs -t ${5} -L $3 $1$2
		check_error "Line($LINENO): Failed to create filesystem of type: $5, and name:$3, on $1$2."
	fi
}

################################################################################
#
#		$1 = Hard Drive Path
#		$2 = Partition Number
#   $3 = 
################################################################################
setup_encryption() {
	cryptsetup --type luks1 -q luksFormat $1$2
	check_error "Line($LINENO): Failed to format encrypted partition."

	cryptsetup --type luks1 -q luksOpen $1$2 $3
	check_error "Line($LINENO): Failed to open encrypted partition."
}

#		$1 = Partition Name
#		$2 = Volume Group Name
setup_lvm() {
	# Create the volume group.
	pvcreate /dev/mapper/$1
	vgcreate $2 /dev/mapper/$1
}

# 	$1 = VG Name
#		$2 = LV Name
#		$3 = Size

################################################################################
#		$1 = Volume Group Name
#		$2 = Logical Volume Name
# 	$3 = Logical Volume Size
#		$4 = Logical Volume File System
create_lv() {
	if [[ "$3" == *"%"* ]]; then
		lvcreate -l $3 -n $2 $1
	else
		lvcreate -L $3 -n $2 $1
	fi
	
	check_error "Line($LINENO): Failed to create logical volume: VG Name=$1, LV Name=$2, LV Size=$3, LV FS=$4"
	
	if [ ${4} == "swap" ]; then
		mkswap -L $2 /dev/$1/$2
	else
		mke2fs -t ${4} -L $2 /dev/$1/$2
	fi
	
	check_error "Line($LINENO): Failed to LV file system: VG Name=$1, LV Name=$2, LV Size=$3, LV FS=$4"
}

################################################################################
# Create a new GPT partition.
create_partition_table ${HDD}

# Create and configure the EFI partition.
create_partition ${HDD} ${EFI_PART_NUM} ${EFI_PART_NAME} ${EFI_PART_TYPE} \
	${EFI_PART_FS} ${EFI_PART_START} ${EFI_PART_END}
	
# Create and configure the EFI partition.
create_partition ${HDD} ${BOOT_PART_NUM} ${BOOT_PART_NAME} ${BOOT_PART_TYPE} \
	${BOOT_PART_FS} ${BOOT_PART_START} ${BOOT_PART_END}

# Create the LUKS partition.
create_partition ${HDD} ${LUKS_PART_NUM} ${LUKS_PART_NAME} ${LUKS_PART_TYPE} \
	${LUKS_PART_FS} ${LUKS_PART_START} ${LUKS_PART_END}

# Setup the encrypted partition.
setup_encryption ${HDD} ${LUKS_PART_NUM} ${LUKS_PART_NAME}

# Setup LVM and the logical volume for Swap and /root.
setup_lvm ${LUKS_PART_NAME} ${LVM_VG_NAME}
create_lv ${LVM_VG_NAME} ${LVM_SWAP_LV_NAME} ${SWAP_SIZE} ${SWAP_FS}
create_lv ${LVM_VG_NAME} ${LVM_ROOT_LV_NAME} ${ROOT_SIZE} ${ROOT_FS}

# Wait for the LVMs to become available.
while [ ! -e /dev/disk/by-label/${LVM_ROOT_LV_NAME} ]; do
	echo "Line($LINENO): Waiting for /dev/disk/by-label/${LVM_ROOT_LV_NAME} to become available....."
	sleep 1s
done

# Mount the partions for installation.
mount /dev/disk/by-label/${LVM_ROOT_LV_NAME} /mnt
check_error "Line($LINENO): Failed to mount: /dev/disk/by-label/${LVM_ROOT_LV_NAME} to /mnt."

mkdir -p /mnt/boot
mount /dev/sda2 /mnt/boot
check_error "Line($LINENO): Failed to mount: /dev/sda2 to /mnt/boot."

mkdir -p /mnt/boot/efi
mount /dev/disk/by-partlabel/${EFI_PART_NAME} /mnt/boot/efi
check_error "Line($LINENO): Failed to mount: /dev/disk/by-partlabel/${EFI_PART_NAME} to /mnt/boot/efi."

# Create the configurations files.
mkdir -p /mnt/etc/nixos
cp configuration.nix /mnt/etc/nixos/
cp hardware-configuration.nix /mnt/etc/nixos/

# Run the nixos installer.
nixos-install

