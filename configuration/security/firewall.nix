{config, pkgs, ...}:
{
  networking = {
    firewall = {
      enable = true;

      # Port 22 is automatically opened when SSH is enabled.
      allowedTCPPorts = [
      ];
    };
  };
}

