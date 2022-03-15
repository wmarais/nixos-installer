#!/bin/sh
################################################################################
# This is general purpose function library used to do things like check for
# errors after function calls etc. To use it, include it into your script using
# the following command:
#
#  . $(dirname "$0")/scripts/common_funcs.sh
#
# NOTE:
#   1. This assumes your script is located one level up from this scripts 
#      folder.
#   2. The '.' is critical for this to work as it executes the function within
#      the same shell as your script. If you don't do this, the error detecting
#      functions will not terminate the script upon error etc.
#
################################################################################
# Print a fatal error message.
################################################################################
fatal_error() 
{
  # The file in which the error occurred.
  local FILE_NAME="$1"

  # The line on which the check was performed.
  local LINE_NUM="$2"

  # The message associated with the error.
  local MESSAGE="$3"

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
  local RET_CODE="$1"

  # The file in which the function is called.
  local FILE_NAME="$2"

  # The line on which the function was called.
  local LINE_NUM="$3"

  # The message to print if the error was fatal.
  local MESSAGE="$4"

  # Check if the previous call produced a non zero return code (an error).
  if [ "${RET_CODE}" -ne "0" ]; then
    fatal_error "${FILE_NAME}" "${LINE_NUM}" "${MESSAGE}"
  fi
 
  # No error occurred. 
  return 0
}

################################################################################
# Print and information message to cout.
################################################################################
print_info()
{
  # The file in which the function is called.
  local FILE_NAME="$1"

  # The line on which the function was called.
  local LINE_NUM="$2"

  # The message to print if the error was fatal.
  local MESSAGE="$3"

  # Only print the message if the script is not told to be quiet.
  if [ "${DEBUG}" == "true" ]; then
    echo "INFO  | ${FILE_NAME} | ${LINE_NUM} | ${MESSAGE}" >&1  
  elif [ "${QUIET}" = "false" ]; then
    echo "${MESSAGE}" >&1
  fi

  # No error occured.
  return 0
}

################################################################################
# Wait for the specified file to become available or time out / exit.
################################################################################
wait_or_die()
{
  # The file where the function is called from.
  local FILE_NAME=$1

  # The line number on which the call was made.
  local LINE_NUM=$2

  # The file to wait on.
  local FILE_PATH=$3

  # The number of seconds / retries to wait for.
  local MAX_RETRIES=$4

  # The current number of retries.
  local TRY_COUNT=0
  
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
# Check that the user name is valid by check if it matches POSIX user name
# regex and is less <= 32 characters in size.
################################################################################
validate_user_or_group_name() {
  # The user or group name to check.
  local NAME="$1"

  # Check if the name matches the Posix NAME_REGEX.
  local TEMP_USER=$(echo "${USER}" | sed -rn '^[a-z][-a-z0-9]*$')
  local USER_LEN=${#TEMP_USER}

  [[ "${USER_LEN}" > "0" && "${USER_LEN}" <= "32" ]]
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
  local GROUPS=("$@")

  # Validate each group name.
  for NAME in "${GROUPS[@]}"; do
    validate_user_or_group_name "${NAME}"
    if [ "$?" != "0" ]; then
      return 1
    fi
  done 

  # All group names passed.
  return 0
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

