#!/bin/sh

# The user account that will be created.
NI_USER_NAME=""

# The full name of the user that will appear on the account descriptioni.
NI_FULL_NAME=""

# The user password that will be set.
NI_PASSWORD=""

# The configuration file that will be generated.
NI_OUTPUT=""

# The list of groups that the initial user belongs too. It is important to note
# that this user is always in the wheel (admin) group otherwise there will be
# no account with administrative privileges on the host.
NI_REQ_GROUPS=("wheel" "networkmanager" "libvirtd" "audio" "video")

# The combined list of groups.
NI_GROUPS=()

SCRIPTS_PATH=$(dirname "$0")/../scripts

# Include the common helper functions.
. ${SCRIPTS_PATH}/func_lib.sh

################################################################################
# The help message that will be displayed when the user type --help as an
# argument to the script.
################################################################################
NI_STR_HELP="\
NAME:

  gen_users - a script to disable the root account and create the first 
              administrator account.

USAGE:

  ./gen_users.sh \\
    --user-name=<user name> \\
    --full-name=<full name> \\
    --groups=<groups> \\
    --password=<user password> \\
    --output=<output path>

OPTIONS:

  --user-name   The user name that will be registered in the system and used
                to log into the system. For example, for some user \"Bob Jones\"
                , a good username would be \"bjones\".

  --full-name   The full name of the user, i.e. \"Bob Jones\". This will be
                displayed on the longin screen etc.

  --password    The initial password that will be set. The user will be required
                to change it after first login..

  --group       The comma-seperated list of groups that the user belongs too.

  --output      The .nix configuration file that will be created for the user
                account.

  --help        Print the help string for the script and exit execution
                without doing anything.
"

################################################################################
# Print the help information for the script.
################################################################################
print_help() {
  echo "${NI_STR_HELP}"

  # Return an error code so that any other script that uses this script will
  # accidentally call --help and thing that the script actually executed.
  exit 1;
}

################################################################################
# Check that suitable arguments has been supplied to the script.
################################################################################
validate_args() {
  IFS="," read -a NI_TEMP_GROUPS <<< "${NI_GROUPS}"
  NI_GROUPS=("${NI_REQ_GROUPS[@]}" "${NI_TEMP_GROUPS[@]}")

  # Validate all the groups.
  validate_groups "${NI_GROUPS[@]}"
  check_error "${LINENO}" "Invalid group names: ${NI_GROUPS[@]}"

  # Make sure the user name is valid.
  validate_user_or_group_name "${NI_USER_NAME}"
  check_error "${LINENO}" "Invalid user name: ${NI_USER_NAME}"

  # Make sure the password meet the password policy.
  validate_password "${NI_PASSWORD}"
  check_error "${LINENO}" "Invalid password."

  # Check that the output file can be generated.
  validate_file_path "${NI_OUTPUT}"
  check_error "${LINENO}" "Invalid output path: ${NI_OUTPUT}."
}

################################################################################
# Print all the groups in the groups list to stdout. This is used to build the
# extraGroups string for the user account.
################################################################################
print_groups() {
  for g in "${NI_GROUPS[@]}"
  do
    printf "\"$g\" "
  done
}

################################################################################
# Parse the arguments to the script.
################################################################################
while [ "$#" -gt 0 ]; do
  case "$1" in
    --user-name=*)    NI_USER_NAME="${1#*=}"; shift 1;;
    --full-name=*)    NI_FULL_NAME="${1#*=}"; shift 1;;
    --password=*)     NI_PASSWORD="${1#*=}"; shift 1;;
    --output=*)       NI_OUTPUT="${1#*=}"; shift 1;;
    --groups=*)       NI_GROUPS="${1#*=}"; shift 1;;
    --help)           print_help; exit 1;;
    *)                echo "Invalid argument: $1" >&2; print_help; exit 1;;
  esac
done

# Make sure the arguments are valid.
validate_args

# The template string that will be used to generate the configuration.
NI_STR_USERS="\
{ config, pkgs, ... }:
{
  users = {
    mutableUsers = true;
    users = {
      # Disable root logins.
      root = {
        hashedPassword = \"!\";
      };

      # Create a the default user with sudo access.
      ${NI_USER_NAME} = {
        description = \"${NI_FULL_NAME}\";
        isNormalUser = true;
        extraGroups = [ $(print_groups)];
        initialHashedPassword = \"$(mkpasswd -m sha-512 ${NI_PASSWORD})\";
      };
    };
  };
}"

echo "${NI_STR_USERS}" > ${NI_OUTPUT}
