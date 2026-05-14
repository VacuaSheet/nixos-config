# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, inputs, ... }:
let
  # 2. Crie um atalho para os pacotes unstable
    unstable = import inputs.unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./squidservers.nix
    ];

  # Define o Zen Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # "boot.kernelParams"  Remove a espera pelas portas seriais inúteis que tem mais de 30 anos (Ganha ~5 segundos de timeout)
  boot.kernelParams = [ "amd_pstate=active" "8250.nr_uarts=0" "usbcore.autosuspend=-1" ]; #"amd_pstate=active" Ativa o controle fino de energia/clocks 
  # Garante que o driver carregue cedo no boot para evitar problemas de resolução
  boot.initrd.kernelModules = [ "amdgpu" ];
  # Isso garante que os módulos de virtualização sejam carregados
  boot.kernelModules = [ "kvm-amd" "i2c-dev" ]; # ou "kvm-intel" se seu processador for Intel  
  # Ignora a espera pela rede para abrir o login (Opcional, acelera o carregamento do Plasma)
  systemd.services.NetworkManager-wait-online.enable = false;
  # Reduz o tempo de espera no menu do NixOS 
  boot.loader.timeout = 2;

  # Gaming: Gamemode & Steam
  programs.gamemode.enable = true;
  programs.steam.enable = true;

  # Configuração TPM
  boot.initrd.availableKernelModules = [ "tpm_tis" ]; # Driver essencial para o TPM
  # Otimização do Initrd (Ganha tempo no carregamento inicial)
  boot.initrd.systemd.enable = true; # Usa systemd no initrd para maior paralelismo
  boot.initrd.systemd.tpm2.enable = true;
  security.tpm2.enable = true;
  
   boot.kernel.sysctl = {
  "vm.swappiness" = 180; # Força o uso do zram antes de esgotar a RAM física
  "vm.watermark_boost_factor" = 0;
  "vm.watermark_scale_factor" = 125;
  "vm.page-cluster" = 0;
   };


   # "Zé Ram" ZRAM
   zramSwap = {
     enable = true;
     algorithm = "lz4"; # Mais rapido para 4.2GHz
     memoryPercent = 50; # reserva 30% de ram
   };

   # Limpeza e Saúde do SSD
   services.fstrim.enable = true; # Mantem a velocidade do SSD e vida útil

   environment.variables.AMD_VULKAN_ICD = "RADV"; # Força o uso do driver mais estável por padrão

   virtualisation.virtualbox.guest.enable = pkgs.lib.mkForce false;  # Desativa o drive visual box

   # seguração de git mas não nescesaria no kde ou na minah atual configuração  
    programs.ssh.startAgent = false;
    services.gnome.gcr-ssh-agent.enable = false;


      # Ativa o driver AMDGPU e suporte gráfico
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Essencial para Steam/Wine/Jogos
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      rocmPackages.clr # # Aceleração OpenCL para AMD
    libva
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      libva-vdpau-driver
    ];
  };

  networking.hostName = "alligare"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "America/Recife";

  # Select internationalisation properties.
  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
    LC_MESSAGES = "pt_BR.UTF-8"; # Esta linha foca nas ajudas e erros
  };

  # Ativa o Interception Tools para gerenciar periféricos de forma nativa e limpa no Wayland
    services.interception-tools = {
  enable = true;
  udevmonConfig = let
    interception = "${pkgs.interception-tools}/bin";
  in ''
    - JOB: "${interception}/intercept -g $DEVNODE | ${interception}/uinput -d $DEVNODE"
      DEVICE:
        EVENTS:
          EV_KEY: [KEY_CAPSLOCK, KEY_NUMLOCK]
   '';
  };

  # No configuration.nix (Global para todos os usuários)
programs.ssh.extraConfig = ''
  Host github.com
      Hostname ssh.github.com
      Port 443
      User git
'';


  # Habilita o servidor de interface gráfica (X11)
  # You can disable this if you're only using the Wayland session.
   services.xserver.enable = true; # Nescessario mesmo ao usar XWayland
 
   # Ativação e configuração do XWayland
   services.displayManager.sddm.wayland.enable = true;
   services.displayManager.defaultSession = "plasma"; # Para o Plasma 6/Wayland
   programs.xwayland.enable = true;

    # Habilita o gerenciador de login (SDDM)
  services.displayManager.sddm.enable = true;
  # Habilita o ambiente de desktop KDE Plasma 6
  services.desktopManager.plasma6.enable = true;
  # Garante que o driver moderno de inputs gerencie o teclado no Wayland
    services.libinput.enable = true;
  # Configure keymap in X11
     services.xserver.xkb = {
       layout = "br";
       variant = "";
       # Adiciona opções para forçar o comportamento correto dos LEDs e modificadores
       	options = "compat:complete,grp:alt_shift_toggle";
      };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Define a variável de ambiente globalmente
  environment.sessionVariables = {
    nh_FLAKE = "/etc/nixos";
  };
   
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 7";
    flake = "/etc/nixos";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users._-_-yakov_-_- = {
    isNormalUser = true;
    description = "Tiago da Silva Santos";
    extraGroups = [ "networkmanager" "wheel" "networkmanager" "libvirtd" "microvm" "podman" "docker" "video" "kvm" "input" ];
    packages = with pkgs; [
      kdePackages.kate
        # Ferramentas de Terminal e Git
    git
    git-lfs
    gh                  # GitHub CLI
    tldr                # Resumo de comandos (melhor que o 'man')
    direnv              # MÁGICA: carrega ambientes de dev ao entrar na pasta
        # Utilitários
    #postman             # Para testar APIs
    #docker-compose      # Orquestração de containers
    #  thunderbird
       obsidian # Bloco de notas e mais
        # Redes sociais
    # Tema cmd
    eza
    bat
    fzf
    libsForQt5.qtstyleplugin-kvantum
    papirus-icon-theme
    layan-gtk-theme # O tema Layan se assemelha ao visual "moderno/azul" do Zorin
    ];
  };

    programs.git.enable = true;
   programs.git.lfs.enable = true;
  
    # Atalhos
programs.zsh = {
  # O 'enable = true' aqui no sistema é necessário para que o NixOS 
  # entenda que deve aplicar estas configurações globais ao Zsh.
  enable = true; 

            # 	vulkan-toolsvulkan-toolsAtalhos
    shellAliases = {
     nos = "nh os switch /home/_-_-yakov_-_-/nixos-config";
      nosu = "nh os switch -u /home/_-_-yakov_-_-/nixos-config";
      n = "nano";
      clx = "rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/info/* 2>/dev/null || true && nix-store --optimise";
      forall = "nh os switch -u /home/_-_-yakov_-_-/nixos-config && flatpak update -y";
      #hms = "home-manager switch --flake /etc/nixos#_-_-yakov_-_-";
      #hmn  = "home-manager news --flake /etc/nixos#_-_-yakov_-_-"; # Atalho para as notícias
      gp = "git -C /home/_-_-yakov_-_-/nixos-config push origin main"; # Git push
        ls = "eza --icons --group-directories-first";
        ll = "eza -l --icons --git";
        cat = "bat";
        c = "printf \"\\033[2J\\033[3J\\033[1;1H\"" ;
        flat = "f() { flatpak remote-add --if-not-exists flathub https://dl.flathub.org && flatpak install flathub \"$1\"; }; f";
        goanime = "$HOME/go/bin/goanime";
         };  
             
     # 2. A função para o sga aceitar argumentos (FORA do bloco acima)
         interactiveShellInit = ''
      # Função para Add e Commit rápido
    sga() {
      git -C "/home/_-_-yakov_-_-/nixos-config" add .
      
      # No Zsh, podemos usar a expansão de parâmetros diretamente
      local msg="''${1:-update}" 
      
      git -C "/home/_-_-yakov_-_-/nixos-config" commit -m "$msg - ''$(date +'%Y-%m-%d %H:%M')"
    }

    # Função para Limpeza e Rebuild (usando o nh)
     av() {
         echo "🗑️ Esvaziando a Lixeira do usuário..."
         rm -rf ~/.local/share/Trash/*
 
      if [ -z "$1" ]; then
         echo "🚨 Iniciando LIMPEZA PROFUNDA (Removendo TUDO exceto a atual)..."
         # Remove todas as gerações de todos os perfis (usuário e sistema)
         sudo nix-collect-garbage -d
         # Otimiza o banco de dados do Nix e remove links mortos
         sudo nix-store --optimize
         sudo nix-store --gc
      else
         echo "🧹 Mantendo as últimas $1 versões..."
         sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations "+$1"
         sudo nix-collect-garbage
      fi

      echo "⚙️ Aplicando Flake e atualizando sistema..."
      nh os switch /home/_-_-yakov_-_-/nixos-config
    }

'';

};

 # Deixar o comando goanime verde no zsh
   environment.sessionVariables = {
    EDITOR = "nano";
    PATH = [ "$HOME/go/bin" ];
   };

   programs.git.config.safe.directory = [ "/etc/nixos" ];

  
   # Configurações 
    nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Aumenta o número de conexões HTTP simultâneas
  http-connections = 50;
  
  # Aumenta o número de downloads paralelos de substitutos (pacotes binários)
  max-substitution-jobs = 20;

  # Aumenta o tamanho do buffer de download para evitar avisos e lentidão em arquivos grandes
  download-buffer-size = 536870912; # 500 MB
   };

   # Para programas que estão no flatpak como o steam conversar com o hardower da maquina
    services.dbus.enable = true;
    xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "kde";
   };


  # Corretor Ortográfico Global
  # Garante que o sistema aponte para onde os dicionários estão
  #environment.variables.DICPATH = "/run/current-system/sw/share/hunspell";

  # Gamescope
   programs.gamescope = {
     enable = true;
     capSysNice = true; # Melhora a prioridade de CPU para o jogo
   };

   # Bluetooth & WI-FI
   hardware.enableAllFirmware = true;

   # Habilitar o uinput:
   hardware.uinput.enable = true;
	
   # Ativa o Docker
   # virtualisation.docker.enable = true;

  # Permite programas e drivers proprietarios
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # APPs Global
  environment.systemPackages = with pkgs; [
  pkgs.tpm2-tss # TPM seguraça
   qemu # Esqueleto da máquina virtua
  OVMF # Necessário se você quiser simular UEFI/Secure Boot na VM
  amdgpu_top    # Monitor de GPU AMD estilo 'htop'
  btop          # Monitor de sistema bonitão (CPU, RAM, Rede)
  # VPN
  protonvpn-gui  # Ou protonvpn-cli
   # Temas de ícones e aplicações
  papirus-icon-theme
  # Breeze-dark ou outro tema dark para base
  kdePackages.breeze-gtk
  # Opcional: motor kvantum para temas mais profundos
  kdePackages.qtstyleplugin-kvantum 
  kdePackages.breeze-icons # Base para muitos temas monochrome
  #qt6Packages.fcitx5-configtool    # Interface para ajustes visuais se precisar
 # hunspellDicts.pt-br # Dicionário rigoroso
 # hunspell 
  nil       # O servidor LSP para Nix
  nixd
  nixpkgs-fmt # Opcional: formatador de código para Nix
  # Para Plasma 6
  kdePackages.plasma-browser-integration
  nh # O executável do helper
  home-manager
  freerdp
  vulkan-tools
  p7zip # Descompactador
  rar   # Descompactador não freeUser	
  alsa-utils # APP mantedor do unmute
  alsa-tools 
  steamtinkerlaunch
  waydroid

         # Antvirus
           clamav
   	   clamtk
         # Ante-Telemetria
           opensnitch-ui
    mangohud  #  Overlay para ver FPS, temperatura e uso de CPU/GPU (AMD)
  # Adicione ferramentas úteis para monitorar o seu AMD no PC real:
    amdgpu_top  # Se tiver GPU AMD, para ver o uso de vídeo
    lm_sensors  # Para ver temperaturas reais (comando 'sensors')
    lact # Controle de fans e overclock (Interface gráfica)/Gerenciador de energia amd
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget # Baixar qualquer coisa via comando
    pavucontrol # controlador de audio
    usbutils # Para consultar e gerenciar barramentos e dispositivos USB no Linux
    direnv
     mpv # OBRIGATÓRIO: O GoAnime usa ele para dar o play
     mpv-handler
     ani-cli
     yt-dlp
     mov-cli
     fzf
     go # Linguagem de programação
       gcc
       gnumake
       pkg-config
     pciutils
     lutris
   # Games config
     wineWowPackages.staging # Wine com suporte 32/64 bits
     libvdpau-va-gl
     gst_all_1.gstreamer
     gst_all_1.gst-plugins-ugly
     gst_all_1.gst-plugins-base
     gst_all_1.gst-libav # Isso resolve o erro do libavfilter
    anydesk # Gerenciador de outro pc
    appimage-run
    bubblewrap
      jdk17 # Java
    crow-translate # Tradutor_D_Tela
     evtest
     brightnessctl 
     openrgb
     iptables
  ];

   virtualisation.waydroid.enable = true; # Android

   # Configuração VS Code
    # Isso ajuda extensões do VS Code a executarem binários que esperam bibliotecas padrão em locais convencionais.
    programs.nix-ld.enable = true; 
    programs.nix-ld.libraries = with pkgs; [
     stdenv.cc.cc
     zlib
     openssl
     curl
     expat
     libuuid
     libxml2
     glibc
     icu
     # bibliotecas que o httpx (usado pelo bot) precisa
    ];

     # VS Code automatico
      programs.bash.interactiveShellInit = ''
      eval "$(direnv hook bash)"
      '';

  # Isso salva o estado do Alsamixer (Mute/Unmute) automaticamente
    hardware.alsa.enablePersistence = true;
 
  # Não permite mudar as saidas de audio da parte trazeira enquanto a da frente esta plugada
    systemd.user.services.unmute-audio = {
  description = "Unmute e volume no máximo para o Headset";
  wantedBy = [ "graphical-session.target" ];
  partOf = [ "graphical-session.target" ];
  serviceConfig = {
    Type = "oneshot";
    # Garante que o sink padrão não esteja mudo e define volume em 1.0 (100%)
    ExecStart = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0";
    ExecStartPost = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0";
    RemainAfterExit = true;
  };
};

   services.pipewire.wireplumber.extraConfig."10-disable-autoswitch" = {
  "wireplumber.settings" = {
    "bluetooth.autoswitch-to-headset-profile" = false; # Útil se for bluetooth
  };
  "monitor.alsa.rules" = [
    {
      matches = [
        { "node.name" = "~alsa_output.*"; }
      ];
      actions = {
        update-props = {
          "node.pause-on-idle" = false;
          "session.suspend-timeout-seconds" = 0; # Evita que a porta entre em repouso
        };
      };
    }
  ];
};

     # Dentro do seu configuration.nix (chamado pelo flake)
       services.flatpak = {
        enable = true;
        overrides = {
         "net.lutris.Lutris" = {
            Context = {
            devices = [ "all" ];
            filesystems = [
            "xdg-run/render:ro"
            "/home/_-_-yakov_-_-/Games/Lutris" # Sua pasta de jogos
             ];
            };
           };
          };
         };

   # Ativa o serviço e o pacote do OpenRGB com regras de hardware injetadas
     services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb;
    };
/*
  # Processo persistente em segundo plano que força a ativação física das luzes do teclado:
    systemd.user.services.fix-keyboard-leds = {
  description = "Forçar sincronização de LEDs do teclado no Wayland";
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = let
      script = pkgs.writeShellScript "led-sync" ''
        # Monitora os eventos do teclado e força o brilho do LED correspondente
        ${pkgs.evtest}/bin/evtest /dev/input/by-path/*-kbd | while read -r line; do
          if echo "$line" | grep -q "code 58 (KEY_CAPSLOCK), value 1"; then
            # Aguarda o Wayland processar e força o LED do Caps a ligar/desligar
            sleep 0.05
            current=$(${pkgs.brightnessctl}/bin/brightnessctl --device='*::capslock' get)
            if [ "$current" -eq 0 ]; then
              ${pkgs.brightnessctl}/bin/brightnessctl --device='*::capslock' set 1
            else
              ${pkgs.brightnessctl}/bin/brightnessctl --device='*::capslock' set 0
            fi
          elif echo "$line" | grep -q "code 69 (KEY_NUMLOCK), value 1"; then
            sleep 0.05
            current=$(${pkgs.brightnessctl}/bin/brightnessctl --device='*::numlock' get)
            if [ "$current" -eq 0 ]; then
              ${pkgs.brightnessctl}/bin/brightnessctl --device='*::numlock' set 1
            else
              ${pkgs.brightnessctl}/bin/brightnessctl --device='*::numlock' set 0
            fi
          fi
        done
      '';
    in "${script}";
    Restart = "always";
  };
};

services.udev.extraRules = ''
  KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
  SUBSYSTEM=="leds", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod -R 666 /sys/class/leds/%k/brightness"
''; */


 /*  # Ativa o daemon do OpenSnitch
  # 1. Overlay para "pular" o build que falha no Kernel 6.19
  nixpkgs.overlays = [
    (final: prev: {
      # Substitui o pacote que dá erro por uma pasta vazia.
      # Resolve o erro de "no member named ns_id" instantaneamente.
      opensnitch-ebpf = pkgs.runCommand "dummy-ebpf" {} "mkdir -p $out";
    })
  ];

  # 2. Configuração do serviço
  services.opensnitch = {
    enable = true;
    settings.proc_monitor_method = "proc";
  };*/

     networking.extraHosts = ''
     0.0.0.0 telemetry.take2games.com
     0.0.0.0 prod.telemetry.ros.rockstargames.com
     0.0.0.0 mtls.telemetry.ros.rockstargames.com
     0.0.0.0 analytics.socialclub.rockstargames.com
    '';

# Isso tenta forçar o estado do hardware no boot
systemd.user.services.unmute-hardware-audio = {
  description = "Unmute hardware channels";
  wantedBy = [ "default.target" ];
  serviceConfig = {
    Type = "oneshot";
    # Desmuda o Master e o Headphone no hardware
    ExecStart = "${pkgs.alsa-utils}/bin/amixer -c 0 sset Master unmute 100%";
    ExecStartPost = "${pkgs.alsa-utils}/bin/amixer -c 0 sset Headphone unmute 100%";
    RemainAfterExit = true;
  };
};

  # Habilita o serviço do Ollama
   services.ollama = {
    enable = true;
    acceleration = false; # Habilita aceleração para GPUs AMD (incluindo integradas)
      environmentVariables = {
    OLLAMA_ORIGINS = "*";
   # OLLAMA_ORIGINS = "app://obsidian.md*"; 
    HSA_OVERRIDE_GFX_VERSION = "9.0.0";  
    OLLAMA_MODELS = "/srv/ollama_models";
    OLLAMA_MAX_LOADED_MODELS = "1";    # Garante que APENAS 1 modelo carregue por vez
    OLLAMA_KEEP_ALIVE = "97s";         # O modelo fica na RAM por exatamente 1min e 37s
    };
   };

   # Força o Systemd a ignorar o padrão do módulo e usar seu caminho
     systemd.services.ollama = {
      serviceConfig = {
    # Isso permite que o serviço escreva na pasta /srv
       ReadWritePaths = [ "/srv/ollama_models" ];
    
    # Reforce as variáveis aqui para garantir que elas sobrescrevam o padrão
      Environment = [
        "OLLAMA_MODELS=/srv/ollama_models"
        "OLLAMA_ORIGINS=*"
        "HSA_OVERRIDE_GFX_VERSION=9.0.0"
        ];
      };
    };

 #teclado
╚═⋗  nix-shell -p evtest --run "sudo evtest"
No device specified, trying to scan all of /dev/input/event*
Available devices:
/dev/input/event0:	ZXWMicroChip ZXWMutiDev
/dev/input/event1:	ZXWMicroChip ZXWMutiDev Keyboard
/dev/input/event10:	HDA Digital PCBeep
/dev/input/event11:	HD-Audio Generic Rear Mic
/dev/input/event12:	HD-Audio Generic Front Mic
/dev/input/event13:	HD-Audio Generic Line
/dev/input/event14:	HD-Audio Generic Line Out Front
/dev/input/event15:	HD-Audio Generic Line Out Surround
/dev/input/event16:	HD-Audio Generic Line Out CLFE
/dev/input/event17:	HD-Audio Generic Front Headphone
/dev/input/event18:	ZXWMicroChip ZXWMutiDev
/dev/input/event19:	ZXWMicroChip ZXWMutiDev Keyboard
/dev/input/event2:	ZXWMicroChip ZXWMutiDev Mouse
/dev/input/event3:	ZXWMicroChip ZXWMutiDev Wireless Radio Control
/dev/input/event4:	USB OPTICAL MOUSE 
/dev/input/event5:	Power Button
/dev/input/event6:	Power Button
/dev/input/event7:	Eee PC WMI hotkeys
/dev/input/event8:	HD-Audio Generic HDMI/DP,pcm=3
/dev/input/event9:	HD-Audio Generic HDMI/DP,pcm=7
Select the device event number [0-19]: 19
Input driver version is 1.0.1
Input device ID: bus 0x3 vendor 0x5566 product 0x8 version 0x0
Input device name: "ZXWMicroChip ZXWMutiDev Keyboard"
Supported events:
  Event type 0 (EV_SYN)
  Event type 1 (EV_KEY)
    Event code 1 (KEY_ESC)
    Event code 2 (KEY_1)
    Event code 3 (KEY_2)
    Event code 4 (KEY_3)
    Event code 5 (KEY_4)
    Event code 6 (KEY_5)
    Event code 7 (KEY_6)
    Event code 8 (KEY_7)
    Event code 9 (KEY_8)
    Event code 10 (KEY_9)
    Event code 11 (KEY_0)
    Event code 12 (KEY_MINUS)
    Event code 13 (KEY_EQUAL)
    Event code 14 (KEY_BACKSPACE)
    Event code 15 (KEY_TAB)
    Event code 16 (KEY_Q)
    Event code 17 (KEY_W)
    Event code 18 (KEY_E)
    Event code 19 (KEY_R)
    Event code 20 (KEY_T)
    Event code 21 (KEY_Y)
    Event code 22 (KEY_U)
    Event code 23 (KEY_I)
    Event code 24 (KEY_O)
    Event code 25 (KEY_P)
    Event code 26 (KEY_LEFTBRACE)
    Event code 27 (KEY_RIGHTBRACE)
    Event code 28 (KEY_ENTER)
    Event code 30 (KEY_A)
    Event code 31 (KEY_S)
    Event code 32 (KEY_D)
    Event code 33 (KEY_F)
    Event code 34 (KEY_G)
    Event code 35 (KEY_H)
    Event code 36 (KEY_J)
    Event code 37 (KEY_K)
    Event code 38 (KEY_L)
    Event code 39 (KEY_SEMICOLON)
    Event code 40 (KEY_APOSTROPHE)
    Event code 41 (KEY_GRAVE)
    Event code 43 (KEY_BACKSLASH)
    Event code 44 (KEY_Z)
    Event code 45 (KEY_X)
    Event code 46 (KEY_C)
    Event code 47 (KEY_V)
    Event code 48 (KEY_B)
    Event code 49 (KEY_N)
    Event code 50 (KEY_M)
    Event code 51 (KEY_COMMA)
    Event code 52 (KEY_DOT)
    Event code 53 (KEY_SLASH)
    Event code 55 (KEY_KPASTERISK)
    Event code 57 (KEY_SPACE)
    Event code 58 (KEY_CAPSLOCK)
    Event code 59 (KEY_F1)
    Event code 60 (KEY_F2)
    Event code 61 (KEY_F3)
    Event code 62 (KEY_F4)
    Event code 63 (KEY_F5)
    Event code 64 (KEY_F6)
    Event code 65 (KEY_F7)
    Event code 66 (KEY_F8)
    Event code 67 (KEY_F9)
    Event code 68 (KEY_F10)
    Event code 69 (KEY_NUMLOCK)
    Event code 70 (KEY_SCROLLLOCK)
    Event code 71 (KEY_KP7)
    Event code 72 (KEY_KP8)
    Event code 73 (KEY_KP9)
    Event code 74 (KEY_KPMINUS)
    Event code 75 (KEY_KP4)
    Event code 76 (KEY_KP5)
    Event code 77 (KEY_KP6)
    Event code 78 (KEY_KPPLUS)
    Event code 79 (KEY_KP1)
    Event code 80 (KEY_KP2)
    Event code 81 (KEY_KP3)
    Event code 82 (KEY_KP0)
    Event code 83 (KEY_KPDOT)
    Event code 86 (KEY_102ND)
    Event code 87 (KEY_F11)
    Event code 88 (KEY_F12)
    Event code 96 (KEY_KPENTER)
    Event code 98 (KEY_KPSLASH)
    Event code 99 (KEY_SYSRQ)
    Event code 102 (KEY_HOME)
    Event code 103 (KEY_UP)
    Event code 104 (KEY_PAGEUP)
    Event code 105 (KEY_LEFT)
    Event code 106 (KEY_RIGHT)
    Event code 107 (KEY_END)
    Event code 108 (KEY_DOWN)
    Event code 109 (KEY_PAGEDOWN)
    Event code 110 (KEY_INSERT)
    Event code 111 (KEY_DELETE)
    Event code 113 (KEY_MUTE)
    Event code 114 (KEY_VOLUMEDOWN)
    Event code 115 (KEY_VOLUMEUP)
    Event code 116 (KEY_POWER)
    Event code 117 (KEY_KPEQUAL)
    Event code 119 (KEY_PAUSE)
    Event code 120 (KEY_SCALE)
    Event code 127 (KEY_COMPOSE)
    Event code 128 (KEY_STOP)
    Event code 129 (KEY_AGAIN)
    Event code 130 (KEY_PROPS)
    Event code 131 (KEY_UNDO)
    Event code 132 (KEY_FRONT)
    Event code 133 (KEY_COPY)
    Event code 134 (KEY_OPEN)
    Event code 135 (KEY_PASTE)
    Event code 136 (KEY_FIND)
    Event code 137 (KEY_CUT)
    Event code 138 (KEY_HELP)
    Event code 139 (KEY_MENU)
    Event code 140 (KEY_CALC)
    Event code 142 (KEY_SLEEP)
    Event code 143 (KEY_WAKEUP)
    Event code 144 (KEY_FILE)
    Event code 150 (KEY_WWW)
    Event code 152 (KEY_SCREENLOCK)
    Event code 155 (KEY_MAIL)
    Event code 156 (KEY_BOOKMARKS)
    Event code 158 (KEY_BACK)
    Event code 159 (KEY_FORWARD)
    Event code 161 (KEY_EJECTCD)
    Event code 163 (KEY_NEXTSONG)
    Event code 164 (KEY_PLAYPAUSE)
    Event code 165 (KEY_PREVIOUSSONG)
    Event code 166 (KEY_STOPCD)
    Event code 167 (KEY_RECORD)
    Event code 168 (KEY_REWIND)
    Event code 169 (KEY_PHONE)
    Event code 171 (KEY_CONFIG)
    Event code 172 (KEY_HOMEPAGE)
    Event code 173 (KEY_REFRESH)
    Event code 174 (KEY_EXIT)
    Event code 176 (KEY_EDIT)
    Event code 177 (KEY_SCROLLUP)
    Event code 178 (KEY_SCROLLDOWN)
    Event code 181 (KEY_NEW)
    Event code 182 (KEY_REDO)
    Event code 183 (KEY_F13)
    Event code 184 (KEY_F14)
    Event code 185 (KEY_F15)
    Event code 186 (KEY_F16)
    Event code 187 (KEY_F17)
    Event code 188 (KEY_F18)
    Event code 189 (KEY_F19)
    Event code 190 (KEY_F20)
    Event code 191 (KEY_F21)
    Event code 192 (KEY_F22)
    Event code 193 (KEY_F23)
    Event code 194 (KEY_F24)
    Event code 206 (KEY_CLOSE)
    Event code 207 (KEY_PLAY)
    Event code 208 (KEY_FASTFORWARD)
    Event code 209 (KEY_BASSBOOST)
    Event code 210 (KEY_PRINT)
    Event code 212 (KEY_CAMERA)
    Event code 216 (KEY_CHAT)
    Event code 217 (KEY_SEARCH)
    Event code 219 (KEY_FINANCE)
    Event code 223 (KEY_CANCEL)
    Event code 224 (KEY_BRIGHTNESSDOWN)
    Event code 225 (KEY_BRIGHTNESSUP)
    Event code 228 (KEY_KBDILLUMTOGGLE)
    Event code 229 (KEY_KBDILLUMDOWN)
    Event code 230 (KEY_KBDILLUMUP)
    Event code 231 (KEY_SEND)
    Event code 232 (KEY_REPLY)
    Event code 233 (KEY_FORWARDMAIL)
    Event code 234 (KEY_SAVE)
    Event code 235 (KEY_DOCUMENTS)
    Event code 240 (KEY_UNKNOWN)
    Event code 241 (KEY_VIDEO_NEXT)
    Event code 244 (KEY_BRIGHTNESS_ZERO)
    Event code 256 (BTN_0)
    Event code 353 (KEY_SELECT)
    Event code 354 (KEY_GOTO)
    Event code 358 (KEY_INFO)
    Event code 362 (KEY_PROGRAM)
    Event code 366 (KEY_PVR)
    Event code 370 (KEY_SUBTITLE)
    Event code 372 (KEY_ZOOM)
    Event code 374 (KEY_KEYBOARD)
    Event code 375 (KEY_SCREEN)
    Event code 376 (KEY_PC)
    Event code 377 (KEY_TV)
    Event code 378 (KEY_TV2)
    Event code 379 (KEY_VCR)
    Event code 380 (KEY_VCR2)
    Event code 381 (KEY_SAT)
    Event code 383 (KEY_CD)
    Event code 384 (KEY_TAPE)
    Event code 386 (KEY_TUNER)
    Event code 387 (KEY_PLAYER)
    Event code 389 (KEY_DVD)
    Event code 392 (KEY_AUDIO)
    Event code 393 (KEY_VIDEO)
    Event code 396 (KEY_MEMO)
    Event code 397 (KEY_CALENDAR)
    Event code 398 (KEY_RED)
    Event code 399 (KEY_GREEN)
    Event code 400 (KEY_YELLOW)
    Event code 401 (KEY_BLUE)
    Event code 402 (KEY_CHANNELUP)
    Event code 403 (KEY_CHANNELDOWN)
    Event code 405 (KEY_LAST)
    Event code 407 (KEY_NEXT)
    Event code 408 (KEY_RESTART)
    Event code 409 (KEY_SLOW)
    Event code 410 (KEY_SHUFFLE)
    Event code 412 (KEY_PREVIOUS)
    Event code 416 (KEY_VIDEOPHONE)
    Event code 417 (KEY_GAMES)
    Event code 418 (KEY_ZOOMIN)
    Event code 419 (KEY_ZOOMOUT)
    Event code 420 (KEY_ZOOMRESET)
    Event code 421 (KEY_WORDPROCESSOR)
    Event code 422 (KEY_EDITOR)
    Event code 423 (KEY_SPREADSHEET)
    Event code 424 (KEY_GRAPHICSEDITOR)
    Event code 425 (KEY_PRESENTATION)
    Event code 426 (KEY_DATABASE)
    Event code 427 (KEY_NEWS)
    Event code 428 (KEY_VOICEMAIL)
    Event code 429 (KEY_ADDRESSBOOK)
    Event code 430 (KEY_MESSENGER)
    Event code 431 (KEY_DISPLAYTOGGLE)
    Event code 432 (KEY_SPELLCHECK)
    Event code 433 (KEY_LOGOFF)
    Event code 439 (KEY_MEDIA_REPEAT)
    Event code 442 (KEY_IMAGES)
    Event code 576 (KEY_BUTTONCONFIG)
    Event code 577 (KEY_TASKMANAGER)
    Event code 578 (KEY_JOURNAL)
    Event code 579 (KEY_CONTROLPANEL)
    Event code 580 (KEY_APPSELECT)
    Event code 581 (KEY_SCREENSAVER)
    Event code 582 (KEY_VOICECOMMAND)
    Event code 583 (KEY_ASSISTANT)
    Event code 584 (KEY_KBD_LAYOUT_NEXT)
    Event code 585 (KEY_EMOJI_PICKER)
    Event code 586 (KEY_DICTATE)
    Event code 587 (KEY_CAMERA_ACCESS_ENABLE)
    Event code 588 (KEY_CAMERA_ACCESS_DISABLE)
    Event code 589 (KEY_CAMERA_ACCESS_TOGGLE)
    Event code 592 (KEY_BRIGHTNESS_MIN)
    Event code 593 (KEY_BRIGHTNESS_MAX)
    Event code 596 (?)
    Event code 597 (?)
    Event code 598 (?)
  Event type 2 (EV_REL)
    Event code 6 (REL_HWHEEL)
    Event code 12 (REL_HWHEEL_HI_RES)
  Event type 3 (EV_ABS)
    Event code 32 (ABS_VOLUME)
      Value      0
      Min        1
      Max      672
  Event type 4 (EV_MSC)
    Event code 4 (MSC_SCAN)
  Event type 17 (EV_LED)
    Event code 0 (LED_NUML) state 1
    Event code 1 (LED_CAPSL) state 1
    Event code 2 (LED_SCROLLL) state 0
    Event code 3 (LED_COMPOSE) state 0
    Event code 4 (LED_KANA) state 0
Key repeat handling:
  Repeat type 20 (EV_REP)
    Repeat code 0 (REP_DELAY)
      Value    250
    Repeat code 1 (REP_PERIOD)
      Value     33
Properties:
Testing ... (interrupt to exit)
#Teclado

  # Habilita o suporte a 32 bits para o Wine/Lutris enxergar a placa
    hardware.amdgpu.initrd.enable = true;

   # Ativa o motor da "box" (Podman)
  virtualisation.podman = {
    enable = true;
  #  dockerCompat = true; # Essencial para o WinBoat reconhecer o Podman
  #  dockerSocket.enable = true; # Cria o socket que o WinBoat procura
    defaultNetwork.settings.dns_enabled = true;
  };


  # Ativa o serviço qe baixar a lista de vírus novos (Fundamental!)
     services.clamav.daemon.enable = false; # O tempo todo ligado se true
     services.clamav.updater.enable = true; # Atualização de vírus

  networking.networkmanager.wifi.powersave = false;
  
  # O app do Proton funciona melhor com o gnome-keyring mesmo no KDE
  services.gnome.gnome-keyring.enable = true;

  # Garante que o NetworkManager gerencie a conexão
  networking.networkmanager.enable = true;

   fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
  corefonts          # Fontes básicas da Microsoft
  vista-fonts         # Fontes como Calibri e Cambria
  liberation_ttf     # Substituto open source essencial
  ];

     # 1. Ativa o daemon da virtualização (KVM/QEMU por baixo)
  virtualisation.libvirtd.enable = true;

  # 2. Ativa a interface gráfica do virt-manager
  programs.virt-manager.enable = true;
  
  # systemd.services.lactd.enable = true; # ativar o gerenciador de energia amd
  # 1. Habilita o gerenciamento de energia base do NixOS
  powerManagement.enable = true;

  # 2. Perfil de energia (substitui o TLP, ideal para desktops modernos)
  # Permite alternar entre "Performance", "Balanced" e "Power Saver"
  services.power-profiles-daemon.enable = true;

  # 4. Evita que o PC suspenda sozinho (opcional para desktops)
  /*systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;*/
  
  #limpesa automatica de gerações
   /* nix.gc = {
    automatic = true;
    dates = "weekly";
    # Este comando deleta todas as gerações do sistema exceto as últimas 7
    options = "--delete-old"; */

  # Adicionalmente, para limpar perfis de usuário e ser mais preciso:
  system.activationScripts.cleanupOldGenerations = {
    text = ''
      ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +7
    '';
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
     pinentryPackage = pkgs.pinentry-qt; # Versão para KDE/Qt
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
   networking.firewall.allowedTCPPorts = [ 80 443 3000 ];
   networking.firewall.allowedUDPPorts = [ 53 1234 ];
  # Habilita wifi automaticamente
   security.pam.services.sddm.enableKwallet = true;
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Força o NixOS a usar a camada nftables e ativa o pacote de compatibilidade iptables-nft
networking.nftables.enable = true;

# Mantém a interface do Waydroid liberada no firewall
networking.firewall.trustedInterfaces = [ "waydroid0" ];

   # Token (classic)
    nix.extraOptions = ''
    !include /etc/nix/access-tokens
   '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment? # build limpo 1
}
