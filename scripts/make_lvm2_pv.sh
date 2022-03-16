#!/bin/sh

# The storage medium on which the GPT partition table will be created.
DEVICE=""

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

  make_gpt - a script to generate a new GPT partition table on a nominated
             storage device.

USAGE:

  ./make_lvm2_pv.sh \\
    --device=<path to storage device>

OPTIONS:

  --device  The storage device on which the LVM2 physical volume will be
            created. This can be a hard-drive, partition or crypto volume.

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
  device_exists "${DEVICE}"
  check_error "${LINENO}" "No such device: ${DEVICE}"
}
################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device=*)   DEVICE="${1#*=}"; shift 1;;
    --help)       print_help;;
    *) echo "Invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Validate the supplied arguments.
validate_args

print_info "${LINENO}" "Creating LVM physical volume on ${DEVICE}."

ERR_MSG=$(pvcreate -f -y -q ${DEVICE} 2>&1 >/dev/null)

check_error "${LINENO}" \
  "Failed to create physical volume: ${DEVICE}, because:\n\n${ERR_MSG}\n\n"

exit 0
