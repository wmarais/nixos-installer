#!/bin/sh

# The path to the volume.
SOURCE=""

# The mount point to mount the volume too.
DESTINATION=""

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

  ${SCRIPT_NAME} - Mount a volume to a path. (Creates the path if missing.)

USAGE:

  ./${SCRIPT_NAME} \\
    --source=<volume path> \\
    --destination=<mount path>

OPTIONS:

  --source        The source volume to be mounted.

  --destination   The location to the mount the source volume too.

  --help          Print the help string for the script and exit execution
                  without doing anything.
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
    --source=*)       SOURCE="${1#*=}"; shift 1;;
    --destination=*)  DESTINATION="${1#*=}"; shift 1;;
    --help)           print_help;;
    *) echo "Invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root "${LINENO}"

# Validate the supplied arguments.
validate_args

# Create the mount point if it does not exist.
if [ ! -d "${DESTINATION}" ]; then
  ERR=$(mkdir -p "${DESTINATION}" 2>&1 >/dev/null)
  check_error "${LINENO}" \
    "Failed to create mount path: ${DESTINATION}, because:\n\n${ERR}\n\n"
fi

# Attempt to mount the volume.
ERR=$(mount "${SOURCE}" "${DESTINATION}" 2>&1 >/dev/null)

check_error "${LINEO}" \
  "Failed to mount volume: ${SOURCE} to: ${DESTINATION}, because:\n\n${ERR}\n\n"

exit 0
