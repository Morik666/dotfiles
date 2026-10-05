{ writeShellApplication, python3, stow }:
writeShellApplication {
  name = "mantix";
  runtimeInputs = [ python3 stow ];
  text = ''
    exec python3 -B ${./mantix.py} "$@"
  '';
}
