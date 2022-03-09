#!/bin/sh

# Store the file name that will be used for error reporting.
HELPERS_FILE_NAME="hdd_setup/helpers.sh"

QUIET=false
DEBUG=true

################################################################################
# Print a fatal error message.
################################################################################
fatal_error() 
{
  # The file in which the error occured.
  FILE_NAME="$1"

  # The line on which the check was performed.
  LINE_NUM="$2"

  # The message associated with the error.
  MESSAGE="$3"

  # Print the error message to cerr.
  echo -e "FATAL | ${FILE_NAME} | ${LINE_NUM} | ${MESSAGE}" >&2

  # Exit out of the script.
  exit 1
}

################################################################################
# Check if the previous call generated an error.
################################################################################
check_error() 
{
  # The value returned by the command.
  RET_CODE="$1"

  # The file in which the function is called.
  FILE_NAME="$2"

  # The line on which the function was called.
  LINE_NUM="$3"

  # The message to print if the error was fatal.
  MESSAGE="$4"

  # Check if the previous call produced a non zero return code (an error).
  if [ "${RET_CODE}" -ne "0" ]; then
    fatal_error "${FILE_NAME}" "${LINE_NUM}" "${MESSAGE}"
  fi
  
  return 0
}

################################################################################
# Print and information message to cout.
################################################################################
print_info()
{
  # The file in which the function is called.
  FILE_NAME="$1"

  # The line on which the function was called.
  LINE_NUM="$2"

  # The message to print if the error was fatal.
  MESSAGE="$3"

  # Only print the message if the script is not told to be quiet.
  if [ "${DEBUG}" == "true" ]; then
    echo "INFO  | ${FILE_NAME} | ${LINE_NUM} | ${MESSAGE}" >&1  
  elif [ "${QUIET}" = "false" ]; then
    echo "${MESSAGE}" >&1
  fi

  return 0
}

################################################################################
# Wait for the specified file to become available or time out / exit.
################################################################################
wait_or_die()
{
  # The file where the function is called from.
  FILE_NAME=$1

  # The line number on which the call was made.
  LINE_NUM=$2

  # The file to wait on.
  FILE_PATH=$3

  # The number of seconds / retries to wait for.
  MAX_RETRIES=$4

  # The current number of retries.
  TRY_COUNT=0
  
  # Keep waiting for the file to become available until the timeout period
  # expires.
  while [[ ! -f "${FILE_PATH}" && ! -L "${FILE_PATH}" ]]; do

    print_info "${FILE_NAME}" "${LINENO}" \
      "Waiting for device ${FILE_PATH} to become available ....."

    # Sleep for a second before trying again.
    sleep 1

    # Check if there are more time to retry.
    if [ "${TRY_COUNT}" -ge "${MAX_RETRIES}" ]; then
      break
    fi

    # Increment the retry counter.
    TRY_COUNT=$((TRY_COUNT+1))
  done

    # Check if there are more time to retry.
  if [ "${TRY_COUNT}" -ge "${MAX_RETRIES}" ]; then
    return 1
  fi

  return 0
}

################################################################################
# Check whether the script is execute as root. If not exit.
################################################################################
must_be_root()
{
  # Check if the current USER ID is 0 which indicates that the script is
  # executed as root.
  if [ "${EUID}" -ne "0" ]; then
    fatal_error "${HELPERS_FILE_NAME}" "${LINENO}" \
      "The script must be executed as root."
  fi
}

################################################################################
# Create a GPT partition table on the specified HDD.
################################################################################
make_gpt()
{
  # The harddrive to create the partition table on.
  HDD=$1

  print_info "${HELPERS_FILE_NAME}" "${LINENO}" \
    "Creating GPT partition table on $1....."

  # Tell parted to create the partition table.
  MSG=$(parted -s "${HDD}" mklabel gpt 2>&1)

  check_error "$?" "${HELPERS_FILE_NAME}" "${LINENO}" \
     "Failed to create GPT partition table on $1, because: \n\n${MSG}."
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

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINEO}" \
        "Failed to create fat32 file system."
      ;;
    "crypt")
      print_info "${HELPERS_FILE_NAME}" "${LINEO}" "Encrypting ${NAME}....."

      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksFormat \
        "/dev/disk/by-partlabel/${NAME}" --key-file=-

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINEO}" \
        "Failed to create encrypted partition."

      print_info "${HELPERS_FILE_NAME}" "${LINEO}" "Opening ${NAME}....."

      echo -n ${PASSWD} | cryptsetup --type luks1 -q luksOpen \
        "/dev/disk/by-partlabel/${NAME}" ${NAME} --key-file=-

      check_error "$?" "${HELPERS_FILE_NAME}" "${LINEO}" \
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
