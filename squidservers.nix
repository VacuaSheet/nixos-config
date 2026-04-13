{ pkgs, ... }:

let
  iconFile = "/home/_-_-yakov_-_-/Apps/SquidServersData/squidservers.png";

  squidPackage = pkgs.symlinkJoin {
    name = "squidservers-app";
    paths = [
      # Adicionamos utilitários que o AppImage pode precisar para extrair o servidor
      pkgs.unzip
      pkgs.curl
      pkgs.xz

      # O Script executável
      (pkgs.writeShellScriptBin "squidservers" ''
        export NIX_LD=$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)
        export NIX_LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib"

        ${pkgs.bubblewrap}/bin/bwrap \
          --ro-bind /nix /nix \
          --ro-bind /etc /etc \
          --ro-bind /run /run \
          --ro-bind /usr /usr \
          --dev-bind /dev /dev \
          --symlink /run/current-system/sw/lib64 /lib64 \
          --bind /run/user/1000 /run/user/1000 \
          --setenv NIX_LD "$NIX_LD" \
          --setenv NIX_LD_LIBRARY_PATH "$NIX_LD_LIBRARY_PATH" \
          --setenv WAYLAND_DISPLAY wayland-0 \
          --setenv XDG_RUNTIME_DIR /run/user/1000 \
          --bind /home/_-_-yakov_-_- /home/_-_-yakov_-_- \
          --proc /proc \
          --tmpfs /tmp \
          --share-net \
          ${pkgs.appimage-run}/bin/appimage-run /home/_-_-yakov_-_-/Apps/SquidServersData/squidservers-latest.appimage \
          -- --ozone-platform=wayland --disable-gpu --disable-gpu-compositing
      '')

      (pkgs.makeDesktopItem {
        name = "squidservers";
        desktopName = "SquidServers";
        genericName = "Servidor de Minecraft";
        exec = "squidservers";
        icon = "${iconFile}";
        categories = [ "Game" ];
        terminal = false;
      })
    ];
  };
in
{
  environment.systemPackages = [ squidPackage ];
}
