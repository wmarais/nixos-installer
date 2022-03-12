#!/bin/sh

# The configuration file that will be generated.
CONF_FILE="/mnt/etc/nixos/host/desktop.nix"

# The type of desktop to deploy.
TYPE=""

# Parse the arguments to the script.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --type=*)         TYPE="${1#*=}"; shift 1;;
    *)                echo "invalid argument: $1" >&2; exit 1;;
  esac
done

# The template string for the base desktop configuration.
STR_DESKTOP="\
{config, pkgs, ...}:
{
  # The required packages for XFCE.
  environment.systemPackages = with pkgs; [
    brave
    lightdm
    lightlocker
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler
    xfce.xfce4-icon-theme
  ];

  # Enable the network manager for used in the desktop.
  networking.networkmanager = {
    enable = true;
  };

  # Enable hardware acceleration.
  hardware.opengl.enable = true;

  # Configure the services required for a desktop.
  services = {
    xserver = {
      enable = true;
      layout = \"us\";
      libinput.enable = true;

      # Make lightdm the default Display Manager and XFCE the default Desktop
      # Manager.
      displayManager = {
        lightdm.enable = true;
        defaultSession = \"xfce\";
      };

      # Enable XCE as an available Desktop Manager.
      desktopManager = {
        xfce.enable = true;
      };
    };
    
    # This adds some nice graphical effects. This is not critical for desktop
    # so if it is slow, disable it.
    picom = {
      enable = false;
      fade = true;
      inactiveOpacity = 0.9;
      shadow = true;
      fadeDelta = 4;
    };
  };
}"

STR_DESKTOP_EMPTY="\
{ config, pkgs, ... }:
{
}"

mkdir -p /mnt/etc/skel
cp -r ./generators/skel/ /mnt/etc/

if [ "${TYPE}" == "desktop" ]; then
  echo "${STR_DESKTOP}" > ${CONF_FILE}
else
  echo "${STR_DESKTOP_EMPTY}" > ${CONF_FILE}
fi
