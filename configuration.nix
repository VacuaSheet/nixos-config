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
  systemd.services.teclado-led-trigger = {
    description = "Gatilho de LED para Caps Lock - Teclado Evolut";
    after = [ "local-fs.target" "systemd-udevd.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ (pkgs.python3.withPackages (ps: [ ps.evdev ])) ];

    # O ExecStart TEM que estar aqui dentro:
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = pkgs.writeScript "caps-trigger-python" ''
        #!${pkgs.python3.withPackages (ps: [ ps.evdev ])}/bin/python
        import evdev
        from evdev import ecodes
        import time

        def monitorar_teclado():
            while True:
                try:
                    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
                    kbd = None
                    for dev in devices:
                        if "ZXWMicroChip" in dev.name:
                            kbd = dev
                            break
                    
                    if kbd:
                        for event in kbd.read_loop():
                            if event.type == ecodes.EV_KEY:
                                data = evdev.categorize(event)
                                if data.scancode == 58 and data.keystate == 1:
                                    time.sleep(0.2)
                                    luzes = kbd.leds()
                                    if ecodes.LED_CAPSL in luzes:
                                        kbd.set_led(ecodes.LED_SCROLLL, 1)
                                        kbd.set_led(3, 1)
                                    else:
                                        kbd.set_led(ecodes.LED_SCROLLL, 0)
                                        kbd.set_led(3, 0)
                except:
                    time.sleep(5)

        monitorar_teclado()
      '';
    }; # Fecha serviceConfig
  }; # Fecha teclado-led-trigger
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
