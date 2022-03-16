################################################################################
# Build a minimum installer ISO image to be use with the nixos-installer.sh
# script. To build the ISO, run:
#
#   nix-build '<nixpkgs/nixos>' \
#     -A config.system.build.isoImage \
#     -I nixos-config=fast_install-iso.nix
#
# The image is stored in "results/iso".
################################################################################


{config, pkgs, ...}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ../configuration/applications/vim.nix
    ../configuration/applications/bash.nix
  ];

  environment.systemPackages = with pkgs; [
    parted
    lvm2
    cryptsetup
    openssh
    zfs
    git
  ];

  users.users.nixos.initialPassword = "nixos";
}
