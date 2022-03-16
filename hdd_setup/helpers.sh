#!/bin/sh

# Store the file name that will be used for error reporting.
HELPERS_FILE_NAME="hdd_setup/helpers.sh"

QUIET=false
DEBUG=false

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

  print_info "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Creating partition: ${NAME} on ${HDD}....."

  # Create the partition.
  parted -s -a optimal ${HDD} mkpart ${NAME} ${START} ${END}

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Failed to create partition."

  # Wait for the parition to become available.
  wait_or_die "${HELPERS_FILE_NAME}" "${LINENO}" "/dev/disk/by-partlabel/${NAME}" 5

  # Check what should be done with the partition.
  case "${TYPE}" in
    "efi")
      print_info "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Creating FAT32 filesystem for ${NAME}....."

      mkfs.vfat -F 32 "/dev/disk/by-partlabel/${NAME}" >/dev/null 2>&1

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to create fat32 file system."
      ;;
    "crypt")
      print_info "${HELPERS_FILE_NAME}" "${LINENO}" "Encrypting ${NAME}....."

      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksFormat \
        "/dev/disk/by-partlabel/${NAME}" --key-file=-

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to create encrypted partition."

      print_info "${HELPERS_FILE_NAME}" "${LINENO}" "Opening ${NAME}....."

      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksOpen \
        "/dev/disk/by-partlabel/${NAME}" ${NAME} --key-file=-

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to open encrypted partition."
      ;;
    *)
      print_info "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Creating ext4 filesystem for ${NAME}....."

      mkfs.ext4 -q -F "/dev/disk/by-partlabel/${NAME}" >/dev/null 2>&1

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to create ext4 file system."
      ;;
  esac
}

################################################################################
# Create a Physical Volume that can be used in an LVM Volume Group.
################################################################################
make_pv()
{
  HDD=$1

  print_info "${HELPERS_FILE_NAME}" \
    "${LINENO}" "Creating LVM physical volume on ${HDD}."

  ERR=$(pvcreate -f -y -q ${HDD} 2>&1)

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Failed to create physical volume: ${HDD_NAME}, because: \n\n${ERR}"
}

################################################################################
# Create a Volume Group from the array of Physical Volumes.
################################################################################
make_vg()
{
  VG_NAME=$1
  shift
  PV=("$@")

  print_info "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Creating volume group \"${VG_NAME}\" on ${PV[@]}"

  ERR=$(vgcreate -f -y -q ${VG_NAME} ${PV[@]} 2>&1)

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Failed to create volume group: ${VG_NAME}, because: \n\n${ERR}"
}

################################################################################
# Create a logical volume on the specific volume group.
################################################################################
make_lv()
{
  LV_NAME=$1
  VG_NAME=$2
  FS_TYPE=$3
  LV_SIZE=$4

  print_info "${HELPERS_FILE_NAME}" "${LINENO}"\
    "Creating logical volume \"${LV_NAME}\" on \"${VG_NAME}\"....."

  if [[ "${LV_SIZE}" == *"%"* ]]; then
    ERR=$(lvcreate -q -y -l ${LV_SIZE} -n ${LV_NAME} ${VG_NAME} 2>&1)
  else
    ERR=$(lvcreate -q -y -L ${LV_SIZE} -n ${LV_NAME} ${VG_NAME} 2>&1)
  fi

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Failed to create logical volume: ${LV_NAME}, because:\n\n${ERR}"

  # Check the required file system.
  case "${FS_TYPE}" in
    "swap")
      ERR=$(mkswap "/dev/${VG_NAME}/${LV_NAME}" 2>&1)

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to create swap file system, because:\n\n${ERR}"

      ERR=$(swapon "/dev/${VG_NAME}/${LV_NAME}" 2>&1)

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to enable swap, because: \n\n${ERR}"
      ;;
    *)
      ERR=$(mkfs.ext4 "/dev/${VG_NAME}/${LV_NAME}" 2>&1)

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
        "Failed to create ext4 file system, because:\n\n${ERR}"
      ;;
  esac
}

################################################################################
# Mount the specified path to the specified destination.
################################################################################
mount_part()
{
  SRC_PATH=$1
  DST_PATH=$2

  mkdir -p ${DST_PATH}
  mount ${SRC_PATH} ${DST_PATH}

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINEO}" \
    "Failed to mount partition."
}
