{ pkgs, ... }:

let
  ani-tupi-repo = pkgs.fetchFromGitHub {
    name = "ani-tupi-python-src";
    owner = "levyvix";
    repo = "ani-tupi";
    rev = "master";
    hash = "sha256-N3UNGzC1Q4s1kMenYdjeAfV2CR8sdHbO+pTbFbyis0s=";
  };

  python-env = pkgs.python3.withPackages (ps: with ps; [
    prompt-toolkit
    inquirerpy
    rich
    loguru
    nest-asyncio

    pydantic
    pydantic-settings
    setuptools

    requests
    urllib3
    cryptography
    httpx
    httpcore
    anyio
    h11

    beautifulsoup4
    html5lib
    brotli
    lxml

    diskcache
    fuzzywuzzy
    levenshtein
  ]);
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "ani-tupi";

      runtimeInputs = with pkgs; [
        mpv
        zathura
        curl
        gnugrep
        coreutils
        bubblewrap
      ];

      text = ''
        set -euo pipefail

        UID="$(id -u)"
        RUNTIME_DIR="/run/user/$UID"

        # Sockets (Wayland)
        WAYLAND_SOCKET=""
        WAYLAND_DISPLAY_VAL="''${WAYLAND_DISPLAY:-}" 


        if [ -n "$WAYLAND_DISPLAY_VAL" ]; then
          WAYLAND_SOCKET="$RUNTIME_DIR/$WAYLAND_DISPLAY_VAL"
        fi




        # Pulse / PipeWire
        PULSE_DIR="$RUNTIME_DIR/pulse"
        PIPEWIRE_0="$RUNTIME_DIR/pipewire-0"

        # X11 socket (quando aplicável)
        XSOCK="/tmp/.X11-unix"

        exec bwrap \
          --ro-bind /nix/store /nix/store \
          --dev /dev \
          --proc /proc \
          --tmpfs /tmp \
          --share-net \
          --die-with-parent \
          --bind-try "$HOME/.config/ani-tupi" "$HOME/.config/ani-tupi" \
          --bind-try "$HOME/.config/mpv" "$HOME/.config/mpv" \
          --ro-bind-try "$PULSE_DIR" "$PULSE_DIR" \
          --ro-bind-try "$PIPEWIRE_0" "$PIPEWIRE_0" \
          --ro-bind-try "$WAYLAND_SOCKET" "$WAYLAND_SOCKET" \
          --ro-bind-try "$XSOCK" "$XSOCK" \
          --setenv DISPLAY "''${DISPLAY:-}" \
          --setenv WAYLAND_DISPLAY "''${WAYLAND_DISPLAY:-}" \
          --setenv XDG_RUNTIME_DIR "$RUNTIME_DIR" \


          "${python-env}/bin/python" "${ani-tupi-repo}/main.py" "$@"
      '';
    })
  ];
}

