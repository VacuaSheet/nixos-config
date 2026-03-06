{ config, pkgs, lib, inputs, ... }:

 {

  home.username = "_-_-yakov_-_-";
  home.homeDirectory = "/home/_-_-yakov_-_-";

  # Pacotes instalados
  home.packages = with pkgs; [
    git
    docker-compose
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.kitty  
    libvirt
    virt-viewer 
    freerdp # Necessário para o LSW exibir as janelas
    hunspell
    hunspellDicts.pt_BR
  ];

     # 1. Habilita o dconf dentro do Home Manager
  dconf.enable = true;

  # 2. Define as configurações do Typing Booster de forma limpa
  dconf.settings = {
    "org/freedesktop/ibus/engine/typing-booster" = {
  # Idioma e Comportamento de Escrita
  current-input-method = "pt_BR";
  space-acceptance-config = "completions";
  propose-enabled = true;

  # SEGURANÇA: Não oferecer sugestões em campos de senha
  # (Corrigido o erro de digitação: o nome da opção é 'preedit-password-fields' com dois 'e')
  preedit-password-fields = false;

  # LISTA NEGRA: Onde o Typing Booster NÃO deve aparecer
  # Adicionamos 'kitty' aqui para não bugar seu Zsh + Starship
  off-context-list = "kitty,konsole,yakuake,terminal,foot,alacritty,ssh,sudo,gpg";
    };
   };   

   # MangoHud (Contador de FPS) configurado por código
   programs.mangohud = {
    enable = true;
    settings = {
      full = true;
      cpu_temp = true;
      gpu_temp = true;
      fps_limit = 144;
     };
    };

    

  # 2. Configuração do Kitty (Ajustado para usar o Zsh)
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

     keybindings = {
    "ctrl+t" = "new_tab";
    "ctrl+tab" = "next_tab";
    "ctrl+shift+tab" = "previous_tab";
    "ctrl+w" = "close_tab";
    };  
 
    settings = {
      style = "numbers,changes";
      #Em caso de erro de GPU
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "no";
      linux_display_backend = "x11";
      #----------------------------
      shell = "${pkgs.zsh}/bin/zsh"; # <--- Movido para o lugar correto
      padding_window_width = 10;
      background_opacity = "0.9";
      dynamic_background_opacity = "no";
      confirm_os_window_close = 0;
      background = "#1a1b26";
      foreground = "#c0caf5";
      tab_bar_style = "powerline"; # Deixa as abas bonitonas com o Starship
    #  tab_powerline_style = "slanted";
      active_tab_foreground = "#1a1b26";
      active_tab_background = "#7aa2f7";
      window_padding_width = 15; # Dá um "respiro" nas bordas
      active_border_color = "#7aa2f7";
      inactive_border_color = "#1a1b26";
     #Estilo de abas "Modernas"
    #   tab_bar_margin_width = 5;
    #   tab_bar_margin_height = 5;
    #  tab_bar_style = "separator";
    #  tab_separator = " | ";
    };
  };

  # 3. Configuração do Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
     # if [ -e /etc/bashrc ]; then . /etc/bashrc; fi # Carrega aliases globais
 [[ -n "$BASH_VERSION" ]] && [ -e /etc/bashrc ] && . /etc/bashrc
      # FIX PARA A TECLA DELETE (Apagar para frente)
      bindkey "^[[3~" delete-char    

      export LANG=pt_BR.UTF-8
      export LC_ALL=pt_BR.UTF-8
    '';
  };

  # 4. Configuração do Starship
  programs.starship = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    format = ''
   
[╔═▬════▬════▬════▬══════▬⋗](bold blue)
[╠╾](bold blue)$os$directory$git_branch$git_status
[╚═⋗](bold blue)$character'';
    add_newline = false;

    os = {
      disabled = false;
      format = "[$symbol]($style)"; # [espaço$symbol] Pequeno espaço para alinhar com a moldura
      symbols.NixOS = " ";
      style = "bold blue";
    };

    directory = {
      style = "bold cyan";
      format = " [$path]($style) ";
      truncation_length = 3;
      truncation_symbol = "…/";
    };

    git_branch = {
      symbol = " ";
      style = "bold purple";
      format = "on [$symbol$branch]($style) ";
    };

    git_status = {
      style = "bold red";
      format = "([$all_status$ahead_behind]($style))";
    };

    character = {
      # Usei um espaço simples aqui para o texto não colar na seta da moldura
      success_symbol = " "; 
      error_symbol = " [!](bold red) ";
    };
  };
};

  # 5. Plasma Manager (Atalhos e Temas)
  programs.plasma = {
    enable = true;
    workspace = {
      colorScheme = "BreezeDark";
      theme = "Layan";
    };

    # Atalhos de Teclado (Global Shortcuts)
    shortcuts.kwin = {
      "Increase Opacity" = "Meta+Alt+="; # Aumentar (Meta + Alt + =)
      "Decrease Opacity" = "Meta+Alt+-"; # Diminuir (Meta + Alt + -)
    };

    # Em vez de 'nightColor', vamos direto no arquivo de config que o KDE lê:
    configFile."kwinrc"."NightColor" = {
     Active = true;
     Mode = "Times"; # "constant" ou "times" ou "location"
     NightTemperature = 3500;
     DayTemperature = 6500;
    };
    
    # Configuração de atalho para o Kitty
    shortcuts = {
      "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
    };

    # Define o Kitty como terminal padrão do sistema
    configFile."kdeglobals"."General"."TerminalApplication" = "kitty";
  };

  services.espanso.enable = true;
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";

  # Configuração do vscode para funcionar no linux
  programs.vscode = {
    enable = true;
    # Esta linha abaixo cria uma versão do 'unstable' que aceita pacotes unfree
    package = (import inputs.unstable { 
      system = pkgs.stdenv.hostPlatform.system; 
      config.allowUnfree = true; 
    }).vscode-fhs;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
         mkhl.direnv
      ];
    /*  userSettings = {
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "direnv.restart.automatic" = true;
     };*/
    };
  };
  programs.direnv = {
    enable = true;
     nix-direnv.enable = true; # Versão mais rápida
  };

}
