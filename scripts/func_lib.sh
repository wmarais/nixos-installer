#!/bin/sh
################################################################################
# This is general purpose function library used to do things like check for
# errors after function calls etc. To use it, include it into your script using
# the following command:
#
#  . $(dirname "$0")/scripts/func_lib.sh
#
# NOTE:
#   1. This assumes your script is located one level up from this scripts 
#      folder.
#   2. The '.' is critical for this to work as it executes the function within
#      the same shell as your script. If you don't do this, the error detecting
#      functions will not terminate the script upon error etc.
#
################################################################################
# The name of the script that these functions are called from within.
SCRIPT_NAME=$(basename "$0")

################################################################################
# Check if the specified device (/dev/...) exists.
################################################################################
device_exists()
{
  # Get the name of the file.
  local DEV_PATH="$1"

  # Check if the device file is missing.
  if [ "${DEV_PATH}" == "" ] || [ ! -e "${DEV_PATH}" ]; then
    return 1
  fi

  # The file exists.
  return 0
}

################################################################################
# Print a fatal error message.
################################################################################
fatal_error()
{
  # The line on which the check was performed.
  local LINE_NUM="$1"

  # The message associated with the error.
  local MESSAGE="$2"

  # Print the error message to cerr.
  echo -e "FATAL | ${SCRIPT_NAME} | ${LINE_NUM} | ${MESSAGE}" >&2

  # Exit out of the script.
  exit 1
}

################################################################################
# Check if the previous call generated an error.
################################################################################
check_error()
{
  # The return code of the preceeding call. Must be saved before doing anything
  # else that will overwrite it.
  RET_CODE="$?"

  # The line on which the function was called.
  local LINE_NUM="$1"

  # The message to print if the error was fatal.
  local MESSAGE="$2"

  # Check if the previous call produced a non zero return code (an error).
  if [ "${RET_CODE}" != "0" ]; then
    fatal_error "${LINE_NUM}" "${MESSAGE}"
  fi

  # No error occurred.
  return 0
}

################################################################################
# Check whether the script is execute as root. If not exit.
################################################################################
must_be_root()
{
  # The line on which the check is performed.
  local LINE_NUM="$1"

  # Check if the current USER ID is 0 which indicates that the script is
  # executed as root.
  if [ "${EUID}" -ne "0" ]; then
    fatal_error "${LINENO}" "The script must be executed as root."
  fi
}

################################################################################
# Print and information message to cout.
################################################################################
print_info()
{
  # The line on which the function was called.
  local LINE_NUM="$1"

  # The message to print if the error was fatal.
  local MESSAGE="$2"

  # Only print the message if the script is not told to be quiet.
  if [ "${DEBUG}" == "true" ]; then
    echo "INFO  | ${SCRIPT_NAME} | ${LINE_NUM} | ${MESSAGE}" >&1  
  elif [ "${QUIET}" = "false" ]; then
    echo "${MESSAGE}" >&1
  fi

  # No error occurred.
  return 0
}

disk_exists()
{
  local DISK="$1"
  if [ -e "${DISK}" ]; then
    return 0
  fi
  return 1
}

################################################################################
# Wait for the specified file to become available or time out / exit.
################################################################################
wait_or_die()
{
  # The line number on which the call was made.
  local LINE_NUM=$1

  # The device to wait on.
  local DEVICE=$2

  # The number of seconds / retries to wait for.
  local MAX_RETRIES=$3

  # The current number of retries.
  local TRY_COUNT=0

  # Keep waiting for the file to become available until the timeout period
  # expires.
  while [ ! -e "${DEVICE}" ]; do

    print_info "${LINENO}" \
      "Waiting for device ${DEVICE} to become available ....."

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
# Check that the user name is valid by check if it matches POSIX user name
# regex and length such that: 1 >= length <= 32 characters.
################################################################################
validate_user_or_group_name() {
  # The user or group name to check.
  local NAME="$1"

  if [[ "${NAME}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
    return 0
  fi

  return 1
}

################################################################################
# Validate the password.
#  1. Min 12 Chars Long.
#  2. At least one lower case, one upper case and one special character.
#  3. <>`"'~ are not allowed.
#  4. Order does not matter.
################################################################################
validate_password () {
  # The password string.
  local PASSWORD="$1"

  # The special characters to avoid in the password.
  local AVOID='[<>`"'"'"'~]'

  # Check if the password is valid
  [ "${#1}" -ge 12 ] &&
  [[ $1 =~ [[:upper:]] ]] &&
  [[ $1 =~ [[:lower:]] ]] &&
  [[ $1 =~ [[:digit:]] ]] &&
  [[ $1 =~ [[:punct:]] ]] &&
  [[ ! $1 =~ $AVOID ]]
}

################################################################################
# Validate an array of group names.
################################################################################
validate_groups() {
  # The groups to check.
  shift
  local NI_GROUPS=("$@")

  # Validate each group name.
  for NAME in "${NI_GROUPS[@]}"; do
    validate_user_or_group_name "${NAME}"
    if [ "$?" != "0" ]; then
      return 1
    fi
  done

  # All group names passed.
  return 0
}

################################################################################
# Converts an input valid to a MiB value. It does not append the MiB string
# suffix so that the output value can be used in an expr.
################################################################################
to_mib() {
  # Strip leading and trailing white spaces.
  NI_STR_IN=$(echo $1 | sed -e "s|^[[:space:]]*||" -e "s|[[:space:]]*$||")

  # Check if the value is specified in MiB
  local VALUE=$(echo "${NI_STR_IN}" | sed -n "s|MiB$||p")
  
  if [ "${VALUE}" != "" ]; then
    echo "${VALUE}" >&1
    return "$?"
  fi

    # Check if the value is specified in MiB
  local VALUE=$(echo "${NI_STR_IN}" | sed -n "s|MB$||p")
  
  if [ "${VALUE}" != "" ]; then
    echo echo "$(expr ${VALUE} \* 1000 / 1024)" >&1
    return "$?"
  fi

  # Check if the value is specified in GiB.
  VALUE=$(echo "${NI_STR_IN}" | sed -n "s|GiB$||p")

  if [ "${VALUE}" != "" ]; then
    echo "$(expr ${VALUE} \* 1024)" >&1
    return "$?"
  fi

  # Check if the value is specified in GB.
  VALUE=$(echo "${NI_STR_IN}" | sed -n "s|GB$||p")

  if [ "${VALUE}" != "" ]; then
    echo "$(expr ${VALUE} \* 1000)" >&1
    return "$?"
  fi

  # Check if the value specified in %.
  VALUE=$(echo "${NI_STR_IN}" | sed -n "s|%$||p")
  if [ "${VALUE}" != "" ]; then
    # The maximum size of the volume.
    local MAX_SIZE=$(to_mib "$2" "0" "0")

    echo "$(expr ${VALUE} / 100 \* ${MAX_SIZE})" >&1
    return "$?"
  fi

  # Check if the value specified is as %FREE.
  VALUE=$(echo "${NI_STR_IN}" | sed -n "s|%FREE$||p")
  if [ "${VALUE}" != "" ]; then
    # The remaining size of the volume (empty space).
    local REMAINING_SIZE=$(to_mib "$3" "0" "0")

    echo "$(expr ${VALUE} / 100 \* ${REMAINING_SIZE})" >&1
    return "$?"
  fi

  # The supplied value was not in any of the known formats.
  return 1
}

add_size() {
  # Extract the components of the additions as "${LHS} + ${RHS}".
  local LHS="$1"
  local RHS="$2"
  local MAXIMUM_SIZE="$3"
  local REMAINING_SIZE="$4"

  # Convert both sizes to MiB.
  LHS=$(to_mib ${LHS} ${MAXIMUM_SIZE} ${REMAINING_SIZE})
  RHS=$(to_mib ${RHS} ${MAXIMUM_SIZE} ${REMAINING_SIZE})

  # Calculate and return the size of the addition.
  echo "$(expr ${LHS} + ${RHS})MiB" >&1
}

subtract_size() {
  # Extract the components of the subtraction as "${LHS} - ${RHS}".
  local LHS="$1"
  local RHS="$2"
  local MAXIMUM_SIZE="$3"
  local REMAINING_SIZE="$4"

  # Convert both sizes to MiB.
  LHS=$(to_mib ${LHS} ${MAXIMUM_SIZE} ${REMAINING_SIZE})
  RHS=$(to_mib ${RHS} ${MAXIMUM_SIZE} ${REMAINING_SIZE})

  # Calculate and return the size of the addition.
  echo "$(expr ${LHS} - ${RHS})MiB" >&1
}

################################################################################
# Calculate the end of the partition in MiB. This is used for when the user
# specify a size in %.
################################################################################
calc_part_end()
{
  DISK_SIZE=$3
  DISK_REMAINING=$4

  PART_START=$(to_mib $1 ${DISK_SIZE} ${DISK_REMAINING})
  PART_SIZE=$(to_mib $2 ${DISK_SIZE} ${DISK_REMAINING})

  echo "$(expr ${PART_START} + ${PART_SIZE})MiB"
}

calc_remaining() 
{
  local NI_DISK_SIZE="$1"
  local NI_PART_END="$2"




}

################################################################################
# Determine the true start of the partition.
################################################################################
part_start() {
  local PARTITION="$1"
  local PART_START=$(parted ${PARTITION} print | sed -n "s|^ *[0-9]||p" \
    | awk '{print $1}')
  
  echo "$(to_mib ${PART_START})MiB"
}

################################################################################
# Determine the true end of the partition.
################################################################################
part_end() {
  local PARTITION="$1"
  local PART_END=$(parted ${PARTITION} print | sed -n "s|^ *[0-9]||p" \
    | awk '{print $2}')

  echo "$(to_mib ${PART_END})MiB"
}

################################################################################
# Calculate the size of the Disk in MiB.
################################################################################
size_of_disk() {
  local DISK=$1

  local SIZE=$(parted ${DISK} print | sed -n "s|Disk ${DISK}: ||p")
  if [ "$?" != "0" ]; then
    return 1
  fi

  echo "$(to_mib ${SIZE})MiB"
  return $?
}


################################################################################
# Validate the specified file path by checking if the directory and file exists
# or whether it can be created.
#
#   1. Check if the directory exists.
#     1.1. If not, create it.
#   2. Check if a writeable file exists.
#     2.1. If not, create it.
################################################################################
validate_file_path() {
  # The full file path.
  local FILE_PATH="$1"

  # Extract the directory portion only.
  local DIRECTORY=$(dirname "${FILE_PATH}")

  if [ "${FILE_PATH}" == "" ]; then
    return 1;
  fi

  # Check if the directory exist.
  if [ ! -d "${DIRECTORY}" ]; then
    # If not, try to create it.
    mkdir -p "${DIRECTORY}"
    if [ "$?" != "0" ]; then
      return 1
    fi
  fi

  # Check if the file exist.
  if [ ! -w "${FILE_PATH}" ]; then
    # If not, try to create it.
    touch "${FILE_PATH}"
    if [ "$?" != "0" ]; then
      return 1
    fi
  fi

  # All validation passed.
  return 0
}

