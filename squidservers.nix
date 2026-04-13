{ pkgs, ... }:

let
  iconFile = "/home/_-_-yakov_-_-/Apps/SquidServersData/squidservers.png";

  # Criamos o pacote unificado com o script e o atalho
  squidPackage = pkgs.symlinkJoin {
    name = "squidservers-app";
    paths = [

    pkgs.unzip
    pkgs.gnutar
    pkgs.curl
    pkgs.xz
      # 1. O Script executável corrigido
      (pkgs.writeShellScriptBin "squidservers" ''
        export NIX_LD=$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)
        export NIX_LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib"

        ${pkgs.bubblewrap}/bin/bwrap \
          --ro-bind /nix /nix \
          --ro-bind /etc /etc \
          --ro-bind /run /run \
          --ro-bind /usr /usr \
          --ro-bind /etc/ssl/certs /etc/ssl/certs
          --symlink /run/current-system/sw/lib64 /lib64 \
          --bind /run/user/1000 /run/user/1000 \
          --dev-bind /dev /dev \
          --setenv NIX_LD "$NIX_LD" \
          --setenv NIX_LD_LIBRARY_PATH "$NIX_LD_LIBRARY_PATH" \
          --setenv WAYLAND_DISPLAY wayland-0 \
          --setenv XDG_RUNTIME_DIR /run/user/1000 \
          --bind /home/_-_-yakov_-_-/Apps /home/_-_-yakov_-_-/Apps \
          --bind /home/_-_-yakov_-_-/.cache /home/_-_-yakov_-_-/.cache \
          --bind /home/_-_-yakov_-_-/.config /home/_-_-yakov_-_-/.config \
          --proc /proc \
          --tmpfs /tmp \
          --share-net \
          ${pkgs.appimage-run}/bin/appimage-run /home/_-_-yakov_-_-/Apps/SquidServersData/squidservers-latest.appimage \
          -- --ozone-platform=wayland --disable-gpu --disable-gpu-compositing
      '')

      # 2. O Atalho do Desktop
      (pkgs.makeDesktopItem {
        name = "squidservers";
        desktopName = "SquidServers";
        genericName = "Servidor de Minecraft";
        exec = "squidservers";
        icon = "${iconFile}";
        categories = [ "Game" "ActionGame" ];
        keywords = [ "minecraft" "server" "squid" ];
        terminal = false;
      })
    ];
  };
in
{
  environment.systemPackages = [
    squidPackage
  ];
}
