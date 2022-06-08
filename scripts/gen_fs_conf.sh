#!/bin/sh

MODE=$1
EFI_PART_NAME=$2
SYS_PART_NAME=$3
VG_NAME=$4
SWAP_LV_NAME=$5
ROOT_LV_NAME=$6

# The path where the fs configuration will be written too.
FS_CONF_PATH="/mnt/etc/nixos/host"

################################################################################
# The hardrive configuration used for no disk encryption.
################################################################################
ENC_NONE_FS_CONF="{ config, pkgs, ... }:
{
  imports = [ ];

  # Enable EFI Boot.
  boot.loader = {
    grub.enable = false;
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = \"/boot\";
    };
  };

  fileSystems.\"/\" = { 
    device = \"/dev/${VG_NAME}/${ROOT_LV_NAME}\";
    fsType = \"ext4\";
  };

  fileSystems.\"/boot/efi\" = {
    device = \"/dev/disk/by-partlabel/${EFI_PART_NAME}\";
    fsType = \"vfat\";
  };

  swapDevices = [{
    device = \"/dev/${VG_NAME}/${SWAP_LV_NAME}\"; 
  }];
}"

################################################################################
# The hardrive configuration used for root disk encryption.
################################################################################
ENC_ROOT_FS_CONF="{ config, pkgs, ... }:
{
  imports = [ ];

  # Enable EFI Boot.
  boot.loader = {
    grub.enable = false;
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = \"/boot\";
    };
  };

  # Configure luks so that disk must be decrypted then start LVM.
  boot.initrd.luks.devices = {
    root = {
      device = \"/dev/disk/by-partlabel/${SYS_PART_NAME}\";
      preLVM = true;
    };
	};

  fileSystems.\"/\" = { 
    device = \"/dev/${VG_NAME}/${ROOT_LV_NAME}\";
    fsType = \"ext4\";
  };

  fileSystems.\"/boot/efi\" = {
    device = \"/dev/disk/by-partlabel/${EFI_PART_NAME}\";
    fsType = \"vfat\";
  };

  swapDevices = [{
    device = \"/dev/${VG_NAME}/${SWAP_LV_NAME}\"; 
  }];
}"

################################################################################
# The hardrive configuration used for full disk encryption.
################################################################################
ENC_FULL_FS_CONF="{ config, pkgs, ... }:
{
  imports = [ ];

  environment.systemPackages = with pkgs; [
    cryptsetup
    lvm2
    grub2
  ];

  # Enable EFI Boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = \"/boot/efi\";
  };

  # Configure grub to boot the encrypted partition.
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = \"nodev\";
    efiSupport = true;
    enableCryptodisk = true;
  };

  # Configure luks so that disk must be decrypted then start LVM.
  boot.initrd.luks.devices = {
    root = {
      device = \"/dev/disk/by-partlabel/${SYS_PART_NAME}\";
      preLVM = true;
    };
	};

  # Set the root volume.
  fileSystems.\"/\" = { 
    device = \"/dev/${VG_NAME}/${ROOT_LV_NAME}\";
    fsType = \"ext4\";
  };

  # Set the efi partition.
  fileSystems.\"/boot/efi\" = {
    device = \"/dev/disk/by-partlabel/${EFI_PART_NAME}\";
    fsType = \"vfat\";
  };

  # Set the swap volume.
  swapDevices = [{
    device = \"/dev/${VG_NAME}/${SWAP_LV_NAME}\"; 
  }];
}"

# Make sure that the path where the configuration will be saved too exists.
mkdir -p ${FS_CONF_PATH}

# Output the respective configuration.
case ${MODE} in
  "encrypt_root")
    echo "${ENC_ROOT_FS_CONF}" > "${FS_CONF_PATH}/fs.nix"
    ;;

  "encrypt_full")
    echo "${ENC_FULL_FS_CONF}" > "${FS_CONF_PATH}/fs.nix"
    ;;

  *)
    echo "${ENC_NONE_FS_CONF}" > "${FS_CONF_PATH}/fs.nix"
    ;;
esac

