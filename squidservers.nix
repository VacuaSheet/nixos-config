{ pkgs }:

let
  # 1. Definimos o AppImage original com a versão e o hash corretos
  appImage = pkgs.appimageTools.wrapType2 {
    pname = "squidservers-raw";
    version = "0.6.7"; # Adicionei a versão aqui para corrigir o erro
    src = pkgs.fetchurl {
      url = "https://squidservers.com";
      # Substitua pelo hash que você obteve no passo anterior
      sha256 = "sha256-1fa5mcli68y3bra5q33k2d7hl6qyv9bjwrwbg97dnwh50nwbllh8"; 
    };
  };
in
# 2. O resto do script permanece o mesmo
pkgs.writeShellScriptBin "squidservers" ''
  ${pkgs.bubblewrap}/bin/bwrap \
    --ro-bind /nix /nix \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --bind $HOME/SquidServersData $HOME \
    --unshare-all \
    --share-net \
    ${appImage}/bin/squidservers-raw
''
