# NixOS and dotfiles

One repository, two hosts: `ando` (desktop) and `bespin` (headless server).

- `.config/nix/hosts/<host>/`: host settings and hardware configuration.
- `.config/nix/modules/common*.nix`: shared user, locale and terminal packages.
- `.config/nix/modules/ando-*.nix`: desktop, themes, applications and home SSH policy.
- `.config/nix/modules/bespin-*.nix`: server SSH and applications/services.
- `.config/nix/packages/mantix.py`: shared mantix implementation.
- `stow/common/`: shared shell/editor configuration and mantix launchers.
- `stow/ando/`: desktop configuration, themes and desktop scripts.
- `stow/bespin/`: server-only dotfiles (initially empty).

## Applying dotfiles

Clone this repository to `~/.dotfiles`. Run these commands yourself:

```sh
~/.dotfiles/stow/common/.local/bin/mantix stow --dry-run
~/.dotfiles/stow/common/.local/bin/mantix stow
```

Mantix selects `common` plus the current hostname (`ando` or `bespin`).
Use `--host bespin` during setup if the hostname has not been configured yet.
Unknown hosts fail before anything changes. Adding an application's dotfiles
only requires placing them under `stow/common`, `stow/ando` or `stow/bespin`;
there is no per-application list to maintain.

`--dry-run` prints the planned link migration and command; it does not invoke
Stow or perform Stow's conflict checking. Normal execution uses Stow's conflict
checking and never adopts existing files.

Existing root-level `.config`, `.local` and `.bashrc` forwarding links preserve
previously stowed paths on ando. `mantix stow` migrates only legacy home symlinks
that point to this checkout's old paths and resolve to the selected source.
It leaves unrelated symlinks and real files alone. Keep these compatibility
links until all existing installations have migrated. Use `mantix stow` instead
of `stow .` from now on. The Nix flake is read directly from the checkout and
does not need to be stowed.

## System configuration

```sh
mantix install                 # Switch this host using the existing lock
mantix update                  # Update inputs, then switch this host
mantix install --host bespin   # Select bespin on the machine being installed
```

These commands rebuild the **local machine**; `--host` is not remote deployment.
`MANTIX_DOTFILES` overrides the repository path (default `~/.dotfiles`).
`MYNIX_FLAKE` overrides the flake path (default `$MANTIX_DOTFILES/.config/nix`).
Mantix is also installed as a shared Nix package so it is available without Stow.
The legacy `mynix` launcher delegates update/install/stow to mantix.

`flake.lock` is local and ignored by Git. Each checkout may resolve different
versions; `mantix update` updates all inputs in that checkout. Mantix uses an
explicit `path:` flake reference so Nix reads the local lockfile and new files
even before they are staged in Git. Use `--flake path:/path/to/.config/nix#bespin`
when invoking the installer directly.

## Installing bespin

Follow the [bespin installation checklist](docs/bespin-installation.md), including
the checks before the first reboot and before switching to SSH-only access.

Bespin is a configuration scaffold until installation-specific values are set:

1. Replace `.config/nix/hosts/bespin/hardware-configuration.nix` with the file
   generated on bespin by the NixOS installer / `nixos-generate-config`.
   The installer does not automatically update this repository.
2. Configure bespin's bootloader in `hosts/bespin/default.nix`. The flake assumes
   `x86_64-linux`; adjust it if the server uses another architecture.
3. Set `system.stateVersion` to the initial installation's version (the scaffold
   uses `26.05`), then keep it unchanged on upgrades.
4. Add your SSH public key in `hosts/bespin/default.nix`. SSH accepts keys for
   `jarves`, disables root login and password authentication, and opens port 22.
   Set jarves's local password during installation so sudo works over SSH.
5. Install using the flake's `bespin` configuration, following the NixOS
   installation procedure. Configuration assertions block deployment until the
   hardware placeholder is replaced and an SSH key is supplied.

Immich is enabled in `modules/bespin-packages.nix`; its NixOS service module
provides PostgreSQL, Redis and machine learning. It listens on port 2283 on all
IPv4 interfaces with that port open in the host firewall. On your home network,
visit `http://<bespin-address>:2283` and create the first admin account.
Media lives in `/var/lib/immich`; plan its storage and database/media backups
before importing your library. No router port forwarding or VPN is configured.
VPN, file sharing and other media services can be added as bespin modules later.

## Checks

```sh
python3 -B -m unittest discover -s tests -v
```

Mantix tests mock external commands; they do not run Stow or rebuild NixOS.
