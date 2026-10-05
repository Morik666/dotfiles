{ pkgs ? import <nixpkgs> {} }:

let
  runtimePackages = with pkgs; [
    curl
    freetype
    gcc.cc.lib
    gmp
    jsoncpp
    libGL
    libGLU
    libjpeg
    libogg
    libpng
    libvorbis
    luajit
    openal
    openssl
    SDL2
    sqlite
    zlib
    zstd
  ];
in
pkgs.mkShell {
  packages = runtimePackages;
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimePackages;
}
