#!/bin/bash
PATH_GLOBAL_CONFIG=~/.trus.conf

trap stop_animation SIGINT
source $PATH_GLOBAL_CONFIG

#########################################
# Variables

HEADER_MESSAGE=${1:-""}
DESCRIPTION_MESSAGE=${2:-""}
HELP_SCRIPT=${3:-""}
HEADER_LOGO=$4
SIMPLE_ECHO=${5:-""}

TERMINAL_COLORS=("000000" "00005f" "000080" "000087" "0000af" "0000d7" "0000ff" "005f00" "005f5f" "005f87" "005faf" "005fd7" "005fff" "008000" "008080" "008700" "00875f" "008787" "0087af" "0087d7" "0087ff" "00af00" "00af5f" "00af87" "00afaf" "00afd7" "00afff" "00d700" "00d75f" "00d787" "00d7af" "00d7d7" "00d7ff" "00ff00" "00ff5f" "00ff87" "00ffaf" "00ffd7" "00ffff" "080808" "121212" "1c1c1c" "262626" "303030" "3a3a3a" "444444" "4e4e4e" "585858" "5f0000" "5f005f" "5f0087" "5f00af" "5f00d7" "5f00ff" "5f5f00" "5f5f5f" "5f5f87" "5f5faf" "5f5fd7" "5f5fff" "5f8700" "5f875f" "5f8787" "5f87af" "5f87d7" "5f87ff" "5faf00" "5faf5f" "5faf87" "5fafaf" "5fafd7" "5fafff" "5fd700" "5fd75f" "5fd787" "5fd7af" "5fd7d7" "5fd7ff" "5fff00" "5fff5f" "5fff87" "5fffaf" "5fffd7" "5fffff" "626262" "6c6c6c" "767676" "800000" "800080" "808000" "808080" "870000" "87005f" "870087" "8700af" "8700d7" "8700ff" "875f00" "875f5f" "875f87" "875faf" "875fd7" "875fff" "878700" "87875f" "878787" "8787af" "8787d7" "8787ff" "87af00" "87af5f" "87af87" "87afaf" "87afd7" "87afff" "87d700" "87d75f" "87d787" "87d7af" "87d7d7" "87d7ff" "87ff00" "87ff5f" "87ff87" "87ffaf" "87ffd7" "87ffff" "8a8a8a" "949494" "9e9e9e" "a8a8a8" "af0000" "af005f" "af0087" "af00af" "af00d7" "af00ff" "af5f00" "af5f5f" "af5f87" "af5faf" "af5fd7" "af5fff" "af8700" "af875f" "af8787" "af87af" "af87d7" "af87ff" "afaf00" "afaf5f" "afaf87" "afafaf" "afafd7" "afafff" "afd700" "afd75f" "afd787" "afd7af" "afd7d7" "afd7ff" "afff00" "afff5f" "afff87" "afffaf" "afffd7" "afffff" "b2b2b2" "bcbcbc" "c0c0c0" "c6c6c6" "d0d0d0" "d70000" "d7005f" "d70087" "d700af" "d700d7" "d700ff" "d75f00" "d75f5f" "d75f87" "d75faf" "d75fd7" "d75fff" "d78700" "d7875f" "d78787" "d787af" "d787d7" "d787ff" "d7af00" "d7af5f" "d7af87" "d7afaf" "d7afd7" "d7afff" "d7d700" "d7d75f" "d7d787" "d7d7af" "d7d7d7" "d7d7ff" "d7ff00" "d7ff5f" "d7ff87" "d7ffaf" "d7ffd7" "d7ffff" "dadada" "e4e4e4" "eeeeee" "ff0000" "ff005f" "ff0087" "ff00af" "ff00d7" "ff00ff" "ff5f00" "ff5f5f" "ff5f87" "ff5faf" "ff5fd7" "ff5fff" "ff8700" "ff875f" "ff8787" "ff87af" "ff87d7" "ff87ff" "ffaf00" "ffaf5f" "ffaf87" "ffafaf" "ffafd7" "ffafff" "ffd700" "ffd75f" "ffd787" "ffd7af" "ffd7d7" "ffd7ff" "ffff00" "ffff5f" "ffff87" "ffffaf" "ffffd7" "ffffff")

set_terminal_config() {
    local background_color_test=${1:-"$COLOR_BACKRGROUND"}
    local foreground_color_test=${2:-"$NO_COLOR"}

    if [ "$SIMPLE_ECHO" = "" ]; then
        echo -ne "\e]11;#${COLOR_BACKRGROUND}\e\\"
        echo -ne "\e]10;#${COLOR_PRIMARY}\e\\"
    fi
    
   set_active_animation

    if [ "$HIDE_OUTPUT" = true ]; then
        REDIRECT=">/dev/null 2>&1"
    else
        REDIRECT=""
    fi
}

set_active_animation(){
    local selected=${1:-$SELECTED_ANIMATION}

    list_name="TERMINAL_ANIMATION_$selected"    
    eval "active_animation=(\"\${$list_name[@]}\")"
    sed -i "s/^SELECTED_ANIMATION=.*/SELECTED_ANIMATION='$selected'/" "$PATH_GLOBAL_CONFIG"
}

#########################################
# Herramientas generales

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

message_size() {
    local message=$1
    local ancho_terminal
    local espacios_izquierda
    local espacios_derecha
    local longitud_total

    ancho_terminal=$(tput cols)
    espacios_izquierda=$(((ancho_terminal - ${#message}) / 2))
    espacios_derecha=$((ancho_terminal - ${#message} - espacios_izquierda))
    longitud_total=$((espacios_izquierda + ${#message} + espacios_derecha))

    echo "$espacios_izquierda $espacios_derecha $longitud_total"
}

 

#########################################
# Colorinchis

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
    local r, g, b

    r=$(printf "%d" "0x${hex:0:2}")
    g=$(printf "%d" "0x${hex:2:2}")
    b=$(printf "%d" "0x${hex:4:2}")

    echo "$r;$g;$b"
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

#########################################
# Animaciones. Original aqui: https://github.com/Silejonu/bash_loading_animations

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

    stop_animation

    unset "active_animation[0]"
    play_animation "$message" "$tabs" "$color" &
    animation_pid="${!}"
}

#########################################
# Impresion de mensajes y variantes

print_message() {
    local message=${1:-""}
    local color=${2:-"$COLOR_PRIMARY"}
    local tabs=${3:-0}
    local new_line_before_or_after=${4:-"normal"}
    local transformed_color=$(get_color "$color")
    local transformed_no_color=$(get_color "$NO_COLOR")

    for ((i = 1; i <= tabs; i++)); do
        message="\t"$message
    done

    if [ ! "$SIMPLE_ECHO" = "" ]; then
        echo -ne "$message\n"
    else
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
        stop_animation
        echo -ne "$message"
    fi
}

print_question(){
    local question=${1:-""}
    local color=${2:-"$COLOR_WARNING"}
    local tabs=${3:-3}
    
    print_message "$question ¿Deseas hacerlo ahora? (S/N)" "$color" "$tabs"
    read question
    
    local continue_question=$(normalize_text "$question")

    if [ "$continue_question" = "si" ] || [ "$continue_question" = "s" ] || [ "$continue_question" = "y" ] || [ "$continue_question" = "yes" ]; then
        PRINT_QUESTION_RESPONSE=1
    fi            
}

get_print_question_response(){
    local temp=$PRINT_QUESTION_RESPONSE
    PRINT_QUESTION_RESPONSE=0
    echo $temp
}

print_separator() {
    local separator=$1
    local count=$2
    local new_line_before_or_after=${3:-"none"}
    local message

    message=$(printf "%-${count}s" | tr ' ' "$separator")

    if [ "$SIMPLE_ECHO" = "" ]; then
        print_message "$message" "" 0 "$new_line_before_or_after"
    fi
}

print_centered_message() {
    local message=$1
    local color=$2
    local new_line_before_or_after=${3:-""}

    IFS=' ' read -r espacios_izquierda espacios_derecha longitud_total <<<"$(message_size "$message")"

    local tabs=$((espacios_izquierda / 8))

    print_message "$message" "$color" $tabs "$new_line_before_or_after"
}

print_header() {
    clear
    wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    sleep 0.11
    IFS=' ' read -r espacios_izquierda espacios_derecha longitud_total <<<"$(message_size "")"

    local separador=$(print_separator "-" "$(($longitud_total - 37))")

    print_message ""
    print_message "  &           &&&&&&&&&           &  "
    print_message "   &&&  &&&&&           &&&&&  &&&   "
    print_message "     &&&&&&&&&&       &&&&&&&&&&     $separador"
    print_message "     &&&*****&&&&& &&&&&*****&&&     "
    print_message "     &&  *******&&&&&*******  &&     ${HEADER_LOGO[0]}"
    print_message "    &&&     **    &   ***     &&&    ${HEADER_LOGO[1]}   $HEADER_MESSAGE"
    print_message "   &&&&                      &&&&&   ${HEADER_LOGO[2]}"
    print_message "   &&&                     &&& &&&   ${HEADER_LOGO[3]}   Usuario: $(echo "$(getent passwd $USER)" | cut -d ':' -f 5 | cut -d ',' -f 1) ($USER)"
    print_message "  &&&&                  &&&&&  &&&&  ${HEADER_LOGO[4]}   Equipo: $HOSTNAME"
    print_message "  &&&&         &&&&&&&&&&&     &&&&  ${HEADER_LOGO[5]}"
    print_message "   &&&&&  &&&&&&&&&&         &&&&&   ${HEADER_LOGO[6]}   $DESCRIPTION_MESSAGE"
    print_message "    &&&&&&&&&&&            &&&&&&    "
    print_message "      &&&&&&&           &&&&&&       "
    print_message "         &&&&&&&&   &&&&&&&&         $separador"
    print_message "             &&&&&&&&&&&             "
    print_message "                 &&                  "
}

print_semiheader() {
    local message=$1
    local separator="-"
    local longitud_separador

    if [ "$SIMPLE_ECHO" = "" ]; then
        IFS=' ' read -r espacios_izquierda espacios_derecha longitud_total <<<"$(message_size "$message")"
        espacios_izquierda=$((espacios_izquierda / 4))
        message=$(printf "%-${espacios_izquierda}s" | tr ' ' $separator)" "$message
        longitud_separador=$((${#message} + espacios_izquierda))

        print_separator "$separator" $longitud_separador "before"
    fi

    print_message "$message\n" "" 0 "" "after"
}

print_truedat_logo() {
    clear
    wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    sleep 0.11
    print_centered_message ""
    print_centered_message "              &&             &&&&&&&&&&&&&&&&&&&&              &&               "
    print_centered_message "                &&&&&   &&&&&&&                 &&&&&&&   &&&&&                 "
    print_centered_message "                  &&&&&&&&&&&&&                 &&&&&&&&&&&&&                   "
    print_centered_message "                     &&&&&&&&&&&&&&&       &&&&&&&&&&&&&&&                      "
    print_centered_message "                    &&& ********&&&&&&& &&&&&&&******** &&&                     "
    print_centered_message "                   &&&& ***********&&&&&&&&&*********** &&&&                    "
    print_centered_message "                  &&&&&  ************&&&&&************  &&&&&                   "
    print_centered_message "                  &&&&       *****     &     *****      &&&&&                   "
    print_centered_message "                 &&&&&                                  &&&&&&                  "
    print_centered_message "                &&&&&                                  &&&&&&&                  "
    print_centered_message "                &&&&&                                &&&& &&&&&                 "
    print_centered_message "               &&&&&&                             &&&&&&  &&&&&                 "
    print_centered_message "               &&&&&                         &&&&&&&&&    &&&&&&                "
    print_centered_message "               &&&&&&               &&&&&&&&&&&&&&&       &&&&&&                "
    print_centered_message "               &&&&&&&       &&&&&&&&&&&&&&&&&           &&&&&&                 "
    print_centered_message "                &&&&&&&& &&&&&&&&&&&&&&                &&&&&&&                  "
    print_centered_message "                  &&&&&&&&&&&&&&&&&                  &&&&&&&&                   "
    print_centered_message "                    &&&&&&&&&&&&&                 &&&&&&&&&                     "
    print_centered_message "                      &&&&&&&&&&               &&&&&&&&&&                       "
    print_centered_message "                         &&&&&&&&&&&       &&&&&&&&&&&                          "
    print_centered_message "                            &&&&&&&&&&&&&&&&&&&&&&                              "
    print_centered_message "                                &&&&&&&&&&&&&&&                                 "
    print_centered_message "                                    &&&&&&&                                     "
    print_centered_message "                                                                                "
    print_centered_message "                                                            **                  "
    print_centered_message "    &&&    &&&                                             ***             ***  "
    print_centered_message "   &&&     &&&&&  &&&&&& &&&     &&&   &&&&&&&&      *********   ********  *****"
    print_centered_message "  &&&&     &&&   &&&     &&&     &&&  &&&    &&&&  ***    **** ****   (*** ***  "
    print_centered_message " &&&&      &&&   &&&     &&&     &&& &&&&&&&&&&&& ***      ***   ********* ***  "
    print_centered_message "&&&&       &&&   &&&     &&&    &&&& &&&          ****     *** ***    **** ***  "
    print_centered_message "&&&        &&&&& &&&      &&&&&&&&&   &&&&&&&&&&    **********  *********  *****"
}

#########################################
# Funciones para pintar elementos de los formularios

print_menu() {
    local items=("$@")
    
    if [ "$HELP_SCRIPT" = "" ]; then
        HELP_SCRIPT="echo 'No hay ayuda disponible'"
    else
        HELP_SCRIPT="$HELP_SCRIPT --help {}"
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
        --preview="$HELP_SCRIPT"\
        --prompt="Búsqueda > " 
}


#########################################
# Herramientas principales

do_api_call() {
    local token="${1:-""}"
    local url="$2"
    local rest_method="${3:-""}"
    local params="${4:-""}"
    local sudo="${5:-""}"

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

    eval "$command $REDIRECT"
}


#########################################
# Git

checkout() {
    local HEADER=${1:-""}

    print_message_with_animation "Apuntando a $HEADERHEADER..." "$COLOR_SECONDARY" 3
    eval "git checkout $HEADER $REDIRECT"
    print_message "Apuntando a $HEADER (HECHO)" "$COLOR_SUCCESS" 3
}

update_git() {
    print_message_with_animation "Actualizando repositorio..." "$COLOR_SECONDARY" 3
    eval "git fetch $REDIRECT"
    eval "git pull  $REDIRECT"
    print_message "Actualizando repositorio (HECHO)" "$COLOR_SUCCESS" 3
}

clone_if_not_exists() {
    local repo_url=$1
    local target_dir=$2

    if [ ! -d "$target_dir" ]; then
        print_message "Clonando el repositorio desde '$repo_url' en '$target_dir'..." "$COLOR_SUCCESS" 3 
        git clone "$repo_url" "$target_dir"
    else
        print_message "El directorio '$target_dir' ya existe. No se clonará el repositorio."  "$COLOR_WARNING" 3 
    fi
}


#########################################
# Compilaciones

compile_web() {
    print_message_with_animation "Compilando React..." "$COLOR_SECONDARY" 3
    eval "yarn $REDIRECT"
    print_message "Compilando React (HECHO)" "$COLOR_SUCCESS" 3
}

compile_elixir() {
    local create_ddbb=${1:-""}

    print_message_with_animation "Actualizando dependencias Elixir..." "$COLOR_SECONDARY" 3
    eval "mix deps.get --force $REDIRECT"
    print_message "Actualizando dependencias Elixir (HECHO)" "$COLOR_SUCCESS" 3

    print_message_with_animation "Compilando Elixir..." "$COLOR_SECONDARY" 3
    eval "mix compile $REDIRECT"
    print_message "Compilando Elixir (HECHO)" "$COLOR_SUCCESS" 3

    if [ ! "$create_ddbb" = "" ]; then
        print_message_with_animation "Creando bdd..." "$COLOR_SECONDARY" 3
        eval "yes | mix ecto.create $REDIRECT"
        print_message "Creacion de bdd (HECHO)" "$COLOR_SUCCESS" 3
    fi
}


#########################################
# no sql

remove_all_redis() {
    local continue_redis_clean

    print_message "¿Quieres borrar todos los datos de Redis?" "$COLOR_PRIMARY" 1 "before"
    read -r redis_clean

    continue_redis_clean=$(normalize_text "$redis_clean")

    if [ "$continue_redis_clean" = "si" ] || [ "$continue_redis_clean" = "s" ] || [ "$continue_redis_clean" = "y" ] || [ "$continue_redis_clean" = "yes" ]; then
        eval "redis-cli flushall  $REDIRECT"
        print_message "✳ Borrado de Redis completado ✳" "$COLOR_SUCCESS" 1 "both"
    fi
}

remove_all_index() {
    local remove_all_indexes=${1:-""}
    local continue_elastic_clean

    if [ "$remove_all_indexes" = "" ]; then
        print_message "¿Quieres borrar todos los datos de ElasticSearch antes de reindexar?(S/N)" "$COLOR_PRIMARY" 1 "before"
        read -r elastic_clean

        continue_elastic_clean=$(normalize_text "$elastic_clean")
    fi

    if [ "$remove_all_indexes" = "-r" ] || [ "$continue_elastic_clean" = "si" ] || [ "$continue_elastic_clean" = "s" ] || [ "$continue_elastic_clean" = "y" ] || [ "$continue_elastic_clean" = "yes" ]; then
        do_api_call "" "http://localhost:9200/_all" "DELETE" "--fail"
        print_message "✳ Borrado de ElasticSearch completado ✳" "$COLOR_SUCCESS" 1 "both"
    fi
}

#########################################
# tmux y screen

go_to_session() {
    local session_name=$1

    clear

    tmux attach-session -t "$session_name"
}

go_out_session() {
    tmux detach-client
}

#########################################
# Otros

extract_menu_option() {
    local input="$1"
    local first_value=$(echo "$input" | cut -d' ' -f1)
    if [[ "$input" == *" - "* ]]; then
        first_value=$(echo "$input" | cut -d' ' -f1)
    fi

    echo "$first_value"
}
 
