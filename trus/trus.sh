#!/bin/bash

# =================================================================================================
# ======
# ====== TrUs (Truedat Utils)
# ====== V8.0
# ====== 21/10/2024
# ====== Herramientas y utilidades para la instalaion del entorno de Truedat y para el día a día
# ======
# =================================================================================================

# =================================================================================================
# ====== Variables
# =================================================================================================

trap stop_animation SIGINT

# ====== Generales

DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")
HEADER_MESSAGE="Truedat Utils (TrUs)"
DESCRIPTION_MESSAGE=""
SWAP_FILE=/swapfile
SWAP_SIZE=$(free --giga | awk '/^Mem:/ {print int($2)}')
USER_HOME=$(eval echo ~"$SUDO_USER")
APT_INSTALLATION_PACKAGES=("curl" "unzip" "vim" "jq" "apt-transport-https" "screen" "tmux" "build-essential" "git" "libssl-dev" "automake" "autoconf" "gedit" "redis-tools" "libncurses6" "libncurses-dev" "docker.io" "postgresql-client" "xclip" "xdotool" "x11-utils" "wine-stable" "gdebi-core" "fonts-powerline" "xsltproc" "fop" "libxml2-utils" "bc" "wmctrl" "fzf" "sl" "neofetch")
ARCHITECTURE=$(dpkg --print-architecture)

# ====== Sesiones, contextos y configuraciones

AWS_TEST_CONTEXT="test-truedat-eks"
TMUX_SESION="truedat"
GIT_USER_NAME=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)
GIT_USER_EMAIL=$(whoami)"@bluetab.net"
PIDI_PATH=$XDG_DESKTOP_DIR/pidi
PIDI_FILE=$PIDI_PATH/informe_pidi_${GIT_USER_NAME}_${DATE_NOW}.csv

# =================================================================================================
# ====== Rutas

TRUS_BASE_PATH=$USER_HOME/.trus
TRUS_CONFIG="$TRUS_BASE_PATH/trus.config"

# ====== Enlaces simbolicos

LINK_BASE_PATH=/usr/local/bin
TRUS_LINK_PATH=$LINK_BASE_PATH/trus

# ====== Rutas Truedat

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

# ====== SSH, ASDF, AWS, KUBE y otros

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

# ====== Rutas de usuario actual (para poder navegar a las carpetas del usuario, independientemente del ididoma)

if [ -e "~/.config/user-dirs.dirs" ]; then
    source ~/.config/user-dirs.dirs
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

# ====== Listados de elementos de infraestructura a procesar

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

# =================================================================================================
# ====== Configuración de Trus

HEADER_LOGO=("  _________   ______     __  __    ______       "
    " /________/\ /_____/\   /_/\/_/\  /_____/\      "
    " \__.::.__\/ \:::_ \ \  \:\ \:\ \ \::::_\/_     "
    "     \::\ \   \:(_) ) )  \:\ \:\ \ \:\/___/\    "
    "      \::\ \   \: __ ´\ \ \:\ \:\ \ \_::._\:\   "
    "       \::\ \   \ \ ´\ \ \ \:\_\:\ \  /____\:\  "
    "        \__\/    \_\/ \_\/  \_____\/  \_____\/  "
)

MAIN_MENU_OPTIONS=("0 - Salir" "1 - Configurar" "2 - Acciones principales" "3 - Actiones secundarias" "4 - Ayuda")
CONFIGURE_MENU_OPTIONS=("0 - Volver" "1 - Instalación de paquetes y configuración de Truedat" "2 - (Re)instalar ZSH y Oh My ZSH" "3 - Archivos de configuración" "4 - Actualizar splash loader" "5 - Actualizar la memoria SWAP (a $SWAP_SIZE GB)" "6 - Configurar animación de los mensajes" "7 - Configurar colores")
CONFIGURATION_FILES_MENU_OPTIONS=("0 - Volver" "1 - ZSH" "2 - BASH" "3 - Fix login Google (solo BASH)" "4 - TMUX" "5 - TLP" "6 - Añadir al archivo de hosts info de Truedat" "7 - Todos")
ANIMATION_MENU_OPTIONS=("0 - Volver" "1 - Pintar test animaciones" ${ANIMATIONS[@]})
PRINCIPAL_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Arrancar Truedat" "2 - Matar Truedat" "3 - Operaciones de bdd" "4 - Operaciones de repositorios")
START_MENU_OPTIONS=("0 - Volver" "1 - Todo" "2 - Solo contenedores" "3 - Solo servicios" "4 - Solo el frontal")
SECONDARY_ACTIONS_MENU_OPTIONS=("0 - Volver" "1 - Indices de ElasticSearch" "2 - Claves SSH" "3 - Kong" "4 - Linkado de modulos del frontal" "5 - Llamada REST que necesita token de login" "6 - Carga de estructuras" "7 - Carga de linajes" "8 - Entrar en una sesion iniciada de TMUX" "9 - Salir de una sesion inciada de TMUX" "10 - Informe PiDi")
DDBB_MENU_OPTIONS=("0 - Volver" "1 - Descargar SOLO backup de TEST" "2 - Descargar y aplicar backup de TEST" "3 - Aplicar backup de ruta LOCAL" "4 - Crear backup de las bdd actuales" "5 - Limpieza de backups LOCALES" "6 - (Re)crear bdd locales VACÍAS")
REPO_MENU_OPTIONS=("0 - Volver" "1 - Actualizar TODO" "2 - Actualizar solo back" "3 - Actualizar solo front" "4 - Actualizar solo libs")
KONG_MENU_OPTIONS=("0 - Volver" "1 - (Re)generar rutas de Kong" "2 - Configurar Kong")

# ====== Animaciones

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

# =================================================================================================
# ====== Personalizacion de TrUs (se sobreescribe en trus.config)
# =================================================================================================

# ====== Esquema de colores

NO_COLOR="#FFFCE2"
COLOR_PRIMARY="#BED5E8"
COLOR_SECONDARY="#DEE0B7"
COLOR_TERNARY="#937F5F"
COLOR_QUATERNARY="#808F9C"
COLOR_SUCCESS="#10C90A"
COLOR_WARNING="#FFCE00"
COLOR_ERROR="#C90D0A"
COLOR_BACKRGROUND="#000000"

# ====== Esquema de colores del gradiente
# https://github.com/aurora-0025/gradient-terminal?tab=readme-ov-file

GRADIENT_1="orange"
GRADIENT_2="blue"
GRADIENT_3=""
GRADIENT_4=""
GRADIENT_5=""
GRADIENT_6=""

# ====== Comportamiento de

HIDE_OUTPUT='false'
USE_KONG=false
SELECTED_ANIMATION='BUBBLE'
SIMPLE_ECHO=""

# =================================================================================================
# ====== Herramientas
# =================================================================================================

check_sudo() {
    local message=$1
    if [ "$EUID" -ne 0 ]; then
        print_message "$message" "$COLOR_ERROR" "" "centered"
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
    "left") echo "$(generate_separator $filled_space "$separator")$message" ;;
    "right") echo "$message$(generate_separator $filled_space "$separator")" ;;
    "center")
        filled_space=$((filled_space / 2))
        echo "$(generate_separator $filled_space "$separator")$message$(generate_separator $filled_space "$separator")"
        ;;
    *) echo "Posición no reconocida. Usa 'left', 'right' o 'center'." ;;
    esac
}

message_size() {
    local message=$1

    local total_length=$(tput cols)
    local filled_space=$(((total_length - ${#message})))

    echo "$total_length $filled_space"
}

set_terminal_config() {
    source $TRUS_CONFIG

    if [ "$SIMPLE_ECHO" = "" ]; then
        echo -ne "\e]11;#${COLOR_BACKRGROUND}\e\\"
        echo -ne "\e]10;#${NO_COLOR}\e\\"
        set_active_animation
    fi

    if [ ! -z "$HIDE_OUTPUT" ]; then
        REDIRECT=">/dev/null 2>&1"
    else
        REDIRECT=""
    fi

    if command -v wmctrl &>/dev/null; then
        wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi
}

exec_command() {
    local command=$1
    local error_message
    local output_message

    command="$command $REDIRECT"

    if output_message=$(eval "$command" 2>&1); then
        if [[ -n "$HIDE_MESSAGE" ]]; then
            print_message "Comando ejecutado correctamente: $command" "$COLOR_SUCCESS" "before"
            print_message "Salida del comando: $output_message" "$COLOR_INFO"
        fi
    else
        print_message "Error ejecutando el comando: $command" "$COLOR_ERROR" "before"
        print_message "Path actual: $(pwd)" "$COLOR_WARNING"
        print_message "Detalles del error: $output_message" "$COLOR_WARNING" "after"
        exit 1
    fi
}

validar_fecha() {
    local fecha="$1"
    if [[ "$fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

# =================================================================================================
# ====== Personalizacion
# =================================================================================================

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
    print_message "Splash loader Instalado correctamente" "$COLOR_SUCCESS" "both"
}

swap() {
    print_semiheader "Ampliación de memoria SWAP"

    if [ -e "$SWAP_FILE" ]; then
        print_message_with_animation "Ya existe un archivo de intercambio. Eliminando..." "$COLOR_TERNARY"

        sudo swapoff $SWAP_FILE
        sudo rm $SWAP_FILE

        print_message "Archivo de intercambio eliminado" "$COLOR_SUCCESS"
    fi

    print_message "Creando un nuevo archivo de intercambio de $((SWAP_SIZE / 1024))GB..." "$COLOR_TERNARY"

    sudo fallocate -l "${SWAP_SIZE}G" $SWAP_FILE
    sudo chmod 600 $SWAP_FILE
    sudo mkswap $SWAP_FILE
    sudo swapon $SWAP_FILE

    echo "$SWAP_FILE none swap sw 0 0" >>/etc/fstab

    print_message "Memoria SWAP ampliada a $((SWAP_SIZE / 1024))GB" "$COLOR_SUCCESS" "both"
}

get_color() {
    local COLOR=${1:-$COLOR_PRIMARY}
    local R=$((16#${COLOR:1:2}))
    local G=$((16#${COLOR:3:2}))
    local B=$((16#${COLOR:5:2}))
    echo -e "\e[38;2;${R};${G};${B}m"
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

declare propiedadesConfigurables=("COLOR_PRIMARY" "COLOR_SECONDARY" "COLOR_TERNARY" "COLOR_QUATERNARY" "COLOR_SUCCESS" "COLOR_WARNING" "COLOR_ERROR" "COLOR_BACKRGROUND" "GRADIENT_1" "GRADIENT_2" "GRADIENT_3" "GRADIENT_4" "GRADIENT_5" "GRADIENT_6")

declare -A textosPropiedadesConfigurables=(
    [COLOR_PRIMARY]="Color 1º nivel"
    [COLOR_SECONDARY]="Color 2º nivel"
    [COLOR_TERNARY]="Color 3º nivel"
    [COLOR_QUATERNARY]="Color 4º nivel"
    [COLOR_SUCCESS]="Color success"
    [COLOR_WARNING]="Color advertencia"
    [COLOR_ERROR]="Color error"
    [COLOR_BACKRGROUND]="Color Fondo"
    [GRADIENT_1]="Gradiente posicion 1"
    [GRADIENT_2]="Gradiente posicion 2"
    [GRADIENT_3]="Gradiente posicion 3"
    [GRADIENT_4]="Gradiente posicion 4"
    [GRADIENT_5]="Gradiente posicion 5"
    [GRADIENT_6]="Gradiente posicion 6"
)

declare -A relacionPropiedadesConfigurables=(
    ['Color 1º nivel']="COLOR_PRIMARY"
    ['Color 2º nivel']="COLOR_SECONDARY"
    ['Color 3º nivel']="COLOR_TERNARY"
    ['Color 4º nivel']="COLOR_QUATERNARY"
    ['Color success']="COLOR_SUCCESS"
    ['Color advertencia']="COLOR_WARNING"
    ['Color Error']="COLOR_ERROR"
    ['Color Fondo']="COLOR_BACKRGROUND"
    ['Gradiente posicion 1']="GRADIENT_1"
    ['Gradiente posicion 2']="GRADIENT_2"
    ['Gradiente posicion 3']="GRADIENT_3"
    ['Gradiente posicion 4']="GRADIENT_4"
    ['Gradiente posicion 5']="GRADIENT_5"
    ['Gradiente posicion 6']="GRADIENT_6"
)

get_example_color() {
    local campo_seleccionado=${relacionPropiedadesConfigurables[$1]}

    case $campo_seleccionado in
    "COLOR_PRIMARY") print_message "Ejemplo color" "$COLOR_PRIMARY" ;;
    "COLOR_SECONDARY") print_message "Ejemplo color" "$COLOR_SECONDARY" ;;
    "COLOR_TERNARY") print_message "Ejemplo color" "$COLOR_TERNARY" ;;
    "COLOR_QUATERNARY") print_message "Ejemplo color" "$COLOR_QUATERNARY" ;;
    "COLOR_SUCCESS") print_message "Ejemplo color" "$COLOR_SUCCESS" ;;
    "COLOR_WARNING") print_message "Ejemplo color" "$COLOR_WARNING" ;;
    "COLOR_ERROR") print_message "Ejemplo color" "$COLOR_ERROR" ;;
    "COLOR_BACKRGROUND") print_message "Ejemplo color" "$COLOR_BACKRGROUND" ;;
    "GRADIENT_1") print_message "Ejemplo color" "$GRADIENT_1" ;;
    "GRADIENT_2") print_message "Ejemplo color" "$GRADIENT_2" ;;
    "GRADIENT_3") print_message "Ejemplo color" "$GRADIENT_3" ;;
    "GRADIENT_4") print_message "Ejemplo color" "$GRADIENT_4" ;;
    "GRADIENT_5") print_message "Ejemplo color" "$GRADIENT_5" ;;
    "GRADIENT_6") print_message "Ejemplo color" "$GRADIENT_6" ;;
    esac
}

config_colours_menu() {
    local opciones_menu=("0 - Volver" "1 - Visualizar ejemplo de configuracion actual")
    for campo in "${propiedadesConfigurables[@]}"; do
        opciones_menu+=("${textosPropiedadesConfigurables[$campo]}")
    done

    local texto_seleccionado=$(print_menu "get_example_color" "${opciones_menu[@]}")

    option=$(extract_menu_option "$texto_seleccionado")
    case "$option" in
    0)
        configure_menu
        ;;

    1)
        print_test_messages

        if print_question "¿Quieres volver al menu de configuración de colores?" = 0; then
            print_header
            config_colours_menu
        fi
        ;;

    *)
        local campo_seleccionado=${relacionPropiedadesConfigurables[$texto_seleccionado]}

        if [ -z "$campo_seleccionado" ]; then
            print_message "Error: No se encontró el campo correspondiente." "$COLOR_ERROR"
            return 1
        fi

        print_semiheader "Actualizando color: $texto_seleccionado"
        print_message "- Valor actual: ${!campo_seleccionado}" "$COLOR_PRIMARY" "after"
        print_message "Formato admitido de colores:"

        printf "%-22s %-22s %-25s %-25s\n" "Hex" "RGB/RGBA" "HSL/HSLA" "HSV/HSVA"
        print_separator "" "-" "quarter"

        printf "%-22s %-22s %-25s %-25s\n" "#000" "rgb (255, 0, 0)" "hsl(0, 100%, 50%)" "hsv(0, 100%, 100%)"
        printf "%-22s %-22s %-25s %-25s\n" "000" "rgb 255 0 0" "hsla(0, 100%, 50%, .5)" "hsva(0, 100%, 100%, .5)"
        printf "%-22s %-22s %-25s %-25s\n" "#369C" "rgba (255, 0, 0, .5)" "hsl(0, 100%, 50%)" "hsv (0 100% 100%)"
        printf "%-22s %-22s %-25s %-25s\n" "369C" "" "hsl 0 1.0 0.5" "hsv 0 1 1"
        printf "%-22s %-22s %-25s %-25s\n" "#f0f0f6" "" "" ""
        printf "%-22s %-22s %-25s %-25s\n" "f0f0f6" "" "" ""
        printf "%-22s %-22s %-25s %-25s\n" "#f0f0f688" "" "" ""
        printf "%-22s %-22s %-25s %-25s\n" "f0f0f688" "" "" ""

        print_message "  Introduce el nuevo valor (vacío, deja el valor anterior):" "$COLOR_PRIMARY" "before"
        read nuevo_valor

        if [[ $nuevo_valor =~ ^#?[0-9A-Fa-f]{6}$ ]]; then
            update_config "$campo_seleccionado" "$nuevo_valor"
        fi
        ;;
    esac
}

# =================================================================================================
# ======  Mensajes
# =================================================================================================

print_message() {
    local message=${1:-""}
    local color=${2:-"$NO_COLOR"}
    local new_line_before_or_after=${3:-"normal"}
    local centered=${4:-""}

    local transformed_color=$(get_color "$color")
    local transformed_no_color=$(get_color "$NO_COLOR")
    local tabs=0
    stop_animation

    case "$color" in
    "$COLOR_PRIMARY") tabs=1 ;;
    "$COLOR_SECONDARY") tabs=2 ;;
    "$COLOR_TERNARY" | "$COLOR_SUCCESS" | "$COLOR_ERROR" | "$COLOR_WARNING") tabs=3 ;;
    "$COLOR_QUATERNARY") tabs=4 ;;
    *) tabs=0 ;;
    esac

    message="$(get_tabs $tabs)$message"

    if [ ! -z "$centered" ]; then
        message="$(pad_message "$message")"
    fi

    if [ -z "$SIMPLE_ECHO" ]; then
        message=$transformed_color$message$transformed_no_color
        case "$new_line_before_or_after" in
        "after") message="$message\n\n" ;;
        "before") message="\n$message\n" ;;
        "both") message="\n$message\n\n" ;;
        "normal") message="$message\n" ;;
        esac
    fi

    echo -ne "$message"
}

print_question() {
    # para su uso: if print_question "<mensaje>" = 0; then
    local question=${1:-""}
    local response=1

    print_message "$question" "$COLOR_WARNING" "" "centered"

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
        HELP_SCRIPT="bash -c 'trus --help $HELP_SCRIPT {}'"
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

extract_menu_option() {
    local input="$1"
    local first_value=$(echo "$input" | cut -d' ' -f1)
    if [[ "$input" == *" - "* ]]; then
        first_value=$(echo "$input" | cut -d' ' -f1)
    fi

    echo "$first_value"
}

# =================================================================================================
# ====== Especiales

print_message_with_gradient() {
    local message=$1
    local message_length=${#message}

    echo "$message" | gterm $GRADIENT_1 $GRADIENT_2 $GRADIENT_3 $GRADIENT_4 $GRADIENT_5 $GRADIENT_6
}

print_separator() {
    local message=${1:-""}
    local separator=${2:-"-"}
    local size_line=$3
    IFS=' ' read -r total_length filled_space <<<"$(message_size "$message")"

    local separator_lenght

    case "$size_line" in
    "full") separator_lenght=$filled_space ;;
    "half") separator_lenght=$((filled_space / 2)) ;;
    "quarter") separator_lenght=$((filled_space / 4)) ;;
    "") separator_lenght=$((filled_space / 8)) ;;
    esac

    print_message "$(pad_message "" "left" "-" $separator_lenght)" "" "before"
}

print_header() {
    clear
    sleep 0.11
    update_config 'GRADIENT_2' ''

    local USER_DATA="Usuario: $(echo "$(getent passwd $USER)" | cut -d ':' -f 5 | cut -d ',' -f 1) ($USER)"
    local EQUIPO="Equipo: $(hostname)"

    local empty_space="                                         "
    local logo=(""
        "  &           &&&&&&&&&           &  "
        "   &&&  &&&&&           &&&&&  &&&   $(print_separator "$empty_space" "-" "full") "
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
        "      &&&&&&&           &&&&&&       $(print_separator "$empty_space" "-" "full")"
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
        print_separator "" "-" "quarter"
    fi

    print_message "---- $message"
}

print_logo() {
    clear

    update_config 'GRADIENT_2' "$GRADIENT_2_AUX"

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

    sleep 0.5
}

print_test_animations() {
    print_message_with_animation "Esto es un mensaje de prueba con la animación seleccionada actualmente $SELECTED_ANIMATION"
    local actual_animation=$SELECTED_ANIMATIONS
    if print_question "¿Quieres visualizar todas las animaciones disponibles?" = 0; then
        print_message "Se visualizarán ${#ANIMATIONS[@]} animaciones, de una en una ya que solo puede haber una activa a la vez"
        for index in "${!ANIMATIONS[@]}"; do
            animation="${ANIMATIONS[$index]}"
            num_animations=$((index + 1))

            set_active_animation "$animation"
            print_message_with_animation "Ejemplo ${num_animations}: Esto es un mensaje de prueba con la animacion $animation" "$COLOR_SUCCESS"
            sleep 1.5
        done

        set_active_animation "$actual_animation"
    fi
}

print_test_messages() {
    print_header
    print_semiheader "Esto es un semiheader de prueba"
    print_message "Esto es un mensaje de prueba" "$NO_COLOR"
    print_message "Esto es un mensaje de prueba con espacio ANTES" "$NO_COLOR" "before"
    print_message "Esto es un mensaje de prueba con espacio DESPUES" "$NO_COLOR" "after"
    print_message "Esto es un mensaje de prueba con espacio ANTES y DESPUES" "$NO_COLOR" "both"
    print_message "Esto es un mensaje de prueba CENTRADO" "$NO_COLOR" "" "centered"
    print_message "Esto es un mensaje de prueba del color NO_COLOR" "$NO_COLOR"
    print_message "Esto es un mensaje de prueba del color COLOR_PRIMARY" "$COLOR_PRIMARY"
    print_message "Esto es un mensaje de prueba del color COLOR_SECONDARY" "$COLOR_SECONDARY"
    print_message "Esto es un mensaje de prueba del color COLOR_TERNARY" "$COLOR_TERNARY"
    print_message "Esto es un mensaje de prueba del color COLOR_QUATERNARY" "$COLOR_QUATERNARY"
    print_message "Esto es un mensaje de prueba del color COLOR_SUCCESS" "$COLOR_SUCCESS"
    print_message "Esto es un mensaje de prueba del color COLOR_WARNING" "$COLOR_WARNING"
    print_message "Esto es un mensaje de prueba del color COLOR_ERROR" "$COLOR_ERROR"
    print_message_with_gradient "Esto es un mensaje de prueba con GRADIENTE"
}

# =================================================================================================
# ====== Animaciones. Original aqui: https://github.com/Silejonu/bash_loading_animations

play_animation() {
    message=$1
    tabs=$2
    color=$3
    tput civis
    message=$(get_color "$color")$message
    start_time=$(date +%s)

    while true; do
        for frame in "${active_animation[@]}"; do
            for ((i = 1; i <= tabs; i++)); do
                frame="\t"${frame}
            done

            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            formatted_time=$(printf "%02d:%02d" $((elapsed_time / 60)) $((elapsed_time % 60))) # Formato mm:ss

            echo -ne "$frame $message ($formatted_time)\033[0K\r"
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

    local tabs=0

    case "$color" in
    "$COLOR_PRIMARY") tabs=1 ;;
    "$COLOR_SECONDARY") tabs=2 ;;
    "$COLOR_TERNARY" | "$COLOR_SUCCESS" | "$COLOR_ERROR" | "$COLOR_WARNING") tabs=3 ;;
    "$COLOR_QUATERNARY") tabs=4 ;;
    *) tabs=0 ;;
    esac

    if [ -z "$SIMPLE_ECHO" ]; then
        stop_animation
        unset "active_animation[0]"
        play_animation "$message" "$tabs" "$color" &
        animation_pid="${!}"
    else
        print_message "$message" "$color" "$tabs"
    fi
}

set_active_animation() {
    local selected=${1:-$SELECTED_ANIMATION}

    list_name="TERMINAL_ANIMATION_$selected"
    eval "active_animation=(\"\${$list_name[@]}\")"
    sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION='$selected'/" "$TRUS_CONFIG"

    update_config "SELECTED_ANIMATION" "$selected"
}

# =================================================================
# ====== Git
# =================================================================

checkout() {
    local HEADER=${1:-""}

    print_message_with_animation "Apuntando a $HEADER..." "$COLOR_TERNARY"
    exec_command "git checkout $HEADER"
    print_message "Apuntando a $HEADER (HECHO)" "$COLOR_SUCCESS"
}

update_git() {
    local change_branch=$1
    local branch=$2

    print_message_with_animation "Actualizando repositorio..." "$COLOR_SECONDARY"

    if [ $change_branch == "0" ]; then
        checkout "$branch"
    else
        exec_command "git stash"
    fi

    exec_command "git fetch"
    exec_command "git pull origin $branch"

    if [ $change_branch == "1" ]; then
        exec_command "git stash"
    fi

    print_message "Actualizando repositorio (HECHO)" "$COLOR_SUCCESS"
}

clone_if_not_exists() {
    local repo_url=$1
    local target_dir=$2
    local params=${3:-""}

    if [ ! -d "$target_dir" ]; then
        print_message "Clonando el repositorio desde '$repo_url' en '$target_dir'..." "$COLOR_SUCCESS"
        if [ ! -z "$params" ] ; then
            exec_command "git clone '$params' '$repo_url' '$target_dir'"
        else
            exec_command "git clone '$repo_url' '$target_dir'"
        fi
    else
        print_message "El directorio '$target_dir' ya existe. No se clonará el repositorio." "$COLOR_WARNING"
    fi
}

clone_truedat_project() {
    mkdir -p $TRUEDAT_ROOT_PATH
    mkdir -p $BACK_PATH
    mkdir -p $BACK_PATH/logs
    mkdir -p $FRONT_PATH

    print_:message "Quieres descargar los diferentes proectos de los repos condespondiente?"
    if print_question "¿" = 0; then
        #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
        #En linux no es necesario pero no molesta
        eval "$(ssh-agent -s)"
        ssh-add $SSH_PRIVATE_FILE

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

    fi
}

# =================================================================
# ====== Actualizaciones de repos y compilaciones
# =================================================================

update_services() {
    local create_dbb=${1:-""}
    local branch=${2:-""}

    print_semiheader "Actualizando servicios"

    set_elixir_versions

    for SERVICE in "${SERVICES[@]}"; do
        cd "$BACK_PATH/$SERVICE"

        print_message "Actualizando $SERVICE" "$COLOR_PRIMARY" "before"

        update_git "$branch" "develop"

        compile_elixir "$create_dbb"
    done

    if [ -n "$create_ddbb" ]; then
        trus -d -du
    fi
}

update_libraries() {
    local branch=${1:-""}

    print_semiheader "Actualizando librerias"

    for LIBRARY in "${LIBRARIES[@]}"; do
        print_message "Actualizando ${LIBRARY}" "$COLOR_PRIMARY" "before"

        cd "$BACK_PATH/$LIBRARY"

        update_git "$branch" "main"
        compile_elixir

        cd ..
    done

    for REPO in "${LEGACY_REPOS[@]}"; do
        print_message "Actualizando ${REPO}" "$COLOR_PRIMARY" "before"

        cd "$BACK_PATH/$REPO"

        update_git "$branch" "master"

        cd ..
    done

    for REPO in "${NON_ELIXIR_LIBRARIES[@]}"; do
        print_message "Actualizando ${REPO}" "$COLOR_PRIMARY" "before"

        cd "$BACK_PATH/$REPO"

        update_git "$branch" "main"

        cd ..
    done
}

update_web() {
    local branch=${1:-""}

    cd "$FRONT_PATH/td-web"

    print_semiheader "Actualizando frontal"

    print_message "Actualizando td-web" "$COLOR_PRIMARY" "before"

    update_git "$branch""develop"
    compile_web

    cd ..

    cd "$FRONT_PATH/td-web-modules"
    print_message "Actualizando td-web-modules" "$COLOR_PRIMARY" "before"

    update_git "$branch" "main"
    compile_web

    cd ..
}

update_repositories() {
    local create_dbb=${2:-""}
    local branch=1

    if print_question "¿Quieres apuntar los repositorios a la rama principal o dejarlos en la rama que estan? (S: rama principal; N: rama actual )" = 0; then
        branch=0
    fi

    case "$updated_option" in
    "-b" | "--back")
        update_services "$create_dbb" "$branch"
        updated_option="de back"
        ;;

    "-f" | "--front")
        update_web "$branch"
        updated_option="de front"
        ;;

    "-l" | "--libs")
        update_libraries "$branch"
        updated_option="de librerias"
        ;;

    "-a" | "--all" | "")
        update_services "$create_dbb" "$branch"
        update_libraries "$branch"
        update_web "$branch"
        updated_option="de back, librerias y front"
        ;;
    esac

    print_message "REPOSITORIOS $updated_option ACTUALIZADOS" "$COLOR_SUCCESS" "both"
}

compile_web() {
    print_message_with_animation "Compilando React..." "$COLOR_TERNARY"
    update_configuration "HIDE_OUTPUT" ""
    exec_command "yarn"
    print_message "Compilando React (HECHO)" "$COLOR_SUCCESS"
}

compile_elixir() {
    local create_ddbb=${1:-""}

    exec_command "set -o errexit"
    exec_command "set -o nounset"
    exec_command "set -o pipefail"
    exec_command "set -o xtrace"
    exec_command "export HEX_HTTP_TIMEOUT=300000"

    print_message_with_animation "mix local.hex" "$COLOR_TERNARY"
    exec_command "mix local.hex --force"
    print_message "mix local.hex (HECHO)" "$COLOR_SUCCESS"

    print_message_with_animation "mix local.rebar" "$COLOR_TERNARY"
    exec_command "mix local.rebar --force"
    print_message "mix local.rebar (HECHO)" "$COLOR_SUCCESS"

    print_message_with_animation "mix deps.get" "$COLOR_TERNARY"
    exec_command "mix deps.get"
    print_message "mix deps.get (HECHO)" "$COLOR_SUCCESS"

    print_message_with_animation "mix compile" "$COLOR_TERNARY"
    exec_command "mix compile --force"
    print_message "mix compile (HECHO)" "$COLOR_SUCCESS"

    print_message "Actualizando dependencias Elixir (HECHO)" "$COLOR_SUCCESS"

    if [ ! "$create_ddbb" = "" ]; then
        print_message_with_animation "Creando bdd..." "$COLOR_TERNARY"
        exec_command "yes | mix ecto.create"
        print_message "Creacion de bdd (HECHO)" "$COLOR_SUCCESS"
    fi
}

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
    print_message "Versiones específicas de Elixir configuradas" "$COLOR_SUCCESS" "both"
}

# =================================================================
# ====== SQL
# =================================================================

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

    if [ -d "$backup_path" ] && [ -n "$backup_path" ]; then
        if [[ "$options" == "-du" || "$options" == "--download-update" || "$options" == "-lu" || "$options" == "--local-update" ]]; then
            update_ddbb_from_backup "$backup_path"
        fi
    fi
}

recreate_local_ddbb() {
    if print_question "Esta acción BORRARÁ las bases de datos y las creará de nuevo VACÍAS" = 0; then
        start_containers
        for DATABASE in "${DATABASES[@]}"; do
            local SERVICE="${DATABASE//_/-}"

            cd $BACK_PATH/$SERVICE

            create_empty_ddbb "$DATABASE"
        done
    fi
}

download_test_backup() {
    print_semiheader "Creación y descarga de backup de test "

    local PSQL=$(kubectl get pods -l run=psql -o name | cut -d/ -f2)

    mkdir -p "$DDBB_BACKUP_PATH"

    print_message "Ruta de backup creada: $DDBB_BACKUP_PATH" "$COLOR_SECONDARY" "before"
    for DATABASE in "${DATABASES[@]}"; do
        print_message "-->  Descargando $DATABASE" "$COLOR_SECONDARY" "before"

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
            print_message_with_animation "creación de backup" "$COLOR_TERNARY"
            kubectl --context ${AWS_TEST_CONTEXT} exec ${PSQL} -- bash -c "PGPASSWORD='${PASSWORD}' pg_dump -d '${SERVICE_PODNAME}' -U '${USER}' -f '/${DATABASE}.sql' -x -O"
            print_message "Creación de backup (HECHO)" "$COLOR_SUCCESS"

            print_message_with_animation "descarga backup" "$COLOR_TERNARY"
            kubectl --context ${AWS_TEST_CONTEXT} cp "${PSQL}:/${DATABASE}.sql" "./${FILENAME}" >/dev/null 2>&1
            print_message "Descarga backup (HECHO)" "$COLOR_SUCCESS"

            print_message " backup descargado en $service_path/$FILENAME" "$COLOR_WARNING"

            print_message_with_animation "borrando fichero generado en el pod" "$COLOR_TERNARY"
            kubectl --context "${AWS_TEST_CONTEXT}" exec "${PSQL}" -- rm "/${DATABASE}.sql" >/dev/null 2>&1
            print_message "Borrando fichero generado en el pod (HECHO)" "$COLOR_SUCCESS"

            print_message_with_animation "comentado de 'create publication'" "$COLOR_TERNARY"
            sed -i 's/create publication/--create publication/g' "./${FILENAME}" >/dev/null 2>&1
            print_message "Comentado de 'create publication' (HECHO)" "$COLOR_SUCCESS"

            print_message_with_animation "moviendo fichero $FILENAME a backup" "$COLOR_TERNARY"
            mv "$FILENAME" "$DDBB_BACKUP_PATH" >/dev/null 2>&1
            print_message "Moviendo fichero $FILENAME a backup (HECHO)" "$COLOR_SUCCESS"
        else
            print_message "Creación de backup" "$COLOR_SECONDARY"
            kubectl --context ${AWS_TEST_CONTEXT} exec ${PSQL} -- bash -c "PGPASSWORD='${PASSWORD}' pg_dump -d '${SERVICE_PODNAME}' -U '${USER}' -f '/${DATABASE}.sql' -x -O"
            print_message "Creación de backup (HECHO)" "$COLOR_SUCCESS" "BOTH"

            print_message "Descarga backup" "$COLOR_SECONDARY"
            kubectl --context ${AWS_TEST_CONTEXT} cp "${PSQL}:/${DATABASE}.sql" "./${FILENAME}"
            print_message "Descarga backup (HECHO)" "$COLOR_SUCCESS"

            print_message " backup descargado en $service_path/$FILENAME" "$COLOR_WARNING"

            print_message "Borrando fichero generado en el pod" "$COLOR_SECONDARY"
            kubectl --context "${AWS_TEST_CONTEXT}" exec "${PSQL}" -- rm "/${DATABASE}.sql"
            print_message "Borrando fichero generado en el pod (HECHO)" "$COLOR_SUCCESS"

            print_message "Comentado de 'create publication'" "$COLOR_SECONDARY"
            sed -i 's/create publication/--create publication/g' "./${FILENAME}"
            print_message "Comentado de 'create publication' (HECHO)" "$COLOR_SUCCESS"

            print_message "Moviendo fichero $FILENAME a backup" "$COLOR_SECONDARY"
            mv "$FILENAME" "$DDBB_BACKUP_PATH"
            print_message "Moviendo fichero $FILENAME a backup (HECHO)" "$COLOR_SUCCESS"
        fi
    done

    print_message "Descarga de backup de test terminada" "$COLOR_SUCCESS" "both"
}

create_empty_ddbb() {
    local SERVICE_DBNAME=$1

    print_message "Creando db: $SERVICE_DBNAME" "$COLOR_PRIMARY"

    print_message_with_animation " Borrado de bdd" "$COLOR_TERNARY"
    exec_command "mix ecto.drop"
    print_message " Borrado de bdd (HECHO)" "$COLOR_SUCCESS"

    print_message_with_animation " Creacion de bdd" "$COLOR_TERNARY"
    exec_command "mix ecto.create"
    print_message " Creacion de bdd (HECHO)" "$COLOR_SUCCESS"
}

update_ddbb() {
    local FILENAME=("$@")

    for FILENAME in "${sql_files[@]}"; do
        SERVICE_DBNAME=$(basename "$FILENAME" ".sql")
        SERVICE_NAME=$(basename "$FILENAME" "_dev.sql" | sed 's/_dev//g; s/_/-/g')

        cd "$BACK_PATH"/"$SERVICE_NAME"
        print_message "-->  Actualizando $SERVICE_DBNAME" "$COLOR_SECONDARY" "before"
        create_empty_ddbb "$SERVICE_DBNAME"

        print_message_with_animation " Volcado de datos del backup de test" "$COLOR_TERNARY"
        exec_command "PGPASSWORD=postgres psql -d \"${SERVICE_DBNAME}\" -U postgres  -h localhost < \"${FILENAME}\""

        print_message " Volcado de datos del backup de test (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Aplicando migraciones" "$COLOR_TERNARY"
        exec_command "mix ecto.migrate"
        print_message " Aplicando migraciones (HECHO)" "$COLOR_SUCCESS" "after"
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
            print_message "No se encontraron archivos .sql en el directorio." "$COLOR_ERROR"
        else
            start_containers

            remove_all_redis

            update_ddbb "${sql_files[@]}"

            reindex_all
        fi
    else
        print_message "El directorio especificado no existe." "$COLOR_ERROR"
        exit 1
    fi

    print_message "actualizacion de bdd local terminada" "$color_success"
}

get_local_backup_path() {
    print_semiheader "Aplicando un backup de bdd desde una ruta de local"

    print_message "Por favor, indica la carpeta donde está el backup que deseas aplicar (debe estar dentro de '$DDBB_BASE_BACKUP_PATH')" "$COLOR_SECONDARY" "both"
    read -r path_backup

    if [[ "$path_backup" == "$DDBB_BASE_BACKUP_PATH"* ]]; then
        backup_path=$path_backup
    else
        print_message "La ruta '$path_backup' no es una subruta de '$DDBB_BASE_BACKUP_PATH'." "$COLOR_ERROR" "both"
    fi
}

create_backup_local_ddbb() {
    start_containers

    print_semiheader "Creando backup de la bdd"

    mkdir -p "$DDBB_LOCAL_BACKUP_PATH/LB_$(date +%Y%m%d_%H%M%S)"

    cd "$DDBB_LOCAL_BACKUP_PATH/LB_$(date +%Y%m%d_%H%M%S)"

    for DATABASE in "${DATABASES[@]}"; do
        FILENAME=${DATABASE}"_dev.sql"
        print_message_with_animation " Creación de backup de $DATABASE" "$COLOR_TERNARY"
        PGPASSWORD=postgres pg_dump -U postgres -h localhost "${DATABASE}_dev" >"${FILENAME}"
        print_message " Creación de backup de $DATABASE (HECHO)" "$COLOR_SUCCESS"
    done
    print_message " Backup creado en $DDBB_LOCAL_BACKUP_PATH" "$COLOR_WARNING" "both"
}

# =================================================================
# ====== NoSQL
# =================================================================

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

reind() {
    local service=$1

    cd "$BACK_PATH/td-$service"
    print_message "Reindexando servicios de td-$service" "$COLOR_PRIMARY"

    case "$service" in
    "dd")
        print_message_with_animation " Reindexando :jobs" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:jobs, :all)\""
        print_message " Reindexando :jobs (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Reindexando :structures" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:structures, :all)\""
        print_message " Reindexando :structures (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Reindexando :grants" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:grants, :all)\""
        print_message " Reindexando :grants (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Reindexando :grant_requests" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:grant_requests, :all)\""
        print_message " Reindexando :grant_requests (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Reindexando :implementations" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:implementations, :all)\""
        print_message " Reindexando :implementations (HECHO)" "$COLOR_SUCCESS"

        print_message_with_animation " Reindexando :rules" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:rules, :all)\""
        print_message " Reindexando :rules (HECHO)" "$COLOR_SUCCESS" "after"
        ;;

    "bg")
        print_message_with_animation " Reindexando :concepts" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:concepts, :all)\""
        print_message " Reindexando :concepts (HECHO)" "$COLOR_SUCCESS" "after"
        ;;

    "ie")
        print_message_with_animation " Reindexando :ingests" "$COLOR_TERNARY"
        exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:ingests, :all)\""
        print_message " Reindexando :ingests (HECHO)" "$COLOR_SUCCESS" "after"
        ;;

    "qx")
        print_message_with_animation " Reindexando :quality_controls" "$COLOR_TERNARY"

        print_message "REINDEXADO DE QX DESACTIVADO" "$COLOR_ERROR" "" "centered"
        # exec_command "mix run -e \"TdCore.Search.Indexer.reindex(:quality_controls, :all)\""

        print_message " Reindexando :quality_controls (HECHO)" "$COLOR_SUCCESS" "both"
        ;;
    esac
}

remove_all_index() {
    if print_question "¿Quieres borrar todos los datos de ElasticSearch antes de reindexar?" = 0; then
        #do_api_call "" "http://localhost:9200/_all" "DELETE" "--fail"
        do_api_call "" "" "http://localhost:9200/_all" "DELETE" "--fail"
        print_message "✳ Borrado de ElasticSearch completado ✳" "$COLOR_SUCCESS" "both"
    fi
}

remove_all_redis() {
    if print_question "¿Quieres borrar todos los datos de Redis?" = 0; then

        exec_command "redis-cli flushall "
        print_message "✳ Borrado de Redis completado ✳" "$COLOR_SUCCESS" "both"
    fi
}

# =================================================================
# ====== Llamadas API
# =================================================================

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

do_api_call() {
    local token_type="${1:-"Bearer"}"
    local token="${2:-""}"
    local url="$3"
    local rest_method="${4:-"GET"}"
    local params="${5:-""}"
    local content_type="${6:-"application/json"}"
    local extra_headers="${7:-""}"
    local output_format="${8:-""}"

    if [ -z "$url" ]; then
        echo "Error: No se ha proporcionado una URL." >&2
        return 1
    fi

    local command="curl --silent --globoff --fail "

    if [ ! -z "$token" ]; then
        command+="--header 'Authorization: $token_type ${token}' "
    fi

    if [ ! -z "$rest_method" ]; then
        command+="--request $rest_method "
        if [[ "$rest_method" == "POST" || "$rest_method" == "PUT" || "$rest_method" == "PATCH" ]]; then
            command+="--header 'Content-Type: ${content_type}' "
        fi
    fi

    if [ ! -z "$extra_headers" ]; then
        command+=" $extra_headers "
    fi

    if [ ! -z "$params" ]; then
        if [[ "$rest_method" == "POST" || "$rest_method" == "PUT" || "$rest_method" == "PATCH" ]]; then
            command+="--data '$params' "
        else
            command+="$params "
        fi
    fi

    command+="--location \"$url\""

    start_time=$(date +%s)
    response=$(eval "$command" 2>&1)
    status=$?
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))

    if [ $status -ne 0 ]; then
        echo "Error en la llamada API: $response" >&2
        return $status
    fi

    echo "Llamada API completada en $execution_time segundos"

    if [ "$output_format" == "json" ]; then
        echo "$response" | jq .
    else
        echo "$response"
    fi
}

get_token() {
    local token=$(do_api_call "" "json" "localhost:8080/api/sessions/" "POST" "--data '{\"access_method\": \"alternative_login\",\"user\": {\"user_name\": \"admin\",\"password\": \"patata\"}}'" ".token")
    echo "$token"
}

do_api_call_with_login_token() {
    local url="$1"
    local rest_method="$2"
    local params="$3"
    local content_type="$4"
    local extra_headers="$5"
    local output_format="$6"

    local token_type="bearer"
    local token=${get_token}

    do_api_call \ 
    $token_type \ 
    $token \
        $url \
        $rest_method \ 
    $params \
        $content_type \ 
    $extra_headers \
        $output_format

}

add_terminal_to_tmux_session() {
    local PANEL=$1
    local COMMAND=$2
    tmux select-pane -t truedat:0."$PANEL"
    tmux send-keys -t truedat:0."$PANEL" "${COMMAND}" C-m
}

# =================================================================
# ====== Archivos de configuración
# =================================================================

create_configurations() {
    bash_config "y"
    zsh_config
    tmux_config
    tlp_config
}

bash_config() {
    local google_fix=${1:-""}
    print_semiheader "Prompt de Bash"

    local fix=''
    local fix_message=""
    if [ ! -z "$google_fix" ]; then
        fix='export LD_PRELOAD=/lib/x86_64-linux-gnu/libnss_sss.so.2'
        fix_message="(fix login de Google incluido)"
    fi

    if ! grep -q '## Config añadida por TrUs' "$BASH_PATH_CONFIG"; then
        {
            echo ''
            echo ''
            # =================================================================================================

            echo '## Config añadida por TrUs'
            # =================================================================================================

            echo ''
            echo ''
            echo 'export COLORTERM=truecolor'
            echo '. "$HOME/.asdf/asdf.sh"'
            echo '. "$HOME/.asdf/completions/asdf.bash"'
            echo ''
            echo ''
            echo '# Aliases'
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
            echo 'alias helm="cd ~/workspace/truedat/back/td-helm"'
            echo 'alias k8s="cd ~/workspace/truedat/back/k8s"'
            echo 'alias web="cd ~/workspace/truedat/front/td-web"'
            echo 'alias webmodules="cd ~/workspace/truedat/front/td-web-modules"'
            echo 'alias trudev="cd ~/workspace/truedat/true-dev"'
            echo 'alias format="mix format && mix credo --strict"'
            echo ''
            echo ''
            echo '# Function to shorten path'
            echo 'shorten_path() {'
            echo '    full_path=$(pwd)'
            echo ''
            echo '    IFS=/ read -r -a path_parts <<< "$full_path"'
            echo ''
            echo '    if (( ${#path_parts[@]} > 3 )); then'
            echo '        echo ".../${path_parts[-3]}/${path_parts[-2]}/${path_parts[-1]}"'
            echo '    else'
            echo '        echo "$full_path"'
            echo '    fi'
            echo '}'
            echo ''
            echo '# Function to get git branch status'
            echo 'git_branch_status() {'
            echo '    branch=$(git branch --show-current 2>/dev/null)'
            echo '    if [[ -n "$branch" ]]; then'
            echo '        if git diff --quiet 2>/dev/null; then'
            echo '            echo -e "\033[97;48;5;75m($branch)"  # Green branch name'
            echo '        else'
            echo '            echo -e "\033[30;48;5;214m($branch) "  # Yellow branch name'
            echo '        fi'
            echo '    else'
            echo '        echo ""  '
            echo '    fi'
            echo '}'
            echo ''
            echo '# Function to set prompt'
            echo 'set_prompt() {'
            echo '    PS1="|\[\033[1;34m\]\t\[\033[m\]|\033[48;5;202m$(git_branch_status)\033[m|\[\033[1;38;5;202m\]$(shorten_path)\[\033[m\]> "'
            echo '}'
            echo ''
            echo '# Set the prompt when the directory changes'
            echo 'PROMPT_COMMAND=set_prompt'
            echo ' '
        } >>$BASH_PATH_CONFIG
    fi

    print_message "Prompt de Bash actualizado $fix_message" "$COLOR_SUCCESS" "after"
    print_message "Cierra la terminal y vuelvela a abrir para que surgan efecto los cambios" "$COLOR_WARNING" 
}

hosts_config() {
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
            } >> /etc/hosts'
}

zsh_config() {
    print_semiheader "ZSH"

    {
        echo ''
        echo ''
        echo 'export ZSH="$HOME/.oh-my-zsh"'
        echo '. "$HOME/.asdf/asdf.sh"'
        echo 'export COLORTERM=truecolor'
        echo 'source $ZSH/oh-my-zsh.sh'
        echo ''
        echo 'zstyle :omz:update mode auto # update automatically without asking'
        echo 'zstyle :omz:update frequency 1'
        echo 'HIST_STAMPS="dd/mm/yyyy"'
        echo ''
        echo '# configuration'
        echo 'export MANPATH="/usr/local/man:$MANPATH"'
        echo 'export LANG=en_US.UTF-8'
        echo 'EDITOR=code'
        echo 'export ARCHFLAGS="-arch $(uname -m)"'
        echo 'plugins=(git elixir asdf fzf zsh-autosuggestions zsh-syntax-highlighting zsh-completions)'
        echo '#git-prompt'
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
        echo 'alias helm="cd ~/workspace/truedat/back/td-helm"'
        echo 'alias k8s="cd ~/workspace/truedat/back/k8s"'
        echo 'alias web="cd ~/workspace/truedat/front/td-web"'
        echo 'alias webmodules="cd ~/workspace/truedat/front/td-web-modules"'
        echo 'alias trudev="cd ~/workspace/truedat/true-dev"'
        echo 'alias format="mix format && mix credo --strict"'
        echo ''
        echo ''
        echo ''
        echo 'NEWLINE=$'\''\n'\'''
        echo "SEGMENT_SEPARATOR=\$'\ue0b0'"
        echo ''
        echo 'PROMPT_BACK_COLOR=208'
        echo 'PROMPT_FONT_COLOR=0'
        echo 'PROMPT_GIT_OK=10'
        echo 'PROMPT_GIT_PENDING=11'
        echo 'KEYBOARD_GIT_OK="4E9A06FF"'
        echo 'KEYBOARD_GIT_PENDING="C4A000FF"'
        echo 'KEYBOARD_GIT_RESET="FF8700FF"'
        echo ''
        echo 'shorten_path() {'
        echo '    full_path=$(pwd)'
        echo '    '
        echo '    IFS=/ read -r -A path_parts <<< "$full_path"'
        echo ''
        echo '    if (( ${#path_parts[@]} > 3 )); then'
        echo '        echo "%B%F{$PROMPT_BACK_COLOR}┌ %K{$PROMPT_BACK_COLOR}%F{$PROMPT_FONT_COLOR}.../${path_parts[-3]}/${path_parts[-2]}/${path_parts[-1]} %k%f%F{$PROMPT_BACK_COLOR}$SEGMENT_SEPARATOR%k%f"'
        echo '    else'
        echo '        echo "%B%F{$PROMPT_BACK_COLOR}┌ %K{$PROMPT_BACK_COLOR}%F{$PROMPT_FONT_COLOR}$full_path %k%f%F{$PROMPT_BACK_COLOR}$SEGMENT_SEPARATOR%k%f"'
        echo '    fi'
        echo '}'
        echo ''
        echo 'git_branch_status() {'
        echo '    branch=$(git branch --show-current 2>/dev/null)'
        echo '    if [[ -n "$branch" ]]; then'
        echo '        if git diff --quiet 2>/dev/null; then'
        echo '            print "${NEWLINE}%B%F{$PROMPT_BACK_COLOR}├ %K{$PROMPT_GIT_OK}%F{$PROMPT_FONT_COLOR}($branch) %k%f%F{$PROMPT_GIT_OK}$SEGMENT_SEPARATOR%k%f"'
        echo '            echo "rgb $KEYBOARD_GIT_OK" > /tmp/ckbpipe000  '
        echo '        else'
        echo '            print "${NEWLINE}%B%F{$PROMPT_BACK_COLOR}├ %K{$PROMPT_GIT_PENDING}%F{$PROMPT_FONT_COLOR}($branch) ± %k%f%F{$PROMPT_GIT_PENDING}$SEGMENT_SEPARATOR%k%f" '
        echo '            echo "rgb $KEYBOARD_GIT_PENDING" > /tmp/ckbpipe000'
        echo '        fi'
        echo '    else'
        echo '        echo ""  '
        echo '        echo "rgb $KEYBOARD_GIT_RESET" > /tmp/ckbpipe000'
        echo '    fi'
        echo '}'
        echo ''
        echo 'prompt_last_segment() {'
        echo '    echo "%f${NEWLINE}%B%F{$PROMPT_BACK_COLOR}└> %f%k"'
        echo '}'
        echo ''
        echo 'local -A schars'
        echo 'autoload -Uz prompt_special_chars'
        echo 'prompt_special_chars'
        echo ''
        echo 'PROMPT="${NEWLINE}$(shorten_path) $(git_branch_status) $(prompt_last_segment)"   '
        echo ''
        echo 'chpwd() {'
        echo '    PROMPT="${NEWLINE}$(shorten_path) $(git_branch_status) $(prompt_last_segment)"   '
        echo '}'

    } >$ZSH_PATH_CONFIG

    print_message "Archivo de configuración creado con éxito." "$COLOR_SUCCESS" "after"
    print_message "Cierra la terminal y vuelvela a abrir para que surgan efecto los cambios" "$COLOR_PRIMARY" "after"
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

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" "after"
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

    print_message "Archivo de configuración creado con éxito" "$COLOR_SUCCESS" "after"

    print_message_with_animation "Lanzando TLP para hacer efectiva la nueva configuración" "$COLOR_SUCCESS"
    exec_command "sudo tlp start"
    exec_command "sudo systemctl enable tlp.service"
    print_message "TLP lanzado con éxito" "$COLOR_SUCCESS" "after"
}

update_config() {
    local option=$1
    local value=$2
    sed -i "s/^$option=.*/$option='$value'/" "$TRUS_CONFIG"
    source $TRUS_CONFIG
}

aws_configure() {    
    if [ ! -e "$AWSCONFIG" ]; then    
        aws ecr get-login-password --profile truedat --region eu-west-1 | docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com

        if [ ! -f "$AWS_CREDENTIALS_PATH" ] || ! grep -q "\[default\]" "$AWS_CREDENTIALS_PATH"; then
            print_message "ATENCIÓN, SE VA A SOLICITAR LOS DATOS DE ACCESO A AWS" "$COLOR_WARNING" "before"
            print_message "perfil: 'default'"
            print_message "Estos datos te los debe dar tu responsable" "$COLOR_WARNING" "both"
            aws configure
        fi

        if [ ! -f "$AWS_CREDENTIALS_PATH" ] || ! grep -q "\[truedat\]" "$AWS_CREDENTIALS_PATH"; then
            print_message "ATENCIÓN, SE VA A SOLICITAR LOS DATOS DE ACCESO A AWS" "$COLOR_WARNING" "before"
            print_message "perfil: 'truedat'"
            print_message "Estos datos te los debe dar tu responsable" "$COLOR_WARNING" "both"
            aws configure --profile truedat
        fi
    fi
}

# =================================================================
# ====== Instalación
# =================================================================

install_trus() {
    mkdir -p "$TRUS_BASE_PATH"
    rm -f "$TRUS_BASE_PATH"/*
    cp -r "$PWD"/* "$TRUS_BASE_PATH"

    sudo rm -f $TRUS_LINK_PATH && sudo ln -s $TRUS_PATH $TRUS_LINK_PATH

    source $TRUS_CONFIG

    print_message "Truedat Utils (TrUs) instalado con éxito" "$COLOR_SUCCESS"
}

preinstallation() {
    print_header
    print_semiheader "Preparando el entorno de Truedat/TrUs"

    if [ ! -e "/tmp/trus_install" ] || ([ -e "/tmp/trus_install" ] && print_question "Se ha detectado que ya se ha realizado la preinstalación con anterioridad" == 0); then
        print_message "Arquitectura detectada: $ARCHITECTURE" "$COLOR_PRIMARY" "both"
        print_message "Se va a proceder a realizar las siguientes tareas:" "$COLOR_PRIMARY"
        print_message " - Actualizar el sistema" "$COLOR_SECONDARY"
        print_message " - Instalación de paquetes:" "$COLOR_SECONDARY"
        for package in "${APT_INSTALLATION_PACKAGES[@]}"; do
            print_message " > $package" "$COLOR_TERNARY"
        done

        print_message " - Instalación de FZF" "$COLOR_SECONDARY" "before"
        print_message " - Configuracion de info de usuario de GIT:" "$COLOR_SECONDARY"
        print_message " - Instalación de AWSCLI" "$COLOR_SECONDARY"
        print_message " - Instalación de KUBECTL" "$COLOR_SECONDARY"
        print_message " - Instalación de ZSH, OhMyZSH y plugins" "$COLOR_SECONDARY"
        print_message " - Instalación de ASDF y plugins" "$COLOR_SECONDARY" "after"

        print_message "En el paso de la instalacion donde se ofrece instalar zsh y oh my zsh, si se decide instalarlo, cuando esté disponible ZSH, escribir "exit" para salir de dicho terminal y terminar con la instalación" "$COLOR_PRIMARY"
        print_message "ya que la instalación se ha lanzado desde bash y en ese contexto, zsh es un proceso lanzado mas y se queda esperando hasta terminar (con el exit), no la terminal por defecto." "$COLOR_PRIMARY" "after"

        print_semiheader "Actualizando sistema"
        print_message_with_animation "Actualizando..." "$COLOR_TERNARY"
        exec_command "sudo apt -qq update"
        exec_command "sudo apt -qq upgrade -y"
        print_message "Sistema actualizado" "$COLOR_SUCCESS" "" "after"

        print_semiheader "Instalación paquetes de software"

        for package in "${APT_INSTALLATION_PACKAGES[@]}"; do
            print_message_with_animation "Instalando $package" "$COLOR_TERNARY"
            exec_command "sudo apt -qq install -y --install-recommends $package"
            print_message "$package instalado" "$COLOR_SUCCESS"
        done

        if [ -e "~/.fzf" ]; then
            rm -fr ~/.fzf
            clone_if_not_exists "https://github.com/junegunn/fzf.git" "~/.fzf"
            exec_command "~/.fzf/install"
        fi
        
        print_message "--- (GIT) Se ha configurado GIT con los siguientes datos" "$COLOR_PRIMARY" "before"
        print_message "        - Nombre: $GIT_USER_NAME" "$COLOR_SECONDARY"
        print_message "        - Email: $GIT_USER_NAME" "$COLOR_SECONDARY"
        print_message "        Si deseas modificarlo, utiliza los siguientes comandos en la terminal:" "$COLOR_PRIMARY" "before"
        print_message "        - Nombre: git config --global user.name "\<user_name\>"'" "$COLOR_SECONDARY"
        print_message "        - Email: git config --global user.email "\<user_email\>"'" "$COLOR_SECONDARY"

        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"

        install_awscli
        install_kubectl
        install_zsh
        install_asdf

        touch "/tmp/trus_install"
    fi
}

install_truedat() {
    print_semiheader "Intalación de Truedat"
    
    if [ ! -e "/tmp/truedat_installation" ]; then
        if [ -f "$SSH_PUBLIC_FILE" ]; then
            print_message "Guia de instalación: https://confluence.bluetab.net/pages/viewpage.action?pageId=136022683" "$COLOR_QUATERNARY" 5 "both"

            print_message "IMPORTANTE: Para poder seguir con la instalación de Truedat, debes crear las claves SSH con 'trus -cs' y tambien tenerlas registrarlas en Gitlab y Githab" "$COLOR_WARNING" "before"
            print_message "De lo contrario, no se descargarán los proyectos y dará error" "$COLOR_WARNING" "after"

            print_message "Se va a proceder a realizar las siguientes tareas:" "$COLOR_PRIMARY"
            print_message " - Configurar AWS los perfiles 'default' y 'truedat'" "$COLOR_SECONDARY"
            print_message " - Instalación de contenedores" "$COLOR_SECONDARY"
            print_message " - Añadido a fichero de hosts info de Truedat" "$COLOR_SECONDARY"
            print_message " - Creación de estructuras de proyecto y descarga de código" "$COLOR_SECONDARY"
            print_message " - Configuración de elastic 'max_map_count'" "$COLOR_SECONDARY"
            print_message " - Linkado de paquetes del los proyectos de  front" "$COLOR_SECONDARY"
            print_message " - Descarga de último backup de bdd de TEST y aplicado a las bdd locales" "$COLOR_SECONDARY"
            print_message " - Configuración de Kong" "$COLOR_SECONDARY"
        
            if print_question "A continuación se va a proceder a realizar la preinstalación" = 1; then exit 0 ; fi

            aws_configure

            install_containers
            clone_truedat_project

            cd $DEV_PATH
            sudo sysctl -w vm.max_map_count=262144
            sudo cp elastic-search/999-map-count.conf /etc/sysctl.d/

            hosts_config
            update_repositories "-a" "yes"
            link_web_modules
            ddbb "-du"
            config_kong
            touch "/tmp/truedat_installation"
            print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" "both"
        else
            print_message "- Claves SSH (NO CREADAS): Tienes que tener creada una clave SSH (el script chequea que la clave se llame 'truedat') en la carpeta ~/.ssh" "$COLOR_ERROR" "before"
            print_message "RECUERDA que tiene que estar registrada en el equipo y en Gitlab. Si no, debes crearla con 'trus -cr' y registarla en la web'" "$COLOR_WARNING" "after"
        fi
        
    else
        print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" "both"

        if print_question "Es posible realizar de nuevo la preinstalación" = 0; then
            rm "/tmp/truedat_installation"
            print_message "Archivo '/tmp/truedat_installation' eliminado correctamente" "$COLOR_PRIMARY" "both"
        fi
    fi
}

install_containers() {
    if [ ! -e "/usr/local/bin/docker-compose" ]; then
        cd $DEV_PATH

        print_message "Instalando Docker Compose y los contenedores de Truedat" "$COLOR_PRIMARY"

        ip=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        echo SERVICES_HOST="$ip" >local_ip.env

        if [ ! -f /usr/local/bin/docker-compose ]; then
            exec_command "sudo curl -L 'https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose"
        fi
        
        exec_command "sudo chmod +x /usr/local/bin/docker-compose"

        if ! getent group docker >/dev/null 2>&1; then
            exec_command "sudo groupadd docker"
        fi

        if ! groups $USER | grep -q "\bdocker\b"; then
            exec_command "sudo usermod -aG docker $USER"
        fi

        exec_command "sudo chmod 666 /var/run/docker.sock"

        print_message "Docker Compose instalado y configurado" "$COLOR_SUCCESS"        

        start_containers
    fi
}

install_asdf() {
    if [ -e "$ASDF_ROOT_PATH" ]; then
        rm -fr $ASDF_ROOT_PATH
    fi

    print_semiheader "Instalacion y configuración de ASDF y los plugins de Erlang, Elixir, NodeJS y Yarn"

    print_message_with_animation "Instalando ASDF" "$COLOR_TERNARY"
    exec_command "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1"
    print_message "ASDF Instalado" "$COLOR_SUCCESS"


    print_message_with_animation "Instalando plugins de ASDF" "$COLOR_TERNARY"
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf plugin-add yarn
    print_message "Plugins de ASDF instalados" "$COLOR_SUCCESS"


    print_message_with_animation "Descargando versiones de Erlang, Elixir, NodeJS y Yarn" "$COLOR_TERNARY"
    KERL_BUILD_DOCS=yes asdf install erlang 25.3
    asdf install elixir 1.13.4
    asdf install elixir 1.14.5-otp-25
    asdf install elixir 1.15
    asdf install elixir 1.16
    asdf install nodejs 18.20.3
    asdf install yarn latest
    print_message "Versiones instaladas" "$COLOR_SUCCESS"


    print_message_with_animation "Seteando versiones por defecto" "$COLOR_TERNARY"
    asdf global erlang 25.3
    asdf global elixir 1.14.5-otp-25
    asdf global nodejs 18.20.3
    asdf global yarn latest
    print_message "Versiones seteadas" "$COLOR_SUCCESS"


    print_message_with_animation "Instalando Gradient Terminal y dependencias" "$COLOR_TERNARY"
    # Meto esto aqui porque aunque no es de ASDF, depende de que ASDF instale NodeJs
    # https://github.com/aurora-0025/gradient-terminal?tab=readme-ov-file
    npm install -g gradient-terminal
    npm install -g tinygradient
    npm install -g ansi-regex
    print_message "Gradient Terminal instalado" "$COLOR_SUCCESS"
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
        print_message_with_animation "Instalando Kubectl" "$COLOR_TERNARY"

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

        print_message "Kubectl instalado y configurado" "$COLOR_SUCCESS"
    fi

    print_message "Paquetes y dependencias instalado correctamente" "$COLOR_SUCCESS" "both"
}

install_zsh() {
    print_semiheader "Instalación de ZSH"

    print_message_with_animation "Instalando $package" "$COLOR_TERNARY"
    exec_command "sudo apt install -y --install-recommends zsh"
    print_message "$package instalado" "$COLOR_SUCCESS"

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

    print_message "Oh-My-ZSH Instalado correctamente. ZSH y Oh-My-ZSH estará disponible en el próximo inicio de sesión" "$COLOR_SUCCESS" "both"
}

# =================================================================================================
# ====== Kong
# =================================================================================================

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
        print_message "Kong no está habilitado" "$COLOR_WARNING"
        print_message "Si se desea habilitar, utiliza 'trus --config_kong'" "$COLOR_WARNING"
    else
        cd $KONG_PATH
        set -o pipefail

        for SERVICE in ${KONG_SERVICES[@]}; do
            local PORT=$(get_service_port "$SERVICE")
            #local SERVICE_ID=$(do_api_call "${KONG_ADMIN_URL}/services/${SERVICE}" | jq -r '.id // empty')
            local SERVICE_ID=$(do_api_call "" "json" "${KONG_ADMIN_URL}/services/${SERVICE}" "GET" "" ".id // empty")
            local DATA='{ "name": "'${SERVICE}'", "host": "'${DOCKER_LOCALHOST}'", "port": '$PORT' }'

            print_message_with_animation "Creando rutas para el servicio: $SERVICE (puerto: $PORT)" "$COLOR_TERNARY"

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

            print_message "Rutas servicio: $SERVICE (puerto: $PORT) creadas con éxito" "$COLOR_SUCCESS"
        done

        #exec_command "do_api_call '${KONG_ADMIN_URL}/services/health/plugins' "POST" "--data 'name=request-termination' --data 'config.status_code=200' --data 'config.message=Kong is alive'"  | jq -r '.id'"
        exec_command "do_api_call '' 'json' '${KONG_ADMIN_URL}/services/health/plugins' 'POST' '--data 'name=request-termination' --data 'config.status_code=200' --data 'config.message=Kong is alive'' '.id'"

        print_message "Creacion de rutas finalizada" "$COLOR_SUCCESS" "both"

    fi
}

activate_kong() {
    print_semiheader "Habilitación de Kong"
    print_message "A continuación, se van a explicar los pasos que se van a seguir si sigues con este proceso" "$COLOR_PRIMARY" "before"
    print_message "Se va a actualizar el archivo de configuracion para reflejar que se debe utilizar Kong a partir de ahora" "$COLOR_SECONDARY"
    print_message "Se va a descargar el repo de Kong en $BACK_PATH" "$COLOR_SECONDARY"
    print_message "Se van a descargar los siguientes contenedores: ${CONTAINERS_SETUP[@]}" "$COLOR_SECONDARY"

    for container in "${CONTAINERS_SETUP[@]}"; do
        print_message "${container[@]}" "$COLOR_TERNARY"
    done

    print_message "Se va a actualizar el archivo $TD_WEB_DEV_CONFIG para que apunte a Kong" "$COLOR_SECONDARY"
    print_message "Se van a actualizar las rutas de Kong" "$COLOR_SECONDARY"

    if print_question "Se va a activar Kong" = 0; then
        sed -i 's/USE_KONG=false/USE_KONG=true/' "$TRUS_CONFIG"

        source $TRUS_CONFIG

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
        print_message "NO SE HAN REALIZADO MODIFICACIONES" "$COLOR_SUCCESS"
    fi
}

deactivate_kong() {
    print_semiheader "Deshabilitación de Kong"
    print_message "A continuación, se van a explicar los pasos que se van a seguir si sigues con este proceso" "$COLOR_PRIMARY" "before"
    print_message "Se va a actualizar el archivo de configuracion para reflejar que se debe utilizar Kong a partir de ahora" "$COLOR_SECONDARY"
    print_message "Se va a borrar el proyecto de kong, que se encuentra en $BACK_PATH/kong-setup" "$COLOR_SECONDARY"
    print_message "Se va a eliminar los siguientes contenedores" "$COLOR_SECONDARY"

    for container in "${CONTAINERS_SETUP[@]}"; do
        print_message "${container[@]}" "$COLOR_TERNARY"
    done

    print_message "Se va a actualizar el archivo $TD_WEB_DEV_CONFIG para que se encargue de enrutar td-web" "$COLOR_SECONDARY"

    if print_question "Se va a desactivar Kong" = 0; then
        sed -i 's/USE_KONG=true/USE_KONG=false/' "$TRUS_CONFIG"
        source $TRUS_CONFIG

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
        print_message "NO SE HAN REALIZADO MODIFICACIONES" "$COLOR_SUCCESS" "" "centered"
    fi
}

config_kong() {

    print_semiheader "Kong"
    print_message "¿Quién quieres que enrute, Kong(k) o td-web(w)? (k/w)" "$COLOR_PRIMARY"
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
###### Arranque y apagado
###################################################################################################

start_containers() {
    print_semiheader "Contenedores Docker"

    cd $DEV_PATH

    print_message "Arrancando contenedores" "$COLOR_SECONDARY"

    for container in "${CONTAINERS[@]}"; do
        print_message "container" "$COLOR_SECONDARY"

        exec_command "docker-compose up -d '${container}'"
    done

    if "$USE_KONG" = true; then
        exec_command "docker-compose up -d kong"
    fi
}

stop_docker() {
    print_semiheader "Apagando contenedores..."
    cd "$DEV_PATH"

    for container in "${CONTAINERS[@]}"; do
        exec_command "docker stop '${container}'"
    done

    if "$USE_KONG" = true; then
        exec_command "docker stop 'kong'"
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

    print_message "Servicios arrancados:" "$COLOR_PRIMARY"
    screen -ls | awk '/\.td-/ {print $1}' | sed 's/\.\(td-[[:alnum:]]*\)/ => \1/'
}

start_front() {
    cd "$FRONT_PATH"/td-web
    yarn start
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
    add_terminal_to_tmux_session "$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') + 1))" "trus --help"
    tmux select-pane -t truedat:0."$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') - 1))"

    go_to_session $TRUEDAT
}

kill_truedat() {
    print_semiheader "Matando procesos 'mix' (elixir)"
    pkill -9 -f mix

    print_semiheader "Matando sesiones Screen"
    for session in $(screen -ls | awk '/\t/ {print $1}'); do
        screen -S "$TMUX_SESION" -X quit
    done

    screen -wipe

    print_semiheader "Matando sesiones TMUX"
    tmux kill-session -t "$TMUX_SESION"

    print_semiheader "Matando front"
    pkill -9 -f yarn
}

go_to_session() {
    local session_name=$1

    clear

    tmux attach-session -t "$session_name"
}

go_out_session() {
    tmux detach-client
}

# =================================================================================================
# ====== Otras operaciones importantes
# =================================================================================================

help() {
    local option=${1:-""}
    local suboption=${2:-""}

    case "$option" in
        "main_menu_help") echo "main_menu_help LANZADA" ;;
        "configure_menu_help") echo "configure_menu_help LANZADA" ;;
        "configuration_files_menu_help") echo "configuration_files_menu_help LANZADA" ;;
        "animation_menu_help") echo "animation_menu_help LANZADA" ;;
        "principal_actions_menu_help") echo "principal_actions_menu_help LANZADA" ;;
        "start_menu_help") echo "start_menu_help LANZADA" ;;
        "secondary_actions_menu_help") echo "secondary_actions_menu_help LANZADA" ;;
        "ddbb_menu_help") echo "ddbb_menu_help LANZADA" ;;
        "repo_menu_help") echo "repo_menu_help LANZADA" ;;
        "kong_menu_help") echo "kong_menu_help LANZADA" ;;
        "0 - Volver") print_message "Volver al menú anterior" "$COLOR_PRIMARY" ;;
        "0 - Salir") print_message "Salir de TrUs" "$COLOR_PRIMARY" ;;
    *) echo "TODO" ;;
    esac
}

animation_menu_help() {
    local animation=$1
    local frames_var="TERMINAL_ANIMATION_${animation}"
    local frame_delay=0.1

    eval "local frames=(\"\${${frames_var}[@]}\")"

    for frame in "${frames[@]}"; do
        echo "$frame"
    done
}

# =================================================================================================
# ====== Otras operaciones importantes
# =================================================================================================

create_ssh() {
    local continue_ssh_normalized

    if print_question "SE VA A PROCEDER HACER BACKUP DE LAS CLAVES SSH 'truedat' ACTUALES, BORRAR LA CLAVE EXISTENTE Y CREAR UNA NUEVA HOMÓNIMA" "$COLOR_ERROR" = 0; then
        cd $SSH_PATH

        if [ -f "$SSH_PUBLIC_FILE" ] || [ -f "$SSH_PRIVATE_FILE" ]; then
            print_message "Haciendo backup del contenido de ~/.ssh..." "$COLOR_SECONDARY"
            mkdir -p "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
            print_message "Carpeta creada: $SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)" "$COLOR_SUCCESS"

            if [ -f "$SSH_PUBLIC_FILE" ]; then
                mv "$SSH_PUBLIC_FILE" "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
                print_message "Guardado archivo: $SSH_PUBLIC_FILE" "$COLOR_TERNARY"
            fi

            if [ -f "$SSH_PRIVATE_FILE" ]; then
                mv "$SSH_PRIVATE_FILE" "$SSH_PATH/backup_$(date +%Y%m%d_%H%M%S)"
                print_message "Guardado archivo: $SSH_PRIVATE_FILE" "$COLOR_TERNARY"
            fi
        fi

        exec_command "yes | ssh-keygen -t ed25519 -f $SSH_PRIVATE_FILE -q -N \"\""
        print_message "Clave creada correctamente" "$COLOR_SUCCESS" "before"

        #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
        #En linux no es necesario pero no molesta
        eval "$(ssh-agent -s)"
        ssh_add_result=$(ssh-add $SSH_PRIVATE_FILE 2>&1)

        if [[ "$ssh_add_result" == *"Identity added"* ]]; then
            print_message "Clave registrada correctamente" "$COLOR_SUCCESS" "both"
            print_message "Por favor, registra la siguiente clave en gitlab: $(cat $SSH_PUBLIC_FILE)" "$COLOR_PRIMARY" "after"
        else
            print_message "Hubo un problema al registrar la clave: $ssh_add_result" "$COLOR_ERROR" "" "centered"
        fi
    fi
}

informe_pidi() {
    print_header
    print_semiheader "Generación de informe PiDi"
    print_message "IMPORTANTE Formato de fecha a introducir: YYYY-MM-DD" "$COLOR_WARNING" "both"

    while true; do
        print_message "Por favor, introduce una fecha de inicio (por defecto: 2020-01-01)"
        read informe_desde

        if validar_fecha "$informe_desde"; then
            break
        else
            print_message "La fecha introducida no es válida. Inténtalo de nuevo." "$COLOR_ERROR"
        fi
    done

    while true; do
        print_message "Por favor, introduce una fecha de fin (por defecto: 2032-12-31)"
        read informe_hasta

        if validar_fecha "$informe_hasta"; then
            break
        else
            print_message "La fecha introducida no es válida. Inténtalo de nuevo." "$COLOR_ERROR"
        fi
    done

    generar_informe_pidi "$informe_desde" "$informe_hasta"

    print_message "Informe generado con éxito" "$COLOR_SUCCESS"
    print_message "Archivo generado: $PIDI_FILE" "$COLOR_QUATERNARY"
}

generar_informe_pidi() {
    local desde=${1:-"2020-01-01"}
    local hasta=${2:-"2032-12-31"}
    local autor="$(git config --global user.email)"

    if [ ! -e "$PIDI_PATH" ]; then
        mkdir -p $PIDI_PATH
    fi

    touch "$PIDI_FILE"
    local header="commit;author;commit line 1;commit line 2;commit line 3;commit line 4;commit line 5;"

    for SERVICE in "${SERVICES[@]}"; do
        {
            echo ""
            echo "Commits de $SERVICE"
            echo ""
        } >>"$PIDI_FILE"

        cd "$BACK_PATH/$SERVICE"
        echo "$header" >>"$PIDI_FILE"

        git log --all --pretty=format:"%h - %an <%ae> - %s" \
            --since="$desde" \
            --until="$hasta" \
            --regexp-ignore-case |
            grep -i "$autor" |
            sed 's/ - /;/g' \
                >>"$PIDI_FILE"
    done

    for LIBRARY in "${LIBRARIES[@]}"; do
        {
            echo ""
            echo "Commits de $LIBRARY"
            echo ""
        } >>"$PIDI_FILE"

        cd "$BACK_PATH/$LIBRARY"
        echo "$header" >>"$PIDI_FILE"

        git log --all --pretty=format:"%h - %an <%ae> - %s" \
            --regexp-ignore-case |
            grep -i "$autor" |
            sed 's/ - /;/g' \
                >>"$PIDI_FILE"
    done

    {
        echo ""
        echo "Commits de td-web"
        echo ""
    } >>"$PIDI_FILE"

    cd "$FRONT_PATH/td-web"

    echo "$header" >>"$PIDI_FILE"

    git log --all --pretty=format:"%h - %an <%ae> - %s" \
        --regexp-ignore-case |
        grep -i "$autor" |
        sed 's/ - /;/g' \
            >>"$PIDI_FILE"

    {
        echo ""
        echo "Commits de td-web-modules"
        echo ""
    } >>"$PIDI_FILE"

    cd "$FRONT_PATH/td-web-modules"

    echo "$header" >>"$PIDI_FILE"

    git log --all --pretty=format:"%h - %an <%ae> - %s" \
        --regexp-ignore-case |
        grep -i "$autor" |
        sed 's/ - /;/g' \
            >>"$PIDI_FILE"

}

# =================================================================================================
# ====== Menus principales
# =================================================================================================

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
        install_truedat
        ;;

    2)
        install_zsh
        ;;

    3)
        configuration_files_menu
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
        config_colours_menu
        ;;

    0)
        main_menu
        ;;
    esac
}

configuration_files_menu() {
    local option=$(print_menu "configuration_files_menu_help" "${CONFIGURATION_FILES_MENU_OPTIONS[@]}")

    option=$(extract_menu_option "$option")

    case "$option" in
    1)
        zsh_config
        ;;

    2)
        bash_config
        ;;

    3)
        bash_config "y"
        ;;

    4)
        tmux_config
        ;;

    5)
        tlp_config
        ;;

    6)
        hosts_config
        ;;

    7)
        zsh_config
        bash_config "y"
        tmux_config
        tlp_config
        hosts_config
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
    1)
        print_test_animations

        if print_question "¿Quieres volver al menu de configuración de animaciones?" = 0; then
            print_header
            animation_menu
        fi

        ;;
    *)
        sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION=$option/" "$TRUS_CONFIG"
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

    10)
        informe_pidi
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
        update_ddbb_from_backup "$option"
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
                print_message_with_animation "Borrando backup -> $FILENAME" "$COLOR_TERNARY"
                rm -fr $FILENAME
                print_message "Backup $FILENAME Borrado" "$COLOR_SUCCESS"

            done

            print_message "Backups borrados" "$COLOR_SUCCESS" "both" "" "centered"
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
        trus -d -lb
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

# =================================================================================================
# ====== Ayudas
# =================================================================================================

main_menu_help() {
    local option=$1

    case "$option" in
    1)
        print_message "Configurar" "$COLOR_PRIMARY"
        print_message "Aqui se puede instalar los paquetes necesarios para truedat, generar diferentes archivos de configuracón, personalizar TrUs y el equipo, etc" "$COLOR_SECONDARY"
        ;;
    2)
        print_message "Acciones principales" "$COLOR_PRIMARY"
        print_message "Aqui se realizan las acciones importantes: Arrancar y matar Truedat, actualizar repos, bajar backups de bdd, etc" "$COLOR_SECONDARY"
        ;;
    3)
        print_message "Actiones secundarias" "$COLOR_PRIMARY"
        print_message "Aqui se realizan otras acciones, no tan importantes, pero necesarias: Reindexar Elastic, Crear claves ssh, configurar el uso de Kong en el equipo, linkar paquetes web, etc" "$COLOR_SECONDARY"
        ;;
    4)
        print_message "Ayuda" "$COLOR_PRIMARY"
        print_message "Aqui se muestra toda la ayuda de todas las opciones disponibles en Trus (incluidos parámetros para realizar acciones desde script)" "$COLOR_SECONDARY"
        ;;
    *)

        print_semiheader "Opciones Menú Principal"
        print_message "Configurar" "$COLOR_PRIMARY"
        --print_message "Aqui se puede instalar los paquetes necesarios para truedat, generar diferentes archivos de configuracón, personalizar TrUs y el equipo, etc" "$COLOR_SECONDARY"

        print_message "Acciones principales" "$COLOR_PRIMARY"
        print_message "Aqui se realizan las acciones importantes: Arrancar y matar Truedat, actualizar repos, bajar backups de bdd, etc" "$COLOR_SECONDARY"

        print_message "Actiones secundarias" "$COLOR_PRIMARY"
        print_message "Aqui se realizan otras acciones, no tan importantes, pero necesarias: Reindexar Elastic, Crear claves ssh, configurar el uso de Kong en el equipo, linkar paquetes web, etc" "$COLOR_SECONDARY"

        print_message "Ayuda" "$COLOR_PRIMARY"
        print_message "Aqui se muestra toda la ayuda de todas las opciones disponibles en Trus (incluidos parámetros para realizar acciones desde script)" "$COLOR_SECONDARY"
        ;;

    esac
}

# =================================================================================================
# ====== Enrutador de parámetros
# =================================================================================================

param_router() {
    local param1=$1
    local param2=$2
    local param3=$3
    local param4=$4
    local param5=$5

    if [ -z "$param1" ]; then
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

        "--stop-containers")
            stop_docker
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

        "--help")
            help "$param2" "$param3"
            ;;

        "*")
            help
            ;;
        esac
    fi
}

# =================================================================================================
# ====== Lógica inicial
# =================================================================================================

TRUS_ACTUAL_PATH=$(realpath "$0")

if [[ "$0" != "/usr/local/bin/trus" ]]; then
    install_trus
    preinstallation
elif [ "$1" = "--help" ]; then
    if [[ -f "$TRUS_CONFIG" ]]; then

        source $TRUS_CONFIG
    else
        echo "Error: Archivos de configuración no encontrados."
        exit 1
    fi
    help "$2" "$3" "$4"
else
    if [[ -f "$TRUS_CONFIG" ]]; then
        source $TRUS_CONFIG
    else
        echo "Error: Archivos de configuración no encontrados."
        exit 1
    fi

    set_terminal_config
    param_router $1 $2 $3 $4 $5
fi

# # print_message "tareas por completar" "$color_primary" "both"
# # print_message "bugs" "$color_primary"
# # print_message "- revisar error de 'ruta/*' sale en algunas ocasiones al actualizar la bdd" "$color_secondary"
# # print_message "- revisar error del linkado de paquetes de yarn que no va" "$color_secondary"
# # print_message "- revisar error cuando se pregunta por  algo de s/n que antes pinta un error de get_color" "$color_secondary"

# # print_message "cosas que antes habia y ahora no" "$color_primary"
# # print_message "- hacer los helps" "$color_secondary"
# # print_message "- configurar animacion" "$color_secondary"
# # print_message "- funciones de ayuda" "$color_secondary"

# # print_message "cosas nuevas" "$color_primary"
# # print_message "- informe pidi (script victor)" "$color_secondary"
# # print_message "- multi yarn test" "$color_secondary"
# # print_message "- configurar colores de trus" "$color_secondary"
# # print_message "- añadir submenu al reindexado de elastic, para seleccionar qué indices se quiere reindexar" "$color_secondary"
# # print_message "- añadir submenu al arranque de todo/servicios de truedat, para seleccionar qué servicios se quiere arrancar" "$color_secondary"
# # print_message "- añadir submenu a la actualizacion de repos para seleccionar qué actualizar" "$color_secondary"
# # print_message "- añadir submenu a la descarga de bdd de test para seleccionar qué actualizar" "$color_secondary" "after"
# # print_message
