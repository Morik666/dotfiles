# Repository Instructions

- This repository stores dotfiles managed with GNU Stow.
- I'm using nixox with flake path .config/nix.
- I'm using hyperland with config path .config/hypr.
- Don't run stow or nix-rebuild. If you need to do that, tell me and I'll do it myself.

# Home network

- Main OpenWrt router: `root@192.168.1.1`, it can be ssh-ed into by key. A separate dumb AP extends the LAN.
- Ando is personal laptop with nixOS.
- Bespin is a home server PC with headless nix OS. It can be ssh-ed into from home network by `ssh jarves@192.168.1.163` by key.
- Bespin and ando share some nix configuration. And each has it's own part.
- Crait is a Raspberry Pi 3 Model B Rev 1.2 (1 GB RAM), intended for Home Assistant. It can be ssh-ed into from home network by key.
- Crait runs Raspberry Pi OS Lite 64-bit (Debian 13 trixie), with `aarch64` kernel and `arm64` userspace.

