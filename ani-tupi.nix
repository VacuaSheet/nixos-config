{ pkgs, ... }:

let
  # 1. Buscamos o script oficial usando a URL corrigida do domínio da AWS/GitHub
  ani-tupi-script = pkgs.fetchurl {
    url = "https://githubusercontent.com";
    hash = "sha256-o6f6O5uH0WJ4tO17Yyv86ZpS5b3Y4tZ76uB81vX0cW4=";
  };

  # 2. Criamos o executável sandboxado usando a estrutura correta para scripts isolados
  ani-tupi-sandbox = pkgs.writeShellApplication {
    name = "ani-tupi";
    
    # Injeta os programas necessários direto no PATH interno do script
    runtimeInputs = with pkgs; [ 
      mpv 
      fzf 
      curl 
      gnugrep 
      coreutils 
      bubblewrap 
    ];

    text = ''
      # Executa o Bubblewrap isolando o ambiente e chamando o script que baixamos
      exec bwrap \
        --ro-bind /nix/store /nix/store \
        --dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --share-net \
        --die-with-parent \
        --bind-try "$HOME/.config/mpv" "$HOME/.config/mpv" \
        --ro-bind-try "/run/user/$(id -u)/pulse" "/run/user/$(id -u)/pulse" \
        --ro-bind-try "/run/user/$(id -u)/pipewire-0" "/run/user/$(id -u)/pipewire-0" \
        --ro-bind-try "/run/user/$(id -u)/wayland-0" "/run/user/$(id -u)/wayland-0" \
        --setenv DISPLAY "$DISPLAY" \
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
        bash "${ani-tupi-script}" "$@"
    '';
  };
in
{
  # 3. Adiciona o programa resultante diretamente ao seu perfil do Home Manager
  home.packages = [
    ani-tupi-sandbox
  ];
}

