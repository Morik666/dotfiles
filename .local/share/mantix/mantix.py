#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


KEEP_DAYS = 3
SYSTEM_PROFILE = "/nix/var/nix/profiles/system"


@dataclass(frozen=True)
class Generation:
    generation: int
    date: str
    time: str
    current: bool
    nixos_version: str
    kernel_version: str

    @property
    def day(self) -> str:
        return self.date

    @property
    def sort_key(self) -> tuple[str, str, int]:
        return (self.date, self.time, self.generation)


def usage() -> str:
    return """Usage:
  mantix update
  mantix install
  mantix stow
  mantix cleanup

Environment:
  MYNIX_FLAKE  Path to your Nix flake. Defaults to ~/.config/nix.

Commands:
  update        Update flake inputs and switch to the new system.
  install       Switch to the current flake without updating inputs.
  stow          Symlink dotfiles from ~/.dotfiles into ~.
  cleanup       Review and clean old NixOS boot generations.
"""


def die(message: str, code: int = 1) -> None:
    print(f"mantix: {message}", file=sys.stderr)
    raise SystemExit(code)


def require_command(command: str) -> None:
    if shutil.which(command) is None:
        die(f"missing required command: {command}", 127)


def run(command: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
    )


def flake_dir() -> Path:
    return Path(os.environ.get("MYNIX_FLAKE", "~/.config/nix")).expanduser()


def switch_checks() -> Path:
    if os.geteuid() == 0:
        die("do not run this command with sudo\nmantix: run mantix as your user; it will ask for sudo when switching")

    flake = flake_dir()
    if not (flake / "flake.nix").is_file():
        die(f"flake.nix not found in {flake}")

    require_command("nixos-rebuild")
    require_command("sudo")
    return flake


def update_system(_args: argparse.Namespace) -> None:
    flake = switch_checks()
    require_command("nix")

    print(f"==> Updating flake inputs in {flake}")
    run(["nix", "flake", "update", "--flake", str(flake)])

    print("==> Switching NixOS system")
    run(["sudo", "nixos-rebuild", "switch", "--flake", str(flake)])


def install_system(_args: argparse.Namespace) -> None:
    flake = switch_checks()

    print("==> Switching NixOS system from current flake")
    run(["sudo", "nixos-rebuild", "switch", "--flake", str(flake)])


def stow_dotfiles(_args: argparse.Namespace) -> None:
    dotfiles_dir = Path.home() / ".dotfiles"
    if not dotfiles_dir.is_dir():
        die(f"dotfiles directory not found: {dotfiles_dir}")

    require_command("stow")

    print(f"==> Stowing dotfiles from {dotfiles_dir} into {Path.home()}")
    run(["stow", "--dir", str(dotfiles_dir), "--target", str(Path.home()), "."])


def normalize_generation(raw: dict) -> Generation:
    date_parts = str(raw.get("date", "")).split()
    date = date_parts[0] if date_parts else "unknown-date"
    time = date_parts[1] if len(date_parts) > 1 else "unknown-time"

    return Generation(
        generation=int(raw["generation"]),
        date=date,
        time=time,
        current=bool(raw.get("current", False)),
        nixos_version=str(raw.get("nixosVersion") or raw.get("nixos_version") or "unknown NixOS"),
        kernel_version=str(raw.get("kernelVersion") or raw.get("kernel_version") or "unknown kernel"),
    )


def list_generations() -> list[Generation]:
    require_command("nixos-rebuild")

    result = run(["nixos-rebuild", "list-generations", "--json"], capture=True)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        die(f"could not parse nixos-rebuild generation JSON: {exc}")

    if isinstance(payload, dict):
        raw_generations = payload.get("generations", [])
    else:
        raw_generations = payload

    generations = [normalize_generation(item) for item in raw_generations]
    return sorted(generations, key=lambda item: item.sort_key)


def select_generations(generations: list[Generation]) -> tuple[set[int], set[int], set[int], list[str]]:
    days = []
    for generation in generations:
        if not days or days[-1] != generation.day:
            days.append(generation.day)

    keep_days = set(days[-KEEP_DAYS:])
    keep = set()
    delete = set()
    current_kept_outside_policy = set()

    by_day = defaultdict(list)
    for generation in generations:
        by_day[generation.day].append(generation)

    for day in days:
        group = by_day[day]
        first = group[0].generation
        last = group[-1].generation

        for generation in group:
            keep_by_policy = day in keep_days and generation.generation in {first, last}
            if keep_by_policy:
                keep.add(generation.generation)
            elif generation.current:
                keep.add(generation.generation)
                current_kept_outside_policy.add(generation.generation)
            else:
                delete.add(generation.generation)

    return keep, delete, current_kept_outside_policy, days[-KEEP_DAYS:]


def print_generation_table(
    generations: list[Generation],
    keep: set[int],
    delete: set[int],
    current_kept_outside_policy: set[int],
    kept_days: list[str],
) -> None:
    print(f"==> Keeping date groups: {' '.join(kept_days)}")
    if current_kept_outside_policy:
        current = " ".join(str(item) for item in sorted(current_kept_outside_policy))
        print(f"==> Current generation kept outside retention policy: {current}")
    print()

    for generation in generations:
        action = "KEEP" if generation.generation in keep else "DELETE"
        current = " current" if generation.current else ""
        print(
            f"{action:<6} "
            f"gen {generation.generation:<5} "
            f"{generation.date} {generation.time:<8} "
            f"NixOS {generation.nixos_version:<12} "
            f"Linux {generation.kernel_version}"
            f"{current}"
        )

    if delete:
        selected = " ".join(str(item) for item in sorted(delete))
        print(f"\n==> Generations selected for deletion: {selected}")
    else:
        print("\n==> Nothing to delete")


def prompt_cleanup_action() -> str:
    if not sys.stdin.isatty():
        print("==> Non-interactive input detected; canceling.")
        return "cancel"

    print("\nOptions:")
    print("  1. apply")
    print("  2. apply and collect garbage")
    print("  3. cancel")

    while True:
        choice = input("Choose [1/2/3, default 3]: ").strip().lower()
        if choice in {"", "3", "c", "cancel"}:
            return "cancel"
        if choice in {"1", "a", "apply"}:
            return "apply"
        if choice in {"2", "g", "gc", "garbage", "apply and collect garbage"}:
            return "apply-gc"
        print("mantix: choose 1, 2, or 3")


def cleanup_boot_generations(_args: argparse.Namespace) -> None:
    require_command("nixos-rebuild")
    require_command("nix-env")
    require_command("sudo")

    generations = list_generations()
    if not generations:
        die("no NixOS system generations found")

    keep, delete, current_kept_outside_policy, kept_days = select_generations(generations)
    print_generation_table(generations, keep, delete, current_kept_outside_policy, kept_days)

    if not delete:
        return

    action = prompt_cleanup_action()
    if action == "cancel":
        print("==> Canceled")
        return

    delete_args = [str(item) for item in sorted(delete)]
    print("==> Deleting selected system generations")
    run(["sudo", "nix-env", "--profile", SYSTEM_PROFILE, "--delete-generations", *delete_args])

    print("==> Refreshing boot entries from current system profile")
    run(["sudo", f"{SYSTEM_PROFILE}/bin/switch-to-configuration", "boot"])

    if action == "apply-gc":
        require_command("nix-collect-garbage")
        print("==> Running garbage collection")
        run(["sudo", "nix-collect-garbage"])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mantix",
        description="Manage this user's NixOS dotfiles workflow.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=usage(),
    )
    subparsers = parser.add_subparsers(dest="command")

    update = subparsers.add_parser("update", help="update flake inputs and switch")
    update.set_defaults(func=update_system)

    install = subparsers.add_parser("install", help="switch to the current flake")
    install.set_defaults(func=install_system)

    stow = subparsers.add_parser("stow", help="symlink dotfiles into $HOME")
    stow.set_defaults(func=stow_dotfiles)

    cleanup = subparsers.add_parser("cleanup", help="review and clean old boot generations")
    cleanup.set_defaults(func=cleanup_boot_generations)

    return parser


def main(argv: list[str]) -> int:
    parser = build_parser()
    if not argv or argv[0] == "help":
        print(usage(), end="")
        return 0

    args = parser.parse_args(argv)
    if not hasattr(args, "func"):
        parser.print_help()
        return 0

    try:
        args.func(args)
    except subprocess.CalledProcessError as exc:
        return exc.returncode

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
