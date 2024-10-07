#!/bin/bash

check_sudo() {
    local message=$1
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
        "left")  echo "$(generate_separator $filled_space "$separator")$message" ;;
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

### Colorinchis
get_color() {
    local COLOR=${1:-$COLOR_PRIMARY}
    local R=$((16#${COLOR:0:2}))
    local G=$((16#${COLOR:2:2}))
    local B=$((16#${COLOR:4:2}))
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

	if command -v wmctrl &> /dev/null; then
		wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
	fi
}

exec_command() {
    local command=$1
    local error_message
    if ! error_message=$(eval "$command" 2>&1); then
        print_message "Error ejecutando el comando: $command" "$COLOR_ERROR" 2 "before"
        print_message "Detalles del error: $error_message" "$COLOR_ERROR" 2 "after"
        exit 1
    fi
}


## mensajes
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

update_config(){
	local option=$1
	local value=$2
	sed -i "s/^$option=.*/$option='$value'/" "$TRUS_CONFIG"
	source $TRUS_CONFIG
}

### Animaciones. Original aqui: https://github.com/Silejonu/bash_loading_animations
set_active_animation() {
    local selected=${1:-$SELECTED_ANIMATION}

    list_name="TERMINAL_ANIMATION_$selected"
    eval "active_animation=(\"\${$list_name[@]}\")"
    sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION='$selected'/" "$TRUS_CONFIG"
    
    update_config "SELECTED_ANIMATION" "$selected"   
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
	exec_command "mix local.hex --force"
    exec_command "yes | mix deps.get"
    print_message "Actualizando dependencias Elixir (HECHO)" "$COLOR_SUCCESS" 3

    print_message_with_animation "Compilando Elixir..." "$COLOR_SECONDARY" 3
    exec_command "mix compile --force"
    print_message "Compilando Elixir (HECHO)" "$COLOR_SUCCESS" 3

    if [ ! "$create_ddbb" = "" ]; then
        print_message_with_animation "Creando bdd..." "$COLOR_SECONDARY" 3
        exec_command "yes | mix ecto.create"
        print_message "Creacion de bdd (HECHO)" "$COLOR_SUCCESS" 3
    fi
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
        #do_api_call "" "http://localhost:9200/_all" "DELETE" "--fail"
        do_api_call "" "" "http://localhost:9200/_all" "DELETE" "--fail"
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


#### Otros
extract_menu_option() {
    local input="$1"
    local first_value=$(echo "$input" | cut -d' ' -f1)
    if [[ "$input" == *" - "* ]]; then
        first_value=$(echo "$input" | cut -d' ' -f1)
    fi

    echo "$first_value"
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

do_api_call_with_login_token(){
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
	    $token  \
	    $url  \
	    $rest_method \ 
	    $params  \
	    $content_type \ 
	    $extra_headers  \
	    $output_format
 
}

get_token() {
    local token=$(do_api_call "" "json" "localhost:8080/api/sessions/" "POST" "--data '{\"access_method\": \"alternative_login\",\"user\": {\"user_name\": \"admin\",\"password\": \"patata\"}}'" ".token")
    echo "$token" 
}


## Configurations

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
            echo 'GRUB_TERMINAL="console"'
            echo 'GRUB_COLOR_NORMAL="yellow/black"          # Colores grub(letra/fondo)'
            echo 'GRUB_COLOR_HIGHLIGHT="yellow/black"       # Colores opcion selecionada (letra/fondo)'
            echo 'GRUB_GFXMODE=1024x768                        # Resolucion de grub'
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
 