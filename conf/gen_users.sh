#!/bin/sh

# The configuration file that will be generated.
CONF_FILE="/mnt/etc/nixos/conf/users.nix"

# The user account that will be created.
USER=""

# The user password that will be set.
PASSWORD=""

# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --user=*)         USER="${1#*=}"; shift 1;;
    --password=*)     PASSWORD="${1#*=}"; shift 1;;
    *)                echo "invalid argument: $1" >&2; exit 1;;
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
        extraGroups = [ \"wheel\" ];
        initialHashedPassword = \"$(mkpasswd -m sha-512 ${PASSWORD})\";
      };
    };
  };
}"

echo "${STR_USERS}" > ${CONF_FILE}
