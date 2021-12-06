#!/bin/bash

EFI_PART_NAME=$1
SWAP_LV_NAME=$2
ROOT_LV_NAME=$3

mkdir -p /mnt/etc/nixos

echo "{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ ];

  boot.initrd.availableKernelModules = [ \"ata_piix\" \"mptspi\" \"uhci_hcd\" \"ehci_pci\" \"sd_mod\" \"sr_mod\" ];
  boot.initrd.kernelModules = [ \"dm-snapshot\" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems.\"/boot/efi\" = {
    device = \"/dev/disk/by-label/${EFI_PART_NAME}\";
    fsType = \"vfat\";
  };

  swapDevices = [{
    device = \"/dev/disk/by-label/${SWAP_LV_NAME}\"; 
  }];

  fileSystems.\"/\" = { 
    device = \"/dev/disk/by-label/${ROOT_LV_NAME}\";
    fsType = \"ext4\";
  };
}" > /mnt/etc/nixos/hardware-configuration.nix