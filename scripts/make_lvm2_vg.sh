#!/bin/sh

# The name of the volume group.
NAME=""

# The list of physical volumes to add to the volume group.
PVS=()

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

  --name    The name of the volume group.

  --phy_vol A physical volume to be added to the volume group. This parameter
            can be supplied repeatedly to add all the required physical volumes.

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
    --name=*)     NAME="${1#*=}"; shift 1;;
    --phy_vol=*)  PVS+=("${1#*=}"); shift 1;;
    --help)       print_help;;
    *) echo "Invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Validate the supplied arguments.
validate_args

print_info "${LINENO}" "Creating volume group \"${NAME}\" on ${PVS[@]}"

ERR_MSG=$(vgcreate -f -y -q ${NAME} ${PVS[@]} 2>&1 >/dev/null)

check_error "${LINENO}" \
  "Failed to create volume group: ${NAME}, because:\n\n${ERR_MSG}\n\n"

exit 0
