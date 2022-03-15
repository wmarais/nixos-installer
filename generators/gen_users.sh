#!/bin/sh

# The user account that will be created.
USER=""

# The full name of the user that will appear on the account descriptioni.
FULL_NAME=""

# The user password that will be set.
PASSWORD=""

# The configuration file that will be generated.
OUTPUT=""

# The list of groups that the initial user belongs too. It is important to note
# that this user is always in the wheel (admin) group otherwise there will be
# no account with administrative privileges on the host.
REQ_GROUPS=("wheel")

# The combined list of groups.
GROUPS=()

################################################################################
# The help message that will be displayed when the user type --help as an
# argument to the script.
################################################################################
STR_HELP="\
NAME:

  gen_users - a script to disable the root account and create the first 
              administrator account.

USAGE:

  gen_users \
    --user=<user name> \
    --full_name=<full name> \
    --groups=<groups> \
    --password=<user password> \
    --output=<output path>

OPTIONS:

  --user        The user name that will be registered in the system and used
                to log into the system. For example, for some user \"Bob Jones\"
                , a good username would be \"bjones\".

  --full_name   The full name of the user, i.e. \"Bob Jones\". This will be
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
  echo "${STR_HELP}"

  # Return an error code so that any other script that uses this script will
  # accidentally call --help and thing that the script actually executed.
  exit 1;
}




################################################################################
# Check that suitable arguments has been supplied to the script.
################################################################################
validate_args() {
  IFS="," read -a TEMP_GROUPS <<< "${GROUPS_IN}"
  GROUPS=("${REQ_GROUPS[@]}" "${TEMP_GROUPS[@]}")

  # Make sure the user name is valid.
  validate_user "${USER}"

  # Make sure the password meet the password policy.
  validate_password "${PASSWORD}"

  # Check that the output file can be generated.
  validate_file_path "${OUTPUT}"
}


################################################################################
# Parse the arguments to the script.



while [ "$#" -gt 0 ]; do
  case "$1" in
    --user=*)         USER="${1#*=}"; shift 1;;
    --full_name=*)    FULL_NAME="${1#*=}"; shift 1;;
    --password=*)     PASSWORD="${1#*=}"; shift 1;;
    --output=*)       OUTPUT="${1#*=}"; shift 1;;
    --groups=*)       GROUPS="${1#*=}"; shift 1;;
    --help)           print_help; exit 1;
    *)                echo "invalid argument: $1" >&2; print_help; exit 1;;
  esac
done

# The template string that will be used to generate the configuration.
STR_USERS="\
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
      ${USER} = {
        isNormalUser = true;
        extraGroups = [ 
          \"wheel\" 

          \"networkmanager\" 
          \"libvirtd\" 
          \"audio\" \"${VBOXSF_GROUP}\" ];
        initialHashedPassword = \"$(mkpasswd -m sha-512 ${PASSWORD})\";
      };
    };
  };
}"

echo "${STR_USERS}" > ${CONF_FILE}

