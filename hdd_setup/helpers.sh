#!/bin/sh

fatal_error() 
{
  echo "FATAL | $1 | $2" >&2
  exit 1
}

check_error() 
{
  if [ $? -ne 0 ]; then
    fatal_error $1 $2
  fi
}

must_be_root()
{
  if [ ${EUID} -ne 0 ]; then
    fatal_error $1 "The script must be executed as root."
  fi
}

print_info()
{
  echo "INFO | $1 | $2" >&1
}

make_gpt()
{
  echo "Creating GPT partition table on $1....."
  parted -s $1 mklabel gpt
  check_error ${LINENO} "Failed to create GPT partition table on $1."
}

################################################################################
#
################################################################################
make_part()
{
  # The HDD that the partition will be created on.
  HDD=$1

  # The filesystem that the partition will be formatted too. This only support
  # the three partition types that is used to implement the installation
  # startegy. These are:
  #   efi   - The EFI partition.
  #   lvm   - LVM physical volume.
  #   crypt - Encrypted partition.
  #   boot  - Boot partition.
  # All other partitions such as the root and swap partitions are created as
  # LVM logical volumes and thus there are no supported "ext*" or "swap" type.
  TYPE=$2
  
  # The name of the partition. This will make the disk appear in  
  # /dev/disk/by-label/${NAME} which makes it easier to reference when the
  # partition layout changes. (I.e. no dependency on exact partition numbers.)
  NAME=$3

  # The boundary of the partition. Since things tend to work better when the
  # boundaries align to 2^N, use the MiB and GiB notations for explicit sizes.
  # It is also possible to use % to specify the boundaries. I.e. it is common
  # to use END=100% for the last partition to use all remaining disk space.
  START=$4
  END=$5

  # The password to use for encrypting the partition. This is only used when
  # the ${TYPE} is "crypt". The password is only cached in RAM for the duration
  # of installation and is not written to ROM at any point.
  PASSWD=$6

  # Create the partition.
  parted -s -a optimal mkpart ${HDD} ${NAME} ${START} ${END}
  check_error ${LINENO} "Failed to create partition."

  # Set the name of the partition.
  #parted -s name ${HDD}${NUM} ${NAME}
  #check_error ${LINENO} "Failed to set partition name."

  # Check what should be done with the partition.
  case "${TYPE}" in
    "efi")
      mkfs.vfat -F 32 "/dev/disk/by-label/${NAME}"
      ;;
    "crypt")
      cryptsetup --type luks1 -q luksFormat "/dev/disk/by-label/${NAME}" \
        ${PASSWD}
      check_error ${LINENO} "Failed to create encrypted partition."

      cryptsetup --type luks1 -q luksOpen "/dev/disk/by-label/${NAME}" \
        ${NAME} ${PASSWD}
      check_error ${LINENO} "Failed to open encrypted partition."
      ;;
    "lvm")
      pvcreate "/dev/disk/by-label/${NAME}"
      ;;
    *)
      mkfs.ext4 "/dev/disk/by-label/${NAME}"
      ;;
  esac
}

################################################################################
# Create a Volume Group from the array of Physical Volumes.
################################################################################
make_vg()
{
  VG_NAME=$1
  shift
  PHYSICAL_VOLUMES=("$@")

  vgcreate ${VG_NAME} ${PHYSICAL_VOLUMES[@]}
  check_error ${LINENO} "Failed to create volume group: ${VG_NAME}."
}

################################################################################
# 
################################################################################
make_lv()
{
  LV_NAME=$1
  VG_NAME=$2
  FS_TYPE=$3
  LV_SIZE=$4

  lvcreate -L ${LV_SIZE} -n ${LV_NAME} ${VG_NAME}
  check_error ${LINENO} "Failed to create logical volume: ${LV_NAME}."

  # Check the required file system.
  case "${FS_TYPE}" in
    "swap")
      mkswap "/dev/${VG_NAME}/${LV_NAME}"
      check_error ${LINENO} "Failed to create swap file system."
      ;;
    *)
      mkfs.ext4 "/dev/${VG_NAME}/${LV_NAME}"
      check_error ${LINENO} "Failed to create ext4 file system."
      ;;
  esac
}

################################################################################
# 
################################################################################
mount_part()
{
  SRC_PATH=$1
  DST_PATH=$2

  mkdir -p ${DST_PATH}
  mount ${SRC_PATH} ${DST_PATH}
  check_error ${LINENO} "Failed to mount partition."
}
