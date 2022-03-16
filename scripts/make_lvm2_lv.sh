#!/bin/sh

# The name of the logical volume.
LV_NAME=""

# The name of the volume group to create the logical volume on.
VG_NAME=""

# The file system of the logical volume.
FS_TYPE=""

# The size of the logical volume.
LV_SIZE=""

# Get the name of the script to use in the help command.
SCRIPT_NAME=$(basename  "$0")

# Load the helper function library.
. $(dirname "$0")/func_lib.sh

################################################################################
# The help message that will be displayed when the user type --help as an
# argument to the script.
################################################################################
HELP_STR="\
NAME:

  ${SCRIPT_NAME} - a script to generate a new GPT partition table on a nominated
             storage device.

USAGE:

  ./${SCRIPT_NAME} \\
    --device=<path to storage device>

OPTIONS:

  --vg-name
  --lv-name
  --lv-size
  --fs-type

  --help    Print the help string for the script and exit execution without 
            doing anything.
"

################################################################################
# Print the help information for the script.
################################################################################
print_help() {
  echo "${HELP_STR}"

  # Return an error code so that any other script that uses this script will
  # accidentally call --help and thing that the script actually executed.
  exit 1;
}

################################################################################
# Check that the user supplied arguments are valid before trying to execute
# the script.
################################################################################
validate_args()
{
  # Check if the specified HDD exists.
  #device_exists "${DEVICE}"
  #check_error "${LINENO}" "No such device: ${DEVICE}"
}
################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --vg-name=*)  VG_NAME="${1#*=}"; shift 1;;
    --lv-name=*)  LV_NAME="${1#*=}"; shift 1;;
    --fs-type=*)  FS_TYPE="${1#*=}"; shift 1;;
    --lv-size=*)  LV_SIZE="${1#*=}"; shift 1;;
    --help)       print_help;;
    *) echo "Invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Validate the supplied arguments.
validate_args

print_info "${LINENO}"\
  "Creating logical volume \"${LV_NAME}\" on \"${VG_NAME}\"....."

if [[ "${LV_SIZE}" == *"%"* ]]; then
  ERR=$(lvcreate -q -y -l ${LV_SIZE} -n ${LV_NAME} ${VG_NAME} 2>&1 >/dev/null)
else
  ERR=$(lvcreate -q -y -L ${LV_SIZE} -n ${LV_NAME} ${VG_NAME} 2>&1 >/dev/null)
fi

check_error "${LINENO}" \
  "Failed to create logical volume: ${LV_NAME}, because:\n\n${ERR}\n\n"

# Check the required file system.
case "${FS_TYPE}" in
  "swap")
    ERR=$(mkswap "/dev/${VG_NAME}/${LV_NAME}" 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to create swap file system, because:\n\n${ERR}\n\n"

    ERR=$(swapon "/dev/${VG_NAME}/${LV_NAME}" 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to enable swap, because: \n\n${ERR}\n\n"
    ;;
  *)
    ERR=$(mkfs.ext4 "/dev/${VG_NAME}/${LV_NAME}" 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to create ext4 file system, because:\n\n${ERR}\n\n"
    ;;
esac

exit 0
