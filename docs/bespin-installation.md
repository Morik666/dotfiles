# Bespin installation checklist

Follow this for a manual installation from a NixOS USB installer. Commands are
for you to run on bespin unless marked **ando**. Keep a monitor/keyboard or a
remote console available until both reboot checks pass.

The current config uses Ethernet DHCP, key-only SSH for `jarves`, and Immich on
port 2283. It does not yet configure VPN, file sharing, backups or a data disk.

## 1. Before starting

- [ ] Back up anything on disks you might repartition.
- [ ] Identify the OS disk and any separate photo/data disks by model and serial.
- [ ] Decide UEFI versus legacy BIOS, filesystem layout and encryption. If you
  encrypt the root disk with a passphrase, decide how to unlock it after a
  remote reboot; normal SSH is unavailable until the system has booted.
- [ ] Arrange wired Ethernet and a DHCP reservation in the router. Record the
  MAC address and intended IP. The config does not provide `bespin.local`.
- [ ] **Ando:** make the latest repo changes available to the installer, either
  by committing/pushing them yourself or copying the current checkout. A clone
  will not include uncommitted work.
- [ ] **Ando:** have your SSH **public** key ready. Keep the private key on ando.
- [ ] Save a copy of `.config/nix/flake.lock` with your installation notes if you
  want the versions already checked here; Git deliberately excludes it. The
  flake follows `nixos-unstable`, regardless of the installer ISO's release.

## 2. Installer: disks and configuration

- [ ] Boot the USB in the intended firmware mode. Check the CPU architecture
  against `x86_64-linux` in `.config/nix/flake.nix`.
- [ ] Confirm network access. Inspect disks with `lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS`.
- [ ] Partition/format the chosen disks, then mount root at `/mnt`, the EFI
  partition at `/mnt/boot` if using that layout, and any separate filesystems
  beneath `/mnt`. Do this before hardware detection. Use the
  [NixOS installation manual](https://nixos.org/manual/nixos/stable/#sec-installation-manual)
  for the commands matching your disk layout.
- [ ] Open a root shell with `sudo -i`. Put the checkout at
  `/mnt/home/jarves/.dotfiles`, after mounting any separate `/home` filesystem.
  Use HTTPS to clone if appropriate, or copy the prepared checkout from ando.
- [ ] Generate hardware settings and replace the repo's placeholder:

```sh
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/jarves/.dotfiles/.config/nix/hosts/bespin/hardware-configuration.nix
```

- [ ] Check that this file describes bespin's actual root, boot and data mounts.
- [ ] Edit `.config/nix/hosts/bespin/default.nix` in that checkout: add the public
  key, set the initial `system.stateVersion`, and configure the bootloader.
  Consult the generated `/mnt/etc/nixos/configuration.nix` for installer defaults;
  the flake does **not** import that file. Keep `stateVersion` unchanged afterward.
- [ ] For UEFI with the EFI partition mounted at `/boot`, a typical bootloader
  configuration is the following. Do not use it for legacy BIOS:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

- [ ] Decide whether Immich should initially store media on root at
  `/var/lib/immich`. If using a data disk, configure its persistent mount and
  service mount dependency before enabling uploads. Ensure Immich cannot write
  into an empty mountpoint on root when that disk is absent.

**Checkpoint: the repo must now contain real hardware settings, a bootloader
and your SSH key. Deleting the placeholder assertion alone is not sufficient.**

## 3. Install — before the first reboot

Still in the installer's root shell:

```sh
nixos-install --root /mnt --flake path:/mnt/home/jarves/.dotfiles/.config/nix#bespin
nixos-enter --root /mnt -c 'passwd jarves'
nixos-enter --root /mnt -c 'chown -R jarves:users /home/jarves/.dotfiles'
```

- [ ] Installation completed successfully; resolve any errors before rebooting.
- [ ] Set the root recovery password when prompted by the installer.
- [ ] Set **jarves's password separately** using the command above. It is needed
  for sudo/local login; it will not enable SSH password authentication.
- [ ] Confirm the authorized key is the one whose private key you have on ando.
- [ ] Preserve the edited checkout and its local lockfile on the installed disk.
- [ ] Keep console access available, reboot, and remove the installer USB.

The installer password and temporary installer SSH access do not configure
jarves's installed-system credentials. Installation/password steps follow the
[NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation-installing).

## 4. First boot — prove you can administer it

- [ ] Confirm it boots from disk and displays `bespin` at the console.
- [ ] Log in locally as `jarves` and inspect `ip -br address` if the IP is unclear.
- [ ] **Ando:** run `ssh jarves@<bespin-ip>`. Check the new host-key fingerprint
  against the console's `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`.
  Installer and installed-system host keys may differ; verify before replacing
  an old known-hosts entry.
- [ ] Inside the SSH session, run:

```sh
hostname
sudo -v
systemctl --failed
findmnt /
findmnt /boot
df -h
systemctl status sshd immich-server immich-machine-learning postgresql redis-immich
```

- [ ] `hostname` reports `bespin`, sudo accepts your password, expected disks are
  mounted, and service failures are understood. `/boot` is a separate mount only
  if your chosen layout uses one. Inspect failures with `journalctl -b -u SERVICE`.
- [ ] Open a **second SSH session from ando** and confirm it works before closing
  the first. Check that `~/.dotfiles` is owned by jarves.
- [ ] As jarves, optionally apply the shared/bespin dotfiles:

```sh
mantix stow --dry-run
mantix stow
```

**Checkpoint: don't remove console access until SSH and sudo both work.**

## 5. Second reboot — prove unattended startup works

- [ ] Run `sudo reboot` over SSH, then reconnect from ando after startup.
- [ ] Confirm the reserved IP, data mounts and Immich return without intervention.
- [ ] Check `systemctl --failed` again. Resolve boot/unlock/mount issues now.
- [ ] Save the generated hardware settings and host edits back to Git; separately
  retain the working lockfile. Keep the installer USB for recovery.
- [ ] Only now disconnect the monitor/keyboard and put bespin in its final location.

If it cannot boot, use the console and a previous boot generation when one exists,
or boot the USB, mount the installed filesystems and use `nixos-enter` to repair.
The first installation may have no previous generation to fall back to.

## 6. Before entrusting photos to Immich

- [ ] On your LAN, open `http://<bespin-ip>:2283` and create your admin account.
  The first registered user becomes admin. Follow the
  [Immich first-use guide](https://docs.immich.app/overview/quick-start/).
- [ ] Upload a few test photos; verify viewing and downloading, and check that
  disk usage grows on the intended filesystem.
- [ ] Configure backups of **both media and the database**, with a copy outside
  bespin, then test a restore separately. Immich's database backups alone do not
  include your photos. See [Immich backup and restore](https://docs.immich.app/administration/backup-and-restore/).
- [ ] Keep the original photo library until upload and recovery checks pass.
- [ ] Add VPN separately and test access from outside your Wi-Fi before relying
  on it. The current config opens SSH and Immich on the host but does not set up
  router forwarding or a VPN; keep this installation on your trusted LAN.
- [ ] Keep the first working generation while stabilizing the server. Avoid
  `mantix cleanup` and unnecessary dependency updates during initial testing.
  A NixOS generation rollback does not restore Immich's database or media.
