{ pkgs, ... }:

let
  # 1. Busca os arquivos do repositório usando a função dedicada do GitHub para evitar travas de cache
  ani-tupi-repo = pkgs.fetchFromGitHub {
    owner = "eduardonery1";
    repo = "ani-tupi";
    rev = "master";
    hash = "sha256-4YIidXw1nU7AonhX/gO3j+hE/X+G0IeYm8mIqV9zP8A=";
  };

  # 2. Cria o executável sandboxado usando a estrutura correta para scripts isolados
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
      # Executa o Bubblewrap isolando o ambiente e apontando para o script no repositório baixado
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
        bash "${ani-tupi-repo}/ani-tupi" "$@"
    '';
  };
in
{
  # 3. Adiciona o programa resultante diretamente ao seu perfil do Home Manager
  home.packages = [
    ani-tupi-sandbox
  ];
}

