#!/bin/sh

HDD="/dev/sda"
ENCRYPT=full
USAGE="server"
PASSWD=$1
HOSTNAME=nixos-test


# Configure the hard-drive.
case ${ENCRYPT} in
  "full")
    $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD} ${PASSWD}
    ;;
  
  "root")
    $(dirname "$0")/hdd_setup/encrypt_full.sh ${HDD} ${PASSWD}
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

# Rebuild the distribution.
nixos-install
