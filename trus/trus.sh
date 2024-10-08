#!/bin/bash

USER_HOME=$(eval echo ~"$SUDO_USER")
TRUS_BASE_PATH=$USER_HOME/.trus
TRUS_DEFAULT_CONFIG="$TRUS_BASE_PATH/trus.default.config"
TRUS_CONFIG="$USER_HOME/trus.config"

LINK_BASE_PATH=/usr/local/bin

TRUS_CONFIGURATIONS_PATH=$TRUS_BASE_PATH/trus_configurations.sh 
TRUS_DDBB_PATH=$TRUS_BASE_PATH/trus_ddbb.sh 
TRUS_INSTALLATION_PATH=$TRUS_BASE_PATH/trus_installation.sh 
TRUS_KONG_PATH=$TRUS_BASE_PATH/trus_kong.sh 
TRUS_MESSAGES_PATH=$TRUS_BASE_PATH/trus_messages.sh 
TRUS_TOOLS_PATH=$TRUS_BASE_PATH/trus_tools.sh 
TRUS_PATH=$TRUS_BASE_PATH/trus.sh

TRUS_LINK_CONFIGURATIONS_PATH=$LINK_BASE_PATH/trus_configurations
TRUS_LINK_DDBB_PATH=$LINK_BASE_PATH/trus_ddbb
TRUS_LINK_INSTALLATION_PATH=$LINK_BASE_PATH/trus_installation
TRUS_LINK_KONG_PATH=$LINK_BASE_PATH/trus_kong
TRUS_LINK_MESSAGES_PATH=$LINK_BASE_PATH/trus_messages
TRUS_LINK_TOOLS_PATH=$LINK_BASE_PATH/trus_tools
TRUS_LINK_PATH=$LINK_BASE_PATH/trus

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


### Llamadas a apis

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
        install
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
        config_colours_menu
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


install_trus() {
    mkdir -p "$TRUS_BASE_PATH"

    rm -f "$TRUS_BASE_PATH"/*

    cp -r "$PWD"/* "$TRUS_BASE_PATH"
    cp $TRUS_DEFAULT_CONFIG trus.config

    sudo rm -f $TRUS_LINK_PATH && sudo ln -s $TRUS_PATH $TRUS_LINK_PATH
    sudo rm -f $TRUS_LINK_DDBB_PATH && sudo ln -s $TRUS_DDBB_PATH $TRUS_LINK_DDBB_PATH
    sudo rm -f $TRUS_LINK_INSTALLATION_PATH && sudo ln -s $TRUS_INSTALLATION_PATH $TRUS_LINK_INSTALLATION_PATH
    sudo rm -f $TRUS_LINK_TOOLS_PATH && sudo ln -s $TRUS_TOOLS_PATH $TRUS_LINK_TOOLS_PATH
        
    source $TRUS_DEFAULT_CONFIG
    source $TRUS_CONFIG
    source trus_tools
    source trus_ddbb
    source trus_installation
    
    print_centered_message "Truedat Utils (TrUs) instalado con éxito" "$COLOR_SUCCESS"
}

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



TRUS_ACTUAL_PATH=$(realpath "$0")

if [ ! -e "$TRUS_PATH" ]; then
    install_trus
else
    source $TRUS_DEFAULT_CONFIG
    source $TRUS_CONFIG
    source trus_tools
    source trus_ddbb
    source trus_installation
fi

set_terminal_config

# print_centered_message "tareas por completar" "$color_primary" "both"
# print_message "bugs" "$color_primary" 1
# print_message "- revisar error de 'ruta/*' sale en algunas ocasiones al actualizar la bdd" "$color_secondary" 2
# print_message "- revisar error del linkado de paquetes de yarn que no va" "$color_secondary" 2
# print_message "- revisar error cuando se pregunta por  algo de s/n que antes pinta un error de get_color" "$color_secondary" 2

# print_message "cosas que antes habia y ahora no" "$color_primary" 1
# print_message "- hacer los helps" "$color_secondary" 2
# print_message "- configurar animacion" "$color_secondary" 2
# print_message "- funciones de ayuda" "$color_secondary" 2

# print_message "cosas nuevas" "$color_primary" 1
# print_message "- informe pidi (script victor)" "$color_secondary" 2
# print_message "- multi yarn test" "$color_secondary" 2
# print_message "- configurar colores de trus" "$color_secondary" 2
# print_message "- añadir submenu al reindexado de elastic, para seleccionar qué indices se quiere reindexar" "$color_secondary" 2
# print_message "- añadir submenu al arranque de todo/servicios de truedat, para seleccionar qué servicios se quiere arrancar" "$color_secondary" 2
# print_message "- añadir submenu a la actualizacion de repos para seleccionar qué actualizar" "$color_secondary" 2
# print_message "- añadir submenu a la descarga de bdd de test para seleccionar qué actualizar" "$color_secondary" 2 "after"
# print_message

param_router $1 $2 $3 $4 $5


