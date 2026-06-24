{ pkgs, ... }:

let
  # 1. Baixa o repositório oficial em Python do levyvix
  ani-tupi-src = pkgs.fetchFromGitHub {
    owner = "levyvix";
    repo = "ani-tupi";
    rev = "master";
    # Hash do repositório Python atualizado
    hash = "sha256-pWrPuzpilXwHVRLwJB+XMkgTiyPRIKdoMf4fXS8GnPg="; 
  };

  # 2. Empacota a aplicação Python nativamente no ecossistema Nix
  ani-tupi-app = pkgs.python3Packages.buildPythonApplication {
    pname = "ani-tupi";
    version = "1.2.1";
    src = ani-tupi-src;
    format = "pyproject";

    # Dependências do ecossistema Python que o programa usa para rodar
    propagatedBuildInputs = with pkgs.python3Packages; [
      setuptools
      requests
      beautifulsoup4
      prompt-toolkit
    ];

    doCheck = false;
  };

  # 3. Cria a Sandbox do Bubblewrap trancando o executável Python
  ani-tupi-sandbox = pkgs.writeShellApplication {
    name = "ani-tupi";
    
    runtimeInputs = with pkgs; [ 
      mpv          # Player de vídeo obrigatório
      zathura      # Leitor de PDF para Mangá (recomendado)
      curl 
      gnugrep 
      coreutils 
      bubblewrap 
    ];

    text = ''
      exec bwrap \
        --ro-bind /nix/store /nix/store \
        --dev /dev \
        --proc /proc \
        --tmpfs /tmp \
        --share-net \
        --die-with-parent \
        --bind-try "$HOME/.config/ani-tupi" "$HOME/.config/ani-tupi" \
        --bind-try "$HOME/.config/mpv" "$HOME/.config/mpv" \
        --ro-bind-try "/run/user/$(id -u)/pulse" "/run/user/$(id -u)/pulse" \
        --ro-bind-try "/run/user/$(id -u)/pipewire-0" "/run/user/$(id -u)/pipewire-0" \
        --ro-bind-try "/run/user/$(id -u)/wayland-0" "/run/user/$(id -u)/wayland-0" \
        --setenv DISPLAY "$DISPLAY" \
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
        --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
        "${ani-tupi-app}/bin/ani-tupi" "$@"
    '';
  };
in
{
  # 4. Injeta o executável final na sua Home
  home.packages = [
    ani-tupi-sandbox
  ];
}
