{config, pkgs, ...}:
{
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  virtualisation.libvirtd.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
