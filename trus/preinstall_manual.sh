#!/bin/bash

trap stop_animation SIGINT
# APT_INSTALLATION_PACKAGES=("curl" "unzip" "vim" "jq" "screen" "tmux" "build-essential" "git" "libssl-dev" "automake" "autoconf" "gedit" "redis-tools" "libncurses6" "libncurses-dev" "docker.io" "postgresql-client" "xclip" "xdotool" "x11-utils" "wine-stable" "gdebi-core" "fonts-powerline" "xsltproc" "fop" "libxml2-utils" "bc" "wmctrl" "fzf" "sl" "neofetch")
APT_INSTALLATION_PACKAGES=("curl" "zsh" "unzip" "vim" "jq" "screen" "tmux" "git" "gedit" "redis-tools" "libncurses6" "libncurses-dev" "docker.io" "postgresql-client" "xclip" "gdebi-core" "fonts-powerline" "xsltproc" "fop" "libxml2-utils" "wmctrl" "fzf" "sl" "neofetch")

if [ -e "~/.config/user-dirs.dirs" ] ; then
    source "~/.config/user-dirs.dirs"
else
    XDG_DESKTOP_DIR="$USER_HOME/Escritorio"
    XDG_DOWNLOAD_DIR="$USER_HOME/Descargas"
    XDG_TEMPLATES_DIR="$USER_HOME/Plantillas"
    XDG_PUBLICSHARE_DIR="$USER_HOME/Público"
    XDG_DOCUMENTS_DIR="$USER_HOME/Documentos"
    XDG_MUSIC_DIR="$USER_HOME/Música"
    XDG_PICTURES_DIR="$USER_HOME/Imágenes"
    XDG_VIDEOS_DIR="$USER_HOME/Vídeos"
fi

DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")
HEADER_MESSAGE="Truedat Utils (TrUs)"
DESCRIPTION_MESSAGE=""
SWAP_FILE=/swapfile
SWAP_SIZE=$(free --giga | awk '/^Mem:/ {print int($2)}')
USER_HOME=$(eval echo ~"$SUDO_USER")
LINK_BASE_PATH=/usr/local/bin
TRUS_BASE_PATH=$USER_HOME/.trus



TRUS_CONFIGURATIONS_PATH=$TRUS_BASE_PATH/trus_configurations.sh 
TRUS_DDBB_PATH=$TRUS_BASE_PATH/trus_ddbb.sh 
TRUS_INSTALLATION_PATH=$TRUS_BASE_PATH/trus_installation.sh 
TRUS_KONG_PATH=$TRUS_BASE_PATH/trus_kong.sh 
TRUS_MESSAGES_PATH=$TRUS_BASE_PATH/trus_messages.sh 
TRUS_TOOLS_PATH=$TRUS_BASE_PATH/trus_tools.sh 
TRUS_PATH=$TRUS_BASE_PATH/trus.sh

TRUS_CONFIG="$TRUS_BASE_PATH/trus.config"

TRUS_LINK_CONFIGURATIONS_PATH=$LINK_BASE_PATH/trus_configurations
TRUS_LINK_DDBB_PATH=$LINK_BASE_PATH/trus_ddbb
TRUS_LINK_INSTALLATION_PATH=$LINK_BASE_PATH/trus_installation
TRUS_LINK_KONG_PATH=$LINK_BASE_PATH/trus_kong
TRUS_LINK_MESSAGES_PATH=$LINK_BASE_PATH/trus_messages
TRUS_LINK_TOOLS_PATH=$LINK_BASE_PATH/trus_tools
TRUS_LINK_PATH=$LINK_BASE_PATH/trus


AWS_TEST_CONTEXT="test-truedat-eks"
TMUX_SESION="truedat"


### Esquema de colores
NO_COLOR='ffffff'
COLOR_PRIMARY='d8dee9'
COLOR_SECONDARY='8fbcbb'
COLOR_TERNARY='d08770'
COLOR_QUATERNARY='b48ead'
COLOR_SUCCESS='a3be8c'
COLOR_WARNING='ebcb8b'
COLOR_ERROR='bf616a'
COLOR_BACKRGROUND='2e3440'


# Echar un ojo para ver qué formato de colores admite (son muchos)
# https://github.com/aurora-0025/gradient-terminal?tab=readme-ov-file
GRADIENT_1='FFC745'
GRADIENT_2=''
# Copia del gradiente 2, para que el degradado se visualice bien
GRADIENT_2_AUX=$GRADIENT_2 
GRADIENT_3='FFC745'
GRADIENT_4=''
GRADIENT_5='007A78'
GRADIENT_6='007A78'

### Animaciones
TERMINAL_ANIMATION_ARROW=(▹▹▹▹▹ ▸▹▹▹▹ ▹▸▹▹▹ ▹▹▸▹▹ ▹▹▹▸▹ ▹▹▹▹▸ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹ ▹▹▹▹▹)
TERMINAL_ANIMATION_BOUNCE=(. · ˙ ·)
TERMINAL_ANIMATION_BOUNCING_BALL=("(●     )" "( ●    )" "(  ●   )" "(   ●  )" "(    ● )" "(     ●)" "(    ● )" "(   ●  )" "(  ●   )" "( ●    )")
TERMINAL_ANIMATION_BOX=(┤ ┴ ├ ┬)
TERMINAL_ANIMATION_BRAILLE=(⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽ ⣾)
TERMINAL_ANIMATION_BREATHE=("  ()  " " (  ) " "(    )" " (  ) ")
TERMINAL_ANIMATION_BUBBLE=(· o O O o ·)
TERMINAL_ANIMATION_OTHER_BUBBLE=("  (·)  " "  (·)  " " ( o ) " " ( o ) " "(  O  )" "(  O  )" " ( o ) " " ( o ) " "  (·)  " "  (·)  ")
TERMINAL_ANIMATION_CLASSIC_UTF8=("—" "\\" "|" "/")
TERMINAL_ANIMATION_CLASSIC=("-" "\\" "|" "/")
TERMINAL_ANIMATION_DOT=(∙∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ●∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙●∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙●∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙●∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙●∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙●∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙●∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙●∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙●∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙●∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙●∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙●∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙●∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙●∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙∙● ∙∙∙∙∙∙∙∙∙∙∙∙∙●∙ ∙∙∙∙∙∙∙∙∙∙∙∙●∙∙ ∙∙∙∙∙∙∙∙∙∙∙●∙∙∙ ∙∙∙∙∙∙∙∙∙∙●∙∙∙∙ ∙∙∙∙∙∙∙∙∙●∙∙∙∙∙ ∙∙∙∙∙∙∙∙●∙∙∙∙∙∙ ∙∙∙∙∙∙∙●∙∙∙∙∙∙∙ ∙∙∙∙∙∙●∙∙∙∙∙∙∙∙ ∙∙∙∙∙●∙∙∙∙∙∙∙∙∙ ∙∙∙∙●∙∙∙∙∙∙∙∙∙∙ ∙∙∙●∙∙∙∙∙∙∙∙∙∙∙ ∙∙●∙∙∙∙∙∙∙∙∙∙∙∙ ∙●∙∙∙∙∙∙∙∙∙∙∙∙∙ ●∙∙∙∙∙∙∙∙∙∙∙∙∙∙ ∙∙∙∙∙∙∙∙∙∙∙∙∙∙∙)
TERMINAL_ANIMATION_FILLING_BAR=("█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒" "███████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒" "████████████████████▒▒▒▒▒▒▒▒▒▒▒▒" "█████████████████████▒▒▒▒▒▒▒▒▒▒▒" "██████████████████████▒▒▒▒▒▒▒▒▒▒" "███████████████████████▒▒▒▒▒▒▒▒▒" "████████████████████████▒▒▒▒▒▒▒▒" "█████████████████████████▒▒▒▒▒▒▒" "██████████████████████████▒▒▒▒▒▒" "███████████████████████████▒▒▒▒▒" "████████████████████████████▒▒▒▒" "█████████████████████████████▒▒▒" "██████████████████████████████▒▒" "███████████████████████████████▒" "████████████████████████████████")
TERMINAL_ANIMATION_FIREWORK=("⢀" "⠠" "⠐" "⠈" "*" "*" " ")
TERMINAL_ANIMATION_GROWING_DOTS=(".  " ".. " "..." ".. " ".  " "   ")
TERMINAL_ANIMATION_HORIZONTAL_BLOCK=(▏ ▎ ▍ ▌ ▋ ▊ ▉ ▉ ▉ ▊ ▋ ▌ ▍ ▎ ▏)
TERMINAL_ANIMATION_KITT=(▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱ ▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱ ▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱ ▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱ ▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱ ▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱ ▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱ ▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱ ▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱ ▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱ ▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱ ▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱ ▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱ ▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰ ▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱)
TERMINAL_ANIMATION_METRO=("[    ]" "[=   ]" "[==  ]" "[=== ]" "[ ===]" "[  ==]" "[   =]")
TERMINAL_ANIMATION_PASSING_DOTS=(".  " ".. " "..." " .." "  ." "   ")
TERMINAL_ANIMATION_PONG=("▐⠂       ▌" "▐⠈       ▌" "▐ ⠂      ▌" "▐ ⠠      ▌" "▐  ⡀     ▌" "▐  ⠠     ▌" "▐   ⠂    ▌" "▐   ⠈    ▌" "▐    ⠂   ▌" "▐    ⠠   ▌" "▐     ⡀  ▌" "▐     ⠠  ▌" "▐      ⠂ ▌" "▐      ⠈ ▌" "▐       ⠂▌" "▐       ⠠▌" "▐       ⡀▌" "▐      ⠠ ▌" "▐      ⠂ ▌" "▐     ⠈  ▌" "▐     ⠂  ▌" "▐    ⠠   ▌" "▐    ⡀   ▌" "▐   ⠠    ▌" "▐   ⠂    ▌" "▐  ⠈     ▌" "▐  ⠂     ▌" "▐ ⠠      ▌" "▐ ⡀      ▌" "▐⠠       ▌")
TERMINAL_ANIMATION_QUARTER=(▖ ▘ ▝ ▗)
TERMINAL_ANIMATION_ROTATING_EYES=(◡◡ ⊙⊙ ⊙⊙ ◠◠)
TERMINAL_ANIMATION_SEMI_CIRCLE=(◐ ◓ ◑ ◒)
TERMINAL_ANIMATION_SIMPLE_BRAILLE=(⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈)
TERMINAL_ANIMATION_SNAKE=("[=     ]" "[~<    ]" "[~~=   ]" "[~~~<  ]" "[ ~~~= ]" "[  ~~~<]" "[   ~~~]" "[    ~~]" "[     ~]" "[      ]")
TERMINAL_ANIMATION_TRIANGLE=(◢ ◣ ◤ ◥)
TERMINAL_ANIMATION_TRIGRAM=(☰ ☱ ☳ ☶ ☴)
TERMINAL_ANIMATION_VERTICAL_BLOCK=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █ █ ▇ ▆ ▅ ▄ ▃ ▂ ▁)
ANIMATIONS=("ARROW" "BOUNCE" "BOUNCING_BALL" "BOX" "BRAILLE" "BREATHE" "BUBBLE" "OTHER_BUBBLE" "CLASSIC_UTF8" "CLASSIC" "DOT" "FILLING_BAR" "FIREWORK" "GROWING_DOTS" "HORIZONTAL_BLOCK" "KITT" "METRO" "PASSING_DOTS" "PONG" "QUARTER" "ROTATING_EYES" "SEMI_CIRCLE" "SIMPLE_BRAILLE" "SNAKE" "TRIANGLE" "TRIGRAM" "VERTICAL_BLOCK")


## Git
GIT_USER_NAME=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)
GIT_USER_EMAIL=$(whoami)"@bluetab.net"
PIDI_PATH=$XDG_DESKTOP_DIR/pidi
PIDI_FILE=$PIDI_PATH/informe_pidi_${GIT_USER_NAME}_${DATE_NOW}.csv


### Menus
MAIN_MENU_OPTIONS=("0 - Salir" "1 - Configurar" "2 - Acciones principales" "3 - Actiones secundarias" "4 - Ayuda")
CONFIGURE_MENU_OPTIONS=("0 - Volver" "1 - Instalación de paquetes y configuración de Truedat" "2 - (Re)instalar ZSH y Oh My ZSH" "3 - Archivos de configuración" "4 - Actualizar splash loader" "5 - Actualizar la memoria SWAP (a $SWAP_SIZE GB)" "6 - Configurar animación de los mensajes" "7 - Configurar colores")
CONFIGURATION_FILES_MENU_OPTIONS=("0 - Volver" "1 - ZSH" "2 - BASH" "3 - Fix login Google (solo BASH)" "4 - TMUX" "5 - TLP" "6 - Todos")
ANIMATION_MENU_OPTIONS=("0 - Volver" "1 - Pintar test animaciones" ${ANIMATIONS[@]})
PRINCIPAL_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Arrancar Truedat" "2 - Matar Truedat" "3 - Operaciones de bdd" "4 - Operaciones de repositorios")
START_MENU_OPTIONS=("0 - Volver" "1 - Todo" "2 - Solo contenedores" "3 - Solo servicios" "4 - Solo el frontal")
SECONDARY_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Indices de ElasticSearch" "2 - Claves SSH" "3 - Kong" "4 - Linkado de modulos del frontal" "5 - Llamada REST que necesita token de login" "6 - Carga de estructuras" "7 - Carga de linajes" "8 - Entrar en una sesion iniciada de TMUX" "9 - Salir de una sesion inciada de TMUX" "10 - Informe PiDi")
DDBB_MENU_OPTIONS=("0 - Volver" "1 - Descargar SOLO backup de TEST" "2 - Descargar y aplicar backup de TEST" "3 - Aplicar backup de ruta LOCAL" "4 - Crear backup de las bdd actuales" "5 - Limpieza de backups LOCALES" "6 - (Re)crear bdd locales VACÍAS")
REPO_MENU_OPTIONS=("0 - Volver" "1 - Actualizar TODO" "2 - Actualizar solo back" "3 - Actualizar solo front" "4 - Actualizar solo libs")
KONG_MENU_OPTIONS=("0 - Volver" "1 - (Re)generar rutas de Kong" "2 - Configurar Kong")


HEADER_LOGO=("  _________   ______     __  __    ______       "
" /________/\ /_____/\   /_/\/_/\  /_____/\      "
" \__.::.__\/ \:::_ \ \  \:\ \:\ \ \::::_\/_     "
"     \::\ \   \:(_) ) )  \:\ \:\ \ \:\/___/\    "
"      \::\ \   \: __ ´\ \ \:\ \:\ \ \_::._\:\   "
"       \::\ \   \ \ ´\ \ \ \:\_\:\ \  /____\:\  "
"        \__\/    \_\/ \_\/  \_____\/  \_____\/  "
)

### Rutas
WORKSPACE_PATH=$USER_HOME/workspace
TRUEDAT_ROOT_PATH=$WORKSPACE_PATH/truedat
BACK_PATH=$TRUEDAT_ROOT_PATH/back
KONG_PATH=$BACK_PATH/kong-setup/data
FRONT_PATH=$TRUEDAT_ROOT_PATH/front
TD_WEB_DEV_CONFIG=$FRONT_PATH/td-web/dev.config.js
DEV_PATH=$TRUEDAT_ROOT_PATH/true-dev
DDBB_BASE_BACKUP_PATH=$TRUEDAT_ROOT_PATH"/ddbb_truedat"
DDBB_BACKUP_PATH=$DDBB_BASE_BACKUP_PATH/$DATE_NOW
DDBB_LOCAL_BACKUP_PATH=$DDBB_BASE_BACKUP_PATH"/local_backups"

SSH_PATH=$USER_HOME/.ssh
SSH_PUBLIC_FILE=$SSH_PATH/truedat.pub
SSH_PRIVATE_FILE=$SSH_PATH/truedat

ASDF_ROOT_PATH=$USER_HOME/.asdf
ASDF_PATH=$ASDF_ROOT_PATH/asdf.sh
ASDF_LINK_PATH=$LINK_BASE_PATH/asdf
AWS_PATH=$USER_HOME/.aws
AWS_CREDENTIALS_PATH="$HOME/.aws/credentials"
AWSCONFIG_PATH=$AWS_PATH/config
KUBE_PATH=$USER_HOME/.kube
KUBECONFIG_PATH=$KUBE_PATH/config

BASH_PATH_CONFIG=$USER_HOME/.bashrc
ZSH_PATH_CONFIG=$USER_HOME/.zshrc
OMZ_PATH=$USER_HOME/.oh-my-zsh
OMZ_PLUGINS_PATH=$OMZ_PATH/custom/plugins
TMUX_PATH_CONFIG=$USER_HOME/.tmux.conf
TLP_PATH_CONFIG=/etc/tlp.conf

### Listados de infraestructura
DATABASES=("td_ai" "td_audit" "td_bg" "td_dd" "td_df" "td_i18n" "td_ie" "td_lm" "td_qx")
INDEXES=("dd" "bg" "ie" "qx")
CONTAINERS=("elasticsearch" "redis" "redis_test" "vault")
CONTAINERS_SETUP=("kong_create" "kong_migrate" "kong_setup" "kong")
FRONT_PACKAGES=("audit" "auth" "bg" "core" "cx" "dd" "df" "dq" "qx" "ie" "lm" "profile" "se" "test")
SERVICES=("td-ai" "td-audit" "td-auth" "td-bg" "td-dd" "td-df" "td-i18n" "td-ie" "td-lm" "td-qx" "td-se")
LIBRARIES=("td-cache" "td-cluster" "td-core" "td-df-lib")
NON_ELIXIR_LIBRARIES=("k8s")
LEGACY_REPOS=("td-helm")
DOCKER_LOCALHOST="172.17.0.1"
KONG_ADMIN_URL="localhost:8001"
KONG_ROUTES_SERVICES=("health" "td_audit" "td_auth" "td_bg" "td_dd" "td_qx" "td_dq" "td_lm" "td_qe" "td_se" "td_df" "td_ie" "td_cx" "td_i18n" "td_ai")

# Variables de uso cotidiano (suelen cambiar de valor)
HIDE_OUTPUT='true'
USE_KONG=true
SELECTED_ANIMATION='BRAILLE'
SIMPLE_ECHO=''


apt -qq update
apt -qq upgrade -y
apt -qq install  -y --install-recommends apt-transport-https
apt -qq install -y --install-recommends $package
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
git config --global user.name "$user_name"
git config --global user.email "$user_email"

mkdir $AWS_PATH
cd $AWS_PATH
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
cd aws
sudo ./install

ir $KUBE_PATH

cd $KUBE_PATH

curl -LO https://dl.k8s.io/release/v1.23.6/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

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

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $OMZ_PLUGINS_PATH/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $OMZ_PLUGINS_PATH/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions $OMZ_PLUGINS_PATH/zsh-completions
git clone https://github.com/gusaiani/elixir-oh-my-zsh.git $OMZ_PLUGINS_PATH/elixir

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
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
asdf global erlang 25.3
asdf global elixir 1.14.5-otp-25
asdf global nodejs 18.20.3
asdf global yarn latest
npm install -g gradient-terminal
npm install -g tinygradient
npm install -g ansi-regex
    

mkdir -p "$TRUS_BASE_PATH"
rm -f "$TRUS_BASE_PATH"/*
cp -r "$PWD"/* "$TRUS_BASE_PATH"
cp $TRUS_DEFAULT_CONFIG trus.config

sudo rm -f $TRUS_LINK_PATH && sudo ln -s $TRUS_PATH $TRUS_LINK_PATH

source $TRUS_DEFAULT_CONFIG
source $TRUS_CONFIG          