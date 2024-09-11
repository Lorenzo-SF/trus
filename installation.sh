#!/bin/bash

variables() {
    PATH_GLOBAL_CONFIG=~/.trus.conf

    if [ ! -e "$PATH_GLOBAL_CONFIG" ]; then
        trus_config
    fi

    source $PATH_GLOBAL_CONFIG

    MAIN_MENU_OPTIONS=(
        "Salir"
        "1 - Instalación de paquetes y dependencias"
        "2 - Instalar ZSH y Oh My ZSH"
        "3 - Actualizar prompt de BASH"
        "4 - Actualizar splash loader"
        "5 - Archivos de configuración"
        "6 - Actualizar la memoria SWAP (a $(($SWAP_SIZE_MB/1024)) GB)"
        "7 - Configurar animación de los mensajes"
        "8 - Instala TrUs (Truedat Utils)"
        "9 - Instala Tools" 
        "10 - Todo"
    )

    CONFIGURATION_MENU_OPTIONS=(
        "Volver"
        "ZSH"
        "TMUX"
        "TLP"
        "TrUs"
        "Todos"
    )
}

install_tools() {
    if [ ! -d "$TOOLS_LINK_PATH" ]; then
        if [ ! -d "$TRUS_DIRECTORY" ]; then
            mkdir -p "$TRUS_DIRECTORY"
        fi

        cp -f "$TOOLS_ACTUAL_PATH" "$TOOLS_PATH"

        sudo rm -f "$TOOLS_LINK_PATH"
        sudo ln -s "$TOOLS_PATH" "$TOOLS_LINK_PATH"
 
        # necesario para los menus
        eval "sudo apt install -qqq -y --install-recommends fzf wmctrl $REDIRECT"
    fi
}

install_trus() {
    print_header "Instalación de TrUs"

    cp "$TRUS_ACTUAL_PATH" "$TRUS_PATH"

    sudo rm -f "$TRUS_LINK_PATH"
    sudo ln -s "$TRUS_PATH" "$TRUS_LINK_PATH"
    
    trus_config

    print_message "Truedat Utils (TrUs) instalado con éxito" "$COLOR_SUCCESS" 3 "both"
}

package_installation() {
    print_semiheader "Instalación de origenes de software"

    add_origins

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

    # Por si AWS no se instala con apt, que pué pasar
    if [ ! command -v aws ] &>/dev/null; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        mkdir .aws
        cd .aws
        unzip awscliv2.zip
        sudo install
    fi

    print_message_with_animation "Instalando Discord y DBeaver" "$COLOR_TERNARY" 2
    eval "sudo snap install discord dbeaver-ce $REDIRECT"
    print_message "Discord y DBeaver instalado" "$COLOR_SUCCESS" 3

    if [ -e "~/.asdf" ]; then
        rm -r ~/.asdf

        print_message_with_animation "Instalando ASDF" "$COLOR_TERNARY" 2
        eval "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 $REDIRECT"
        print_message "ASDF instalado" "$COLOR_SUCCESS" 3
    fi

    if [ ! -e "$KUBE_PATH" ]; then
        print_message_with_animation "Instalando Kubectl" "$COLOR_TERNARY" 2

        mkdir $KUBE_PATH   

        cd $KUBE_PATH

        eval "curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl $REDIRECT"
        
        touch "$KUBECONFIG"

        {
            echo 'apiVersion: v1'
            echo 'clusters:'
            echo '- cluster:'
            echo '    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRFNE1URXlPVEF4TlRJeU5Gb1hEVEk0TVRFeU5qQXhOVEl5TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGtjCnBhOWlvSGNYNmIyTGEycmtJQnpqdUd3SkFMYjR6QkxiSzl2b2ZkZGdRODNFeUZaMFExR2UrT3JuUmNZUEowT04KeHBGUTNYT2o2RW9HSGYxbGVQQU8zZG84WlR1UGp6YnluOWVNdU55YkxqWkY1NXNGaGVEYzhtYUlIWW4yV0VzcApkeHl6UllFWUVtRjlHU0EyblZ0bDk2NGxnOEpVMjJMN092THV6bWFhSHlJZGN4VU1JS2I0RThFdG03T3d6aElMClNKZUdTU0xvYUNDQzVaVXFObWx3Yk1tQlE3QkNqUzhwblo3c0FSWjRtbUhDa3ZzQ2RrN01pYUJDMStvZXk3b3IKcjhSbW1yeUN6MndER0R5NTlNamlrOElNRG92cldLQXlPSE9zZXBuS3VRTjRGd0E0U2g5M3g1Rml5bEpyamVRMAo0Y0FxN2swd0xKRFFpb3BTR3ZrQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFHS1hDMFdJSWZHVmhDRXFKUUVRY2xzS1Q1MlUKSkdFMmtlS2piYytwdWVuL0tZTSs2b2hRZE4wbjRDNHZRZzVaNC9NTW1kZ1Vmb0Z2TmcyTy9DKzFSb0ZkajBCOQpNWG1Zc1BzZTVCcEQ1YUkzY0praU1mcElmUC9JYmRRbGVWOW1YYkZoa0lKKzRWYzhjN3FabUdUbzdqdTZvdHRGCkpuVjQxMmZNS25PWHp4NC9MYm1kSjcrdkhGZ053M2kvbjc2Q24wOVNsWTMxRVBtc25ZekYwUUlJczhHZjlZby8Kdm02T3VzbjIyTDZBeUVWNVNnTDBsaWorZEVOR1FoMkpnYUpRYURLM3QySkN3YTg5U2ZFSTZKZHFBaDVSVllLdApQYk82bW1TeTRFTEJWNy9WM1lTTnplZ0ZyR0EvRStaL01CbTBoS3FxcStPUERwUlVmVkk1djlmYTdtZz0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo='
            echo '    server: https://B4E4C4ED51C8A123744DE0E261A4C8F7.sk1.eu-west-1.eks.amazonaws.com'
            echo '  name: arn:aws:eks:eu-west-1:576759405678:cluster/truedat'
            echo '- cluster:'
            echo '    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJVEhPc2VHTWkrRm93RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBeE1UQXhOREk0TkRKYUZ3MHpOREF4TURjeE5ETXpOREphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURQQzZRQjIrZUNCbGE0a1pWVjVrMEx1OFJSRlozN2M3c3VvSnYxUlhwUFhHb2c4d1RpbkZiNVVpSzQKUFJHc3c2ZDU5M2l5YlI4TzYzRTBmM05HTFNGcEUyMkpscW9DQUNyRmpDTEF3NzN6Z0NiQXY1Ym8xdWh2Mk5DVQpjVFN5RjFQN29qK3RXQ0o0QUVDQlA1KzgyZXVUK0czOUFKelRhdDFrUUpVVWtlbUllR1dWM2Zvblk5YS91SkVECkJUcllmMnJEVWUxOG02T2xEVlBQNEdoRG85Q3Yya0J1bVJ0Z0ovYnRkbWpFYkpOdkFTYjB5QTRpWnJxeGYxeE8KakFOZTdJWnFBbjVBWm42NU1zbmNNTW5ISmw2Q3k2LzJmSU0yMWNOeUxXU1JoVFI4ZkJXdlRXWFNDNUZJUjBXdQpTSzNnRG9lTEI2YnZMN2dxZ21Mbyt4WnNDMWVOQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUZjBLVEhYVU9SZnFUSU93Rm5nOUdRY2lBNGpqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ3dwZWVQODQzRQpTWFFya0piK2NQakIyZDk1eHNRUG1vL0NRL0l2MGdQd2tKam1ZcXdDU1ptUE1qcmV6WE5mUVZVUSt4bU94M3BaCjBrL0dBTEVOLzYyei9RVm9rQnZkakxwN0dJblhsb2dwUFZxN0ZOUkZSckpYTy9jOTZpWUVoZFFSdDVpMmRtVmYKcWltNnAzMXZSVTVBclFpUktBcW5KZzFuYnA0Q0NTb0pERmhUWlh0dFBFU2RJZ3Mwb05wUmZjWm9xZXNQQlJvOAorZDFYRUdzeGw4bXJJN0FNRXIzMVdSRlNwdHQ5eFpRenhKQU9WY3V2NkFJK2dQMmhnWnBEQTJPY3BhRk40bkkyCmpJTmhrVUVTRWRRSlFUNUJwa2hVUmkxNTBjMStSTm0zclRBbmVEQ1IydjMzQUNXc2h1bmdhdlJ0cy9mVTIzbWoKc1JRTjFpZFBIcEdMCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K'
            echo '    server: https://69A8FA57BC0A79CAB4BBAD796024AB81.gr7.eu-west-1.eks.amazonaws.com'
            echo '  name: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo 'contexts:'
            echo '- context:'
            echo '    cluster: arn:aws:eks:eu-west-1:576759405678:cluster/truedat'
            echo '    user: arn:aws:eks:eu-west-1:576759405678:cluster/truedat'
            echo '  name: truedat'
            echo '- context:'
            echo '    cluster: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo '    user: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo '  name: test-truedat-eks'
            echo '- context:'
            echo '    cluster: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo '    user: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo '  name: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo 'current-context: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo 'kind: Config'
            echo 'preferences: {}'
            echo 'users:'
            echo '- name: arn:aws:eks:eu-west-1:576759405678:cluster/truedat'
            echo '  user:'
            echo '    exec:'
            echo '      apiVersion: client.authentication.k8s.io/v1alpha1'
            echo '      args:'
            echo '      - --region'
            echo '      - eu-west-1'
            echo '      - eks'
            echo '      - get-token'
            echo '      - --cluster-name'
            echo '      - truedat'
            echo '      command: aws'
            echo '- name: arn:aws:eks:eu-west-1:576759405678:cluster/test-truedat-eks'
            echo '  user:'
            echo '    exec:'
            echo '      apiVersion: client.authentication.k8s.io/v1beta1'
            echo '      args:'
            echo '      - --region'
            echo '      - eu-west-1'
            echo '      - eks'
            echo '      - get-token'
            echo '      - --cluster-name'
            echo '      - test-truedat-eks'
            echo '      - --output'
            echo '      - json'
            echo '      command: aws'

        } >$KUBECONFIG
        
        print_message "Kubectl instalado y configurado" "$COLOR_SUCCESS" 3
    fi
    print_message "Paquetes y dependencias (extra) instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

add_origins(){
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
}

install_zsh() {
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

    clone_if_not_exists https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    clone_if_not_exists https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    clone_if_not_exists https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
    clone_if_not_exists https://github.com/gusaiani/elixir-oh-my-zsh.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/elixir

    zsh_config

    print_message "ZSH Instalado correctamente. ZSH estará disponible en el próximo inicio de sesión" "$COLOR_SUCCESS" 3 "both"
}

splash_loader() {
    print_semiheader "Splash loader"

    cd ~/
    git clone https://github.com/adi1090x/plymouth-themes.git ~/plymouth-themes
    cd plymouth-themes/pack_3
    sudo cp -r loader /usr/share/plymouth/themes/
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/loader/loader.plymouth 10000
    sudo update-alternatives --config default.plymouth
    sudo update-initramfs -u
    print_message "Splash loader Instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

bash_prompt() {
    print_semiheader "Prompt de Bash"

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

zsh_config() {
    print_semiheader "ZSH"

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

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" 3
}

tmux_config() {
    print_semiheader "TMUX"

    touch $TMUX_PATH_CONFIG

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

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" 3
}

tlp_config() {
    print_semiheader "TLP"
    
    sudo sh -c " touch $TLP_PATH_CONFIG"

    sudo sh -c "
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
        } > $TLP_PATH_CONFIG"

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" 3

    eval "sudo tlp start $REDIRECT"
    eval "sudo systemctl enable tlp.service $REDIRECT"
}

trus_config() {
    print_semiheader "TrUs"
    
    local SWAP_SIZE_MB=$(free --mega | awk '/^Mem:/ {print int($2 + ($2))}')
    local USER_HOME=$(eval echo ~"$SUDO_USER")
    local TRUS_DIRECTORY=$USER_HOME/.trus/
    local TOOLS_PATH=$TRUS_DIRECTORY/tools.sh
    local TRUS_PATH=$TRUS_DIRECTORY/trus.sh
    local SSH_PUBLIC_FILE=$SSH_PATH/truedat.pub
    local SSH_PRIVATE_FILE=$SSH_PATH/truedat
    local SSH_BACKUP_FOLDER=$SSH_PATH"/backup_$(date +%Y%m%d_%H%M%S)"
    local WORKSPACE_PATH=$USER_HOME/workspace
    local TRUEDAT_ROOT_PATH=$WORKSPACE_PATH/truedat
    local BACK_PATH=$TRUEDAT_ROOT_PATH/back
    local FRONT_PATH=$TRUEDAT_ROOT_PATH/front
    local DEV_PATH=$TRUEDAT_ROOT_PATH/true-dev
    local KONG_PATH=$BACK_PATH/kong-setup/data
    local DDBB_BASE_BACKUP_PATH=$TRUEDAT_ROOT_PATH"/ddbb_truedat"
    local DDBB_BACKUP_PATH=$DDBB_BASE_BACKUP_PATH/$DATE_NOW
    local DDBB_LOCAL_BACKUP_PATH=$DDBB_BASE_BACKUP_PATH"/local_backups/$(date +%Y%m%d_%H%M%S)"
    local TD_WEB_DEV_CONFIG=$FRONT_PATH/td-web/dev.config.js
    local KUBECONFIG=$KUBE_PATH/config

    touch $TMUX_PATH_CONFIG
    
    {
        # Configuracion del terminal: Tamaño, colores....
        echo 'TERMINAL_WIDTH=40'
        echo 'TERMINAL_HEIGHT=135'
        echo 'COLOR_RESET_BG="\033[49m"'
        echo 'NO_COLOR="FFFCE2"'
        echo 'COLOR_PRIMARY="BED5E8"'
        echo 'COLOR_SECONDARY="DEE0B7"'
        echo 'COLOR_TERNARY="937F5F"'
        echo 'COLOR_QUATERNARY="808F9C"'
        echo 'COLOR_SUCCESS="10C90A"'
        echo 'COLOR_WARNING="FFCE00"'
        echo 'COLOR_ERROR="C90D0A"   '
        echo 'COLOR_BACKRGROUND="324F69"'
        
        # Configuracion de animaciones, comportamiento de trus...
        echo 'TERMINAL_ANIMATION_ARROW=(▹▹▹▹▹ ▸▹▹▹▹ ▹▸▹▹▹ ▹▹▸▹▹ ▹▹▹▸▹ ▹▹▹▹▸ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹)'
        echo 'TERMINAL_ANIMATION_BOUNCE=(. · ˙ ·)'
        echo 'TERMINAL_ANIMATION_BOUNCING_BALL=("(●     )" "( ●    )" "(  ●   )" "(   ●  )" "(    ● )" "(     ●)" "(    ● )" "(   ●  )" "(  ●   )" "( ●    )")'
        echo 'TERMINAL_ANIMATION_BOX=(┤ ┴ ├ ┬)'
        echo 'TERMINAL_ANIMATION_BRAILLE=(⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽ ⣾)'
        echo 'TERMINAL_ANIMATION_BREATHE=("  ()  " " (  ) " "(    )" " (  ) ")'
        echo 'TERMINAL_ANIMATION_BUBBLE=(· o O O o ·)'
        echo 'TERMINAL_ANIMATION_CLASSIC_UTF8=("—" "\\" "|" "/")'
        echo 'TERMINAL_ANIMATION_CLASSIC=("-" "\\" "|" "/")'
        echo 'TERMINAL_ANIMATION_DOT=(∙∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ●∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙●∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙●∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙●∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙●∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙●∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙●∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙●∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙●∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙●∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙●∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙●∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙●∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙●∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙∙● ∙∙∙∙∙∙∙∙∙∙∙∙∙●∙ ∙∙∙∙∙∙∙∙∙∙∙∙●∙∙ ∙∙∙∙∙∙∙∙∙∙∙●∙∙∙ ∙∙∙∙∙∙∙∙∙∙●∙∙∙∙ ∙∙∙∙∙∙∙∙∙●∙∙∙∙∙ ∙∙∙∙∙∙∙∙●∙∙∙∙∙∙ ∙∙∙∙∙∙∙●∙∙∙∙∙∙∙ ∙∙∙∙∙∙●∙∙∙∙∙∙∙∙ ∙∙∙∙∙●∙∙∙∙∙∙∙∙∙ ∙∙∙∙●∙∙∙∙∙∙∙∙∙∙ ∙∙∙●∙∙∙∙∙∙∙∙∙∙∙ ∙∙●∙∙∙∙∙∙∙∙∙∙∙∙ ∙●∙∙∙∙∙∙∙∙∙∙∙∙∙ ●∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙∙∙)'
        echo 'TERMINAL_ANIMATION_FILLING_BAR=("█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████████████▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████████████▒▒▒▒▒▒▒▒▒▒▒" "██████████████████████▒▒▒▒▒▒▒▒▒▒" "███████████████████████▒▒▒▒▒▒▒▒▒" "████████████████████████▒▒▒▒▒▒▒▒" "█████████████████████████▒▒▒▒▒▒▒" "██████████████████████████▒▒▒▒▒▒" "███████████████████████████▒▒▒▒▒" "████████████████████████████▒▒▒▒" "█████████████████████████████▒▒▒" "██████████████████████████████▒▒" "███████████████████████████████▒" "████████████████████████████████")'
        echo 'TERMINAL_ANIMATION_FIREWORK=("⢀" "⠠" "⠐" "⠈" "*" "*" " ")'
        echo 'TERMINAL_ANIMATION_GROWING_DOTS=(".  " ".. " "..." ".. " ".  " "   ")'
        echo 'TERMINAL_ANIMATION_HORIZONTAL_BLOCK=(▏ ▎ ▍ ▌ ▋ ▊ ▉ ▉ ▊ ▋ ▌ ▍ ▎ ▏)'
        echo 'TERMINAL_ANIMATION_KITT=(▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱ ▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱ ▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱ ▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱ ▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱ ▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱ ▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱ ▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱ ▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱ ▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱ ▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱ ▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱ ▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱)'
        echo 'TERMINAL_ANIMATION_METRO=("[    ]" "[=   ]" "[==  ]" "[=== ]" "[ ===]" "[  ==]" "[   =]")'
        echo 'TERMINAL_ANIMATION_PASSING_DOTS=(".  " ".. " "..." " .." "  ." "   ")'
        echo 'TERMINAL_ANIMATION_PONG=("▐⠂       ▌" "▐⠈       ▌" "▐ ⠂      ▌" "▐ ⠠      ▌" "▐  ⡀     ▌" "▐  ⠠     ▌" "▐   ⠂    ▌" "▐   ⠈    ▌" "▐    ⠂   ▌" "▐    ⠠   ▌" "▐     ⡀  ▌" "▐     ⠠  ▌" "▐      ⠂ ▌" "▐      ⠈ ▌" "▐       ⠂▌" "▐       ⠠▌" "▐       ⡀▌" "▐      ⠠ ▌" "▐      ⠂ ▌" "▐     ⠈  ▌" "▐     ⠂  ▌" "▐    ⠠   ▌" "▐    ⡀   ▌" "▐   ⠠    ▌" "▐   ⠂    ▌" "▐  ⠈     ▌" "▐  ⠂     ▌" "▐ ⠠      ▌" "▐ ⡀      ▌" "▐⠠       ▌")'
        echo 'TERMINAL_ANIMATION_QUARTER=(▖ ▘ ▝ ▗)'
        echo 'TERMINAL_ANIMATION_ROTATING_EYES=(◡◡ ⊙⊙ ⊙⊙ ◠◠)'
        echo 'TERMINAL_ANIMATION_SEMI_CIRCLE=(◐ ◓ ◑ ◒)'
        echo 'TERMINAL_ANIMATION_SIMPLE_BRAILLE=(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈)'
        echo 'TERMINAL_ANIMATION_SNAKE=("[=     ]" "[~<    ]" "[~~=   ]" "[~~~<  ]" "[ ~~~= ]" "[  ~~~<]" "[   ~~~]" "[    ~~]" "[     ~]" "[      ]")'
        echo 'TERMINAL_ANIMATION_TRIANGLE=(◢ ◣ ◤ ◥)'
        echo 'TERMINAL_ANIMATION_TRIGRAM=(☰ ☱ ☳ ☶ ☴)'
        echo 'TERMINAL_ANIMATION_VERTICAL_BLOCK=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ █ ▇ ▆ ▅ ▄ ▃ ▂ ▁)'
        echo 'ANIMATION_MENU=("Volver" "ARROW" "BOUNCE" "BOUNCING_BALL" "BOX" "BRAILLE" "BREATHE" "BUBBLE" "CLASSIC_UTF8" "CLASSIC" "DOT" "FILLING_BAR" "FIREWORK" "GROWING_DOTS" "HORIZONTAL_BLOCK" "KITT" "METRO" "PASSING_DOTS" "PONG" "QUARTER" "ROTATING_EYES" "SEMI_CIRCLE" "SIMPLE_BRAILLE" "SNAKE" "TRIANGLE" "TRIGRAM" "VERTICAL_BLOCK" )'


        # Rutas
        echo "SWAP_FILE=/swapfile"
        echo "SWAP_SIZE_MB=$SWAP_SIZE_MB"
        echo "USER_HOME=$USER_HOME"
        echo "TRUS_DIRECTORY=$TRUS_DIRECTORY"

        echo "TOOLS_ACTUAL_PATH=./tools.sh"
        echo "TOOLS_PATH=$TOOLS_PATH"
        echo "TOOLS_LINK_PATH=/usr/local/bin/tools"

        echo "TRUS_ACTUAL_PATH=./trus.sh"
        echo "TRUS_PATH=$TRUS_PATH"
        echo "TRUS_LINK_PATH=/usr/local/bin/trus"
        
        echo "SSH_PATH=~/.ssh"
        echo "SSH_PUBLIC_FILE=$SSH_PUBLIC_FILE"
        echo "SSH_PRIVATE_FILE=$SSH_PRIVATE_FILE"
        echo "SSH_BACKUP_FOLDER=$SSH_BACKUP_FOLDER"
        
        echo "WORKSPACE_PATH=$WORKSPACE_PATH"
        echo "TRUEDAT_ROOT_PATH=$TRUEDAT_ROOT_PATH"
        echo "BACK_PATH=$BACK_PATH"
        echo "FRONT_PATH=$FRONT_PATH"
        echo "DEV_PATH=$DEV_PATH"
        echo "KONG_PATH=$KONG_PATH"

        echo "DDBB_BASE_BACKUP_PATH=$DDBB_BASE_BACKUP_PATH"
        echo "DDBB_BACKUP_PATH=$DDBB_BACKUP_PATH"
        echo "DDBB_LOCAL_BACKUP_PATH=$DDBB_LOCAL_BACKUP_PATH"
        echo "TD_WEB_DEV_CONFIG=$TD_WEB_DEV_CONFIG"

        echo "BASH_PATH_CONFIG=~/.bashrc"
        echo "ZSH_PATH_CONFIG=~/.zshrc"
        echo "TMUX_PATH_CONFIG=~/.tmux.conf"
        echo "TLP_PATH_CONFIG=/etc/tlp.conf"
        

        #########################################
        #  td_auth no se incluye para que no interfiera con los usuarios que tenemos creados ne local

        echo 'DATABASES=("td_audit" "td_bg" "td_dd" "td_df" "td_ie" "td_lm" "td_i18n" "td_qx" "td_ai")'
        echo 'INDEXES=("dd" "bg" "ie" "qx")'

        #########################################
        #  DOCKER

        echo 'CONTAINERS=("elasticsearch" "redis" "redis_test" "vault")'
        echo 'CONTAINERS_SETUP=("kong_create" "kong_migrate" "kong_setup")'

        #########################################
        #  PROJECTS

        echo 'FRONT_PACKAGES=("audit" "auth" "bg" "core" "cx" "dd" "df" "dq" "qx" "ie" "lm" "profile" "se" "test")'
        echo 'SERVICES=("td-ai" "td-audit" "td-auth" "td-bg" "td-dd" "td-df" "td-i18n" "td-ie" "td-lm" "td-qx" "td-se")'
        echo 'LIBRARIES=("td-cache" "td-cluster" "td-core" "td-df-lib" "td-helm" "k8s")'
        

        #########################################
        #  AWS

        echo "KUBE_PATH=~/.kube"
        echo "KUBECONFIG=$KUBECONFIG"
        echo "AWSCONFIG=~/.aws/config"
        echo 'CONTEXT="test-truedat-eks"'

        #########################################
        # Tmux y Screen

        echo 'TRUEDAT="truedat"'
        echo 'TMUX_CONF=~/.tmux.conf'

        #########################################
        # kong
        echo 'DOCKER_LOCALHOST="172.17.0.1"'
        echo 'KONG_ADMIN_URL="localhost:8001"'
        echo 'KONG_SERVICES=("health" "td_audit" "td_auth" "td_bg" "td_dd" "td_qx" "td_dq" "td_lm" "td_qe" "td_se" "td_df" "td_ie" "td_cx" "td_i18n" "td_ai")'


        #Paquetes de instalación
        echo 'INSTALLATION_PACKAGES=("redis-tools" "screen" "tmux" "unzip" "curl" "vim" "build-essential" "git" "libssl-dev" "automake" "autoconf" "libncurses5" "libncurses5-dev" "awscli" "docker.io" "postgresql-client-14" "jq" "gedit" "xclip" "google-chrome-stable" "code" "snapd" "xdotool" "x11-utils" "winehq-stable" "gdebi-core" "libvulkan1" "libvulkan1:i386" "fonts-powerline" "plymouth" "plymouth-themes" "stress" "bluez" "bluez-tools" "tlp" "lm-sensors" "psensor")'
        
        # Variables que se van modificando con el uso
        echo 'HIDE_OUTPUT=true'
        echo 'USE_KONG=false'
        echo 'SELECTED_ANIMATION="BUBBLE"'
    } > $PATH_GLOBAL_CONFIG

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" 3
}

configurations() {
    print_header "Creación del archivos de configuración por defecto"
    zsh_config
    tmux_config
    tlp_config
    trus_config
    print_message "Se han creado los ficheros de configuracion satisfactoriamente" "$COLOR_SUCCESS" 2    "both"
}

swap() {
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
    echo "$SWAP_FILE none swap sw 0 0" >>/etc/fstab

    print_message "Memoria SWAP ampliada a $((SWAP_SIZE_MB / 1024))GB" "$COLOR_SUCCESS" 3 "both"
}

select_animation_menu(){    
    local option=$(print_menu "${ANIMATION_MENU[@]}")
        
    case "$option" in        
    "Volver")
        main_menu
        ;;
    
    "*")
        sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION=$option/" "$PATH_GLOBAL_CONFIG"
        ;;
    esac
}

main_menu() {
    print_header
    local option=$(print_menu "${MAIN_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
        1)
            package_installation
            ;;

        2)
            install_zsh
            ;;

        3)
            bash_prompt
            ;;

        4)
            splash_loader
            ;;

        5)
            configurations_menu
            ;;

        6)
            swap
            ;;

        7)
            select_animation_menu
            ;;

        8)
            install_trus
            ;;

        9)
            cp -f "$TOOLS_ACTUAL_PATH" "$TOOLS_PATH"
            print_message "Tools instalado con éxito" "$COLOR_SUCCESS" 3 "both"
            ;;

        10)
            package_installation
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

configurations_menu() {
    print_header
    local option=$(print_menu "${CONFIGURATION_MENU_OPTIONS[@]}")

    option=$(extract_option "$option")

    case "$option" in
        "ZSH")
            zsh_config
            ;;

        "TMUX")
            tmux_config
            ;;

        "TLP")
            tlp_config
            ;;

        "TrUs")
            trus_config
            ;;

        "Todos")
            configurations
            ;;

        "Volver")
            main_menu
            ;;
    esac
}

help() {
    local option=$1
    case $option in
    1)
        print_message "Instalación de paquetes:" "$COLOR_SECONDARY"

        for package in "${INSTALLATION_PACKAGES[@]}"; do
            print_message "- $package" "$COLOR_TERNARY" 1
        done
        ;;

    2)
        print_message "Instalación de la terminal ZSH y Oh My Zsh." "$COLOR_SECONDARY"
        ;;

    3)
        print_message "Modificación del prompt de Bash para añadirle nuevo estilo y la visualizacion de la rama de git." "$COLOR_SECONDARY"
        ;;

    4)
        print_message "Modificación de la animacion de la animación de arranque del SO (solo linux)." "$COLOR_SECONDARY"
        ;;

    5)
        print_message "Creación de los archivos de confiuración por defecto de ZSH, TMUX, TLP y TrUs" "$COLOR_SECONDARY"
        ;;

    6)
        print_message "Modificación del tamaño del archivo de intercambio. Se crea con un tamaño del 150% de la RAM actual del equipo." "$COLOR_SECONDARY"
        ;;

    7)
        print_message "Permite configurar la animación activa en los mensajes con animación" "$COLOR_SECONDARY"
        ;;

    8)
        print_message "Instalación de Truedat Utils (TrUs)." "$COLOR_SECONDARY"
        ;;

    9)
        print_message "Instalación de Tools, libreria de funciones genericas utilizadas por este instalador y TrUs." "$COLOR_SECONDARY"
        ;;

    10)
        print_message "Instalación completa. Se lanzan todas las opciones." "$COLOR_SECONDARY"
        ;;

    "volver")
        print_message "Vuelve al menú anterior" "$COLOR_PRIMARY"
        ;;

    "salir")
        print_message "Salir de TrUs" "$COLOR_PRIMARY"
        ;;

    "BRAILLE" | "DOT" | "KITT" | "PONG" | "CLASSIC" | "BOX" | "BUBBLE" | "BREATHE" | "GROWING_DOTS" | "PASSING_DOTS" | "METRO" | "SNAKE" | "FILLING_BAR" | "CLASSIC_UTF8" | "BOUNCE" | "VERTICAL_BLOCK" | "HORIZONTAL_BLOCK" | "QUARTER" | "TRIANGLE" | "SEMI_CIRCLE" | "ROTATING_EYES" | "FIREWORK" | "SIMPLE_BRAILLE" | "TRIGRAM" | "ARROW" | "BOUNCING_BALL" | "PONG" | "EARTH" | "CLOCK" | "MOON" | "ORANGE_PULSE" | "BLUE_PULSE" | "FOOTBALL" | "BLINK" | "CAMERA" | "SPARKLING_CAMERA" | "SICK" | "MONKEY" | "BOMB")
        set_active_animation "$option"
        echo "opcion seleccionada => ${active_animation[@]}"
        print_message_with_animation "Animación de ejemplo" "$COLOR_SECONDARY" 2
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
install_tools
source tools "Bienvenido al equipo de Core de Truedat" "Preparación del entorno" "$0"

if [ "$1" == "--help" ]; then
    help $2
else
    set_terminal_config
    main_menu
fi
