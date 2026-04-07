{ pkgs }:

let
  # 1. Definimos o AppImage
  # IMPORTANTE: Substitua o 'sha256' abaixo pelo código que o 'nix-prefetch-url' te deu
  appImage = pkgs.appimageTools.wrapType2 {
    pname = "squidservers-raw";
    version = "0.6.7";
    src = pkgs.fetchurl {
      url = "https://squidservers.com";
      sha256 = "1fa5mcli68y3bra5q33k2d7hl6qyv9bjwrwbg97dnwh50nwbllh8"; 
    };
  };
in
# 2. O script que cria a "coleira" de segurança
pkgs.writeShellScriptBin "squidservers" ''
  ${pkgs.bubblewrap}/bin/bwrap \
    --ro-bind /nix /nix \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --bind $HOME/Apps/SquidServersData $HOME \
    --unshare-all \
    --share-net \
    ${appImage}/bin/squidservers-raw
''
