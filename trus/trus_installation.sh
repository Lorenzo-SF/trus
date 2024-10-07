#!/bin/bash

source trus_tools

install_applications(){
	local manager="$1"
	shift
	local packages=("$@")
	for package in "${packages[@]}"; do
        print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
        exec_command "sudo $manager $package"
        print_message "$package instalado" "$COLOR_SUCCESS" 3
    done
}

installation() {
	print_semiheader "Preparando el entorno de Truedat/TrUs" 
		
    if [ ! -e "/tmp/trus_install" ]; then   
        print_message "La instalación consta de 2 partes:" "$COLOR_PRIMARY" 2
        print_message "- 1º Instalacion de origenes y paquetes" "$COLOR_SECONDARY" 3
        print_message "- 2º Configuración" "$COLOR_SECONDARY" 3
        
        print_message "Para ello, hay que lanzar primero el script 'trus.sh' y luego el comando 'trus' en ese orden, desde la terminal" "$COLOR_PRIMARY" 2
        print_message "Se va a realizar la primera parte de la instalación de dependencias para TrUs y Truedat" "$COLOR_PRIMARY" 2
        print_message "En una parte de la instalacion, se ofrecerá instalar zsh y oh my zsh. " "$COLOR_PRIMARY" 2
        print_message "Si se decide instalarlo, cuando esté ya disponible zsh, escribir "exit" para salir de dicho terminal y terminar con la instalación" "$COLOR_PRIMARY" 2
        print_message "ya que la instalación se ha lanzado desde bash y en ese contexto, zsh es un proceso lanzado mas, no la terminal por defecto." "$COLOR_PRIMARY" 2 "after"
        
        print_semiheader "Actualizando sistema" 
		print_message_with_animation "Actualizando..." "$COLOR_TERNARY" 2
        exec_command "sudo apt -qq update"
        exec_command "sudo apt -qq upgrade -y"
        exec_command "sudo apt -qq install -y --install-recommends apt-transport-https"
        print_message "Sistema actualizado" "$COLOR_SUCCESS" 3

        print_semiheader "Instalación paquetes de software"
		install_applications "apt -qq install -y --install-recommends" "${APT_INSTALLATION_PACKAGES[@]}"

		if [ ! -f /usr/local/bin/docker-compose ]; then
	        print_message_with_animation "Instalando Docker Compose" "$COLOR_TERNARY" 2
			sudo curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
			sudo chmod +x /usr/local/bin/docker-compose
			sudo groupadd docker
			sudo usermod -aG docker $USER
			sudo chmod 666 /var/run/docker.sock
	        print_message "Docker Compose instalado" "$COLOR_SUCCESS" 3
		fi 

        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install

        local user_name=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)
        local user_email=$(whoami)"@bluetab.net"
        print_message "--- (GIT) Se ha configurado GIT con los siguientes datos" "$COLOR_PRIMARY" 1 "before"
        print_message "        - Nombre: $user_name" "$COLOR_SECONDARY" 1 "both"
        print_message "        - Email: $user_email" "$COLOR_SECONDARY" 1 "both"
        print_message "        Si deseas modificarlo, utiliza los siguientes comandos en la terminal:" "$COLOR_PRIMARY" 1 "before"
        print_message "        - Nombre: git config --global user.name "\<user_name\>"'" "$COLOR_SECONDARY" 1 "both"
        print_message "        - Nombre: git config --global user.email "\<user_email\>"'" "$COLOR_SECONDARY" 1 "both"

        git config --global user.name "$user_name"
        git config --global user.email "$user_email"

        install_asdf
        install_awscli
        install_kubectl
        install_zsh
        
        touch "/tmp/trus_install" 
        update_config "HIDE_OUTPUT" "true"
    fi
}

install_docker() {
    cd $DEV_PATH

    ip=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo SERVICES_HOST="$ip" >local_ip.env
    
    start_containers

    print_message "Contenedores instalados y arrancados" "$COLOR_SECONDARY" 1 "before"
}

set_elixir_versions() {
    exec_command "cd $BACK_PATH/td-auth && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-audit && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-ai && asdf local elixir 1.15"
    exec_command "cd $BACK_PATH/td-bg && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-cluster && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-core && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-dd && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-df && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-df-lib && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-ie && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-lm && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-qx && asdf local elixir 1.14.5-otp-25"
    exec_command "cd $BACK_PATH/td-se && asdf local elixir 1.16"
    print_message "Versiones específicas de Elixir configuradas" "$COLOR_SUCCESS" 2 "both"
}

install_asdf() {
    if [ -e "$ASDF_PATH" ]; then
        rm -fr $ASDF_PATH
    fi

    print_message_with_animation "Instalando ASDF" "$COLOR_TERNARY" 2
    exec_command "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1"
    sudo rm -f ASDF_LINK_PATH && sudo ln -s $ASDF_PATH $ASDF_LINK_PATH
    
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf plugin-add yarn
    KERL_BUILD_DOCS=yes asdf install erlang 25.3
    asdf install elixir 1.13.4
    asdf install elixir 1.14.5-otp-25
    asdf install elixir 1.15
    asdf install elixir 1.16
    asdf install nodejs 18.20.3
    asdf install yarn latest
    print_message "Instalando plugins y librerias de ASDF (HECHO)" "$COLOR_SUCCESS" 3 "before"

    asdf global erlang 25.3
    asdf global elixir 1.13.4
    asdf global nodejs 18.20.3
    asdf global yarn latest

    # Meto esto aqui porque aunque no es de ASDF, depende de que ASDF instale NodeJs
    # https://github.com/aurora-0025/gradient-terminal?tab=readme-ov-file
    npm install -g gradient-terminal
    npm install tinygradient
    npm install ansi-regex
    print_message "ASDF instalado" "$COLOR_SUCCESS" 3
}

install_awscli() {
    mkdir $AWS_PATH
    cd $AWS_PATH
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    cd aws
    sudo ./install
}

install_kubectl() {
    if [ ! -e "$KUBE_PATH" ]; then
        print_message_with_animation "Instalando Kubectl" "$COLOR_TERNARY" 2

        mkdir $KUBE_PATH

        cd $KUBE_PATH

        exec_command "curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"

        touch "$KUBECONFIG_PATH"

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

        } >$KUBECONFIG_PATH

        aws eks update-kubeconfig --region eu-west-1 --name $AWS_TEST_CONTEXT

        print_message "Kubectl instalado y configurado" "$COLOR_SUCCESS" 3
    fi

    print_message "Paquetes y dependencias instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

install_zsh() {
    print_semiheader "Instalación de ZSH"

    print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
    exec_command "sudo apt install -y --install-recommends zsh"
    print_message "$package instalado" "$COLOR_SUCCESS" 3

    print_semiheader "Instalación de Oh-My-ZSH"

    cd

    if [ -e "$OMZ_PATH" ]; then
        rm -fr $OMZ_PATH
    fi

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    clone_if_not_exists https://github.com/zsh-users/zsh-syntax-highlighting.git $OMZ_PLUGINS_PATH/zsh-syntax-highlighting
    clone_if_not_exists https://github.com/zsh-users/zsh-autosuggestions $OMZ_PLUGINS_PATH/zsh-autosuggestions
    clone_if_not_exists https://github.com/zsh-users/zsh-completions $OMZ_PLUGINS_PATH/zsh-completions
    clone_if_not_exists https://github.com/gusaiani/elixir-oh-my-zsh.git $OMZ_PLUGINS_PATH/elixir

    zsh_config

    print_message "Oh-My-ZSH Instalado correctamente. ZSH y Oh-My-ZSH estará disponible en el próximo inicio de sesión" "$COLOR_SUCCESS" 3 "both"
}

splash_loader() {
    print_semiheader "Splash loader"

    # https://github.com/adi1090x/plymouth-themes
    if [ -e "~/plymouth-themes" ]; then
        rm -fr ~/plymouth-themes
    fi

    cd ~/
    git clone https://github.com/adi1090x/plymouth-themes.git ~/plymouth-themes
    cd plymouth-themes/pack_3
    sudo cp -r hexa_retro /usr/share/plymouth/themes/
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/hexa_retro/hexa_retro.plymouth 10000
    sudo update-alternatives --config default.plymouth
    sudo update-initramfs -u
    print_message "Splash loader Instalado correctamente" "$COLOR_SUCCESS" 3 "both"
}

swap() {
    print_semiheader "Ampliación de memoria SWAP"

    if [ -e "$SWAP_FILE" ]; then
        print_message_with_animation "Ya existe un archivo de intercambio. Eliminando..." "$COLOR_TERNARY" 3

        sudo swapoff $SWAP_FILE
        sudo rm $SWAP_FILE

        print_message "Archivo de intercambio eliminado" "$COLOR_SUCCESS" 3
    fi

    print_message "Creando un nuevo archivo de intercambio de $((SWAP_SIZE / 1024))GB..." "$COLOR_TERNARY" 3

    sudo fallocate -l "${SWAP_SIZE}G" $SWAP_FILE
    sudo chmod 600 $SWAP_FILE
    sudo mkswap $SWAP_FILE
    sudo swapon $SWAP_FILE

    echo "$SWAP_FILE none swap sw 0 0" >>/etc/fstab

    print_message "Memoria SWAP ampliada a $((SWAP_SIZE / 1024))GB" "$COLOR_SUCCESS" 3 "both"
}

clone_truedat_project() {
    mkdir -p $WORKSPACE_PATH
    mkdir -p $TRUEDAT_ROOT_PATH
    mkdir -p $BACK_PATH
    mkdir -p $BACK_PATH/logs
    mkdir -p $FRONT_PATH

    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-ai.git $BACK_PATH/td-ai
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-audit.git $BACK_PATH/td-audit
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-auth.git $BACK_PATH/td-auth
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-bg.git $BACK_PATH/td-bg
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-dd.git $BACK_PATH/td-dd
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-df.git $BACK_PATH/td-df
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-ie.git $BACK_PATH/td-ie
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-qx.git $BACK_PATH/td-qx
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-i18n.git $BACK_PATH/td-i18n
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-lm.git $BACK_PATH/td-lm
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-se.git $BACK_PATH/td-se

    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/td-helm.git $BACK_PATH/td-helm
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/clients/demo/k8s.git $BACK_PATH/k8s

    clone_if_not_exists git@github.com:Bluetab/td-df-lib.git $BACK_PATH/td-df-lib
    clone_if_not_exists git@github.com:Bluetab/td-cache.git $BACK_PATH/td-cache
    clone_if_not_exists git@github.com:Bluetab/td-core.git $BACK_PATH/td-core
    clone_if_not_exists git@github.com:Bluetab/td-cluster.git $BACK_PATH/td-cluster

    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/front-end/td-web-modules.git $FRONT_PATH/td-web-modules
    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/front-end/td-web $FRONT_PATH/td-web

    clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/true-dev.git $DEV_PATH
}

install() {
    print_message "Guia de instalación: https://confluence.bluetab.net/pages/viewpage.action?pageId=136022683" "$COLOR_QUATERNARY" 5 "both"

    if [ ! -e "/tmp/truedat_installation" ]; then

        if [ -f "$SSH_PUBLIC_FILE" ]; then
            if [ ! -e "$AWSCONFIG" ]; then
                print_message "ATENCIÓN, SE VA A SOLICITAR LA CONFIGURACIÓN DE AWS 2 VECES" "$COLOR_WARNING" 2 "before"
                print_message "Una para el perfil predeterminado y otra para el de truedat" "$COLOR_WARNING" 2 "both"
                print_message "Estos datos te los debe dar tu responsable" "$COLOR_SECONDARY" 2 "both"

                aws configure
                aws configure --profile truedat
            fi

    		aws ecr get-login-password --profile truedat --region eu-west-1 | docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com    
 
            #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
            #En linux no es necesario pero no molesta
            eval "$(ssh-agent -s)"
            ssh-add $SSH_PRIVATE_FILE

            clone_truedat_project

            cd $DEV_PATH
            sudo sysctl -w vm.max_map_count=262144
            sudo cp elastic-search/999-map-count.conf /etc/sysctl.d/

            update_repositories "-a" "yes"
            link_web_modules
            ddbb "-du"
			install_docker
            config_kong

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
                        echo "0.0.0.0 localhost"
                        echo "##################"
                        echo "# Añadido por trus"
                        echo "##################"
                    } > /etc/hosts'

            touch "/tmp/truedat_installation"
            print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" 3 "both"

            if print_question "Si deseas reinstalarlo, puedes hacerlo borrando el archivo '/temp/truedat_installation'" = 0; then
                rm "/tmp/truedat_installation"
            fi
        else
            print_message "- Claves SSH (NO CREADAS): Tienes que tener creada una clave SSH (el script chequea que la clave se llame 'truedat') en la carpeta ~/.ssh" "$COLOR_ERROR" 3 "before"
            print_message "RECUERDA que tiene que estar registrada en el equipo y en Gitlab. Si no, debes crearla con 'trus -cr' y registarla en la web'" "$COLOR_WARNING" 3 "after"
        fi
    else
        print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" 3 "both"

        if print_question "Si deseas reinstalarlo, puedes hacerlo borrando el archivo '/temp/truedat_installation'" = 0; then
            rm "/tmp/truedat_installation"
            print_message "Archivo '/tmp/truedat_installation' eliminado correctamente" "$COLOR_PRIMARY" 3 "both"
        fi
    fi
}

#kong


get_service_port() {
    local SERVICE_NAME=$1
    local PORT

    case "$SERVICE_NAME" in
    "td_audit")
        PORT=4007
        ;;

    "td_auth")
        PORT=4001
        ;;

    "td_bg")
        PORT=4002
        ;;

    "td_dd")
        PORT=4005
        ;;

    "td_dq")
        PORT=4004
        ;;

    "td_lm")
        PORT=4012
        ;;

    "td_qe")
        PORT=4009
        ;;

    "td_qx")
        PORT=4010
        ;;

    "td_se")
        PORT=4006
        ;;

    "td_df")
        PORT=4013
        ;;

    "td_ie")
        PORT=4014
        ;;

    "td_i18n")
        PORT=4003
        ;;

    "health")
        PORT=9999
        ;;

    "td_cx")
        PORT=4008
        ;;

    "td_ai")
        PORT=4015
        ;;
    esac

    echo $PORT
}

kong_routes() {
    print_header
    print_semiheader "Generación de rutas en Kong"

    if [[ "$USE_KONG" = false ]]; then
        print_message "Kong no está habilitado" "$COLOR_WARNING" 3
        print_message "Si se desea habilitar, utiliza 'trus --config_kong'" "$COLOR_WARNING" 4
    else
        cd $KONG_PATH
        set -o pipefail

        for SERVICE in ${KONG_SERVICES[@]}; do
            local PORT=$(get_service_port "$SERVICE")
            #local SERVICE_ID=$(do_api_call "${KONG_ADMIN_URL}/services/${SERVICE}" | jq -r '.id // empty')
            local SERVICE_ID=$(do_api_call "" "json" "${KONG_ADMIN_URL}/services/${SERVICE}" "GET" "" ".id // empty")
            local DATA='{ "name": "'${SERVICE}'", "host": "'${DOCKER_LOCALHOST}'", "port": '$PORT' }'

            print_message_with_animation "Creando rutas para el servicio: $SERVICE (puerto: $PORT)" "$COLOR_SECONDARY" 2

            if [ -n "${SERVICE_ID}" ]; then
                #ROUTE_IDS=$(do_api_call "" "${KONG_ADMIN_URL}/services/${SERVICE}/routes" | jq -r '.data[].id')
		ROUTE_IDS=$(do_api_call "" "json" "${KONG_ADMIN_URL}/services/${SERVICE}/routes" "GET" "" ".data[].id")
                if [ -n "${ROUTE_IDS}" ]; then
                    for ROUTE_ID in ${ROUTE_IDS}; do
                        #do_api_call "" "${KONG_ADMIN_URL}/routes/${ROUTE_ID}" "DELETE"
                        do_api_call "" "" "${KONG_ADMIN_URL}/routes/${ROUTE_ID}" "DELETE"
                    done
                fi
                #do_api_call "" "${KONG_ADMIN_URL}/services/${SERVICE_ID}" "DELETE"
		do_api_call "" "" "${KONG_ADMIN_URL}/services/${SERVICE_ID}" "DELETE"
            fi

             #local API_ID=$(do_api_call "" "${KONG_ADMIN_URL}/services" "POST" "-d '$DATA'") | jq -r '.id'
	    local API_ID=$(do_api_call "" "json" "${KONG_ADMIN_URL}/services" "POST" "-d '$DATA'" ".id")
            exec_command "sed -e \"s/%API_ID%/${API_ID}/\" ${SERVICE}.json | curl --silent -H \"Content-Type: application/json\" -X POST \"${KONG_ADMIN_URL}/routes\" -d @- | jq -r '.id'"

            print_message "Rutas servicio: $SERVICE (puerto: $PORT) creadas con éxito" "$COLOR_SUCCESS" 2
        done

        #exec_command "do_api_call '${KONG_ADMIN_URL}/services/health/plugins' "POST" "--data 'name=request-termination' --data 'config.status_code=200' --data 'config.message=Kong is alive'"  | jq -r '.id'"
        exec_command "do_api_call '' 'json' '${KONG_ADMIN_URL}/services/health/plugins' 'POST' '--data 'name=request-termination' --data 'config.status_code=200' --data 'config.message=Kong is alive'' '.id'"

        print_message "Creacion de rutas finalizada" "$COLOR_SUCCESS" 2 "both"

    fi
}

activate_kong() {
    print_semiheader "Habilitación de Kong"
    print_message "A continuación, se van a explicar los pasos que se van a seguir si sigues con este proceso" "$COLOR_PRIMARY" 2 "before"
    print_message "Se va a actualizar el archivo de configuracion para reflejar que se debe utilizar Kong a partir de ahora" "$COLOR_SECONDARY" 3
    print_message "Se va a descargar el repo de Kong en $BACK_PATH" "$COLOR_SECONDARY" 3
    print_message "Se van a descargar los siguientes contenedores: ${CONTAINERS_SETUP[@]}" "$COLOR_SECONDARY" 3

    for container in "${CONTAINERS_SETUP[@]}"; do
        print_message "${container[@]}" "$COLOR_TERNARY" 4
    done

    print_message "Se va a actualizar el archivo $TD_WEB_DEV_CONFIG para que apunte a Kong" "$COLOR_SECONDARY" 3
    print_message "Se van a actualizar las rutas de Kong" "$COLOR_SECONDARY" 3

    if print_question "Se va a activar Kong" = 0; then
        sed -i 's/USE_KONG=false/USE_KONG=true/' "$PATH_GLOBAL_CONFIG"

        source $PATH_GLOBAL_CONFIG

        cd $BACK_PATH

        clone_if_not_exists git@gitlab.bluetab.net:dgs-core/true-dat/back-end/kong-setup.git $BACK_PATH/kong-setup

        for container in "${CONTAINERS_SETUP[@]}"; do
            docker-compose up -d "${container}"
        done

        # target: "https://test.truedat.io:443",       -> Se utilizarán los servicios del entorno test
        # target: "http://localhost:8000",             -> Se utilizarán los servicios de nuestro local
        cd $FRONT_PATH

        touch $TD_WEB_DEV_CONFIG

        {
            echo 'module.exports = {'
            echo '  devServer: {'
            echo '    historyApiFallback: true,'
            echo ''
            echo '    proxy: {'
            echo '      "/api": {'
            echo '        target: "http://localhost:8000",'
            echo '        secure: true,'
            echo '        changeOrigin: true,'
            echo '      },'
            echo '      "/callback": {'
            echo '        target: "http://localhost:8000",'
            echo '      },'
            echo '    },'
            echo '  },'
            echo '};'
        } >$TD_WEB_DEV_CONFIG

        start_containers

        kong_routes
    else
        print_centered_message "NO SE HAN REALIZADO MODIFICACIONES" "$COLOR_SUCCESS"
    fi
}

deactivate_kong() {
    print_semiheader "Deshabilitación de Kong"
    print_message "A continuación, se van a explicar los pasos que se van a seguir si sigues con este proceso" "$COLOR_PRIMARY" 2 "before"
    print_message "Se va a actualizar el archivo de configuracion para reflejar que se debe utilizar Kong a partir de ahora" "$COLOR_SECONDARY" 3
    print_message "Se va a borrar el proyecto de kong, que se encuentra en $BACK_PATH/kong-setup" "$COLOR_SECONDARY" 3
    print_message "Se va a eliminar los siguientes contenedores" "$COLOR_SECONDARY" 3

    for container in "${CONTAINERS_SETUP[@]}"; do
        print_message "${container[@]}" "$COLOR_TERNARY" 4
    done

    print_message "Se va a actualizar el archivo $TD_WEB_DEV_CONFIG para que se encargue de enrutar td-web" "$COLOR_SECONDARY" 3

    if print_question "Se va a desactivar Kong" = 0; then
        sed -i 's/USE_KONG=true/USE_KONG=false/' "$PATH_GLOBAL_CONFIG"
        source $PATH_GLOBAL_CONFIG

        rm -f $BACK_PATH/kong_routes

        local kong_id=$(docker ps -q --filter "name=kong")

        stop_docker

        if [ ! $kong_id="" ]; then
            docker rm $kong_id
        fi

        cd $FRONT_PATH

        touch $TD_WEB_DEV_CONFIG

        {
            echo 'const target = host => ({'
            echo '  target: host,'
            echo '  secure: false,'
            echo '  proxyTimeout: 5 * 60 * 1000,'
            echo '  timeout: 5 * 60 * 1000,'
            echo '  onProxyReq: (proxyReq, req, res) => req.setTimeout(5 * 60 * 1000),'
            echo '  changeOrigin: true'
            echo '});'
            echo '// const defaultHost = "https://test.truedat.io";'
            echo 'const defaultHost = "http://localhost:4001";'
            echo 'const defaultTargets = {'
            echo '  ai: target(defaultHost),'
            echo '  audit: target(defaultHost),'
            echo '  auth: target(defaultHost),'
            echo '  bg: target(defaultHost),'
            echo '  cx: target(defaultHost),'
            echo '  dd: target(defaultHost),'
            echo '  df: target(defaultHost),'
            echo '  dq: target(defaultHost),'
            echo '  ie: target(defaultHost),'
            echo '  lm: target(defaultHost),'
            echo '  se: target(defaultHost),'
            echo '  i18n: target(defaultHost),'
            echo '  qx: target(defaultHost)'
            echo '};'
            echo 'const targets = {'
            echo '  ...defaultTargets,'
            echo '  ai: target("http://localhost:4015"),'
            echo '  audit: target("http://localhost:4007"),'
            echo '  auth: target("http://localhost:4001"),'
            echo '  bg: target("http://localhost:4002"),'
            echo '  cx: target("http://localhost:4008"),'
            echo '  dd: target("http://localhost:4005"),'
            echo '  df: target("http://localhost:4013"),'
            echo '  dq: target("http://localhost:4004"),'
            echo '  ie: target("http://localhost:4014"),'
            echo '  lm: target("http://localhost:4012"),'
            echo '  se: target("http://localhost:4006"),'
            echo '  i18n: target("http://localhost:4003"),'
            echo '  qx: target("http://localhost:4010")'
            echo '};'
            echo 'const ai = {'
            echo '  "/api/resource_mappings": targets.ai,'
            echo '  "/api/prompts": targets.ai'
            echo '};'
            echo 'const audit = {'
            echo '  "/api/events": targets.audit,'
            echo '  "/api/notifications": targets.audit,'
            echo '  "/api/subscribers": targets.audit,'
            echo '  "/api/subscriptions": targets.audit'
            echo '};'
            echo 'const auth = {'
            echo '  "/api/acl_entries": targets.auth,'
            echo '  "/api/auth": targets.auth,'
            echo '  "/api/groups": targets.auth,'
            echo '  "/api/init": targets.auth,'
            echo '  "/api/password": targets.auth,'
            echo '  "/api/permission_groupss": targets.auth,'
            echo '  "/api/permissions": targets.auth,'
            echo '  "/api/roles": targets.auth,'
            echo '  "/api/sessions": targets.auth,'
            echo '  "/api/users": targets.auth'
            echo '};'
            echo 'const bg = {'
            echo '  "/api/business_concept_filters": targets.bg,'
            echo '  "/api/business_concept_user_filters": targets.bg,'
            echo '  "/api/business_concept_versions": targets.bg,'
            echo '  "/api/business_concepts": targets.bg,'
            echo '  "/api/domains": targets.bg'
            echo '};'
            echo 'const cx = {'
            echo '  "/api/configurations": targets.cx,'
            echo '  "/api/job_filters": targets.cx,'
            echo '  "/api/jobs": targets.cx,'
            echo '  "/api/sources": targets.cx'
            echo '};'
            echo 'const dd = {'
            echo '  "/api/accesses": targets.dd,'
            echo '  "/api/buckets/structures": targets.dd,'
            echo '  "/api/data_structure_filters": targets.dd,'
            echo '  "/api/data_structure_notes": targets.dd,'
            echo '  "/api/data_structure_tags": targets.dd,'
            echo '  "/api/data_structure_types": targets.dd,'
            echo '  "/api/data_structure_versions": targets.dd,'
            echo '  "/api/data_structures": targets.dd,'
            echo '  "/api/grant_filters": targets.dd,'
            echo '  "/api/grant_request_groups": targets.dd,'
            echo '  "/api/grant_requests": targets.dd,'
            echo '  "/api/grants": targets.dd,'
            echo '  "/api/graphs": targets.dd,'
            echo '  "/api/lineage_events": targets.dd,'
            echo '  "/api/nodes": targets.dd,'
            echo '  "/api/profile_execution_groups": targets.dd,'
            echo '  "/api/profile_executions": targets.dd,'
            echo '  "/api/profiles": targets.dd,'
            echo '  "/api/reference_data": targets.dd,'
            echo '  "/api/relation_types": targets.dd,'
            echo '  "/api/systems": targets.dd,'
            echo '  "/api/units": targets.dd,'
            echo '  "/api/user_search_filters": targets.dd,'
            echo '  "/api/v2": targets.dd'
            echo '};'
            echo 'const df = {'
            echo '  "/api/templates": targets.df,'
            echo '  "/api/hierarchies": targets.df'
            echo '};'
            echo 'const dq = {'
            echo '  "/api/execution_groups": targets.dq,'
            echo '  "/api/executions": targets.dq,'
            echo '  "/api/rule_filters": targets.dq,'
            echo '  "/api/rule_implementation_filters": targets.dq,'
            echo '  "/api/rule_implementations": targets.dq,'
            echo '  "/api/rule_results": targets.dq,'
            echo '  "/api/rules": targets.dq'
            echo '};'
            echo 'const ie = {'
            echo '  "/api/ingests": targets.ie,'
            echo '  "/api/ingest_filters": targets.ie,'
            echo '  "/api/ingest_versions": targets.ie'
            echo '};'
            echo 'const lm = {'
            echo '  "/api/relations": targets.lm,'
            echo '  "/api/tags": targets.lm'
            echo '};'
            echo 'const se = {'
            echo '  "/api/global_search": targets.se'
            echo '};'
            echo 'const i18n = {'
            echo '  "/api/messages": targets.i18n,'
            echo '  "/api/locales": targets.i18n'
            echo '};'
            echo 'const qx = {'
            echo '  "/api/data_views": targets.qx,'
            echo '  "/api/quality_functions": targets.qx,'
            echo '  "/api/quality_controls": targets.qx'
            echo '};'
            echo ''
            echo 'module.exports = {'
            echo '  devtool: "cheap-module-eval-source-map",'
            echo '  devServer: {'
            echo '    host: "0.0.0.0",'
            echo '    disableHostCheck: true,'
            echo '    historyApiFallback: true,'
            echo '    proxy: {'
            echo '      ...ai,'
            echo '      ...audit,'
            echo '      ...auth,'
            echo '      ...bg,'
            echo '      ...cx,'
            echo '      ...dd,'
            echo '      ...df,'
            echo '      ...dq,'
            echo '      ...ie,'
            echo '      ...lm,'
            echo '      ...se,'
            echo '      ...i18n,'
            echo '      ...qx,'
            echo '      "/api": target(defaultHost)'
            echo '    }'
            echo '  }'
            echo '};'
        } >$TD_WEB_DEV_CONFIG
    else
        print_centered_message "NO SE HAN REALIZADO MODIFICACIONES" "$COLOR_SUCCESS"
    fi
}

config_kong() {

    print_semiheader "Kong"
    print_message "¿Quién quieres que enrute, Kong(k) o td-web(w)? (k/w)" "$COLOR_PRIMARY" 1
    read -r install_kong

    local router=$(normalize_text "$install_kong")

    if [ ! "$router" == "" ]; then
        if [ "$router" == "k" ]; then
            activate_kong
        elif [ "$router" == "w" ]; then
            deactivate_kong
        fi
    fi
}