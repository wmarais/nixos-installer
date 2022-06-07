{config, pkgs, ...}:
{
  # Only list the default tools that should be available too all systems post installation.
  environment.systemPackages = with pkgs; [
    wget
    htop
    curl
    git
    qemu_kvm
    lshw
  ];
}
