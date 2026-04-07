{ pkgs }:

let
  # 1. Definimos o AppImage original com verificação de segurança (Hash)
  appImage = pkgs.appimageTools.wrapType2 {
    name = "squidservers-raw";
    src = pkgs.fetchurl {
      url = "https://squidservers.com";
      # O Nix confere esse código. Se o arquivo for alterado no site, ele não instala.
      sha256 = "sha256-1fa5mcli68y3bra5q33k2d7hl6qyv9bjwrwbg97dnwh50nwbllh8"; 
    };
  };
in
# 2. Criamos o "Wrap" (a coleira de segurança) usando Bubblewrap
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
