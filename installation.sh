#!/bin/bash

variables(){
    SWAP_FILE="/swapfile"
    SWAP_SIZE_MB=$(free --giga | awk '/^Mem:/ {print int($2 + ($2))}')
    USER_HOME=$(eval echo ~"$SUDO_USER")
    TRUS_DIRECTORY=$USER_HOME/.trus/
    
    TOOLS_ACTUAL_PATH=./tools.sh
    TOOLS_PATH=$TRUS_DIRECTORY/tools.sh
    TOOLS_LINK_PATH=/usr/local/bin/tools

    TRUS_ACTUAL_PATH=./trus.sh
    TRUS_PATH=$TRUS_DIRECTORY/trus.sh
    TRUS_LINK_PATH="/usr/local/bin/trus"
    PATH_GLOBAL_CONFIG=~/.trus.conf
 
    INSTALL_OPTIONS=(
        "Salir"
        "1 - Instalacion de paquetes y dependencias"
        "2 - Instalacion de paquetes y dependencias (extra)"
        "3 - Instalar ZSH y Oh My ZSH"
        "4 - Actualizar prompt de BASH"
        "5 - Actualizar splash loader"
        "6 - Creación de archivos de configuracion (ZSH, TMUX y TLP)"
        "7 - Actualizar la memoria SWAP (a $SWAP_SIZE_MB GB)"
        "8 - Instala TrUs (Truedat Utils)"
        "9 - Todo"
    )

    if [ ! -d "$PATH_GLOBAL_CONFIG" ]; then        
        trus_config
    fi
}

install_tools(){
    if [ ! -d "$TOOLS_LINK_PATH" ]; then        
        if [ ! -d "$TRUS_DIRECTORY" ]; then
            mkdir -p "$TRUS_DIRECTORY" 
        fi

        cp -f "$TOOLS_ACTUAL_PATH" "$TOOLS_PATH" 

        sudo rm -f "$TOOLS_LINK_PATH"
        sudo ln -s "$TOOLS_PATH" "$TOOLS_LINK_PATH" 
        
        if [ ! command -v fzf &> /dev/null ]; then
            eval "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf $REDIRECT"
            ~/.fzf/install
        fi
        
        eval "sudo apt install -qqq -y --install-recommends wmctrl $REDIRECT"  

        sudo sh -c '{
            echo "##################"
            echo "# Añadido por trus"
            echo "##################"
            echo "127.0.0.1 localhost"
            echo "127.0.0.1 $(uname -n).bluetab.net $(uname -n)"
            echo "127.0.0.1 redis"
            echo "127.0.0.1 postgres"
            echo "127.0.0.1 elastic"
            echo "127.0.0.1 kong"
            echo "127.0.0.1 neo"
            echo "127.0.0.1 vault"
            echo "0.0.0.0 local"
            echo "##################"
            echo "# Añadido por trus"
            echo "##################"
        } >> /etc/hosts'
    fi
}

install_trus(){
    print_header "Instalación de TrUs"
 
    cp "$TRUS_ACTUAL_PATH" "$TRUS_PATH"
        
    sudo rm -f "$TRUS_LINK_PATH"
    sudo ln -s "$TRUS_PATH" "$TRUS_LINK_PATH"
  
    print_message "Truedat Utils (TrUs) instalado con éxito" "$COLOR_SUCCESS" 3 "both"     
}

package_installation(){
    print_semiheader "Instalación de origenes de software"

    #postgres
    print_message_with_animation "Añadiendo origen de Postgres" "$COLOR_TERNARY" 2
    eval "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - $REDIRECT" 
    eval "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' | sudo tee /etc/apt/sources.list.d/pgdg.list$REDIRECT"
    print_message "Origen de Postgres añadido" "$COLOR_SUCCESS" 3        
  
    # chrome
    print_message_with_animation "Añadiendo origen de chrome" "$COLOR_TERNARY" 2
    eval "wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - $REDIRECT"
    eval "sudo add-apt-repository -y 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' $REDIRECT"
    print_message "Origen de chrome añadido" "$COLOR_SUCCESS" 3        

    # vscode
    print_message_with_animation "Añadiendo origen de VSCode" "$COLOR_TERNARY" 2
    eval "wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - $REDIRECT"
    eval "sudo add-apt-repository -y 'deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main' $REDIRECT"
    print_message "Origen de VSCode añadido" "$COLOR_SUCCESS" 3        

    # dbeaver
    print_message_with_animation "Añadiendo origen de DBeaver" "$COLOR_TERNARY" 2
    eval "wget -q -O- https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add - $REDIRECT"
    print_message "Origen de DBeaver añadido" "$COLOR_SUCCESS" 3        
        
    if [ -e "/etc/apt/preferences.d/nosnap.pref" ]; then
        eval "sudo rm /etc/apt/preferences.d/nosnap.pref #en mint viene deshabilitado snap por defecto $REDIRECT"
    fi
    
    print_message_with_animation "Actualizando sistema" "$COLOR_TERNARY" 2
    eval "sudo apt update $REDIRECT"
    eval "sudo apt upgrade -y $REDIRECT"
    print_message "Sistema actualizado" "$COLOR_SUCCESS" 3            


    print_semiheader "Instalación de paquetes"

    print_message_with_animation "Instalando Docker Compose" "$COLOR_TERNARY" 2
    sudo curl -s -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
    eval "sudo chmod +x /usr/local/bin/docker-compose $REDIRECT"
    eval "sudo groupadd docker $REDIRECT"
    eval "sudo usermod -aG docker '$USER' $REDIRECT"
    print_message "Docker Compose instalado" "$COLOR_SUCCESS" 3        

    for package in "${INSTALLATION_PACKAGES[@]}"; do        
        print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
        eval "sudo apt install -y --install-recommends $package $REDIRECT"  
        print_message "$package instalado" "$COLOR_SUCCESS" 3        
    done     

    print_message_with_animation "Instalando Discord y DBeaver" "$COLOR_TERNARY" 2
    eval "sudo snap install discord dbeaver-ce $REDIRECT"
    print_message "Discord y DBeaver instalado" "$COLOR_SUCCESS" 3        

    if [ -e "~/.asdf" ]; then
        rm -r ~/.asdf  
    fi
    
    print_message_with_animation "Instalando ASDF" "$COLOR_TERNARY" 2
    eval "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 $REDIRECT"
    print_message "ASDF instalado" "$COLOR_SUCCESS" 3        
    
    print_message_with_animation "Instalando Kubectl" "$COLOR_TERNARY" 2   
    
    eval "curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl $REDIRECT"
    print_message "Kubectl instalado" "$COLOR_SUCCESS" 3        

    print_message "Paquetes y dependencias (extra) instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

package_installation_extra(){
    print_semiheader "Instalación de origenes de software (extra)"
    
    # wine
    print_message_with_animation "Instalando Wine" "$COLOR_TERNARY" 2
    eval "sudo dpkg --add-architecture i386 $REDIRECT"
    eval "wget -q -O- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add - $REDIRECT"
    eval "sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main' $REDIRECT"
    print_message "Wine instalado" "$COLOR_SUCCESS" 3        

    # para añadir soporte vulkan
    print_message_with_animation "Instalando soporte Vulkan" "$COLOR_TERNARY" 2
    eval "sudo add-apt-repository -y ppa:graphics-drivers/ppa $REDIRECT"
    print_message "Vulkan instalado" "$COLOR_SUCCESS" 3        
   
    # para los colorinchis del teclado
    print_message_with_animation "Instalando CBK NEXT" "$COLOR_TERNARY" 2
    eval "sudo add-apt-repository -y ppa:tatokis/ckb-next $REDIRECT"
    print_message " CBK NEXT instalado" "$COLOR_SUCCESS" 3        
        
    print_message_with_animation "Actualizando sistema" "$COLOR_TERNARY" 2
    eval "sudo apt update $REDIRECT"
    eval "sudo apt upgrade -y $REDIRECT"
    print_message "Sistema actualizado" "$COLOR_SUCCESS" 3    
        

    print_semiheader "Instalación de paquetes (extra)"
    for package in "${INSTALLATION_PACKAGES_EXTRA[@]}"; do     
        print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
        eval "sudo apt install -y --install-recommends $package $REDIRECT"        
        print_message "$package instalado" "$COLOR_SUCCESS" 3        
    done     

    eval "sudo snap install video-downloader $REDIRECT"
    
    if [ -e "~/.xone" ]; then
        rm -r ~/.xone  
    fi

    eval "git clone https://github.com/medusalix/xone ~/.xone $REDIRECT"
    cd ~/.xone
    eval "sudo ./install.sh $REDIRECT"

    print_message "Paquetes y dependencias (extra) instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

install_zsh(){
    print_semiheader "Instalación de ZSH"

    print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
    eval "sudo apt install -y --install-recommends zsh $REDIRECT"  
    print_message "$package instalado" "$COLOR_SUCCESS" 3        

    chsh -s $(which zsh)

    cd ~

    if [ -e "~/.oh-my-zsh" ]; then
        rm -r -f ~/.oh-my-zsh  
    fi
    
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions 
    git clone https://github.com/gusaiani/elixir-oh-my-zsh.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/elixir

    zsh_config

    print_message "ZSH Instalado correctamente. ZSH estará disponible en el próximo inicio de sesión" "$COLOR_SUCCESS" 3 "both"
}

splash_loader(){
    print_semiheader "Cambiando loader"

    cd ~/
    git clone https://github.com/adi1090x/plymouth-themes.git ~/plymouth-themes
    cd plymouth-themes/pack_3
    sudo cp -r loader /usr/share/plymouth/themes/ 
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/loader/loader.plymouth 10000
    sudo update-alternatives --config default.plymouth 
    sudo update-initramfs -u 
    print_message "Splash loader Instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

bash_prompt(){
    print_semiheader "Actualizacion del prompt de Bash"

    {
        echo 'export COLORTERM=truecolor'
        echo '. "$HOME/.asdf/asdf.sh"'
        echo '. "$HOME/.asdf/completions/asdf.bash"'
        echo 'parse_git_branch() {'
        echo ' git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/(\1)/"'
        echo '}'
        echo 
        echo 'PS1="${debian_chroot:+($debian_chroot)}\[\033[1;38;5;231;48;5;208m\]\w\[\033[00m\]\[\033[1;38;5;039m\] $(parse_git_branch)\[\033[00m\]-> "'
    } >> $BASH_PATH_CONFIG
    
    print_message "Prompt de Bash actualizado" "$COLOR_SUCCESS" 3 "both"
}

zsh_config(){
    print_semiheader "Creación del archivo de configuración de ZSH"

    {
        echo 'export ZSH="$HOME/.oh-my-zsh"'
        echo 'export COLORTERM=truecolor'
        echo 'plugins=('
        echo '    git'
        echo '    elixir'
        echo '    asdf'
        echo '    git-prompt'
        echo '    zsh-autosuggestions '
        echo '    zsh-syntax-highlighting '
        echo '    zsh-completions)'
        echo ''
        echo 'source $ZSH/oh-my-zsh.sh'
        echo '. "$HOME/.asdf/asdf.sh"'
        echo ''
        echo 'alias update-mint="sudo apt update && sudo apt upgrade"' 
        echo 'alias ai="cd ~/workspace/truedat/back/td-ai"'
        echo 'alias audit="cd ~/workspace/truedat/back/td-audit"'
        echo 'alias auth="cd ~/workspace/truedat/back/td-auth"'
        echo 'alias bg="cd ~/workspace/truedat/back/td-bg"'
        echo 'alias dd="cd ~/workspace/truedat/back/td-dd"'
        echo 'alias df="cd ~/workspace/truedat/back/td-df"'
        echo 'alias i18n="cd ~/workspace/truedat/back/td-i18n"'
        echo 'alias ie="cd ~/workspace/truedat/back/td-ie"'
        echo 'alias lm="cd ~/workspace/truedat/back/td-lm"'
        echo 'alias qx="cd ~/workspace/truedat/back/td-qx"'
        echo 'alias se="cd ~/workspace/truedat/back/td-se"'
        echo 'alias web="cd ~/workspace/truedat/front/td-web"'
        echo 'alias webmodules="cd ~/workspace/truedat/front/td-web-modules"'
        echo 'alias format="mix format && mix credo --strict"'
        echo ''
        echo 'autoload -U compinit && compinit'
        echo '# autoload -Uz promptinit'
        echo '# promptinit'
        echo '# prompt bigfade'
        echo ''
        echo 'local -A schars'
        echo 'autoload -Uz prompt_special_chars'
        echo 'prompt_special_chars'
        echo 'setopt PROMPT_SUBST'
        echo ''
        echo 'PROMPT="%B%F{208}$schars[333]$schars[262]$schars[261]$schars[260]%B%~/$schars[260]$schars[261]$schars[262]$schars[333]%b%F{208}%b%f%k "'
        echo ''
    } > $ZSH_PATH_CONFIG
}

tmux_config(){
    print_semiheader "Creación del archivo de configuración de TMUX"
    
    {
        echo 'set -g mouse on'
        echo '# To copy, left click and drag to highlight text in yellow, '
        echo '# once you release left click yellow text will disappear and will automatically be available in clibboard'
        echo '# # Use vim keybindings in copy mode'
        echo 'setw -g mode-keys vi'
        echo '# Update default binding of `Enter` to also use copy-pipe'
        echo 'unbind -T copy-mode-vi Enter'
        echo 'bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -selection c"'
        echo 'bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"'
    } > $TMUX_PATH_CONFIG    
}

tlp_config(){
    print_semiheader "Creación del archivo de configuración de TLP"

    { 
        echo 'TLP_ENABLE=1' 
        echo 'TLP_DEFAULT_MODE=AC' 
        echo 'CPU_SCALING_GOVERNOR_ON_AC=performance' 
        echo 'CPU_SCALING_GOVERNOR_ON_BAT=powersave' 
        echo 'CPU_ENERGY_PERF_POLICY_ON_AC=performance' 
        echo 'CPU_ENERGY_PERF_POLICY_ON_BAT=power-saver' 
        echo 'CPU_MIN_PERF_ON_AC=0' 
        echo 'CPU_MAX_PERF_ON_AC=100' 
        echo 'CPU_MIN_PERF_ON_BAT=0' 
        echo 'CPU_MAX_PERF_ON_BAT=70' 
        echo 'CPU_BOOST_ON_AC=1' 
        echo 'CPU_BOOST_ON_BAT=0' 
        echo 'CPU_HWP_DYN_BOOST_ON_AC=1' 
        echo 'CPU_HWP_DYN_BOOST_ON_BAT=0' 
        echo 'SCHED_POWERSAVE_ON_AC=0' 
        echo 'SCHED_POWERSAVE_ON_BAT=1' 
        echo 'PLATFORM_PROFILE_ON_AC=performance' 
        echo 'PLATFORM_PROFILE_ON_BAT=low-power' 
        echo 'RUNTIME_PM_ON_AC=auto' 
        echo 'RUNTIME_PM_ON_BAT=auto' 
    } > $TLP_PATH_CONFIG

    sudo tlp start     
    sudo systemctl enable tlp.service      
    
}

trus_config(){
    {
        echo 'TERMINAL_WIDTH=40'
        echo 'TERMINAL_HEIGHT=135'
        echo 'COLOR_PRIMARY="8D9B43"'
        echo 'COLOR_SECONDARY="945296"'
        echo 'COLOR_TERNARY="E6B77D"'
        echo 'COLOR_QUATERNARY="2F5266"'
        echo 'COLOR_SUCCESS="9DED32"'
        echo 'COLOR_WARNING="EDDE32"'
        echo 'COLOR_ERROR="ED5732"   '
        echo 'COLOR_BACKRGROUND="305367"'
        echo 'BASH_PATH_CONFIG=~/.bashrc'
        echo 'ZSH_PATH_CONFIG=~/.zshrc'
        echo 'TMUX_PATH_CONFIG=~/.tmux.conf'
        echo 'TLP_PATH_CONFIG=/etc/tlp.conf'
        echo 'INSTALLATION_PACKAGES="redis-tools screen tmux unzip curl vim build-essential git libssl-dev automake autoconf libncurses5 libncurses5-dev awscli docker.io postgresql-client-14 jq gedit xclip google-chrome-stable code snapd xdotool x11-utils"'
        echo 'INSTALLATION_PACKAGES_EXTRA="winehq-stable gdebi-core libvulkan1 libvulkan1:i386 fonts-powerline plymouth plymouth-themes ckb-next pavucontrol gnome-boxes virt-manager stress bluez bluez-tools tlp lm-sensors psensor"'
        echo 'HIDE_OUTPUT=false'
    } > $PATH_GLOBAL_CONFIG 
}

configurations(){  
    print_header "Creación del archivos de configuración" 
    zsh_config
    tmux_config  
    tlp_config
    print_message "Se han creado los ficheros de configuracion de ZSH, TMUX y TLP" "$COLOR_SUCCESS" 3 "both"
}

swap(){
    print_semiheader "Ampliación de memoria SWAP"

    if [ -e "$SWAP_FILE" ]; then
        print_message_with_animation "Ya existe un archivo de intercambio. Eliminando..." "$COLOR_TERNARY" 3 

        sudo swapoff "$SWAP_FILE"  
        sudo rm "$SWAP_FILE"   

        print_message "Archivo de intercambio eliminado" "$COLOR_SUCCESS" 3        
    fi

    print_message "Creando un nuevo archivo de intercambio de $((SWAP_SIZE_MB / 1024))GB..." "$COLOR_TERNARY" 3 

    sudo fallocate -l "${SWAP_SIZE_MB}M" "$SWAP_FILE" 
    sudo chmod 600 "$SWAP_FILE" 
    sudo mkswap "$SWAP_FILE" 
    sudo swapon "$SWAP_FILE" 
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab

    print_message "Memoria SWAP ampliada a $((SWAP_SIZE_MB / 1024))GB" "$COLOR_SUCCESS" 3 "both"
}
 
main_menu(){
    print_header
    local option=$(print_menu "${INSTALL_OPTIONS[@]}")
    
    option=$(extract_start_option "$option")

    case "$option" in
        "1")            
            package_installation
            ;;

        "2")
            package_installation_extra
            ;;

        "3")
            install_zsh
            ;;

        "4")
            bash_prompt
            ;;

        "5")
            splash_loader
            ;;

        "6")
            configurations
            ;;

        "7")
            swap
            ;;
            
        "8" )
            install_trus
            ;;

        "9")
            package_installation
            package_installation_extra
            install_zsh
            bash_prompt
            splash_loader
            configurations
            install_trus
            swap
            ;;
            
        "Salir")
            clear
            tput reset
            exit 0
            ;;
    esac
}

help(){
    local option=$1
    case $option in
        "0")
            print_message "Selecciona una opción" "$COLOR_SECONDARY"
            ;;

        "1")
            print_message "Instalación de paquetes:" "$COLOR_SECONDARY"
            
            for package in "${INSTALLATION_PACKAGES[@]}"; do     
                print_message "- $package" "$COLOR_TERNARY" 1
            done     
            ;;

        "2")
            print_message "Instalación de paquetes extra:" "$COLOR_SECONDARY"
            
            for package in "${INSTALLATION_PACKAGES_EXTRA[@]}"; do     
                print_message "- $package" "$COLOR_TERNARY" 1
            done     
            ;;

        "3")
            print_message "Instalación de la terminal ZSH y Oh My Zsh." "$COLOR_SECONDARY"
            ;;

        "4")
            print_message "Modificación del prompt de Bash para añadirle nuevo estilo y la visualizacion de la rama de git." "$COLOR_SECONDARY"
            ;;

        "5")
            print_message "Modificación de la animacion de la animación de arranque del SO (solo linux)." "$COLOR_SECONDARY"
            ;;

        "6")
            print_message "Creación de los archivos de confiuración de ZSH, TMUX y TLP" "$COLOR_SECONDARY"
            ;;

        "7")
            print_message "Modificación del tamaño del archivo de intercambio. Se crea con un tamaño del 150% de la RAM actual del equipo." "$COLOR_SECONDARY"
            ;;

        "8")
            print_message "Instalación de Truedat Utils (TrUs)." "$COLOR_SECONDARY"
            ;;

        "9")
            print_message "Instalación completa. Se lanzan todas las opciones." "$COLOR_SECONDARY"
            ;;

        "volver")
            print_message "Vuelve al menú anterior" "$COLOR_PRIMARY"
            ;;

        "salir")
            print_message "Salir de TrUs" "$COLOR_PRIMARY"
            ;;
            
        "*" | "")
            print_message "Introduzca una opción válida." "$COLOR_SECONDARY"
            ;;
    esac
}

#########################################
#            Lógica principal             
#########################################

variables


if [ "$1" == "--help" ]; then
    help $2
else
    install_tools
    set_terminal_config
    main_menu
fi