#!/bin/sh

# Store the file name that will be used for error reporting.
HELPERS_FILE_NAME="hdd_setup/helpers.sh"

QUIET=false
DEBUG=false

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
