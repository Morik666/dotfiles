#!/bin/bash

alias la="ls -a"

# function hx() {
#   # Set WezTerm tab title to show the file being edited
#   # if [ $# -gt 0 ]; then
#   #   wezterm cli set-tab-title "hx one $(basename "$1")"
#   # else
#   #   wezterm cli set-tab-title "hx path"
#   # fi
#   # printf "\033]0;%s\007" "$(basename "$PWD")"
#   # wezterm cli set-tab-title "hx path"
#   echo "123"
#   # Run helix with all arguments
#   command hx "$@"

#   # Reset title when exiting (optional)
#   # wezterm cli set-tab-title "$(basename "$PWD")"
# }

eval "$(starship init bash)"
alias dotfiles='/run/current-system/sw/bin/git --git-dir=/home/jarves/.dotfiles/ --work-tree=/home/jarves'
