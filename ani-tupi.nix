{ pkgs, ... }:

let
  # 1. Baixamos o repositório em Python atualizado do levyvix
  # Alteramos o identificador 'name' para forçar o Nix a baixar a pasta certa e ignorar o cache antigo
  ani-tupi-repo = pkgs.fetchFromGitHub {
    name = "ani-tupi-python-src";
    owner = "levyvix";
    repo = "ani-tupi";
    rev = "master";
    hash = "sha256-pWrPuzpilXwHVRLwJB+XMkgTiyPRIKdoMf4fXS8GnPg=";
  };

  # 2. Montamos o ambiente Python do Nix com todas as dependências que o script pede
  python-env = pkgs.python3.withPackages (ps: with ps; [
    requests
    beautifulsoup4
    prompt-toolkit
    setuptools
  ]);
in
{
  # 3. Criamos a Sandbox do Bubblewrap injetando o ambiente Python estruturado
  home.packages = [
    (pkgs.writeShellApplication {
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
          "${python-env}/bin/python" "${ani-tupi-repo}/main.py" "$@"
      '';
    })
  ];
}
