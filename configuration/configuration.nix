{ config, pkgs, ... }:
{
  imports =
  [ # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Host specific configuration.
    ./host/fs.nix
    ./host/desktop.nix
    ./host/vm_guest.nix
    ./host/kernel.nix
    ./host/maintenance.nix
    ./host/network.nix

    # Security settings for the host.
    ./security/antivirus.nix
    ./security/firewall.nix
    ./security/users.nix 

    # Application specific configurations.
    ./applications/bash.nix
    ./applications/vim.nix
    ./applications/system_tools.nix
  ];

  # Allow us to cross compile and build SD card images.
  nixpkgs.config.allowUnsupportedSystems = true;

  # Allow the use of non-free software.
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Australia/Adelaide";

  # The nixos version.
  system.stateVersion = "21.11";
}

