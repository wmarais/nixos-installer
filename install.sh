#!/bin/sh

HDD="/dev/sda"
USER=""
PASSWORD=""
HOSTNAME=""
ENCRYPT=""
KEY=""
TYPE=""

# Include the common helper functions.
. $(dirname "$0")/hdd_setup/helpers.sh

################################################################################
# Check whether the combination of arguments look sensible.
################################################################################
validate_args() {
  if [[ ${ENCRYPT} == "full" || ${ENCRYPT} == "root" ]]; then
    if [ ${KEY} == "" ]; then
      ehco "An ecryption key must be specified using -k or --key."
    fi
  fi

  echo "HDD = ${HDD}"
  echo "USER = ${USER}"
  echo "PASSWORD = ${PASSWORD}"
  echo "HOSTNAME = ${HOSTNAME}"
  echo "ENCRYPT = ${ENCRYPT}"
  echo "KEY = ${KEY}"
  echo "TYPE = ${TYPE}"
}

################################################################################
# EXEC START
################################################################################
# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    -u) USER="$2"; shift 2;;
    -p) PASSWORD="$2"; shift 2;;
    -h) HOSTNAME="$2"; shift 2;;
    -e) ENCRYPT="$2"; shift 2;;
    -k) KEY="$2"; shift 2;;
    -t) TYPE="$2"; shift 2;;

    --user=*) USER="${1#*=}"; shift 1;;
    --password=*) PASSWORD="${1#*=}"; shift 1;;
    --hostname=*) HOSTNAME="${1#*=}"; shift 1;;
    --encrypt=*) ENCRPT="${1#*=}"; shift 1;;
    --key=*) KEY="${1#*=}"; shift 1;;
    --type=*) TYPE="${1#*=}"; shift 1;;

    *) echo "invalid argument: $1" >&2; exit 1;;
  esac
done

must_be_root ${LINENO}

# Check that the script args are valid.
validate_args

# Configure the hard-drive.
case ${ENCRYPT} in
  "full")
    $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD} ${KEY}
    ;;
  
  "root")
    $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD} ${KEY}
    ;;

  *)
    $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD}
    ;;
esac

# Generate the hardware configuration without the filesystems section since this
# is done automatically by the hdd_setup scripts.
nixos-generate-config --root /mnt --no-filesystems

# Copy the configuration of the system.
cp -f $(dirname "$0")/conf/configuration.nix "/mnt/etc/nixos/"
check_error ${LINENO} "Failed to copy default configuration file."

# Generate the user configuration.
echo "{ config, pkgs, ... }:
{
  users.users = {
    # Disable root logins.
    root = {
      hashedPassword = \"!\";
    };

    # Create a the default user with sudo access.
    ${USER} = {
      isNormalUser = true;
      extraGroups = [ \"wheel\" ];
      hashedPassword = \"$(echo ${PASSWORD} | mkpasswd -m sha-512)\";
    };
  };
}" >> /mnt/etc/nixos/conf/users.nix

# Rebuild the distribution.
nixos-install
