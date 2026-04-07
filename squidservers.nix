{ pkgs, ... }:

let
  # Caminho exato para a sua imagem PNG
  iconFile = "/home/_-_-yakov_-_-/Apps/squidservers.png";
in
{
  environment.systemPackages = with pkgs; [
    # 1. O script de execução (mantendo a segurança do Bubblewrap)
    (pkgs.writeShellScriptBin "squidservers" ''
      ${pkgs.bubblewrap}/bin/bwrap \
        --ro-bind /nix /nix \
        --ro-bind /etc /etc \
        --ro-bind /run/current-system /run/current-system \
        --ro-bind /run/wrappers /run/wrappers \
        --ro-bind /run/opengl-driver /run/opengl-driver \
        --ro-bind /run/dbus /run/dbus \
        --bind /run/user/1000 /run/user/1000 \
        --dev-bind /dev /dev \
        --setenv WAYLAND_DISPLAY wayland-0 \
        --setenv XDG_RUNTIME_DIR /run/user/1000 \
        --bind /home/_-_-yakov_-_-/Apps /home/_-_-yakov_-_-/Apps \
        --bind /home/_-_-yakov_-_-/.cache /home/_-_-yakov_-_-/.cache \
        --bind /home/_-_-yakov_-_-/.config /home/_-_-yakov_-_-/.config \
        --proc /proc \
        --tmpfs /tmp \
        --share-net \
        ${pkgs.appimage-run}/bin/appimage-run /home/_-_-yakov_-_-/Apps/squidservers-latest.appimage \
        -- --ozone-platform=wayland --disable-gpu --disable-gpu-compositing > /dev/null 2>&1 &
    '')

    # 2. O item que cria o ícone no Menu Iniciar (KDE Plasma)
    (pkgs.makeDesktopItem {
      name = "squidservers";
      desktopName = "SquidServers";
      genericName = "Servidor de Minecraft";
      exec = "squidservers";
      icon = iconFile;
      comment = "Gerenciador de Servidores Minecraft";
      categories = [ "Game" "Network" ];
      terminal = false;
    })
  ];
}

