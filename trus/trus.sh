#!/bin/bash
#
# Nuevo TrUs v7.0
#     - monolitico, porque 3 archivos de script y uno de config es complicado de mantener
#     - interactivo, con menuses bonitos que faciliten la vida
#     - configurable, desde los colorinchis a formas de instalacion o de trabajar
#     -
###################################################################################################
###### Variables
### Principales

trap stop_animation SIGINT

DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")
HEADER_MESSAGE="Truedat Utils (TrUs)"
DESCRIPTION_MESSAGE=""
SWAP_FILE='/swapfile'
SWAP_SIZE=$(free --giga | awk '/^Mem:/ {print int($2)}')
USER_HOME=$(eval echo ~"$SUDO_USER")
TRUS_DIRECTORY=$USER_HOME/.trus
TRUS_PATH=$TRUS_DIRECTORY/trus.sh
TRUS_LINK_PATH=/usr/local/bin/trus
AWS_TEST_CONTEXT="test-truedat-eks"
TMUX_SESION="truedat"
APT_INSTALLATION_PACKAGES=("redis-tools" "screen" "tmux" "unzip" "curl" "vim" "build-essential" "git" "libssl-dev" "automake" "autoconf" "libncurses5" "libncurses5-dev" "docker.io" "postgresql-client-14" "jq" "gedit" "xclip" "xdotool" "x11-utils" "winehq-stable" "gdebi-core" "libvulkan1" "libvulkan1:i386" "fonts-powerline" "stress" "bluez" "bluez-tools" "tlp" "lm-sensors" "psensor" "xsltproc" "fop" "xmllint" "bc" "wmctrl" "fzf")
SNAP_INSTALLATION_PACKAGES=("dbeaver-ce" "discord" "vivaldi")
TRUS_CONFIG="$USER_HOME/trus.config"

### Menus
MAIN_MENU_OPTIONS=("0 - Salir" "1 - Configurar" "2 - Acciones principales" "3 - Actiones secundarias" "4 - Ayuda")
CONFIGURE_MENU_OPTIONS=("0 - Volver" "1 - Instalación de paquetes y dependencias" "2 - Instalar ZSH y Oh My ZSH" "3 - Archivos de configuración" "4 - Actualizar splash loader" "5 - Actualizar la memoria SWAP (a $SWAP_SIZE GB)" "6 - Configurar animación de los mensajes" "7 - Configurar colores" "8 - Instala TrUs (Truedat Utils)" "9 - Todo")
CONFIGURATION_MENU_OPTIONS=("0 - Volver" "1 - ZSH" "2 - BASH" "3 - Fix login Google (solo BASH)" "4 - TMUX" "5 - TLP" "6 - Grub" "7 - Todos")
ANIMATION_MENU_OPTIONS=("0 - Volver" "ARROW" "BOUNCE" "BOUNCING_BALL" "BOX" "BRAILLE" "BREATHE" "BUBBLE" "OTHER_BUBBLE" "CLASSIC_UTF8" "CLASSIC" "DOT" "FILLING_BAR" "FIREWORK" "GROWING_DOTS" "HORIZONTAL_BLOCK" "KITT" "METRO" "PASSING_DOTS" "PONG" "QUARTER" "ROTATING_EYES" "SEMI_CIRCLE" "SIMPLE_BRAILLE" "SNAKE" "TRIANGLE" "TRIGRAM" "VERTICAL_BLOCK")
PRINCIPAL_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Arrancar Truedat" "2 - Matar Truedat" "3 - Operaciones de bdd" "4 - Operaciones de repositorios")
START_MENU_OPTIONS=("0 - Volver" "1 - Todo" "2 - Solo contenedores" "3 - Solo servicios" "4 - Solo el frontal")
SECONDARY_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Indices de ElasticSearch" "2 - Claves SSH" "3 - Kong" "4 - Linkado de modulos del frontal" "5 - Llamada REST que necesita token de login" "6 - Carga de estructuras" "7 - Carga de linajes" "8 - Entrar en una sesion iniciada de TMUX" "9 - Salir de una sesion inciada de TMUX")
DDBB_MENU_OPTIONS=("0 - Volver" "1 - Descargar SOLO backup de TEST" "2 - Descargar y aplicar backup de TEST" "3 - Aplicar backup de ruta LOCAL" "4 - Crear backup de las bdd actuales" "5 - Limpieza de backups LOCALES" "6 - (Re)crear bdd locales VACÍAS")
REPO_MENU_OPTIONS=("0 - Volver" "1 - Actualizar TODO" "2 - Actualizar solo back" "3 - Actualizar solo front" "4 - Actualizar solo libs")
KONG_MENU_OPTIONS=("0 - Volver" "1 - (Re)generar rutas de Kong" "2 - Configurar Kong")

### Esquema de colores
NO_COLOR="FFFCE2"
COLOR_PRIMARY="BED5E8"
COLOR_SECONDARY="DEE0B7"
COLOR_TERNARY="937F5F"
COLOR_QUATERNARY="808F9C"
COLOR_SUCCESS="10C90A"
COLOR_WARNING="FFCE00"
COLOR_ERROR="C90D0A"
COLOR_BACKRGROUND="000000"

# Echar un ojo para ver qué formato de colores admite (son muchos)
# https://github.com/aurora-0025/gradient-terminal?tab=readme-ov-file
GRADIENT_1="orange"
GRADIENT_2="blue"
GRADIENT_3=""
GRADIENT_4=""
GRADIENT_5=""
GRADIENT_6=""

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
TERMINAL_ANIMATION_HORIZONTAL_BLOCK=(▏ ▎ ▍ ▌ ▋ ▊ ▉ ▉ ▊ ▋ ▌ ▍ ▎ ▏)
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

ASDF_PATH=$USER_HOME/.asdf
AWS_PATH=$USER_HOME/.aws
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
LIBRARIES=("td-cache" "td-cluster" "td-core" "td-df-lib" "td-helm" "k8s")
DOCKER_LOCALHOST="172.17.0.1"
KONG_ADMIN_URL="localhost:8001"
KONG_ROUTES_SERVICES=("health" "td_audit" "td_auth" "td_bg" "td_dd" "td_qx" "td_dq" "td_lm" "td_qe" "td_se" "td_df" "td_ie" "td_cx" "td_i18n" "td_ai")

###################################################################################################
###### Herramientas
### General

check_sudo() {
    message=$1
    if [ "$EUID" -ne 0 ]; then
        print_centered_message "$message" "$COLOR_ERROR"
        exit 1
    fi
}

normalize_text() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | iconv -f utf8 -t ascii//TRANSLIT
}

get_tabs() {
    local tabs=$(($1 * 4))
    printf "%*s" $tabs
}

generate_separator() {
    local length=$1
    local separator=$2

    printf "%${length}s" | tr ' ' "${separator}"
}

pad_message() {
    local message=$1
    local position=${2:-"center"}
    local separator=${3:-" "}
    local max_size=${4:-"-1"}

    local message_length=${#message}

    if [ $max_size -eq -1 ]; then
        IFS=' ' read -r total_length filled_space <<<"$(message_size "$message")"
    else
        filled_space=$max_size
    fi

    case "$position" in
    "left")
        local padding_left=$(generate_separator $filled_space "$separator")
        echo "${padding_left}${message}"
        ;;
    "right")
        local padding_right=$(generate_separator $filled_space "$separator")
        echo "${message}${padding_right}"
        ;;
    "center")
        filled_space=$((filled_space / 2))
        local padding=$(generate_separator $filled_space "$separator")

        echo "${padding}${message}${padding}"
        ;;
    *)
        echo "Posición no reconocida. Usa 'left', 'right' o 'center'."
        ;;
    esac
}

message_size() {
    local message=$1

    local total_length=$(tput cols)
    local filled_space=$(((longitud_total - ${#message})))

    echo "$total_length $filled_space"
}

### Colorinchis

get_color() {
    local COLOR=${1:-$COLOR_PRIMARY}

    R=$((16#${COLOR:0:2}))
    G=$((16#${COLOR:2:2}))
    B=$((16#${COLOR:4:2}))

    BACK_R=$((16#${COLOR_BACKRGROUND:0:2}))
    BACK_G=$((16#${COLOR_BACKRGROUND:2:2}))
    BACK_B=$((16#${COLOR_BACKRGROUND:4:2}))

    echo -e "\e[1;38;2;${R};${G};${B}m"
}

hex_to_rgb() {
    local hex=$1
    local r g b

    r=$(printf "%d" "0x${hex:0:2}")
    g=$(printf "%d" "0x${hex:2:2}")
    b=$(printf "%d" "0x${hex:4:2}")

    echo "$r $g $b"
}

euclidean_distance() {
    local r1=$((16#${1:0:2}))
    local g1=$((16#${1:2:2}))
    local b1=$((16#${1:4:2}))

    local r2=$((16#${2:0:2}))
    local g2=$((16#${2:2:2}))
    local b2=$((16#${2:4:2}))

    local dr=$((r1 - r2))
    local dg=$((g1 - g2))
    local db=$((b1 - b2))

    echo $((dr * dr + dg * dg + db * db))
}

calculate_closest_color() {
    desired_color=$1

    closest_color=""
    closest_distance=-1

    for color in "${TERMINAL_COLORS[@]}"; do
        distance=$(euclidean_distance "$desired_color" "$color")
        if [[ $closest_distance == -1 || $distance -lt $closest_distance ]]; then
            closest_distance=$distance
            closest_color=$color
        fi
    done

    echo
    echo "Color deseado: #$desired_color"
    echo "Color más cercano: #$closest_color"
    echo
}

set_terminal_config() {
    if [ ! -e "$TRUS_CONFIG" ]; then
        trus_config
    fi

    source $TRUS_CONFIG

    if [ "$SIMPLE_ECHO" = "" ]; then
        local background_color_test=${1:-"$COLOR_BACKRGROUND"}
        local foreground_color_test=${2:-"$NO_COLOR"}

        echo -ne "\e]11;#${COLOR_BACKRGROUND}\e\\"
        echo -ne "\e]10;#${COLOR_PRIMARY}\e\\"
        set_active_animation
    fi

    if [ "$HIDE_OUTPUT" = true ]; then
        REDIRECT=">/dev/null 2>&1"
    else
        REDIRECT=""
    fi

    wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
}

exec_command() {
    local command=$1
    eval "$command $REDIRECT"
}

###### Mensajes
### Base

print_message() {
    local message=${1:-""}
    local color=${2:-"$NO_COLOR"}
    local tabs=${3:-0}
    local new_line_before_or_after=${4:-"normal"}

    local transformed_color=$(get_color "$color")
    local transformed_no_color=$(get_color "$NO_COLOR")

    stop_animation

    message="$(get_tabs $tabs)$message"

    if [ -z "$SIMPLE_ECHO" ]; then
        message=$transformed_color$message$transformed_no_color

        if [ "$new_line_before_or_after" = "after" ]; then
            message="$message\n\n"
        elif [ "$new_line_before_or_after" = "before" ]; then
            message="\n$message\n"
        elif [ "$new_line_before_or_after" = "both" ]; then
            message="\n$message\n\n"
        elif [ "$new_line_before_or_after" = "normal" ]; then
            message="$message\n"
        fi
    fi

    echo -ne "$message"
}

print_question() {
    # para su uso: if print_question "<mensaje>" = 0; then
    local question=${1:-""}
    local response=1

    print_centered_message "$question" "$COLOR_WARNING"

    if [ -n "$BASH_VERSION" ]; then
        read -p "¿Deseas hacerlo ahora? (S/N): " user_input
    else
        echo -n "¿Deseas hacerlo ahora? (S/N): "
        read user_input
    fi

    local continue_question=$(normalize_text "$user_input")

    if [ "$continue_question" = "si" ] || [ "$continue_question" = "s" ] || [ "$continue_question" = "y" ] || [ "$continue_question" = "yes" ]; then
        response=0
    fi

    return $response
}

print_menu() {
    local HELP_SCRIPT=$1
    shift
    local items=("$@")

    if [ "$HELP_SCRIPT" = "" ]; then
        HELP_SCRIPT="echo 'No hay ayuda disponible'"
    else
        HELP_SCRIPT="$HELP_SCRIPT {}"
    fi

    printf '%s\n' "${items[@]}" | fzf \
        --ansi \
        --border=rounded \
        --height="$((${#items[@]} + 16))" \
        --info=hidden \
        --layout=reverse \
        --margin=0,3 \
        --padding=1 \
        --preview-window=right,60%,wrap \
        --preview="$HELP_SCRIPT" \
        --prompt="Búsqueda > "
}

### Especiales

print_centered_message() {
    local message=$1
    local color=$2
    local new_line_before_or_after=${3:-"both"}

    if [ -z "$SIMPLE_ECHO" ]; then
        print_message "$(pad_message "$message")" "$color" 0 "$new_line_before_or_after"
    fi
}

print_message_with_gradient() {
    local message=$1
    local message_length=${#message}

    echo "$message" | gterm $GRADIENT_1 $GRADIENT_2 $GRADIENT_3 $GRADIENT_4 $GRADIENT_5 $GRADIENT_6
}

print_separator() {
    local message=${1:-""}
    local separator=${2:-"-"}
    local full_line=$3
    IFS=' ' read -r total_length filled_space <<<"$(message_size "$message")"

    if [ -z "$full_line" ]; then
        echo $(pad_message "" "left" "-" $((filled_space / 4)))

    else
        echo $(pad_message "" "left" "-" $filled_space)
    fi
}

print_header() {
    clear
    sleep 0.11

    local USER_DATA="Usuario: $(echo "$(getent passwd $USER)" | cut -d ':' -f 5 | cut -d ',' -f 1) ($USER)"
    local EQUIPO="Equipo: $(hostname)"
    local empty_line="                                     "

    local logo=($empty_line
        "  &           &&&&&&&&&           &  $(print_separator "$empty_line" "y")"
        "   &&&  &&&&&           &&&&&  &&&   "
        "     &&&&&&&&&&       &&&&&&&&&&     "
        "     &&&*****&&&&& &&&&&*****&&&      _________   ______     __  __    ______       "
        "     &&  *******&&&&&*******  &&     /________/\ /_____/\   /_/\/_/\  /_____/\      $HEADER_MESSAGE"
        "    &&&     **    &   ***     &&&    \__.::.__\/ \:::_ \ \  \:\ \:\ \ \::::_\/_     "
        "   &&&&                      &&&&&       \::\ \   \:(_) ) )  \:\ \:\ \ \:\/___/\    $USER_DATA"
        "   &&&                     &&& &&&        \::\ \   \: __ ´\ \ \:\ \:\ \ \_::._\:\   $EQUIPO"
        "  &&&&                  &&&&&  &&&&        \::\ \   \ \ ´\ \ \ \:\_\:\ \  /____\:\  "
        "  &&&&         &&&&&&&&&&&     &&&&         \__\/    \_\/ \_\/  \_____\/  \_____\/  $DESCRIPTION_MESSAGE"
        "   &&&&&  &&&&&&&&&&         &&&&&   "
        "    &&&&&&&&&&&            &&&&&&    "
        "      &&&&&&&           &&&&&&       $(print_separator "$empty_line" "y")"
        "         &&&&&&&&   &&&&&&&&         "
        "             &&&&&&&&&&&             "
        "                 &&                  ")

    local centered_logo=()
    local min_length=${#logo[0]}

    for line in "${logo[@]}"; do
        local line_length=${#line}
        if [ "$line_length" -lt "$min_length" ]; then
            min_length=$line_length
        fi
    done

    for line in "${logo[@]}"; do
        centered_logo+=("$(pad_message "$line" "right" " " "$min_length")")
    done

    print_message_with_gradient "$(printf "%s\n" "${centered_logo[@]}")"
}

print_semiheader() {
    local message=$1

    if [ -z "$SIMPLE_ECHO" ]; then
        print_separator
    fi

    print_message "$message\n"
}

print_logo() {
    clear

    local logo=("" "" ""
        "              &&             &&&&&&&&&&&&&&&&&&&&              &&               "
        "                &&&&&   &&&&&&&                 &&&&&&&   &&&&&                 "
        "                  &&&&&&&&&&&&&                 &&&&&&&&&&&&&                   "
        "                     &&&&&&&&&&&&&&&       &&&&&&&&&&&&&&&                      "
        "                    &&& ********&&&&&&& &&&&&&&******** &&&                     "
        "                   &&&& ***********&&&&&&&&&*********** &&&&                    "
        "                  &&&&&  ************&&&&&************  &&&&&                   "
        "                  &&&&       *****     &     *****      &&&&&                   "
        "                 &&&&&                                  &&&&&&                  "
        "                &&&&&                                  &&&&&&&                  "
        "                &&&&&                                &&&& &&&&&                 "
        "               &&&&&&                             &&&&&&  &&&&&                 "
        "               &&&&&                         &&&&&&&&&    &&&&&&                "
        "               &&&&&&               &&&&&&&&&&&&&&&       &&&&&&                "
        "               &&&&&&&       &&&&&&&&&&&&&&&&&           &&&&&&                 "
        "                &&&&&&&& &&&&&&&&&&&&&&                &&&&&&&                  "
        "                  &&&&&&&&&&&&&&&&&                  &&&&&&&&                   "
        "                    &&&&&&&&&&&&&                 &&&&&&&&&                     "
        "                      &&&&&&&&&&               &&&&&&&&&&                       "
        "                         &&&&&&&&&&&       &&&&&&&&&&&                          "
        "                            &&&&&&&&&&&&&&&&&&&&&&                              "
        "                                &&&&&&&&&&&&&&&                                 "
        "                                    &&&&&&&                                     "
        "                                                                                "
        "                                                            **                  "
        "    &&&    &&&                                             ***             ***  "
        "   &&&     &&&&&  &&&&&& &&&     &&&   &&&&&&&&      *********   ********  *****"
        "  &&&&     &&&   &&&     &&&     &&&  &&&    &&&&  ***    **** ****   (*** ***  "
        " &&&&      &&&   &&&     &&&     &&& &&&&&&&&&&&& ***      ***   ********* ***  "
        "&&&&       &&&   &&&     &&&    &&&& &&&          ****     *** ***    **** ***  "
        "&&&        &&&&& &&&      &&&&&&&&&   &&&&&&&&&&    **********  *********  *****"
    )

    local centered_logo=()
    local max_length=$(printf "%s" "${logo_lines[@]}" | awk '{print length($0)}' | sort -nr | head -n1)

    for line in "${logo[@]}"; do
        centered_logo+=("$(pad_message "$line" "center" " " "$max_length")")
    done

    print_message_with_gradient "$(printf "%s\n" "${centered_logo[@]}")"

    sleep 1
}

### Animaciones. Original aqui: https://github.com/Silejonu/bash_loading_animations

set_active_animation() {
    local selected=${1:-$SELECTED_ANIMATION}

    list_name="TERMINAL_ANIMATION_$selected"
    eval "active_animation=(\"\${$list_name[@]}\")"
    sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION='$selected'/" "$TRUS_CONFIG"
}

play_animation() {
    message=$1
    tabs=$2
    color=$3
    tput civis
    message=$(get_color "$color")$message

    while true; do
        for frame in "${active_animation[@]}"; do
            for ((i = 1; i <= tabs; i++)); do
                frame="\t"${frame}
            done

            echo -ne "$frame $message\033[0K\r"
            sleep 0.075
        done
    done
}

stop_animation() {
    kill "${animation_pid}" &>/dev/null
    echo -ne "\033[0K"
    tput cnorm
}

print_message_with_animation() {
    local message=${1:-""}
    local color=${2:-"${COLOR_PRIMARY}"}
    local tabs=${3:-0}

    if [ -z "$SIMPLE_ECHO" ]; then
        stop_animation
        unset "active_animation[0]"
        play_animation "$message" "$tabs" "$color" &
        animation_pid="${!}"
    else
        print_message "$message" "$color" "$tabs"
    fi
}

### Git

checkout() {
    local HEADER=${1:-""}

    print_message_with_animation "Apuntando a $HEADER..." "$COLOR_SECONDARY" 3
    exec_command "git checkout $HEADER"
    print_message "Apuntando a $HEADER (HECHO)" "$COLOR_SUCCESS" 3
}

update_git() {
    print_message_with_animation "Actualizando repositorio..." "$COLOR_SECONDARY" 3
    exec_command "git fetch"
    exec_command "git pull "
    print_message "Actualizando repositorio (HECHO)" "$COLOR_SUCCESS" 3
}

clone_if_not_exists() {
    local repo_url=$1
    local target_dir=$2

    if [ ! -d "$target_dir" ]; then
        print_message "Clonando el repositorio desde '$repo_url' en '$target_dir'..." "$COLOR_SUCCESS" 3
        git clone "$repo_url" "$target_dir"
    else
        print_message "El directorio '$target_dir' ya existe. No se clonará el repositorio." "$COLOR_WARNING" 3
    fi
}

update_services() {
    local create_dbb=${1:-""}

    print_semiheader "Actualizando servicios"

    set_elixir_versions

    for SERVICE in "${SERVICES[@]}"; do
        cd "$BACK_PATH/$SERVICE"

        print_message "Actualizando $SERVICE" "$COLOR_SECONDARY" 2 "before"
        checkout "develop"
        update_git

        compile_elixir "$create_dbb"
    done

    if [ -n "$create_ddbb" ]; then
        trus -d -du
    fi
}

update_libraries() {
    print_semiheader "Actualizando librerias"

    for LIBRARY in "${LIBRARIES[@]}"; do
        print_message "Actualizando ${LIBRARY}" "$COLOR_TERNARY" 2 "before"

        cd "$BACK_PATH/$LIBRARY"

        checkout "main"
        update_git
        compile_elixir

        cd ..
    done
}

update_web() {
    cd "$FRONT_PATH/td-web"

    print_semiheader "Actualizando frontal"

    print_message "Actualizando td-web" "$COLOR_QUATERNARY" 2 "before"

    checkout "develop"
    update_git
    compile_web

    cd ..

    cd "$FRONT_PATH/td-web-modules"
    print_message "Actualizando td-web-modules" "$COLOR_QUATERNARY" 2 "before"

    checkout "main"
    update_git
    compile_web

    cd ..
}

update_repositories() {
    local updated_option=${1:-"-a"}
    local create_dbb=${2:-""}

    case "$updated_option" in
    "-b" | "--back")
        update_services "$create_dbb"
        updated_option="de back"
        ;;

    "-f" | "--front")
        update_web
        updated_option="de front"
        ;;

    "-l" | "--libs")
        update_libraries
        updated_option="de librerias"
        ;;

    "-a" | "--all" | "")
        update_services "$create_dbb"
        update_libraries
        update_web
        updated_option="de back, librerias y front"
        ;;
    esac

    print_centered_message "REPOSITORIOS $updated_option ACTUALIZADOS" "$COLOR_SUCCESS" "both"
}

### Compilaciones

compile_web() {
    print_message_with_animation "Compilando React..." "$COLOR_SECONDARY" 3
    exec_command "yarn"
    print_message "Compilando React (HECHO)" "$COLOR_SUCCESS" 3
}

compile_elixir() {
    local create_ddbb=${1:-""}

    print_message_with_animation "Actualizando dependencias Elixir..." "$COLOR_SECONDARY" 3
    exec_command "yes | mix deps.get"
    print_message "Actualizando dependencias Elixir (HECHO)" "$COLOR_SUCCESS" 3

    print_message_with_animation "Compilando Elixir..." "$COLOR_SECONDARY" 3
    exec_command "mix compile"
    print_message "Compilando Elixir (HECHO)" "$COLOR_SUCCESS" 3

    if [ ! "$create_ddbb" = "" ]; then
        print_message_with_animation "Creando bdd..." "$COLOR_SECONDARY" 3
        exec_command "yes | mix ecto.create"
        print_message "Creacion de bdd (HECHO)" "$COLOR_SUCCESS" 3
    fi
}

### ddbb

ddbb() {
    local options=$1
    local backup_path=""

    if [ "$options" = "-d" ] || [ "$options" = "--download-test" ] || [ "$options" = "-du" ] || [ "$options" = "--download-update" ]; then
        download_test_backup
        backup_path=$DDBB_BACKUP_PATH
    fi

    if [ "$options" = "-lu" ] || [ "$options" = "--local-update" ]; then
        get_local_backup_path
    fi

    if [ "$options" = "-lb" ] || [ "$options" = "--local-backup" ]; then
        create_backup_local_ddbb
    fi

    if [ "$options" = "-rc" ] || [ "$options" = "--recreate" ]; then
        recreate_local_ddbb
    fi    

    if { [ -d "$backup_path" ] && [ "$backup_path" != "" ] && [[ "$path_backup" == "$DDBB_BASE_BACKUP_PATH"* ]] && [ "$options" = "-du" ] || [ "$options" = "--download-update" ] || [ "$options" = "-lu" ] || [ "$options" = "--local-update" ]; }; then
        update_ddbb_from_backup "$backup_path"
    fi
}

recreate_local_ddbb(){
    if print_question "Esta acción BORRARÁ las bases de datos y las creará de nuevo VACÍAS" = 0; then
        start_containers
        create_empty_ddbb
    fi
}

download_test_backup() {
    print_semiheader "Creación y descarga de backup de test "

    local PSQL=$(kubectl get pods -l run=psql -o name | cut -d/ -f2)

    mkdir -p "$DDBB_BACKUP_PATH"

    print_message "Ruta de backup creada: $DDBB_BACKUP_PATH" "$COLOR_SECONDARY" 1 "before"
    for DATABASE in "${DATABASES[@]}"; do
        print_message "-->  Descargando $DATABASE" "$COLOR_SECONDARY" 1 "before"

        local SERVICE_NAME="${DATABASE//_/-}"
        local SERVICE_PODNAME="${DATABASE//-/_}"
        local SERVICE_DBNAME="${DATABASE}_dev"
        local SERVICE_PATH="$BACK_PATH/$SERVICE_NAME"
        local FILENAME=$SERVICE_DBNAME".sql"
        local PASSWORD=$(kubectl --context ${AWS_TEST_CONTEXT} get secrets postgres -o json | jq -r '.data.PGPASSWORD' | base64 -d)
        local USER=$(kubectl --context ${AWS_TEST_CONTEXT} get secrets postgres -o json | jq -r '.data.PGUSER' | base64 -d)

        # este codigo está asi (sin usar exec_command) porque al meter la contraseá en una variable e interpretala con eval, se jode y no la interpreta bien,
        # por lo que la funcionalidad que se desa con esa funcion (mostrar o no los mensajes de los comandos) hay que hacerla a lo borrico

        cd "$SERVICE_PATH"
        if [ "$HIDE_OUTPUT" = true ]; then
            print_message_with_animation "creación de backup" "$COLOR_SECONDARY" 2
            kubectl --context ${AWS_TEST_CONTEXT} exec ${PSQL} -- bash -c "PGPASSWORD='${PASSWORD}' pg_dump -d '${SERVICE_PODNAME}' -U '${USER}' -f '/${DATABASE}.sql' -x -O"
            print_message "Creación de backup (HECHO)" "$COLOR_SUCCESS" 2

            print_message_with_animation "descarga backup" "$COLOR_SECONDARY" 2
            kubectl --context ${AWS_TEST_CONTEXT} cp "${PSQL}:/${DATABASE}.sql" "./${FILENAME}" >/dev/null 2>&1
            print_message "Descarga backup (HECHO)" "$COLOR_SUCCESS" 2

            print_message " backup descargado en $service_path/$FILENAME" "$COLOR_WARNING" 2

            print_message_with_animation "borrando fichero generado en el pod" "$COLOR_SECONDARY" 2
            kubectl --context "${AWS_TEST_CONTEXT}" exec "${PSQL}" -- rm "/${DATABASE}.sql" >/dev/null 2>&1
            print_message "Borrando fichero generado en el pod (HECHO)" "$COLOR_SUCCESS" 2

            print_message_with_animation "comentado de 'create publication'" "$COLOR_SECONDARY" 2
            sed -i 's/create publication/--create publication/g' "./${FILENAME}" >/dev/null 2>&1
            print_message "Comentado de 'create publication' (HECHO)" "$COLOR_SUCCESS" 2

            print_message_with_animation "moviendo fichero $FILENAME a backup" "$COLOR_SECONDARY" 2
            mv "$FILENAME" "$DDBB_BACKUP_PATH" >/dev/null 2>&1
            print_message "Moviendo fichero $FILENAME a backup (HECHO)" "$COLOR_SUCCESS" 2
        else
            print_message "Creación de backup" "$COLOR_SECONDARY" 2
            kubectl --context ${AWS_TEST_CONTEXT} exec ${PSQL} -- bash -c "PGPASSWORD='${PASSWORD}' pg_dump -d '${SERVICE_PODNAME}' -U '${USER}' -f '/${DATABASE}.sql' -x -O"
            print_message "Creación de backup (HECHO)" "$COLOR_SUCCESS" 2 "BOTH"

            print_message "Descarga backup" "$COLOR_SECONDARY" 2
            kubectl --context ${AWS_TEST_CONTEXT} cp "${PSQL}:/${DATABASE}.sql" "./${FILENAME}"
            print_message "Descarga backup (HECHO)" "$COLOR_SUCCESS" 2

            print_message " backup descargado en $service_path/$FILENAME" "$COLOR_WARNING" 2

            print_message "Borrando fichero generado en el pod" "$COLOR_SECONDARY" 2
            kubectl --context "${AWS_TEST_CONTEXT}" exec "${PSQL}" -- rm "/${DATABASE}.sql"
            print_message "Borrando fichero generado en el pod (HECHO)" "$COLOR_SUCCESS" 2

            print_message "Comentado de 'create publication'" "$COLOR_SECONDARY" 2
            sed -i 's/create publication/--create publication/g' "./${FILENAME}"
            print_message "Comentado de 'create publication' (HECHO)" "$COLOR_SUCCESS" 2

            print_message "Moviendo fichero $FILENAME a backup" "$COLOR_SECONDARY" 2
            mv "$FILENAME" "$DDBB_BACKUP_PATH"
            print_message "Moviendo fichero $FILENAME a backup (HECHO)" "$COLOR_SUCCESS" 2
        fi
    done

    print_message "Descarga de backup de test terminada" "$COLOR_SUCCESS" 3 "both"
}

-() {
    local SERVICE_DBNAME=$1

    print_message_with_animation " Borrado de bdd $SERVICE_DBNAME" "$COLOR_SECONDARY" 2
    exec_command "mix ecto.drop"
    print_message " Borrado de bdd $SERVICE_DBNAME (HECHO)" "$COLOR_SUCCESS" 2

    print_message_with_animation " Creacion de bdd $SERVICE_DBNAME" "$COLOR_SECONDARY" 2
    exec_command "mix ecto.create"
    print_message " Creacion de bdd $SERVICE_DBNAME (HECHO)" "$COLOR_SUCCESS" 2

    print_message_with_animation " Aplicando migraciones" "$COLOR_SECONDARY" 2
    exec_command "mix ecto.migrate"
    print_message " Aplicando migraciones (HECHO)" "$COLOR_SUCCESS" 2
}

update_ddbb() {
    local FILENAME=("$@")
    

    for FILENAME in "${sql_files[@]}"; do
        SERVICE_DBNAME=$(basename "$FILENAME" ".sql")
        SERVICE_NAME=$(basename "$FILENAME" "_dev.sql" | sed 's/_dev//g; s/_/-/g')

        cd "$BACK_PATH"/"$SERVICE_NAME"

        print_message "-->  actualizando $SERVICE_DBNAME" "$COLOR_SECONDARY" 1 "before"
        create_empty_ddbb "$SERVICE_DBNAME"

        print_message_with_animation " Volcado de datos del backup de test" "$COLOR_SECONDARY" 2
        exec_command "PGPASSWORD=postgres psql -d \"${SERVICE_DBNAME}\" -U postgres  -h localhost < \"${FILENAME}\""
        print_message " Volcado de datos del backup de test (HECHO)" "$COLOR_SUCCESS" 2
    done
    
    
}

update_ddbb_from_backup() {
    local path_backup="$1"

    if [ -d "$path_backup" ] && [ -e "$path_backup" ]; then
        sql_files=()

        while IFS= read -r file; do
            sql_files+=("$file")
        done < <(find "$path_backup" -type f -name "*.sql")

        if [ ${#sql_files[@]} -eq 0 ]; then
            print_centered_message "No se encontraron archivos .sql en el directorio." "$COLOR_ERROR"
        else
            remove_all_redis

            update_ddbb "${sql_files[@]}"

            reindex_all
        fi
    else
        print_centered_message "El directorio especificado no existe." "$COLOR_ERROR"
        exit 1
    fi

    print_message "actualizacion de bdd local terminada" "$color_success" 1
}

get_local_backup_path() {
    print_semiheader "Aplicando un backup de bdd desde una ruta de local"

    print_message "Por favor, indica la carpeta donde está el backup que deseas aplicar (debe estar dentro de '$DDBB_BASE_BACKUP_PATH')" "$COLOR_SECONDARY" 1 "both"
    read -r path_backup

    if [[ "$path_backup" == "$DDBB_BASE_BACKUP_PATH"* ]]; then
        backup_path=$path_backup
    else
        print_message "La ruta '$path_backup' no es una subruta de '$DDBB_BASE_BACKUP_PATH'." "$COLOR_ERROR" 3 "both"
    fi
}

create_backup_local_ddbb() {
    start_containers

    print_semiheader "Creando backup de la bdd"

    mkdir -p "$DDBB_LOCAL_BACKUP_PATH/LB_$(date +%Y%m%d_%H%M%S)"

    cd "$DDBB_LOCAL_BACKUP_PATH/LB_$(date +%Y%m%d_%H%M%S)"

    for DATABASE in "${DATABASES[@]}"; do
        FILENAME=${DATABASE}"_dev.sql"
        print_message_with_animation " Creación de backup de $DATABASE" "$COLOR_SECONDARY" 2
        PGPASSWORD=postgres pg_dump -U postgres -h localhost "${DATABASE}_dev" >"${FILENAME}"
        print_message " Creación de backup de $DATABASE (HECHO)" "$COLOR_SUCCESS" 2
    done
    print_message " Backup creado en $DDBB_LOCAL_BACKUP_PATH" "$COLOR_WARNING" 1 "both"
}

### No-SQL

remove_all_redis() {
    if print_question "¿Quieres borrar todos los datos de Redis?" = 0; then
        exec_command "redis-cli flushall "
        print_message "✳ Borrado de Redis completado ✳" "$COLOR_SUCCESS" 1 "both"
    fi
}

remove_all_index() {
    if print_question "¿Quieres borrar todos los datos de ElasticSearch antes de reindexar?" = 0; then
        do_api_call "" "http://localhost:9200/_all" "DELETE" "--fail"
        print_message "✳ Borrado de ElasticSearch completado ✳" "$COLOR_SUCCESS" 1 "both"
    fi
}

### tmux y screen

go_to_session() {
    local session_name=$1

    clear

    tmux attach-session -t "$session_name"
}

go_out_session() {
    tmux detach-client
}

### Elasticsearch

reindex_all() {
    local remove_all_indexes=${1:-""}
    
    print_header
    print_semiheader "Reindexado de Elasticsearch"

    remove_all_index

    if print_question "¿Seguro que quieres reindexar los indices de ElasticSearch?" = 0; then
        for service in "${INDEXES[@]}"; do
            local normalized_service

            normalized_service=$(normalize_text "$service")

            reindex_one "$normalized_service"
        done
    fi
}

reindex_one() {
    local service=$1

    cd "$BACK_PATH/td-$service"
    print_message "Reindexando servicios de td-$service" "$COLOR_PRIMARY" 1

    case "$service" in
    "dd")
        print_message_with_animation " Reindexando :jobs" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:jobs, :all)\""
        print_message " Reindexando :jobs (HECHO)" "$COLOR_SUCCESS" 2

        print_message_with_animation " Reindexando :structures" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:structures, :all)\""
        print_message " Reindexando :structures (HECHO)" "$COLOR_SUCCESS" 2

        print_message_with_animation " Reindexando :grants" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:grants, :all)\""
        print_message " Reindexando :grants (HECHO)" "$COLOR_SUCCESS" 2

        print_message_with_animation " Reindexando :grant_requests" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:grant_requests, :all)\""
        print_message " Reindexando :grant_requests (HECHO)" "$COLOR_SUCCESS" 2

        print_message_with_animation " Reindexando :implementations" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:implementations, :all)\""
        print_message " Reindexando :implementations (HECHO)" "$COLOR_SUCCESS" 2

        print_message_with_animation " Reindexando :rules" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:rules, :all)\""
        print_message " Reindexando :rules (HECHO)" "$COLOR_SUCCESS" 2 "after"
        ;;

    "bg")
        print_message_with_animation " Reindexando :concepts" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:concepts, :all)\""
        print_message " Reindexando :concepts (HECHO)" "$COLOR_SUCCESS" 2 "after"
        ;;

    "ie")
        print_message_with_animation " Reindexando :ingests" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:ingests, :all)\""
        print_message " Reindexando :ingests (HECHO)" "$COLOR_SUCCESS" 2 "after"
        ;;

    "qx")
        print_message_with_animation " Reindexando :quality_controls" "$COLOR_SECONDARY" 2
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:quality_controls, :all)\""
        print_message " Reindexando :quality_controls (HECHO)" "$COLOR_SUCCESS" 2 "after"
        ;;
    esac
}

### ssh

create_ssh() {
    local continue_ssh_normalized

    if print_question "SE VA A PROCEDER HACER BACKUP DE LAS CLAVES '$TRUEDAT' ACTUALES, BORRAR LA CLAVE EXISTENTE Y CREAR UNA NUEVA HOMÓNIMA" "$COLOR_ERROR" = 0; then
        cd $SSH_PATH

        if [ -f "$SSH_PUBLIC_FILE" ] || [ -f "$SSH_PRIVATE_FILE" ]; then
            print_message "Haciendo backup del contenido de ~/.ssh..." "$COLOR_SECONDARY" 1
            mkdir -p "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
            print_message "Carpeta creada: $SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)" "$COLOR_TERNARY" 3

            if [ -f "$SSH_PUBLIC_FILE" ]; then
                mv "$SSH_PUBLIC_FILE" "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
                print_message "Guardado archivo: $SSH_PUBLIC_FILE" "$COLOR_TERNARY" 3
            fi

            if [ -f "$SSH_PRIVATE_FILE" ]; then
                mv "$SSH_PRIVATE_FILE" "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
                print_message "Guardado archivo: $SSH_PRIVATE_FILE" "$COLOR_TERNARY" 3
            fi
        fi

        exec_command "yes | ssh-keygen -t ed25519 -f $SSH_PRIVATE_FILE -q -N \"\""
        print_message "Clave creada correctamente" "$COLOR_SUCCESS" 3 "before"

        #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
        #En linux no es necesario pero no molesta
        eval "$(ssh-agent -s)"
        ssh_add_result=$(ssh-add $SSH_PRIVATE_FILE 2>&1)

        if [[ "$ssh_add_result" == *"Identity added"* ]]; then
            print_message "Clave registrada correctamente" "$COLOR_SUCCESS" 3 "both"
            print_message "Por favor, registra la siguiente clave en gitlab: $(cat $SSH_PUBLIC_FILE)" "$COLOR_PRIMARY" 1 "after"
        else
            print_centered_message "Hubo un problema al registrar la clave: $ssh_add_result" "$COLOR_ERROR"
        fi
    fi
}

### Link webmodules

link_web_modules() {
    print_header
    print_semiheader "Linkado de modulos"

    if print_question "Se borrarán los links y se volveran a crear" = 0; then
        for d in "${FRONT_PACKAGES[@]}"; do
            cd "$FRONT_PATH/td-web-modules/packages/$d"
            exec_command "yarn unlink"
            exec_command "yarn link"
            cd "$FRONT_PATH/td-web"
            yarn link "@truedat/$d"
        done
    fi
}

#### Otros

extract_menu_option() {
    local input="$1"
    local first_value=$(echo "$input" | cut -d' ' -f1)
    if [[ "$input" == *" - "* ]]; then
        first_value=$(echo "$input" | cut -d' ' -f1)
    fi

    echo "$first_value"
}

###################################################################################################
###### Herramientas para de la instalación
### Configuración

create_configurations() {
    bash_config
    zsh_config
    tmux_config
    tlp_config
    grub_config
}

grub_config() {
    sudo sh -c "
        {
            echo "##################"
            echo "# Añadido por trus"
            echo "##################"
            
            echo 'GRUB_DEFAULT=0                              # Para decir qué opcion tiene por defecto (para que se seleccione automaticamente despues del timeout)'
            echo 'GRUB_TIMEOUT_STYLE=menu 			        # "hidden" para que vaya del tiron'
            echo 'GRUB_TIMEOUT=5					            # Tiempo de espera para elegir, si no, saltará la opcion seleccionada por defecto'
            echo 'GRUB_DISTRIBUTOR='echo Cacafuti'		    # Nombre de la distribucion, antes era => lsb_release -i -s 2> /dev/null || echo Debian'
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"	# Parametros que se le dan al kernel para que haga cosas en el arranque. 'quiet' es para que no muestre mensajes, 'splash' para que muestre la splash screen'
            echo 'GRUB_CMDLINE_LINUX=""				        # Similar al anterior, pero es para pasar parametros a las entradas que muestra grub'
            echo ''
            echo 'GRUB_TERMINAL_OUTPUT="gfxterm"              # Para forzar que pinte colores. Por defecto => console'
            echo 'GRUB_COLOR_NORMAL="black/yellow"            # Colores grub(letra/fondo)'
            echo 'GRUB_COLOR_HIGHLIGHT="black/yellow"           # Colores opcion selecionada (letra/fondo)'
            echo 'GRUB_GFXMODE=auto                           # Resolucion de grub'
            echo ''
            echo 'GRUB_DISABLE_OS_PROBER=true			        # Desactivar para que registre particiones con otros SO (como Windows)'
            echo '#GRUB_DISABLE_LINUX_UUID=true			    # Si se habilita, evitas mandar a grub el UUID al kernel, por lo que habria que pasarle el nombre del dispositivo donde esta el SO (como /(dev/nvme0p1n1 o como se llame la unidad ssd)'
            echo '#GRUB_DISABLE_RECOVERY='true'			    # Si se habilita, quitas las entradas de recuperacion de los SO en grub. Queda mas limpio pero si se jode algo no puedes entrar    '
            
            echo "##################"
            echo "# Añadido por trus"
            echo "##################"
        } > /etc/default/grub"

    sudo update-grub

}

fix_google_login() {
    if ! grep -q "LD_PRELOAD=/lib/x86_64-linux-gnu/libnss_sss.so.2" "$BASH_PATH_CONFIG"; then
        echo 'export LD_PRELOAD=/lib/x86_64-linux-gnu/libnss_sss.so.2' >>"$BASH_PATH_CONFIG"
    fi
}

bash_config() {
    print_semiheader "Prompt de Bash"

    if  ! grep -q 'export COLORTERM=truecolor' "$BASH_PATH_CONFIG" ||
        ! grep -q 'shorten_path() {' "$BASH_PATH_CONFIG" ||
        ! grep -q 'git_branch_status() {' "$BASH_PATH_CONFIG" ||
        ! grep -q 'parse_git_branch() {' "$BASH_PATH_CONFIG" ||
        ! grep -q 'PS1="${debian_chroot' "$BASH_PATH_CONFIG"; then
        {
            echo 'export COLORTERM=truecolor'
            echo '. "$HOME/.asdf/asdf.sh"'
            echo '. "$HOME/.asdf/completions/asdf.bash"'
            echo ''
            echo 'shorten_path() {'
            echo '    full_path=$(pwd)'
            echo '    echo "$full_path" | awk -F/ "{'
            echo '        if (NF > 3) {'
            echo '            print $(NF-2) "/" $(NF-1) "/" $NF;  '
            echo '        } else {'
            echo '            print $0;'
            echo '        }'
            echo '    }"'
            echo '}'
            echo ''
            echo ''
            echo 'git_branch_status() {'
            echo '    branch=$(git branch --show-current 2>/dev/null)'
            echo '    if [ -n "$branch" ]; then'
            echo '        if git diff --quiet 2>/dev/null >&2; then'
            echo '            echo -e "\033[97;48;5;75m($branch)"  '
            echo '        else'
            echo '            echo -e "\033[30;48;5;214m($branch)"  '
            echo ''
            echo '        fi'
            echo '    else'
            echo '        echo ""  '
            echo '    fi'
            echo '}'
            echo ''
            echo 'if [ "`id -u`" -eq 0 ]; then'
            echo '    PS1="|\[\033[1;34m\]\t\[\033[m\]|\033[48;5;202m$(git_branch_status)\033[m|\[\033[1;38;5;202m\]$(shorten_path)\[\033[m\]> "'
            echo 'else'
            echo '    PS1="|\[\033[1;34m\]\t\[\033[m\]|\033[48;5;202m$(git_branch_status)\033[m|\[\033[1;38;5;202m\]$(shorten_path)\[\033[m\]> "'
            echo 'fi'
        } >> $BASH_PATH_CONFIG
    fi

    print_message "Prompt de Bash actualizado" "$COLOR_SUCCESS" 3 "both"
}

zsh_config() {
    print_semiheader "ZSH"

    {
        echo '# If you come from bash you might have to change your $PATH.'
        echo '# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH'
        echo 'ZSH_THEME="agnoster"'
        echo ''
        echo '. "$HOME/.asdf/asdf.sh"'
        echo 'export ZSH="$HOME/.oh-my-zsh"'
        echo 'export COLORTERM=truecolor'
        echo 'source $ZSH/oh-my-zsh.sh'
        echo ''
        echo 'zstyle ':omz:update' mode auto      # update automatically without asking'
        echo 'zstyle ':omz:update' frequency 1'
        echo 'HIST_STAMPS="dd/mm/yyyy"'
        echo ''
        echo ''
        echo '# configuration'
        echo 'export MANPATH="/usr/local/man:$MANPATH"'
        echo 'export LANG=en_US.UTF-8'
        echo 'EDITOR='code''
        echo 'export ARCHFLAGS="-arch $(uname -m)"'
        echo 'plugins=(git elixir asdf fzf git-prompt zsh-autosuggestions zsh-syntax-highlighting zsh-completions)'
        echo ''
        echo "alias ai='cd $BACK_PATH/td-ai'"
        echo "alias audit='cd $BACK_PATH/td-audit'"
        echo "alias auth='cd $BACK_PATH/td-auth'"
        echo "alias bg='cd $BACK_PATH/td-bg'"
        echo "alias dd='cd $BACK_PATH/td-dd'"
        echo "alias df='cd $BACK_PATH/td-df'"
        echo "alias i18n='cd $BACK_PATH/td-i18n'"
        echo "alias ie='cd $BACK_PATH/td-ie'"
        echo "alias lm='cd $BACK_PATH/td-lm'"
        echo "alias qx='cd $BACK_PATH/td-qx'"
        echo "alias se='cd $BACK_PATH/td-se'"
        echo "alias helm='cd $BACK_PATH//td-helm'"
        echo "alias k8s='cd $BACK_PATH//k8s'"
        echo "alias web='cd $FRONT_PATH/td-web'"
        echo "alias webmodules='cd $FRONT_PATH/td-web-modules'"
        echo "alias trudev='cd $DEV_PATH'"
        echo 'alias format="mix format && mix credo --strict"'
        echo ''
        echo 'local -A schars'
        echo 'setopt PROMPT_SUBST'
        echo 'autoload -U compinit && compinit'
        echo 'autoload -Uz prompt_special_chars && prompt_special_chars'
        echo ''
        echo '# otro estilo del prompt'
        echo '# autoload -Uz promptinit && promptinit'
        echo '# prompt bigfade'
        echo ''
        echo '# PROMPT="%B%F{208}$schars[333]$schars[262]$schars[261]$schars[260]%B%~/$schars[260]$schars[261]$schars[262]$schars[333]%b%F{208}%b%f%k "'
        echo ''
        # echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
        echo ''
    } >$ZSH_PATH_CONFIG

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
    } >$TMUX_PATH_CONFIG

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

    exec_command "sudo tlp start"
    exec_command "sudo systemctl enable tlp.service"
}

trus_config() {
    touch $TRUS_CONFIG

    {
        echo 'HIDE_OUTPUT=true'
        echo 'USE_KONG=false'
        echo 'SELECTED_ANIMATION="BUBBLE"'
        echo 'SIMPLE_ECHO=""'
    } >$TRUS_CONFIG

    source $TRUS_CONFIG
}

configure_asdf() {
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
    print_message "Configurando ASDF (HECHO)" "$COLOR_SUCCESS" 3 "before"
}

### Instalación de dependencias

install_trus() {
    print_separator "" "-"
    print_centered_message "Instalando Truedat Utils (TrUs)"
    print_separator "" "-"

    mkdir -p "$TRUS_DIRECTORY"
    cp "$TRUS_ACTUAL_PATH" "$TRUS_PATH"

    sudo rm -f "$TRUS_LINK_PATH"
    sudo ln -s "$TRUS_PATH" "$TRUS_LINK_PATH"

    print_centered_message "Truedat Utils (TrUs) instalado con éxito" "$COLOR_SUCCESS"
}

add_origins() {
    print_semiheader "Instalación de origenes de software"

    #postgres
    print_message_with_animation "Añadiendo origen de Postgres" "$COLOR_TERNARY" 2
    exec_command "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -"
    eval "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' | sudo tee /etc/apt/sources.list.d/pgdg.list$REDIRECT"
    print_message "Origen de Postgres añadido" "$COLOR_SUCCESS" 3

    # wine
    print_message_with_animation "Instalando Wine" "$COLOR_TERNARY" 2
    exec_command "sudo dpkg --add-architecture i386"
    exec_command "wget -q -O- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -"
    exec_command "sudo apt-add-repository -y 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main'"
    print_message "Wine instalado" "$COLOR_SUCCESS" 3

    # para añadir soporte vulkan, que ayuda con temas de temperatura
    print_message_with_animation "Instalando soporte Vulkan" "$COLOR_TERNARY" 2
    exec_command "sudo add-apt-repository -y ppa:graphics-drivers/ppa"
    print_message "Vulkan instalado" "$COLOR_SUCCESS" 3
}

preinstallation() {
    if [ ! -e "/tmp/trus_install_first_part" ]; then
        Se va a realizar la primera parte de la instalación de dependencias para TrUs y Truedat
        En una parte de la instalacion, se ofrecerá instalar zsh y oh my zsh. 
        Si se decide instalarlo, cuando esté ya disponible zsh, escribir "exit" para salir de dicho terminal, 
        ya que la instalación se ha lanzado desde bash y en ese contexto, zsh es un proceso lanzado mas, no la terminal por defecto.
        
        install_trus

        add_origins

        print_message_with_animation "Actualizando sistema" "$COLOR_TERNARY" 2
        exec_command "sudo apt -qq update"
        exec_command "sudo apt -qq upgrade -y"
        print_message "Sistema actualizado" "$COLOR_SUCCESS" 3

        print_message_with_animation "Instalando Docker Compose" "$COLOR_TERNARY" 2
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        sudo chmod +x /usr/local/bin/docker-compose
        sudo groupadd docker
        sudo usermod -aG docker '$USER'
        print_message "Docker Compose instalado" "$COLOR_SUCCESS" 3

        for package in "${APT_INSTALLATION_PACKAGES[@]}"; do
            print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
            exec_command "sudo apt -qq install -y --install-recommends $package"
            print_message "$package instalado" "$COLOR_SUCCESS" 3
        done

        for snap in "${SNAP_INSTALLATION_PACKAGES[@]}"; do
            print_message_with_animation "Instalando $package" "$COLOR_TERNARY" 2
            exec_command "sudo snap install $package"
            print_message "$package instalado" "$COLOR_SUCCESS" 3
        done

        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install

        local user_name=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)
        local user_email=$(whoami)"@bluetab.net"
        print_centered_message "--- (GIT) Se ha configurado GIT con los siguientes datos" "$COLOR_PRIMARY" 1 "before"
        print_centered_message "        - Nombre: $user_name" "$COLOR_SECONDARY" 1 "both"
        print_centered_message "        - Email: $user_email" "$COLOR_SECONDARY" 1 "both"
        print_centered_message "        Si deseas modificarlo, utiliza los siguientes comandos en la terminal:" "$COLOR_PRIMARY" 1 "before"
        print_centered_message "        - Nombre: git config --global user.name "\<user_name\>"'" "$COLOR_SECONDARY" 1 "both"
        print_centered_message "        - Nombre: git config --global user.email "\<user_email\>"'" "$COLOR_SECONDARY" 1 "both"

        git config --global user.name "$user_name"
        git config --global user.email "$user_email"

        install_asdf
        instal_awscli
        install_kubectl
        install_zsh
        
        touch "/tmp/trus_install_first_part"
    elif [[ -e "/tmp/trus_install_first_part" ]] && [[ -e "/tmp/trus_install_second_part" ]]; then
        configure_asdf
        configurations
        touch "/tmp/trus_install_second_part"
    fi
}

install_docker() {
    aws ecr get-login-password --profile truedat --region eu-west-1 | docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com

    cd $DEV_PATH

    ip=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo SERVICES_HOST="$ip" >local_ip.env
    sudo chmod 666 /var/run/docker.sock

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
    print_message "ASDF instalado" "$COLOR_SUCCESS" 3
}

instal_awscli() {
    mkdir $AWS_PATH
    cd $AWS_PATH
    do_api_call "" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "" "-o 'awscliv2.zip'"
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

### Personalizacion del equipo

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

        sudo swapoff "$SWAP_FILE"
        sudo rm "$SWAP_FILE"

        print_message "Archivo de intercambio eliminado" "$COLOR_SUCCESS" 3
    fi

    print_message "Creando un nuevo archivo de intercambio de $((SWAP_SIZE / 1024))GB..." "$COLOR_TERNARY" 3

    sudo fallocate -l "${SWAP_SIZE}G" "$SWAP_FILE"
    sudo chmod 600 "$SWAP_FILE"
    sudo mkswap "$SWAP_FILE"
    sudo swapon "$SWAP_FILE"

    echo "$SWAP_FILE none swap sw 0 0" >>/etc/fstab

    print_message "Memoria SWAP ampliada a $((SWAP_SIZE / 1024))GB" "$COLOR_SUCCESS" 3 "both"
}

### Llamadas a apis

do_api_call() {
    local token="${1:-""}"
    local url="$2"
    local rest_method="${3:-""}"
    local params="${4:-""}"

    local command="curl --silent --globoff --fail "

    if [ ! -z "$token" ]; then
        command+="'header: Bearer ${token}' "
    fi

    if [ ! -z "$rest_method" ]; then
        command+="--request $rest_method "
        if [[ "$rest_method" == "POST" || "$rest_method" == "PUT" || "$rest_method" == "PATCH" ]]; then
            command+="--header \"Content-Type: application/json\" "
        fi
    fi

    if [ ! -z "$params" ]; then
        command+="$params "
    fi

    command+="--location \"$url\" "

    exec_command "$command"
}

get_token() {
    local response=$(do_api_call \
        "" \
        "localhost:8080/api/sessions/" \
        "" \
        "--data '{\"access_method\": \"alternative_login\",\"user\": {\"user_name\": \"admin\",\"password\": \"patata\"}}'")
    echo "$(echo "$response" | jq -r '.token')"
}

load_structures() {
    local path=$1
    local system="$2"
    local token=$(get_token)

    cd "$path"
    do_api_call \
        "$token" \
        "http://localhost:4005/api/systems/${system}/metadata" \
        "POST" \
        "-F \"data_structures=@structures.csv\" -F \"data_structure_relations=@relations.csv\""
}

load_linages() {
    local path=$
    local token

    path=$(eval echo "$1")
    token=$(get_token)

    cd "$path"

    do_api_call \
        "$token" \
        "http://localhost:4005/api/units/test" \
        "PUT" \
        "-F \"nodes=@nodes.csv\" -F \"rels=@rels.csv\""
}

### Arranque de Truedat (TMUX y Screen)

start_containers() {

    print_semiheader "Arrancando contenedores..."

    cd $DEV_PATH

    for container in "${CONTAINERS[@]}"; do
        docker-compose up -d "${container}"
    done

    if "$USE_KONG" = true; then
        docker-compose up -d 'kong'
    fi
}

stop_docker() {

    print_semiheader "Apagando contenedores..."
    cd "$DEV_PATH"

    for container in "${CONTAINERS[@]}"; do
        exec_command "                    docker stop '${container}'"
    done

    if "$USE_KONG" = true; then
        exec_command "            docker stop 'kong'"
    fi
}

start_services() {
    local SERVICES_TO_IGNORE=("$@")
    local SERVICES_TO_START=()

    for SERVICE in "${SERVICES[@]}"; do
        SERVICE_NAME="${SERVICE#td-}"
        if [[ ! " ${SERVICES_TO_IGNORE[*]} " =~ $SERVICE_NAME ]]; then
            SERVICES_TO_START+=("$SERVICE")
        fi
    done

    for SERVICE in "${SERVICES_TO_START[@]}"; do
        screen -h 10000 -mdS "$SERVICE" bash -c "cd $BACK_PATH/$SERVICE && iex --sname ${SERVICE#td-} -S mix phx.server"
    done

    print_message "Servicios arrancados:" "$COLOR_PRIMARY" 1
    screen -ls | awk '/\.td-/ {print $1}' | sed 's/\.\(td-[[:alnum:]]*\)/ => \1/'
}

start_front() {
    cd "$FRONT_PATH"/td-web
    yarn start
}

add_terminal_to_tmux_session() {
    local PANEL=$1
    local COMMAND=$2
    tmux select-pane -t truedat:0."$PANEL"
    tmux send-keys -t truedat:0."$PANEL" "${COMMAND}" C-m
}

start_truedat() {
    local TMUX_SERVICES=("$@")
    local SCREEN_SERVICES=()
    local WINDOW_TOTAL_HEIGHT
    local WINDOW_TOTAL_WIDTH
    local SMALL_COLUMN
    local LARGE_COLUMN
    local TERMINAL_SIZE

    WINDOW_TOTAL_HEIGHT=$(tmux display-message -p '#{window_height}')
    WINDOW_TOTAL_WIDTH=$(tmux display-message -p '#{window_width}')
    SMALL_COLUMN=$((WINDOW_TOTAL_WIDTH / 4))
    LARGE_COLUMN=$((WINDOW_TOTAL_WIDTH / 4 * 3))
    PRINCIPAL_TERMINAL_HEIGHT=$((WINDOW_TOTAL_HEIGHT / 4 * 3))

    kill_truedat

    for SERVICE in "${SERVICES[@]}"; do
        local founded_service="false"
        SERVICE=${SERVICE/td-/}
        for SPLIT in "${TMUX_SERVICES[@]}"; do
            if [[ "${SERVICE/td-/}" = "$SPLIT" ]]; then
                founded_service="true"
                break
            fi
        done

        if [[ "$founded_service" = "false" ]]; then
            SCREEN_SERVICES+=("${SERVICE}")
        fi
    done

    start_containers
    start_services "${TMUX_SERVICES[@]}"

    tmux source-file $TMUX_PATH_CONFIG
    tmux new-session -d -s $TMUX_SESION -n "Truedat"
    tmux select-layout -t truedat:0 main-vertical
    tmux split-window -h -t truedat:0 -p 6

    if [ ${#TMUX_SERVICES[@]} -gt 0 ]; then
        TERMINAL_SIZE=$((WINDOW_TOTAL_HEIGHT / ${#TMUX_SERVICES[@]}))

        for i in "${!TMUX_SERVICES[@]}"; do
            tmux split-window -v -t truedat:0

            SERVICE="${TMUX_SERVICES[$i]}"
            SERVICE_NAME="td-${SERVICE}"
            COMMAND="cd $BACK_PATH/$SERVICE_NAME && iex --sname ${SERVICE} -S mix phx.server"

            add_terminal_to_tmux_session "$i" "$COMMAND"
        done
    fi

    add_terminal_to_tmux_session "$(tmux list-panes -t truedat | awk 'END {print $1 + 0}')" "trus --start-front"
    add_terminal_to_tmux_session "$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') + 1))" "source tools 'Truedat Utils (TrUs)'; print_semiheader 'Truedat'; print_message 'Truedat está arrancado' '$COLOR_PRIMARY' 1; print_message 'Para acceder a la session, utiliza \"trus --attach\"' '$COLOR_SECONDARY' 2;"
    tmux select-pane -t truedat:0."$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') - 1))"

    go_to_session $TRUEDAT
}

kill_truedat() {

    print_semiheader "Matando procesos 'mix' (elixir)"
    exec_command "pkill -9 mix"

    print_semiheader "Matando sesiones Screen"
    exec_command "screen -ls | grep -oP \"^\s*\K\d+\.(?=[^\t])\" | xargs -I {} screen -X -S {} quit"
    exec_command "screen -wipe"

    print_semiheader "Matando front"
    exec_command "pkill -9 $(pgrep -f \"yarn\")"

    print_semiheader "Matando sesiones TMUX"
    exec_command "tmux kill-server"

}

### Gestion de Kong

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
            local SERVICE_ID=$(do_api_call "${KONG_ADMIN_URL}/services/${SERVICE}" | jq -r '.id // empty')
            local DATA='{ "name": "'${SERVICE}'", "host": "'${DOCKER_LOCALHOST}'", "port": '$PORT' }'

            print_message_with_animation "Creando rutas para el servicio: $SERVICE (puerto: $PORT)" "$COLOR_SECONDARY" 2

            if [ -n "${SERVICE_ID}" ]; then
                ROUTE_IDS=$(do_api_call "" "${KONG_ADMIN_URL}/services/${SERVICE}/routes" | jq -r '.data[].id')

                if [ -n "${ROUTE_IDS}" ]; then
                    for ROUTE_ID in ${ROUTE_IDS}; do
                        do_api_call "" "${KONG_ADMIN_URL}/routes/${ROUTE_ID}" "DELETE"
                    done
                fi
                do_api_call "" "${KONG_ADMIN_URL}/services/${SERVICE_ID}" "DELETE"

            fi

            local API_ID=$(do_api_call "" "${KONG_ADMIN_URL}/services" "POST" "-d '$DATA'") | jq -r '.id'

            exec_command "sed -e \"s/%API_ID%/${API_ID}/\" ${SERVICE}.json | curl --silent -H \"Content-Type: application/json\" -X POST \"${KONG_ADMIN_URL}/routes\" -d @- | jq -r '.id'"

            print_message "Rutas servicio: $SERVICE (puerto: $PORT) creadas con éxito" "$COLOR_SUCCESS" 2
        done

        exec_command "do_api_call '${KONG_ADMIN_URL}/services/health/plugins' "POST" "--data 'name=request-termination' --data 'config.status_code=200' --data 'config.message=Kong is alive'"  | jq -r '.id'"

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

###################################################################################################
###### Menus principales

main_menu() {
    local option=$(print_menu "main_menu_help" "${MAIN_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        configure_menu
        ;;

    2)
        principal_actions_menu
        ;;

    3)
        secondary_actions_menu
        ;;

    4)
        help
        ;;

    0)
        clear
        tput reset
        exit 0
        ;;
    esac
}

configure_menu() {

    local option=$(print_menu "configure_menu_help" "${CONFIGURE_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        preinstallation
        ;;

    2)
        install_zsh
        ;;

    3)
        configuration_menu
        ;;

    4)
        splash_loader
        ;;

    5)
        swap
        ;;

    6)
        animation_menu
        ;;

    7)
        echo "PENDIENTE"
        ;;

    8)
        echo "PENDIENTE"
        ;;

    9)
        preinstallation
        install_zsh
        splash_loader
        swap
        ;;

    0)
        main_menu
        ;;
    esac
}

configuration_menu() {
    local option=$(print_menu "configuration_menu_help" "${CONFIGURATION_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        zsh_config
        ;;

    2)
        bash_config
        ;;

    3)
        fix_google_login
        ;;

    4)
        tmux_config
        ;;

    5)
        tlp_config
        ;;
    6)  
        grub_config
        ;;

    7)
        zsh_config
        bash_config
        tmux_config
        tlp_config
        ;;

    0)
        configure_menu
        ;;
    esac
}

animation_menu() {
    local option=$(print_menu "animation_menu_help" "${ANIMATION_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    0)
        configure_menu
        ;;

    *)
        sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION=$option/" "$PATH_GLOBAL_CONFIG"
        ;;
    esac
}

principal_actions_menu() {
    local option=$(print_menu "principal_actions_menu_help" "${PRINCIPAL_ACTIONS_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        start_menu
        ;;

    2)
        kill_truedat
        ;;

    3)
        ddbb_menu
        ;;

    4)
        repo_menu
        ;;

    0)
        main_menu
        ;;
    esac
}

start_menu() {
    local option=$(print_menu "start_menu_help" "${START_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        trus -s
        ;;

    2)
        trus -sc
        ;;

    3)
        trus -ss
        ;;

    4)
        trus -sf
        ;;

    0)
        principal_actions_menu
        ;;
    esac
}

secondary_actions_menu() {
    local option=$(print_menu "secondary_actions_menu_help" "${SECONDARY_ACTIONS_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        trus --reindex
        ;;

    2)
        trus --create-ssh
        ;;

    3)
        kong_menu
        ;;

    4)
        trus --link-modules
        ;;

    5)
        trus --rest
        ;;

    6)
        trus --load-structures
        ;;

    7)
        trus --load-linage
        ;;

    8)
        trus --attach
        ;;

    9)
        trus --detach
        ;;

    0)
        main_menu
        ;;
    esac
}

local_backup_menu() {
    local backups=("0 - Volver" $(find "$DDBB_BASE_BACKUP_PATH" -mindepth 1 -type d) "Otro...")

    local option=$(print_menu "local_backup_help" "${backups[@]}")
    option=$(extract_menu_option "$option")

    case "$option" in
        0)
            ddbb_menu
            ;;

        "Otro...")
            trus -d -lu
            ;;

        "*")
            update_ddbb_from_backup "$backup_path"
            ;;
    esac
}

clean_local_backup_menu() {
    local backups=("0 - Volver" $(find "$DDBB_BASE_BACKUP_PATH" -mindepth 1 -type d) "Borrar todo")

    local option=$(print_menu "clean_local_backup_help" "${backups[@]}")
    option=$(extract_menu_option "$option")

    case "$option" in
        0)
            ddbb_menu
            ;;

        "Borrar")
            if print_question "Se van a borrar todos los backups de $DDBB_BASE_BACKUP_PATH" = 0; then
                local files=${DDBB_BASE_BACKUP_PATH}"/*"

                for FILENAME in $files; do
                    print_message_with_animation "Borrando backup -> $FILENAME"
                    rm -fr $FILENAME
                    print_message "Backup $FILENAME Borrado" "$COLOR_SUCCESS" 1 "before"

                done

                print_centered_message "Backups borrados" "$COLOR_SUCCESS" "both"
            fi
            ;;

        "*")
            if print_question "Se van a borrar el backup $option" = 0; then
                rm -fr $option
            fi
            ;;
    esac
}

ddbb_menu() {
    local option=$(print_menu "ddbb_menu_help" "${DDBB_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        trus -d -d
        ;;

    2)
        trus -d -du
        ;;

    3)
        local_backup_menu
        ;;

    4)
        trus -d -lu
        ;;

    5)
        clean_local_backup_menu
        ;;

    6)
        trus -d -rc
        ;;

    0) 
        main_menu
        ;;
    esac
}

repo_menu() {
    local option=$(print_menu "repo_menu_help" "${REPO_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
        
        1)
            trus --update-repos --all
            ;;
            
        2)
            trus --update-repos --back
            ;;

        3)
            trus --update-repos --front
            ;;

        4)
            trus --update-repos --libs
            ;;

        1)
            trus --update-repos --all
            ;;

        0) ;;
    esac
}

kong_menu() {
    local option=$(print_menu "kong_menu_help" "${KONG_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        kong_routes
        ;;

    2)
        config_kong
        ;;

    0)
        secondary_menu
        ;;
    esac
}


#########################################
### Ayudas

main_menu_help() {
    local option=$1

    case "$option" in
    1)
        print_message "Configurar" "$COLOR_PRIMARY"
        print_message "Aqui se puede instalar los paquetes necesarios para truedat, generar diferentes archivos de configuracón, personalizar TrUs y el equipo, etc"  "$COLOR_SECONDARY"
        ;;
    2)
        print_message "Acciones principales" "$COLOR_PRIMARY"
        print_message "Aqui se realizan las acciones importantes: Arrancar y matar Truedat, actualizar repos, bajar backups de bdd, etc"  "$COLOR_SECONDARY"
        ;;
    3)
        print_message "Actiones secundarias" "$COLOR_PRIMARY"
        print_message "Aqui se realizan otras acciones, no tan importantes, pero necesarias: Reindexar Elastic, Crear claves ssh, configurar el uso de Kong en el equipo, linkar paquetes web, etc"  "$COLOR_SECONDARY"
        ;;
    4)
        print_message "Ayuda" "$COLOR_PRIMARY"
        print_message "Aqui se muestra toda la ayuda de todas las opciones disponibles en Trus (incluidos parámetros para realizar acciones desde script)" "$COLOR_SECONDARY"
        ;;
    *)
    
        print_semiheader "Opciones Menú Principal"
        print_message "Configurar" "$COLOR_PRIMARY" 1
        --print_message "Aqui se puede instalar los paquetes necesarios para truedat, generar diferentes archivos de configuracón, personalizar TrUs y el equipo, etc"  "$COLOR_SECONDARY" 2

        print_message "Acciones principales" "$COLOR_PRIMARY" 1
        print_message "Aqui se realizan las acciones importantes: Arrancar y matar Truedat, actualizar repos, bajar backups de bdd, etc"  "$COLOR_SECONDARY" 2

        print_message "Actiones secundarias" "$COLOR_PRIMARY" 1
        print_message "Aqui se realizan otras acciones, no tan importantes, pero necesarias: Reindexar Elastic, Crear claves ssh, configurar el uso de Kong en el equipo, linkar paquetes web, etc"  "$COLOR_SECONDARY" 2

        print_message "Ayuda" "$COLOR_PRIMARY" 1
        print_message "Aqui se muestra toda la ayuda de todas las opciones disponibles en Trus (incluidos parámetros para realizar acciones desde script)" "$COLOR_SECONDARY" 2

    esac
}


#########################################
### Acciones Principales

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
            print_message "Configuración de aws (HECHO)" "$COLOR_SUCCESS" 3 "before"

            #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
            #En linux no es necesario pero no molesta
            eval "$(ssh-agent -s)"
            ssh-add $SSH_PRIVATE_FILE

            clone_truedat_project

            cd $DEV_PATH
            sudo sysctl -w vm.max_map_count=262144
            sudo cp elastic-search/999-map-count.conf /etc/sysctl.d/
            print_message "Truedat descargado" "$COLOR_SUCCESS" 3 "before"

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

param_router() {
    local param1=$1
    local param2=$2
    local param3=$3
    local param4=$4
    local param5=$5

    if ! [ -e "$TRUS_PATH" ]; then
        preinstallation
    elif [ -z "$param1" ]; then
        print_logo
        sleep 0.5
        print_header
        main_menu
    else
        params=()
        case "$param1" in
        "-i" | "--install")
            install
            ;;

        "-s" | "--start")
            shift
            start_truedat "$@"
            ;;

        "-d" | "--ddbb")
            ddbb "$param2"
            ;;

        "-r" | "--reindex")
            reindex_all
            ;;

        "-k" | "--kill")
            kill_truedat
            ;;

        "-cs" | "--create-ssh")
            create_ssh
            ;;

        "-ur" | "--update-repos")
            update_repositories "$param2" "$param3"
            ;;

        "-l" | "--link-modules")
            link_web_modules
            ;;

        "-kr" | "--kong-routes")
            kong_routes
            ;;

        "-cl" | "--config_kong")
            config_kong
            ;;

        "-h" | "--help")
            help $param2
            ;;

        "-sc" | "--start-containers")
            start_containers
            ;;

        "-ss" | "--start-services")
            shift
            header="$param1"
            shift
            params_echo="${*}"
            start_services "$header" "$params_echo"
            ;;

        "-sf" | "--start-front")
            start_front "$param1"
            ;;

        "-ls" | "--load-structures")
            load_structures "$param2" "$param3"
            ;;

        "-ll" | "--load-linages")
            load_linages "$param2"
            ;;

        "--rest")
            do_api_call "$param2" "$param3" "$param4"
            ;;

        "-at" | "--attach")
            go_to_session
            ;;

        "-dt" | "--dettach")
            go_out_session
            ;;

        "*")
            help
            ;;
        esac
    fi
}

###################################################################################################
###### Lógica inicial
###################################################################################################

clear
set_terminal_config

TRUS_ACTUAL_PATH=$(realpath "$0")

print_centered_message "tareas por completar" "$color_primary" "both"
print_message "bugs" "$color_primary" 1
print_message "- revisar error de 'ruta/*' sale en algunas ocasiones al actualizar la bdd" "$color_secondary" 2
print_message "- revisar error del linkado de paquetes de yarn que no va" "$color_secondary" 2
print_message "- revisar error cuando se pregunta por  algo de s/n que antes pinta un error de get_color" "$color_secondary" 2

print_message "cosas que antes habia y ahora no" "$color_primary" 1
print_message "- hacer los helps" "$color_secondary" 2
print_message "- configurar animacion" "$color_secondary" 2
print_message "- funciones de ayuda" "$color_secondary" 2

print_message "cosas nuevas" "$color_primary" 1
print_message "- informe pidi (script victor)" "$color_secondary" 2
print_message "- multi yarn test" "$color_secondary" 2
print_message "- configurar colores de trus" "$color_secondary" 2
print_message "- añadir submenu al reindexado de elastic, para seleccionar qué indices se quiere reindexar" "$color_secondary" 2
print_message "- añadir submenu al arranque de todo/servicios de truedat, para seleccionar qué servicios se quiere arrancar" "$color_secondary" 2
print_message "- añadir submenu a la actualizacion de repos para seleccionar qué actualizar" "$color_secondary" 2
print_message "- añadir submenu a la descarga de bdd de test para seleccionar qué actualizar" "$color_secondary" 2 "after"
print_message

# seq 10 -1 1 | while read i; do echo -ne "cuenta atrás: $i\r"; sleep 1; done; echo -ne "¡tiempo!\n"

param_router $1 $2 $3 $4 $5

# RNTDELL001174.BLUETAB.NET