set -gx EDITOR hx
set -gx VISUAL hx

if status is-interactive
    bind shift-enter 'commandline --insert \n'
    # Keep the command editor accessible while Herdr uses Alt+E.
    bind alt-shift-e edit_command_buffer
    starship init fish | source
    zoxide init fish | source
end
