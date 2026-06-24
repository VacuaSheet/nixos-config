{ pkgs, ... }:

let
  # 1. Busca o script oficial do ani-tupi direto do repositório
  ani-tupi-base = pkgs.stdenv.mkDerivation {
    pname = "ani-tupi";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "eduardonery1";
      repo = "ani-tupi";
      rev = "master"; 
      # Hash fictício. Substitua pelo hash correto gerado pelo nix-prefetch-url
      sha256 = "sha256-pWrPuzpilXwHVRLwJB+XMkgTiyPRIKdoMf4fXS8GnPg="; 
    };

    installPhase = ''
      mkdir -p $out/bin
      cp ani-tupi $out/bin/ani-tupi
      chmod +x $out/bin/ani-tupi
    '';
  };

  # 2. Cria o executável protegido dentro da sandbox do Bubblewrap
  ani-tupi-sandbox = pkgs.writeShellScriptBin "ani-tupi" ''
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --ro-bind /nix/store /nix/store \
      --dev /dev \
      --proc /proc \
      --tmpfs /tmp \
      --share-net \
      --die-with-parent \
      --bind-try $HOME/.config/mpv $HOME/.config/mpv \
      --ro-bind-try /run/user/$(id -u)/pulse /run/user/$(id -u)/pulse \
      --ro-bind-try /run/user/$(id -u)/pipewire-0 /run/user/$(id -u)/pipewire-0 \
      --ro-bind-try /run/user/$(id -u)/wayland-0 /run/user/$(id -u)/wayland-0 \
      --setenv PATH "${pkgs.lib.makeBinPath [ ani-tupi-base pkgs.mpv pkgs.fzf pkgs.curl pkgs.gnugrep pkgs.coreutils ]}" \
      --setenv DISPLAY "$DISPLAY" \
      --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
      --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
      ani-tupi "$@"
  '';
in
{
  # 3. Adiciona o programa resultante diretamente aos pacotes do seu Home Manager
  home.packages = [
    pkgs.bubblewrap
    ani-tupi-sandbox
  ];
}
