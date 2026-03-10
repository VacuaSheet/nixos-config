{ config, pkgs, ... }:

let
  # Função que configura automaticamente qualquer navegador baseado em Mozilla
  mkMozillaApp = id: {
    "Session Bus"."talk-name" = [ "org.kde.plasma.browser_integration" ];
    Environment = {
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_APP_REMOTINGNAME" = id;
    };
  };
in
{
  services.flatpak = {
    enable = true;

    packages = [
      "io.github.flattool.Warehouse"
      "com.github.tchx84.Flatseal"
      "org.mozilla.firefox"
      "io.gitlab.librewolf-community"
      "com.usebottles.bottles"
      "net.lutris.Lutris"          # Lutris
      "org.freedesktop.Platform.GL32.default" # Instala o runtime do Steam (ajuda com bibliotecas de jogos)
      "net.lutris.Lutris.Extension.cabextract" # Garante que o Lutris tenha o "cabextract" (essencial para corefonts/EA)
      "org.freedesktop.Platform.Compat.i386" # Garante as bibliotecas gráficas de 32 bits
      "com.heroicgameslauncher.hgl" # Heroic Games Launcher
      "com.google.Chrome"
      "org.telegram.desktop"
      "com.discordapp.Discord"
      "com.ubisoft.Connect"
    ];

  overrides = {
    # Mantém apenas o que é estético/comum para todos
    global = {
      Context.filesystems = [ "xdg-config/kdeglobals:ro" ];
      Context.sockets = [ "wayland" "fallback-x11" ];
    };

    # Permissão de comunicação restrita aos navegadores
     # Aqui a "mágica" acontece: a função mkMozillaApp já preenche tudo
    "org.mozilla.firefox" = mkMozillaApp "firefox";

    "io.gitlab.librewolf-community" = mkMozillaApp "io.gitlab.librewolf-community";
  };
    update.auto.enable = true;
    uninstallUnmanaged = true;
  };
}
