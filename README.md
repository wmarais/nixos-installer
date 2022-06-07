# NIXOS-INSTALLER
NixOS unfortunately does not provide a simple installer to deploy a new system
without some expert knowledge. It is also quite labor intensive to perform the
first configuration. The script warps up the installation actions as documented
at: https://nixos.org/manual/nixos/stable/.

Limitations:
* **EFI:** Only support EFI.
* **GPT:** Only run on GPT partition table.

Requirements:
* **User Name:** 
  * All Lowercase
  * Must start with a letter between: `[a-z]`
  * Followed by letter or numbers, `[a-z]` and `[0-9]`
  * Length such that `1 <= length <= 32`
* **Password:**
  * Upper-case character
  * Lower-case character
  * Number
  * Special character
  * Non allowed: ` < > " ~ ' ;`
  
## HOWTO - General Installation
For installation, networking is required. Only four steps are required:

1. Download the latest NixOS bootable DVD and boot it.
2. In a terminal, clone this repository: `git clone https://github.com/wmarais/nixos-installer.git`.
3. Run the installer: `sudo ./nixos-installer.sh [OPTIONS]`.
4. Reboot.

### Example 1 - No Encryption
**Installation Command:**
```
$ sudo ./nixos-installer.sh \
  --user=admin \
  --password=admin \
  --host-name=nixtest \
  --encrypt=none \
  --type=desktop \
  --eth-dhcp=enp0s3 \
  --vbox
```
**Installer Output:**
```
Creating GPT partition table on /dev/sda.....
Creating partition: EFI on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/EFI to become available .....
Creating FAT32 filesystem for EFI.....
Creating partition: system-pv on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/system-pv to become available .....
Creating ext4 filesystem for system-pv.....
Creating LVM physical volume on /dev/disk/by-partlabel/system-pv.
Creating volume group "system-vg" on /dev/disk/by-partlabel/system-pv
Creating logical volume "swap-lv" on "system-vg".....
Creating logical volume "root-lv" on "system-vg".....
Installing NixOS.....
Done! Enjoy NixOS!
```

### Example 2 - Root Encryption
**Installation Command:**
```
$ sudo ./nixos-installer.sh \
  --user=admin \
  --password=admin \
  --host-name=nixtest \
  --encrypt=root \
  --key=admin \
  --type=desktop \
  --eth-dhcp=enp0s3 \
  --vbox
```
**Installer Output:**
```
Creating GPT partition table on /dev/sda.....
Creating partition: EFI on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/EFI to become available .....
Creating FAT32 filesystem for EFI.....
Creating partition: boot on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/boot to become available .....
Creating ext4 filesystem for boot.....
Creating partition: system-crypt on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/system-crypt to become available .....
Encrypting system-crypt.....
Opening system-crypt.....
Creating LVM physical volume on /dev/mapper/system-crypt.
Creating volume group "system-vg" on /dev/mapper/system-crypt
Creating logical volume "swap-lv" on "system-vg".....
Creating logical volume "root-lv" on "system-vg".....
Installing NixOS.....
Done! Enjoy NixOS!
```

### Example 3 - Full Encryption
**Installation Command:**
```
$ sudo ./nixos-installer.sh \
  --user=admin \
  --password=admin \
  --host-name=nixtest \
  --encrypt=full \
  --key=admin \
  --type=desktop \
  --eth-dhcp=enp0s3 \
  --vbox
```
**Installer Output:**
```
Device No is not active.
Creating GPT partition table on /dev/sda.....
Creating partition: EFI on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/EFI to become available .....
Creating FAT32 filesystem for EFI.....
Creating partition: system-crypt on /dev/sda.....
Waiting for device /dev/disk/by-partlabel/system-crypt to become available .....
Encrypting system-crypt.....
Opening system-crypt.....
Creating LVM physical volume on /dev/mapper/system-crypt.
Creating volume group "system-vg" on /dev/mapper/system-crypt
Creating logical volume "swap-lv" on "system-vg".....
Creating logical volume "root-lv" on "system-vg".....
Installing NixOS.....
Done! Enjoy NixOS!
```


If everything went well, NixOS will now be installed. 
## HOWTO - VirtualBox Installation
The installer is tested on *VirtualBox 6.1.32* with matching *Oracle VM
VirtualBox Extension Pack 6.1.32* installed. The test VM has the configuration
below and suits the purpose of a typical software development VM. The options in
***bold-italics*** are important to get right.

Virtual Machine
* **Name:** nixtest
* **Type:** Linux
* **Version:** Other Linux (64-bit)
* **Memory Size:** 4096 MB

Virtual Hard Disk
* **File Size:** 100 GB
* **Hard disk file type:** VDI (VirtualBox Disk Image)
* **Storage  on physical hard disk:** Fixed Size

System
* ***Enable EFI (special OSes only):*** Checked
* **Processors:** 4

Display
* ***Video Memory:*** 128 MB
* **Graphics Controller:** VMSVGA (default)
* ***Enable 3D Acceleration:*** Checked

Everything else has been left as default. NixOS is pretty space consuming,
however if you are running garbage collection frequently, feel free to reduce
the HDD size.

The installation command(s) used:

```
$ git clone https://github.com/wmarais/nixos-installer.git
$ cd nixos-installer
$ sudo ./nixos-installer.sh \
  --user=admin \
  --password=admin \
  --host-name=nixtest \
  --encrypt=none \
  --type=desktop \
  --eth-dhcp=enp0s3 \
  --vbox
```

NOTES:
* GNOME seems to not work properly in VBox. During installation, simple run the
  commands from a TTY terminal (i.e. press CTRL + ALT + F1). This is the same
  reason why the default desktop used by this installer is LightDM and XFCE.

## TODO
1. Network Detection: Determine which networks are connected at install time and
                      enable them by default post installation.
2. Display Manager:  Provide more options for display managers that work in both
                     physical and virtual deployments.

# MAN PAGE

## NAME
```
nixos-installer - a script to install NixOS.
```

## USAGE

```
sudo ./nixos-installer.sh \
  --user=<user name> \
  --password=<password> \
  --host-name=<host name> \
  --encrypt=<root|full|none> \
  --key=<key> \
  --type=<desktop|server> \
  --eth-dhcp=<eth name> \
```

## OPTIONS
```
--hdd           Specify the hard-drive to partition.

--user          Specify the user name of the default account that will be 
                created during installation. This account has sudo access and
                will be the only enabled account after installation (root login 
                is disabled).

--password      The password for the user account specified by --user.

--host-name     The host name of the machine after installation.

--encrypt       The encryption mode. The installer support three modes:

                  full - Everything except for the EFI partition is encrypted. 
                         This includes the root (/) partition, boot (/boot) and 
                         swap. This can be very slow to boot (upwards of 20 
                         seconds to get through the first grub stage). This is 
                         best used when it's likely that someone will modify 
                         your boot partition to inject a key logger etc. For 
                         this to work best, make sure to enable the TMP module 
                         to protect the EFI partition and lock down the BIOS.

                  root - Encrypts the root (/) and swap partition, but leaves 
                         the boot (/boot) partition unencrypted. This is 
                         generally how linux encrypted drives are setup. This 
                         has an advantage over Full Encryption in that it boots 
                         faster. This is generally well suited for 90% of users 
                         and works well for Laptops, Desktops and Servers.

                  none - There is no OS encryption. This is best used for 
                         unattended boots where the host has strong physical 
                         security, such as servers secured in data centers. 
                         (Though if a remote console is available, both full 
                         and root encryption will also work.) In the present 
                         day and age, no encryption is a last resort, always run
                         at minimum root encryption.

--key           The passphrase that will be used to encrypt the parts specified 
                by --encrypt. If no encryption (none) is used, then this 
                argument has no effect. 

--type          The type of environment that will be deployed. This option can
                be set to "desktop" (comes with XFCE GUI), or "server" (does not
                have a gui / is headless).

--time-zone     The time zone that host is located in. Not critical to set
                during installation, but nice to get it out of the way.

--eth-dhcp      The network adapter to enable for dhcp. This is nice when
                plugged into a home or work network with a dhcp server. It will
                allow you to immediately rebuild. The name of the adapter can
                be determined using "ip a".

--wifi-enable   Whether to enable wifi or not. This will install wpa_supplicant
                and associated wifi tools.

--wifi-ssid     The name of the wireless network to connect too.

--wifi-passwd   The password for the wireless network to connect too.

--auto-gc       Whether NixOS should perform automatic garbage collection.

--auto-dedup    Whether NixOS should perform automatic deduplication.

--auto-update   Whether NixOS should perform automatic updates.

--auto-reboot   Whether NixOS should rebuild and restart the system after
                automatic updates.

--vbox          Install the virtualbox guest additions.

--vmware        Install the vmware guest additions.
```
