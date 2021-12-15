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

wait_or_die()
{
  FILE_NAME=$1
  MAX_RETRIES=$2

  TRY_COUNT=0
  
  while [[ ! -f ${FILE_NAME} && ! -L ${FILE_NAME} ]]; do
    echo "Waiting for device ${FILE_NAME} to become available ....."
    sleep 1s
    if [ "${TRY_COUNT}" -ge "${MAX_RETRIES}" ]; then
      fatal_error ${LINENO} "Timed out waiting for ${FILE_NAME}."
    fi
    TRY_COUNT=$((TRY_COUNT+1))
  done
}

################################################################################
#
################################################################################
make_part()
{
  # The HDD that the partition will be created on.
  HDD=$1

  # The name of the partition. This will make the disk appear in  
  # /dev/disk/by-label/${NAME} which makes it easier to reference when the
  # partition layout changes. (I.e. no dependency on exact partition numbers.)
  NAME=$2

  # The filesystem that the partition will be formatted too. This only support
  # the three partition types that is used to implement the installation
  # startegy. These are:
  #   efi   - The EFI partition.
  #   lvm   - LVM physical volume.
  #   crypt - Encrypted partition.
  #   boot  - Boot partition.
  # All other partitions such as the root and swap partitions are created as
  # LVM logical volumes and thus there are no supported "ext*" or "swap" type.
  TYPE=$3

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

  echo "Creating partition: ${NAME} on ${HDD}....."

  # Create the partition.
  parted -s -a optimal ${HDD} mkpart ${NAME} ${START} ${END}
  check_error ${LINENO} "Failed to create partition."

  # Wait for the parition to become available.
  wait_or_die "/dev/disk/by-partlabel/${NAME}" 5

  # Set the name of the partition.
  #parted -s name ${HDD}${NUM} ${NAME}
  #check_error ${LINENO} "Failed to set partition name."

  # Check what should be done with the partition.
  case "${TYPE}" in
    "efi")
      echo "Creating FAT32 filesystem for ${NAME}....."
      mkfs.vfat -F 32 "/dev/disk/by-partlabel/${NAME}"
      ;;
    "crypt")
      echo "Encrypting ${NAME}....."
      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksFormat \
        "/dev/disk/by-partlabel/${NAME}" --key-file=-
      check_error ${LINENO} "Failed to create encrypted partition."

      echo "Opening ${NAME}....."
      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksOpen \
        "/dev/disk/by-partlabel/${NAME}" ${NAME} --key-file=-
      check_error ${LINENO} "Failed to open encrypted partition."
      ;;
    "lvm")
      echo "Making ${NAME} an LVM physical volume....."
      wait_or_die "/dev/disk/by-partlabel/${NAME}"
      pvcreate -ff "/dev/disk/by-partlabel/${NAME}"
      check_error ${LINENO} "Failed to create LVM physical volume."
      ;;
    *)
      echo "Creating ext4 filesystem for ${NAME}....."
      mkfs.ext4 "/dev/disk/by-partlabel/${NAME}"
      ;;
  esac
}

make_pv()
{
  HDD=$1
  pvcreate -ff ${HDD}
  check_error ${LINENO} "Failed to create physical volume: ${HDD_NAME}."
}

################################################################################
# Create a Volume Group from the array of Physical Volumes.
################################################################################
make_vg()
{
  VG_NAME=$1
  shift
  PV=("$@")

  echo "Creating volume group \"${VG_NAME}\" on ${PV[@]}"

  vgcreate ${VG_NAME} ${PV[@]}
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

  echo "Creating logical volume \"${LV_NAME}\" on \"${VG_NAME}\"....."
  if [[ "${LV_SIZE}" == *"%"* ]]; then
    lvcreate -l ${LV_SIZE} -n ${LV_NAME} ${VG_NAME}
  else
    lvcreate -L ${LV_SIZE} -n ${LV_NAME} ${VG_NAME}
  fi
  check_error ${LINENO} "Failed to create logical volume: ${LV_NAME}."

  # Check the required file system.
  case "${FS_TYPE}" in
    "swap")
      mkswap "/dev/${VG_NAME}/${LV_NAME}"
      check_error ${LINENO} "Failed to create swap file system."
      swapon "/dev/${VG_NAME}/${LV_NAME}"
      check_error ${LINENO} "Failed to enable swap."
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
