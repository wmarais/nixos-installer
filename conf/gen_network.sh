#!/bin/sh

# The configuration file that will be generated.
CONF_FILE="/mnt/etc/nixos/conf/network.nix"

# The interface to enable DHCP on.
ETH_DHCP=""

# Whether to enable WiFi or not. Even if you dont specify a SSID or PASSWD, 
# turn this on if you intend to run WiFi. That way the wpa_supplication tools
# will be installed.
WIFI_ENABLE="false"

# The name of the network to connect too.
WIFI_SSID=""

# The password to connect to the network.
WIFI_PASSWD=""

# The hostname of the machine.
HOST_NAME=""

# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --host-name=*)    HOST_NAME="${1#*=}"; shift 1;;
    --eth-dhcp=*)     ETH_DHCP="${1#*=}"; shift 1;;
    --wifi-enable=*)  WIFI_ENABLE="${1#*=}"; shift 1;;
    --wifi-ssid=*)    WIFI_SSID="${1#*=}"; shift 1;;
    --wifi-passwd=*)  WIFI_PASSWD="${1#*=}"; shift 1;;
    *)                echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# The string template that is used to generate the bulk of the file.
STR_NETWORK="\
{ config, pkgs, ... }:
{
  # Set the name hostname of the machine.
  networking.hostName = \"${HOST_NAME}\";

  # Enable SSH but disable root logins.
  services.openssh = {
    enable = true;
    permitRootLogin = \"no\";
  };

  # Enable wireless networking.
  networking.wireless = {
    enable = ${WIFI_ENABLE};
    userControlled.enable = ${WIFI_ENABLE};
  };

  networking.useDHCP = false;"

# Generate the WiFi configuration file.
if [ "${WIFI_SSID}" != "" ]; then
  wpa_passphrase ${WIFI_SSID} ${WIFI_PASSWD} > "/mnt/etc/wpa_supplicant.conf"
fi

# Write the first section of the network configuration.
echo "${STR_NETWORK}" > ${CONF_FILE}

# Check if an ethernet port has been specified.
if [ "${ETH_DHCP}" != "" ]; then
  echo "  networking.interfaces.${ETH_DHCP}.useDHCP = true;" >> ${CONF_FILE}
fi

# Write the terminator.
echo "}" >> ${CONF_FILE}
