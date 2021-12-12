# NIXOS-INSTALLER
NixOS unfortunately does not provide a simple installer to deploy a new system
without some expert knowledge. It is also quite labor intensive to perform the
first configuration. The script warps up the installation actions as documented
at: https://nixos.org/manual/nixos/stable/.

## HOWTO
For installation, networking is required. Only four steps are required:

1. Download the latest NixOS bootable DVD and boot it.
2. In a terminal, clone this repository: `git clone https://github.com/wmarais/nixos-installer.git`.
3. Run the installer: `sudo ./nixos-installer.sh [OPTIONS]`.
4. Reboot.

If everything went well, NixOS will now be installed. 

## TODO
1. Network Detection: Determine which networks are connected at install time and
                      enable them by default post installation.

# MAN PAGE

## NAME
```
nixos-installer - a script to install NixOS.
```

## USAGE

```
sudo ./nixos-installer.sh \
  -u <user> \
  -p <password> \
  -h <hostname> \
  -e <root|full|none> \
  -k <key> \
  -t <desktop|server>
```

## OPTIONS
```
-u    Specify the user name of the default account that will be created during
      installation. This account has sudo access and will be the only enable
      account after installation (root login is disabled).

-p    The password for the user account specified by -u.

-h    The host name of the machine after installation.

-e    The encryption mode. The installer support three modes:

        full - Everything except for the EFI partition is encrypted. This 
               includes the root (/) partition, boot (/boot) and swap. This can 
               be very slow to boot (upwards of 20 seconds to get through the 
               first grub stage). This is best used when it's likely that 
               someone will modify your boot partition to inject a key logger 
               etc. For this to work best, make sure to enable the TMP module to
               protect the EFI partition and lock down the BIOS.

        root - Encrypts the root (/) and swap partition, but leaves the boot 
               (/boot) partition unencrypted. This is generally how linux
               encrypted drives are setup. This has an advantage over Full 
               Encryption in that it boots faster. This is generally well suited
               for 90% of users and works well for Laptops, Desktops and 
               Servers.

        none - There is no OS encryption. This is best used for unattended boots
               where the host has strong physical security, such as servers 
               secured in data centers. (Though if a remote console is 
               available, both full and root encryption will also work.) In the
               present day and age, no encryption is a last resort, always run 
               at minimum root encryption.

-k    The passphrase that will be used to encrypt the parts specified by -e. If
      no encryption (none) is used, then this argument has no effect. 

-t    The type of environment that will be deployed.

```
