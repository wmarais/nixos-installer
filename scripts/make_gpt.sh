#!/bin/sh

# The storage device on which the partition will be created.
DEVICE=""

# The name that will be assigned to the partition.
NAME=""

# The type of partition that will be created.
TYPE=""

# The start of the partition.
START=""

# End the of the partition.
END=""

# The password used to encrypt partition.
PASSWORD=""

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

  ./make_part.sh \\
    --device=<path to storage device> \\
    --name=<partition name> \\
    --type=<partition type> \\
    --start=<partition start> \\
    --end=<partition end> \\
    --password=<crypt password>

OPTIONS:

  --device    The storage device on which the partition will be created.

  --name      The name that the partition will be labelled with.

  --type      The partition type. This can be \"efi\", \"ext4\" or \"crypt\".  

  --start     The start of the partition in MiB, GiB or %.

  --end       The end of the partition in MiB, GiB or %.

  --password  The password to use for encryption the \"crypt\" type partition.

  --help      Print the help string for the script and exit execution without 
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

  # Check if the name is valid.
  if [ "${NAME}" == "" ]; then
    fatal_error "${LINENO}" "Please specify a partition name."
  fi

  # Check the partition type to create.
  if [ "${TYPE}" != "efi" ] && [ "${TYPE}" != "ext4" ] && \
    [ "${TYPE}" != "crypt" ]; then
    fatale_error "${LINENO}" "Invalid partition type specified: ${TYPE}."
  fi

  # Check if the password is adequate.
  if [ "${TYPE}" == "crypt" ]; then
    validate_password ${PASSWORD}
    check_error "${LINENO}" "Invalid password."
  fi 

}
################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device=*)   DEVICE="${1#*=}"; shift 1;;
    --name=*)     NAME="${1#*=}"; shift 1;;
    --type=*)     TYPE="${1#*=}"; shift 1;;
    --start=*)    START="${1#*=}"; shift 1;;
    --end=*)      END="${1#*=}"; shift 1;;
    --password=*) PASSWORD="${1#*=}"; shift 1;;
    --help)       print_help;;
    *) echo "invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root

# Validate the supplied arguments.
validate_args 

print_info "${LINENO}" "Creating partition: ${NAME} on ${DEVICE}....."

# Create the partition.
ERR_MSG=$(parted -s -a optimal ${DEVICE} mkpart ${NAME} ${START} ${END} \
  2>&1 >/dev/null)

check_error "${LINENO}" "Failed to create partition because:\n\n${ERR_MSG}\n\n"

# Wait for the partition to become available.
wait_or_die "${LINENO}" "/dev/disk/by-partlabel/${NAME}" 5

# Check what should be done with the partition.
case "${TYPE}" in
  "efi")
    print_info "${LINENO}" "Creating FAT32 filesystem for ${NAME}....."

    ERR_MSG=$(mkfs.vfat -F 32 "/dev/disk/by-partlabel/${NAME}" 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to create fat32 file system because:\n\n${ERR_MSG}\n\n"
    ;;
  "crypt")
    print_info "${LINENO}" "Encrypting ${NAME}....."

    ERR_MSG=$(echo -n ${PASSWORD} | cryptsetup --type luks1 -q luksFormat \
      "/dev/disk/by-partlabel/${NAME}" --key-file=- 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to create encrypted partition because:\n\n${ERR_MSG}\n\n"

    print_info "${LINENO}" "Opening ${NAME}....."

    ERR_MSG=$(echo -n ${PASSWORD} | cryptsetup --type luks1 -q luksOpen \
      "/dev/disk/by-partlabel/${NAME}" ${NAME} --key-file=- 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to open encrypted partition because:\n\n${ERR_MSG}\n\n"
    ;;
  "ext4")
    print_info "${LINENO}" "Creating ext4 filesystem for ${NAME}....."

    ERR_MSG=$(mkfs.ext4 -q -F "/dev/disk/by-partlabel/${NAME}" 2>&1 >/dev/null)

    check_error "${LINENO}" \
      "Failed to create ext4 file system because:\n\n${ERR_MSG}\n\n"
    ;;
esac

exit 0

# The storage medium on which the GPT partition table will be created.
DEVICE=""

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

  ./make_gpt.sh \\
    --device=<path to storage device>

OPTIONS:

  --device          The storage device on which the GPT partition table will be
                    created.

  --help            Print the help string for the script and exit execution
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
  device_exists "${DEVICE}"
  check_error "${LINENO}" "No such device: ${DEVICE}"
}
################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --device=*)         DEVICE="${1#*=}"; shift 1;;
    --help)             print_help;;
    *) echo "Invalid argument: $1, see: ${SCRIPT_NAME} --help." >&2; exit 1;;
  esac
done

# Make sure the script is executed as root.
must_be_root ${LINENO}

# Validate the supplied arguments.
validate_args 

print_info "${LINENO}" "Creating GPT partition table on $1....."

ERR_MSG=$(parted -s "${DEVICE}" mklabel gpt 2>&1)

check_error "${LINENO}" \
  "Failed to create GPT partition table on $1, because: \n\n${ERR_MSG}.\n\n"

exit 0
