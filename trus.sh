#!/bin/bash

#########################################
####   Variables Configuracion
#########################################

general_vars(){
    #########################################
    # General
    
    DATE_NOW=$(date +%Y%m%d_%H%M%S)
    USER_HOME=$(eval echo ~"$SUDO_USER")
    TRUS_INSTALLATION_PATH=$USER_HOME/.tools
    TRUS_PATH_CONFIG=$USER_HOME/.trus.conf
    TRUS_PATH=$TRUS_INSTALLATION_PATH/trus.sh
    HEADER_LOGO=(   "  _________   ______     __  __    ______       "
                    " /________/\ /_____/\   /_/\/_/\  /_____/\      "
                    " \__.::.__\/ \:::_ \ \  \:\ \:\ \ \::::_\/_     "
                    "     \::\ \   \:(_) ) )  \:\ \:\ \ \:\/___/\    "
                    "      \::\ \   \: __ ´\ \ \:\ \:\ \ \_::._\:\   "
                    "       \::\ \   \ \ ´\ \ \ \:\_\:\ \  /____\:\  "
                    "        \__\/    \_\/ \_\/  \_____\/  \_____\/  "
                )

    MAIN_MENU_OPTIONS=(
        "Salir"
        "--start"
        "--kill-truedat"
        "--ddbb"
        "--update-repos"
        "--help"
        "Más..."
    )

     SECONDARY_MENU_OPTIONS=(
        "Volver"
        "--reindex"        
        "--create_ssh"
        "--kong-routes"
        "--link-modules"
        "--yarn-test"
        "--load-structures"
        "--load-lineage"
        "--rest"
        "--attach"
        "--detach"        
    )

    START_MENU_SUBOPTIONS=(
        "Volver"
        "--all"
        "--start-containers"
        "--start-services"
        "--start-front"
    )

    DDBB_MENU_SUBOPTIONS=(
        "Volver"
        "--download-test"
        "--download-update"
        "--local-update"
        "--local-backup"
    )

    REPO_MENU_SUBOPTIONS=(
        "Volver"
        "--all"
        "--back"
        "--front"
        "--libs"
    )
}
 
path_vars(){
    #########################################
    #  PATHS

    SSH_PATH=~/.ssh
    SSH_PUBLIC_FILE=$SSH_PATH/truedat.pub
    SSH_PRIVATE_FILE=$SSH_PATH/truedat
    SSH_BACKUP_FOLDER=$SSH_PATH"/backup_$DATE_NOW"
    TRUEDAT_ROOT_PATH=$USER_HOME/workspace/truedat
    BACK_PATH=$TRUEDAT_ROOT_PATH/back
    FRONT_PATH=$TRUEDAT_ROOT_PATH/front 
    DEV_PATH=$TRUEDAT_ROOT_PATH/true-dev
    KONG_PATH=$BACK_PATH/kong-setup/data
    DDBB_BACKUP_PATH=$TRUEDAT_ROOT_PATH"/ddbb_truedat/$DATE_NOW"
    DDBB_LOCAL_BACKUP_PATH=$TRUEDAT_ROOT_PATH"/ddbb_truedat/local_backups/$DATE_NOW"
    AWSCONFIG=~/.aws/config
    KUBECONFIG=~/.kube/config
    TD_WEB_DEV_CONFIG=$FRONT_PATH/td-web/dev.config.js
}   

comands_and_context_vars(){
    #########################################
    #  DATA

    CONTEXT="test-truedat-eks"

    #########################################
    # Tmux y Screen

    TRUEDAT="truedat" 
    TMUX_CONF=~/.tmux.conf
    
    #########################################
    # kong
    DOCKER_LOCALHOST="172.17.0.1"
    KONG_ADMIN_URL="localhost:8001"
    KONG_SERVICES=("health" "td_audit" "td_auth" "td_bg" "td_dd" "td_qx" "td_dq" "td_lm" "td_qe" "td_se" "td_df" "td_ie" "td_cx" "td_i18n" "td_ai")

}

system_name_vars(){
    #########################################
    #  td_auth no se incluye para que no interfiera con los usuarios que tenemos creados ne local

    DATABASES=("td_audit" "td_bg" "td_dd" "td_df" "td_ie" "td_lm" "td_i18n" "td_qx" "td_ai") 
    INDEXES=("dd" "bg" "ie" "qx")


    #########################################
    #  DOCKER

    CONTAINERS=("elasticsearch" "redis" "kong" "redis_test" "vault")
    CONTAINERS_SETUP=("kong_create" "kong_migrate" "kong_setup" )


    #########################################
    #  PROJECTS

    FRONT_PACKAGES=("audit" "auth" "bg" "core" "cx" "dd" "df" "dq" "qx" "ie" "lm" "profile" "se" "test")
    SERVICES=("td-ai" "td-audit" "td-auth" "td-bg" "td-dd" "td-df" "td-i18n" "td-ie" "td-lm" "td-qx" "td-se")
    LIBRARIES=("td-cache" "td-cluster" "td-core" "td-df-lib")
}

set_vars(){
    general_vars
    path_vars
    comands_and_context_vars
    system_name_vars

    if [[ "$USE_KONG" = "" ]]; then
        config_kong_use 
    fi

}


#########################################
####       Operaciones
#########################################

update_services(){
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

compile_elixir(){
    local create_ddbb=${1:-""}
 
    print_message_with_animation "Actualizando dependencias Elixir..."  "$COLOR_SECONDARY" 3
    eval "mix deps.get --force $REDIRECT"
    print_message "Actualizando dependencias Elixir (HECHO)" "$COLOR_SUCCESS" 3  

    print_message_with_animation "Compilando Elixir..." "$COLOR_SECONDARY" 3
    eval "mix compile $REDIRECT"
    print_message "Compilando Elixir (HECHO)" "$COLOR_SUCCESS" 3  
 
    if [ ! "$create_ddbb" = "" ]; then
        print_message_with_animation "Creando bdd..."  "$COLOR_SECONDARY" 3
        eval "yes | mix ecto.create $REDIRECT"
        print_message "Creacion de bdd (HECHO)" "$COLOR_SUCCESS" 3  
    fi
}

update_libraries(){    
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

update_web(){
    cd "$FRONT_PATH/td-web"
    
    print_semiheader "Actualizando frontal"

    print_message "Actualizando td-web"  "$COLOR_QUATERNARY" 2 "before" 

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

yarn_test(){ 
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        packages=$FRONT_PACKAGES
    fi

    for package in "${packages[@]}"; do
        print_header "Front test" "yarn test $package" 
        
        cd $FRONT_PATH/td-web-modules/packages/$package
        yarn test
        sleep 2
    done     
}


#########################################
# ddbb

download_test_backup(){
    local PSQL

    PSQL=$(kubectl get pods -l run=psql -o name | cut -d/ -f2)    

    mkdir -p "$DDBB_BACKUP_PATH"

    print_message "Ruta de backup creada: $DDBB_BACKUP_PATH"  "$COLOR_SECONDARY" 1 "before" 
    for DATABASE in "${DATABASES[@]}"; do
        print_message "-->  Descargando $DATABASE"  "$COLOR_SECONDARY" 1 "before" 

        local SERVICE_NAME="${DATABASE//_/-}"
        local SERVICE_PODNAME="${DATABASE//-/_}"
        local SERVICE_DBNAME="${DATABASE}_dev"
        local SERVICE_PATH="$BACK_PATH/$SERVICE_NAME"
        local FILENAME=$SERVICE_DBNAME".sql"
        local PASSWORD=$(kubectl --context ${CONTEXT} get secrets postgres -o json | jq -r '.data.PGPASSWORD' | base64 -d)
        local USER=$(kubectl --context ${CONTEXT} get secrets postgres -o json | jq -r '.data.PGUSER' | base64 -d)
 
        cd "$SERVICE_PATH"
        print_message_with_animation "Creación de backup"  "$COLOR_SECONDARY" 2
        kubectl --context ${CONTEXT} exec ${PSQL} -- bash -c "PGPASSWORD='${PASSWORD}' pg_dump -d ${SERVICE_PODNAME} -U ${USER} -f ${DATABASE}.sql -x -O"
        print_message "Creación de backup (HECHO)"  "$COLOR_SUCCESS" 2  

        print_message_with_animation "Descarga backup"  "$COLOR_SECONDARY" 2
        eval "kubectl --context ${CONTEXT} cp \"${PSQL}:/${DATABASE}.sql\" \"./${FILENAME}\"  $REDIRECT"
        print_message "Descarga backup (HECHO)"  "$COLOR_SUCCESS" 2  

        print_message " Backup descargado en $SERVICE_PATH/$FILENAME" "$COLOR_WARNING" 2

        print_message_with_animation "Borrando fichero generado en el POD"  "$COLOR_SECONDARY" 2
        eval "kubectl --context \"${CONTEXT}\" exec \"${PSQL}\" -- rm \"/${DATABASE}.sql\"  $REDIRECT"
        print_message "Borrando fichero generado en el POD (HECHO)"  "$COLOR_SUCCESS" 2  

        print_message_with_animation "Comentado de 'CREATE PUBLICATION'"  "$COLOR_SECONDARY" 2
        eval "sed -i 's/CREATE PUBLICATION/--CREATE PUBLICATION/g' \"./${FILENAME}\"  $REDIRECT"
        print_message "Comentado de 'CREATE PUBLICATION' (HECHO)"  "$COLOR_SUCCESS" 2  

        print_message_with_animation "Moviendo fichero $FILENAME a backup"  "$COLOR_SECONDARY" 2
        eval "mv \"$FILENAME\" \"$DDBB_BACKUP_PATH\"  $REDIRECT"
        print_message "Moviendo fichero $FILENAME a backup (HECHO)" "$COLOR_SUCCESS" 2  
    done   

    print_message "Descarga de backup de test terminada" "$COLOR_SUCCESS" 3 "both"  
}

update_ddbb(){
    local FILENAME=$1
    local SERVICE_DBNAME=$2
 
    print_message_with_animation " Borrado de bdd $SERVICE_DBNAME"  "$COLOR_SECONDARY" 2
    eval "mix ecto.drop $REDIRECT"
    print_message " Borrado de bdd $SERVICE_DBNAME (HECHO)"  "$COLOR_SUCCESS" 2  

    print_message_with_animation " Creacion de bdd $SERVICE_DBNAME"  "$COLOR_SECONDARY" 2
    eval "mix ecto.create $REDIRECT"
    print_message " Creacion de bdd $SERVICE_DBNAME (HECHO)"  "$COLOR_SUCCESS" 2  

    print_message_with_animation " Volcado de datos del backup de test"  "$COLOR_SECONDARY" 2
    eval "PGPASSWORD=postgres psql -d \"${SERVICE_DBNAME}\" -U postgres  -h localhost < \"${FILENAME}\" $REDIRECT"
    print_message " Volcado de datos del backup de test (HECHO)"  "$COLOR_SUCCESS" 2  

    print_message_with_animation " Aplicando migraciones"  "$COLOR_SECONDARY" 2
    eval "mix ecto.migrate $REDIRECT"
    print_message " Aplicando migraciones (HECHO)" "$COLOR_SUCCESS" 2   
}

update_ddbb_from_backup(){
    local path_backup=$1
    local files=${path_backup}"/*"
    
    for FILENAME in $files; do
        local SERVICE_DBNAME
        local SERVICE_NAME

        SERVICE_DBNAME=$(basename "$FILENAME" ".sql")
        SERVICE_NAME=$(basename "$FILENAME" "_dev.sql" | sed 's/_dev//g; s/_/-/g')

        cd "$BACK_PATH"/"$SERVICE_NAME"

        print_message "-->  Actualizando $SERVICE_DBNAME"  "$COLOR_SECONDARY" 1 "before" 
        update_ddbb "$FILENAME" "$SERVICE_DBNAME" 
    done

    print_message "Actualizacion de bdd local terminada" "$COLOR_SUCCESS" 1  
}

get_local_backup_path(){
    local contador=0

    
    while [ $contador -lt 5 ]; do
        print_message "Por favor, indica la carpeta donde está el backup que deseas aplicar" "$COLOR_SECONDARY" 1 "both" 
        read -r path_backup

        if [ -d "$path_backup" ]; then                
            backup_path=$path_backup

            break
        else
            contador=$((contador + 1))

            print_centered_message "La ruta introducida no es válida." "$COLOR_WARNING"
        fi
    done
}

create_backup_local_ddbb(){
    mkdir -p "$DDBB_LOCAL_BACKUP_PATH"

    cd "$DDBB_LOCAL_BACKUP_PATH"
    
    for DATABASE in "${DATABASES[@]}"; do
        FILENAME=${DATABASE}"_dev.sql"
        print_message_with_animation " Creación de backup de $DATABASE"  "$COLOR_SECONDARY" 2
        PGPASSWORD=postgres pg_dump -U postgres -h localhost "${DATABASE}_dev"  > "${FILENAME}"
        print_message " Creación de backup de $DATABASE (HECHO)"  "$COLOR_SUCCESS" 2  
    done   
    print_message " Backup creado en $DDBB_LOCAL_BACKUP_PATH" "$COLOR_WARNING" 1 "both"
}
 

#########################################
# Install

install_docker(){
    aws ecr get-login-password --profile truedat --region eu-west-1 | docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com

    set -e
    set -o pipefail
    cd "$DEV_PATH"

    ip=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo SERVICES_HOST="$ip" > local_ip.env
    sudo chmod 666 /var/run/docker.sock

    if [ "$USE_KONG" = true ]; then            
        for container in "${CONTAINERS_SETUP[@]}"; do
            docker-compose up -d "${container}"    
        done  
    fi    
    
    start_containers 
    
    print_message "Contenedores instalados y arrancados" "$COLOR_SECONDARY" 1 "before" 
}

set_elixir_versions(){
    print_message_with_animation "Configurando versiones específicas de Elixir..."  "$COLOR_SECONDARY" 3
    eval "cd $USER_HOME/workspace/truedat/back/td-auth && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-audit && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-ai && asdf local elixir 1.15 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-bg && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-cluster && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-core && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-dd && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-df && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-df-lib && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-ie && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-lm && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-qx && asdf local elixir 1.14.5-otp-25 $REDIRECT"
    eval "cd $USER_HOME/workspace/truedat/back/td-se && asdf local elixir 1.16 $REDIRECT"
    print_message "Configurando versiones específicas de Elixir (HECHO)" "$COLOR_SUCCESS" 3 "both"  
}


#########################################
# Acciones Principales

install(){
    print_header "Instalación"    
    print_message "Guia de instalación: https://confluence.bluetab.net/pages/viewpage.action?pageId=136022683"  "$COLOR_QUATERNARY" 0 "before" 
   
    if [ ! -e "/tmp/truedat_installation" ]; then
        print_header "Instalación Truedat"
       
        if [ -f "$SSH_PUBLIC_FILE" ]; then 
            print_message "ATENCIÓN, SE VA A SOLICITAR LA CONFIGURACIÓN DE AWS 2 VECES" "$COLOR_WARNING" 2 "before"
            print_message "Una para el perfil predeterminado y otra para el de truedat" "$COLOR_WARNING" 2 "both"
            print_message "Estos datos te los debe dar tu responsable" "$COLOR_SECONDARY" 2 "both"

            if [ ! -e "$AWSCONFIG" ]; then
                aws configure
                aws configure --profile truedat
                aws ecr get-login-password --profile truedat --region eu-west-1 | docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com
                print_message "Configuración de aws (HECHO)" "$COLOR_SUCCESS" 3 "before"  
            fi            

            if [ ! -e "~/.kube" ]; then
                mkdir ~/.kube
            fi

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
                echo 'current-context: test-truedat-eks'
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
                echo '      apiVersion: client.authentication.k8s.io/v1alpha1'
                echo '      args:'
                echo '      - --region'
                echo '      - eu-west-1'
                echo '      - eks'
                echo '      - get-token'
                echo '      - --cluster-name'
                echo '      - test-truedat-eks'
                echo '      command: aws               '
            } > $KUBECONFIG
            
            print_message "Instalación de kubectl (HECHO)" "$COLOR_SUCCESS" 3 "both"      
            
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
            print_message "Configurando ASDF (HECHO)" "$COLOR_SUCCESS" 3 "before"      

            #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
            #En linux no es necesario pero no molesta 
            eval "$(ssh-agent -s)"        
            ssh-add $SSH_PRIVATE_FILE

            mkdir "$USER_HOME/workspace"
            mkdir "$USER_HOME/workspace/truedat"
            mkdir "$USER_HOME/workspace/truedat/back"
            mkdir "$USER_HOME/workspace/truedat/back/logs"
            mkdir "$USER_HOME/workspace/truedat/front"

            cd $BACK_PATH
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-ai.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-audit.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-auth.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-bg.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-dd.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-df.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-ie.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-qx.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-i18n.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-lm.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/td-se.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/td-helm.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/clients/demo/k8s.git

            git clone git@github.com:Bluetab/td-df-lib.git
            git clone git@github.com:Bluetab/td-cache.git
            git clone git@github.com:Bluetab/td-core.git
            git clone git@github.com:Bluetab/td-cluster.git

            cd $FRONT_PATH
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/front-end/td-web-modules.git
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/front-end/td-web.git

            cd $TRUEDAT_ROOT_PATH
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/true-dev.git
            cd true-dev
            sudo sysctl -w vm.max_map_count=262144
            sudo cp elastic-search/999-map-count.conf /etc/sysctl.d/
            print_message "Truedat descargado" "$COLOR_SUCCESS" 3 "before"                  

            update_repositories "-a"
            link_web_modules
            ddbb "-du"
            config_kong_use           
            
            touch "/tmp/truedat_installation"
            print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" 3

        else
            print_message "- Claves SSH (NO CREADAS): Tienes que tener creada una clave SSH (el script chequea que la clave se llame 'truedat') en la carpeta ~/.ssh"  "$COLOR_ERROR" 3 "before"
            print_message "RECUERDA que tiene que estar registrada en el equipo y en Gitlab. Si no, debes crearla con 'trus -cr' y registarla en la web'"  "$COLOR_WARNING" 3 "after" 
        fi
    else
        print_message "Truedat ha sido instalado" "$COLOR_PRIMARY" 3
    fi        
     
}

config_kong_use(){
        cd "~/workspace/truedat/front/td-web"
            
        print_message "¿Quieres utilizar Kong o que sea td-web quien enrute? (S/N)" "$COLOR_PRIMARY" 1
        read -r install_kong

        continue_install_kong=$(normalize_text "$install_kong")

        if [ ! "$continue_install_kong" = "" ] || [ "$continue_install_kong" = "si" ] || [ "$continue_install_kong" = "s" ] || [ "$continue_install_kong" = "y" ] || [ "$continue_install_kong" = "yes" ]; then            
            {
                echo 'USE_KONG=true'
            } >> $TRUS_PATH_CONFIG 
        else
            {
                echo 'USE_KONG=false'
            } >> $TRUS_PATH_CONFIG 
        fi 

        source $TRUS_PATH_CONFIG

        touch $TD_WEB_DEV_CONFIG
        
        if [[ "$USE_KONG" = "true" ]]; then
            install_docker
            
            cd "$USER_HOME/workspace/truedat/back"                  
            git clone git@gitlab.bluetab.net:dgs-core/true-dat/back-end/kong-setup.git

            kong_routes

            # target: "https://test.truedat.io:443",       -> Se utilizarán los servicios del entorno test
            # target: "http://localhost:8000",             -> Se utilizarán los servicios de nuestro local
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
            }
        else
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
            } > $TD_WEB_DEV_CONFIG
        fi
}

ddbb(){
    local options=$1
    backup_path=""
    print_header "Operaciones de bdd"
 
    if [ "$options" = "-d" ] || [ "$options" = "--download-test" ] || [ "$options" = "-du" ] || [ "$options" = "--download-update" ] ; then
        download_test_backup
        backup_path=$DDBB_BACKUP_PATH
    fi
        
    if [ "$options" = "-lu" ] || [ "$options" = "--local-update" ] ; then
        get_local_backup_path
    fi

    if [ "$options" = "-lb" ] || [ "$options" = "--local-backup" ] ; then
        create_backup_local_ddbb
    fi

    if { [ -d "$backup_path" ] && [ "$options" = "-du" ] || [ "$options" = "--download-update" ] || [ "$options" = "-lu" ] || [ "$options" = "--local-update" ]; } ; then
        local continue_reindex

        remove_all_redis

        update_ddbb_from_backup "$backup_path"

        print_message "Se ha realizado la actualizacion de las bbdd correctamente. Es recomendable reindexar ¿deseas hacerlo? (S/N)" "$COLOR_PRIMARY" 1
        read -r reindex

        continue_reindex=$(normalize_text "$reindex")

        if [ "$continue_reindex" = "si" ] || [ "$continue_reindex" = "s" ] || [ "$continue_reindex" = "y" ] || [ "$continue_reindex" = "yes" ]; then            
            reindex_all
        fi 
    fi  
}

reindex_all(){
    local remove_all_indexes=${1:-""}  
    print_header "Reindexando"
                
    
    remove_all_index "$remove_all_indexes"

    for service in "${INDEXES[@]}"; do
        local normalized_service
        
        normalized_service=$(normalize_text "$service")

        reindex_one "$normalized_service" "$SILENT"
    done     
}

reindex_one() {
    local service=$1
    local SILENT=${2:-""}  

    cd "$BACK_PATH/td-$service"
    print_message "Reindexando servicios de td-$service" "$COLOR_PRIMARY" 1 

    case "$service" in        
        "dd" )            
            print_message_with_animation " Reindexando :jobs" "$COLOR_SECONDARY" 2 
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:jobs, :all)\" $REDIRECT"
            print_message " Reindexando :jobs (HECHO)"  "$COLOR_SUCCESS" 2

            print_message_with_animation " Reindexando :structures"  "$COLOR_SECONDARY" 2  
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:structures, :all)\" $REDIRECT"
            print_message " Reindexando :structures (HECHO)"  "$COLOR_SUCCESS" 2

            print_message_with_animation " Reindexando :grants"  "$COLOR_SECONDARY" 2 
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:grants, :all)\" $REDIRECT"
            print_message " Reindexando :grants (HECHO)"  "$COLOR_SUCCESS" 2

            print_message_with_animation " Reindexando :grant_requests" "$COLOR_SECONDARY" 2 
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:grant_requests, :all)\" $REDIRECT"
            print_message " Reindexando :grant_requests (HECHO)"  "$COLOR_SUCCESS" 2

            print_message_with_animation " Reindexando :implementations"  "$COLOR_SECONDARY" 2   
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:implementations, :all)\" $REDIRECT"
            print_message " Reindexando :implementations (HECHO)"  "$COLOR_SUCCESS" 2

            print_message_with_animation " Reindexando :rules"  "$COLOR_SECONDARY" 2 
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:rules, :all)\" $REDIRECT"
            print_message " Reindexando :rules (HECHO)" "$COLOR_SUCCESS" 2 "after"

            ;;     

        "bg" )            
            print_message_with_animation " Reindexando :concepts"  "$COLOR_SECONDARY" 2 
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:concepts, :all)\" $REDIRECT"
            print_message " Reindexando :concepts (HECHO)"  "$COLOR_SUCCESS" 2 "after"
                                            
            ;;

        "ie" )            
            print_message_with_animation " Reindexando :ingests"  "$COLOR_SECONDARY" 2   
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:ingests, :all)\" $REDIRECT"
            print_message " Reindexando :ingests (HECHO)"  "$COLOR_SUCCESS" 2 "after"
            
            ;;

        "qx" )            
            print_message_with_animation " Reindexando :quality_controls"  "$COLOR_SECONDARY" 2   
            eval "mix run -e \"TdCore.Search.Indexer.reindex(:quality_controls, :all)\" $REDIRECT"
            print_message " Reindexando :quality_controls (HECHO)"  "$COLOR_SUCCESS" 2 "after"

            ;;

    esac
}

kill_truedat(){
    #back - mix
    eval "pkill -9 mix $REDIRECT"
    
    # back - tmux
    eval "tmux kill-server $REDIRECT"
         
    # back - screen
    eval "screen -ls | grep -oP \"^\s*\K\d+\.(?=[^\t])\" | xargs -I {} screen -X -S {} quit $REDIRECT"
    eval "screen -wipe $REDIRECT"
    
    # front
    eval "pkill -9 $(pgrep -f \"yarn\") $REDIRECT"

    print_header "Truedat ha muerto"
}

create_ssh(){
    local continue_ssh_normalized
    print_header "Creación de una nueva clave ssh" 
    print_centered_message "SE VA A PROCEDER HACER BACKUP DE LAS CLAVES '$TRUEDAT' ACTUALES, BORRAR LA CLAVE EXISTENTE Y CREAR UNA NUEVA HOMONIMA" "$COLOR_ERROR"

    print_centered_message "¿CONTINUAR (S/N)?" "$COLOR_ERROR"
    read -r continue_ssh
    continue_ssh_normalized=$(normalize_text "$continue_ssh")

    if [ "$continue_ssh_normalized" = "si" ] || [ "$continue_ssh_normalized" = "s" ]; then
        cd $SSH_PATH
        
        if [ -f "$SSH_PUBLIC_FILE" ] || [ -f "$SSH_PRIVATE_FILE" ]; then
            print_message "Haciendo backup del contenido de ~/.ssh..." "$COLOR_SECONDARY" 1
            mkdir -p "$SSH_BACKUP_FOLDER"
            print_message "Carpeta creada: $SSH_BACKUP_FOLDER" "$COLOR_TERNARY" 3

            if [ -f "$SSH_PUBLIC_FILE" ]; then
                mv "$SSH_PUBLIC_FILE" "$SSH_BACKUP_FOLDER"
                print_message "Guardado archivo: $SSH_PUBLIC_FILE" "$COLOR_TERNARY" 3
            fi

            if [ -f "$SSH_PRIVATE_FILE" ]; then
                mv "$SSH_PRIVATE_FILE" "$SSH_BACKUP_FOLDER"
                print_message "Guardado archivo: $SSH_PRIVATE_FILE" "$COLOR_TERNARY" 3 
            fi    
        fi

        eval "yes | ssh-keygen -t ed25519 -f $SSH_PRIVATE_FILE -q -N \"\" $REDIRECT"
        print_message "Clave creada correctamente"  "$COLOR_SUCCESS" 3 "before"
        
        #Este eval está porque si se instala el entorno en el WSL de windows, el agente no se mantiene levantado
        #En linux no es necesario pero no molesta 
        eval "$(ssh-agent -s)"        
        ssh_add_result=$(ssh-add $SSH_PRIVATE_FILE 2>&1)        

        if [[ "$ssh_add_result" == *"Identity added"* ]]; then
            print_message "Clave registrada correctamente"  "$COLOR_SUCCESS" 3 "both"
            print_message "Por favor, registra la siguiente clave en gitlab: $(cat $SSH_PUBLIC_FILE)" "$COLOR_PRIMARY" 1 "after"
        else
            print_centered_message "Hubo un problema al registrar la clave: $ssh_add_result" "$COLOR_ERROR"
        fi
    fi
}

update_repositories(){
    local updated_option=${1:-"-a"}
    local create_dbb=${2:-""}

    print_header "Actualizando repositorios locales"

    case "$updated_option" in
        "-b" | "--back" )
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

link_web_modules(){
    print_header "React"
    print_semiheader "Linkado de modulos"

    print_message "Se borrarán los links y se volveran a crear ¿deseas hacerlo? (S/N)" "$COLOR_PRIMARY" 1
    read -r relink

    continue_relink=$(normalize_text "$relink")

    if [ "$continue_relink" = "si" ] || [ "$continue_relink" = "s" ] || [ "$continue_relink" = "y" ] || [ "$continue_relink" = "yes" ]; then            
        for d in "${FRONT_PACKAGES[@]}"; do
            cd "$FRONT_PATH/td-web-modules/packages/$d"
            eval "yarn unlink $REDIRECT"
            eval "yarn link $REDIRECT"
            cd "$FRONT_PATH/td-web"
            yarn link "@truedat/$d"
        done
    fi 
}

get_service_port(){
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
 
kong_routes(){
    print_header "Kong"
    print_semiheader "Creación de rutas"

    cd $KONG_PATH
    set -o pipefail
    
    for SERVICE in ${KONG_SERVICES[@]}; do
        local PORT=$(get_service_port "$SERVICE") 
        local SERVICE_ID=$(curl --silent -X GET "${KONG_ADMIN_URL}/services/${SERVICE}" | jq -r '.id // empty')
        local DATA='{ "name": "'${SERVICE}'", "host": "'${DOCKER_LOCALHOST}'", "port": '$PORT' }'

        print_message_with_animation "Creando rutas para el servicio: $SERVICE (puerto: $PORT)" "$COLOR_SECONDARY" 2 

        if [ -n "${SERVICE_ID}" ]; then
            ROUTE_IDS=$(curl --silent -X GET "${KONG_ADMIN_URL}/services/${SERVICE}/routes" | jq -r '.data[].id')
            if [ -n "${ROUTE_IDS}" ]; then
                for ROUTE_ID in ${ROUTE_IDS}; do
                    curl --fail --silent -X DELETE "${KONG_ADMIN_URL}/routes/${ROUTE_ID}"
                done
            fi
            curl --fail --silent -X DELETE "${KONG_ADMIN_URL}/services/${SERVICE_ID}"
        fi

        local API_ID=$(curl --fail --silent -H 'Content-Type: application/json' -X POST "${KONG_ADMIN_URL}/services" -d "$DATA" | jq -r '.id')
        
        eval "sed -e \"s/%API_ID%/${API_ID}/\" ${SERVICE}.json | curl --silent -H \"Content-Type: application/json\" -X POST \"${KONG_ADMIN_URL}/routes\" -d @- | jq -r '.id' $REDIRECT"
        
        print_message "Rutas servicio: $SERVICE (puerto: $PORT) creadas con éxito" "$COLOR_SUCCESS" 2
    done
          
    eval "curl --silent -X POST \"${KONG_ADMIN_URL}/services/health/plugins\" --data \"name=request-termination\" --data \"config.status_code=200\" --data \"config.message=Kong is alive\"  | jq -r '.id' $REDIRECT"
    print_message "Creacion de rutas finalizada" "$COLOR_SUCCESS" 2 "both"   
}

start_containers(){
    print_header "Contenedores"
    print_semiheader "Arrancando..."
    
    cd "$DEV_PATH"
    
    for container in "${CONTAINERS[@]}"; do        
        if [[ "$USE_KONG" = true ]] || { [[ "$USE_KONG" = false ]] && [[ "$container" != "kong" ]]; }; then
            docker-compose up -d "${container}"    
        fi
    done    
}

stop_docker(){
    print_header "Contenedores"
    print_semiheader "Apagando..."
    cd "$DEV_PATH"

    for container in "${CONTAINERS[@]}"; do
        docker-compose down "${container}"    
    done    
}

start_services(){
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

start_front(){
    cd "$FRONT_PATH"/td-web
    yarn start     
}

add_terminal_to_tmux_session(){
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

    tmux source-file $TMUX_CONF
    tmux new-session -d -s $TRUEDAT -n "Truedat"     
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

    add_terminal_to_tmux_session "$(tmux list-panes -t truedat | awk 'END {print $1 + 0}')" "trus -sf"
    add_terminal_to_tmux_session "$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') + 1))" "source tools 'Truedat Utils (TrUs)'; print_semiheader 'Truedat'; print_message 'Truedat está arrancado' '$COLOR_PRIMARY' 1; print_message 'Para acceder a la session, utiliza \"trus -at\"' '$COLOR_SECONDARY' 2;"
    tmux select-pane -t truedat:0."$(($(tmux list-panes -t truedat | awk 'END {print $1 + 0}') - 1))"

    go_to_session $TRUEDAT
}

get_token(){
    response=$(do_api_call \
                    "" \
                    "localhost:8080/api/sessions/" \
                    "" \
                    "--data '{\"access_method\": \"alternative_login\",\"user\": {\"user_name\": \"admin\",\"password\": \"patata\"}}'")
                    token=$(echo "$response" | jq -r '.token')

    echo "$token"
}

load_structures(){
    local path=$1
    local system="$2"
    local token
    token=$(get_token)
    path=$(eval echo "$1")
    cd "$path"
    do_api_call \
        "$token" \
        "http://localhost:4005/api/systems/${system}/metadata" \
        "POST" \
        "-F \"data_structures=@structures.csv\" -F \"data_structure_relations=@relations.csv\""
}

load_linages(){
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

help(){
    local option=$(normalize_text "${1:-""}")

    case "$option" in
        "salir"  | " volver")
            print_message "Posicionate en una opcion para ver una descripción de lo que hace" "$COLOR_SECONDARY"
            ;;

         "--start")
            print_message "Arranca Truedat." "$COLOR_SECONDARY"
            print_message "Levanta los contenedores de Docker, crea una sesion de Screen por servicio y arranca el frontal." "$COLOR_SECONDARY"
            print_message "Todo en una sesion de Tmux" "$COLOR_SECONDARY"
            ;;

        "--start-containers")
            print_message "Levanta los contenedores de Docker de Truedat" "$COLOR_SECONDARY"
            ;;

        "--start-services")
            print_message "Levanta los servicios de Truedat" "$COLOR_SECONDARY"
            ;;

        "--stop-containers")
            print_message "Para los servicios de Truedat" "$COLOR_SECONDARY"
            ;;
        

        "--start-front")
            print_message "Levanta el frontal de Docker de Truedat" "$COLOR_SECONDARY"
            ;;

        "--start")
            print_message "Levanta Truedat" "$COLOR_SECONDARY"
            ;;

        "--kill-truedat")
            print_message "Mata las sesiones creadas con --start (Screen, Tmux) y los procesos de mix que haya" "$COLOR_SECONDARY"
            ;;

        "--install")
            print_message "Instala Truedat en el equipo. " "$COLOR_SECONDARY"
            ;;

        "--ddbb")
            print_message "Operaciones de BDD:" "$COLOR_SECONDARY"
            print_message "Elegir una opción" "$COLOR_SECONDARY"
            print_message "--download-test: Descarga SOLO el backup de la bdd de test" "$COLOR_SECONDARY" 1
            print_message "--download-update: Además de descargar el backup de test, lo aplica a las bdd locales" "$COLOR_SECONDARY" 1
            print_message "--local-update: Aplica a las bdd locales el backup de una carpeta indicada" "$COLOR_SECONDARY" 1 
            print_message "--local-backup: Crea un backup de la bdd local" "$COLOR_SECONDARY" 1
            ;;

        "--reindex")
            print_message "Reindexa los indices de Elasticsearch." "$COLOR_SECONDARY"
            ;;

        "--update-repos")
            print_message "Actualiza todos los repositorios de Truedat (front y back)." "$COLOR_SECONDARY"
            print_message "Elegir una opción" "$COLOR_SECONDARY"
            print_message "--back" "$COLOR_SECONDARY"
            print_message "--front" "$COLOR_SECONDARY"
            print_message "--libs" "$COLOR_SECONDARY"
            print_message "--all" "$COLOR_SECONDARY"
            ;; 

        "--create_ssh")
            print_message "Hace backup de las claves ssh existentes en ~/.ssh, crea unas nuevas y las registra" "$COLOR_SECONDARY"
            ;;

        "--kong-routes")
            print_message "Actualiza las rutas de Kong" "$COLOR_SECONDARY"
            ;;

        "--link-modules")
            print_message "Linkea los modulos de td-web-modules con td-web" "$COLOR_SECONDARY"
            ;;

        "--yarn-test")
            print_message "Lanza los test del frontal paquete a paquete, Los parámetros disponibles son:" "$COLOR_SECONDARY"
            ;;

        "--load-structures")
            print_message "Carga estructuras a partir de csv. Los parámetros son:" "$COLOR_SECONDARY"
            print_message "<path>: Ruta de la carpeta de los csv. Debe haber 2, uno llamado 'relations.csv' y otro llamado 'structures.csv'" "$COLOR_SECONDARY" 2
            print_message "<system>: El external id del sistema en Truedat" "$COLOR_SECONDARY" 2  "after"
            ;;

        "--load-lineage")
            print_message "Carga linages a partir de csv. Los parámetros son:" "$COLOR_TERNARY" 
            print_message "<path>: Ruta de la carpeta de los csv. Debe haber 2, uno llamado 'nodes.csv' y otro llamado 'rels.csv'" "$COLOR_SECONDARY" 2 "after"
            print_message "--rest: " "$COLOR_SECONDARY" 1 "no"
            ;;

        "--attach")
            print_message "Si se ha arrancado Truedat (con '-s' o '--start') entra en la session de tmux" "$COLOR_SECONDARY"
            ;;

        "--detach")
            print_message "Si se ha arrancado Truedat (con '-s' o '--start'), para salir de la sesion de tmux sin cerrarla " "$COLOR_SECONDARY"
            ;;

        "--rest")
            print_message "Hace una llamada REST a un api de Truedat que necesite token de login" "$COLOR_SECONDARY"
            print_message "<url>: URL del API" "$COLOR_SECONDARY" 2
            print_message "<rest_method>: Verbo de la llamada del API" "$COLOR_SECONDARY" 2
            print_message "<params>: Parámetros de la llamada (opcional)" "$COLOR_SECONDARY" 2 "after"
            ;;

        "--start-containers")
            print_message "Levanta los contenedores de Truedat" "$COLOR_SECONDARY"
            ;;
            
        "--start-services")
            print_message "Levanta los servicios de Truedat" "$COLOR_SECONDARY"
            ;;
            
        "--start-front")
            print_message "Levanta el frontal de Truedat" "$COLOR_SECONDARY"
            ;;
            
        "--all")
            print_message "Se lanzan todas las opciones abajo descritas." "$COLOR_SECONDARY"
            print_message "Si se desea lanzar Truedat completo, pero se necesita visualizar terminales de servicios en concreto" "$COLOR_SECONDARY"
            print_message "Hay que lanzar 'trus -s <servicio1>, <servicio2> ...' (sin el prefijo 'td-')" "$COLOR_SECONDARY"
            ;;
            
        "--download-test")
             print_message "Descarga SOLO el backup de la bdd de test" "$COLOR_SECONDARY"
            ;;
            
        "--download-update")
             print_message "Además de descargar el backup de test, lo aplica a las bdd locales" "$COLOR_SECONDARY"
            ;;
            
        "--local-update")
             print_message "Aplica a las bdd locales el backup de una carpeta indicada" "$COLOR_SECONDARY"
            ;;
            
        "--local-backup")
             print_message "Crea un backup de la bdd local" "$COLOR_SECONDARY"
            ;;
            
        "--back")
             print_message "Actualiza los repositorios de back" "$COLOR_SECONDARY"
            ;;
            
        "--front")
             print_message "Actualiza los repositorios de front" "$COLOR_SECONDARY"
            ;;
            
        "--libs")
             print_message "Actualiza los repositorios de librerias" "$COLOR_SECONDARY"
            ;;

        "*" | "")
            print_header "Ayuda"    
            print_semiheader "Acciones principales"

            print_message "-s | --start: "  "$COLOR_SECONDARY" 1 "no" 
            print_message "Arranca Truedat. Levanta los contenedores de Docker, crea una sesion de Screen por servicio y arranca el frontal." "$COLOR_TERNARY" 
            print_message "Cada accion se realiza en una terminal creada con Tmux. Los parámetros disponibles son:" "$COLOR_TERNARY" 2
            print_message "- <servicios>: Lista de uno o mas servicios que arrancaran en consolas por separado en Tmux. El resto se lanzan en segundo plano con Screen" "$COLOR_QUATERNARY" 3 "after"

            print_message "-sc | --start-containers: " "$COLOR_SECONDARY" 1 "no"
            print_message "Levanta los contenedores de Docker de Truedat" "$COLOR_TERNARY"

            print_message "-ss | --start-services: " "$COLOR_SECONDARY" 1 "no"
            print_message "Levanta los servicios de Truedat. Los parámetros disponibles son:" "$COLOR_TERNARY"
            print_message "<vacío> | <servicio> | <servicio1> <servicio2> <servicio3>...:" "$COLOR_QUATERNARY" 2 
            print_message "Sin nada, levanta todos los servicios. Con uno o varios servicios (sin el prefijo 'td-') levanta todos los servicios, IGNORANDO los servicios indicados (para poder arrancarlos manualmente)" "$COLOR_QUATERNARY" 2 

            print_message "-st | --stop-services":   "$COLOR_SECONDARY" 1 "no"
            print_message "Para los servicios de Truedat" "$COLOR_TERNARY" 
            print_message "<vacío>: Para todos los servicios" "$COLOR_QUATERNARY" 2 
            print_message "<servicio> | <servicio1> <servicio2> <servicio3>...: Para uno o varios servicios indicados (sin el prefijo 'td-')" "$COLOR_QUATERNARY" 2  "after"

            print_message "-sf | --start-front: " "$COLOR_SECONDARY" 1 "no"
            print_message "Levanta el frontal de Truedat" "$COLOR_TERNARY"

            print_message "-k | --kill: " "$COLOR_SECONDARY" 1 "no"
            print_message "Mata las sesiones creadas con --start (Screen, Tmux) y los procesos de mix que haya" "$COLOR_TERNARY" 

            print_semiheader "Instalación, actualización y mantenimiento"

            print_message  "-i | --install: " "$COLOR_SECONDARY" 1 "no" 
            print_message "Instala Truedat en el equipo. " "$COLOR_TERNARY" 0 "no"
            print_message "Requisitos previos a la instalación: " "$COLOR_TERNARY" 
            print_message "- Configuración AWS: Un administrador de AWS te tiene que dar de alta y pasarte el 'Access Key' y el Secret Access Key'" "$COLOR_QUATERNARY" 2
            print_message "- ~/.kube/config: Debido a que contiene info sensible, no se puede meter en el script para que se cree automaticamente." "$COLOR_QUATERNARY" 2
            print_message "Alguien del equipo debe pasartelo" "$COLOR_WARNING" 3 "both"
            print_message "- Claves SSH: Tienes que tener creada una clave SSH (el script chequea que la clave se llame 'truedat'). La puedes crear con 'trus -cr'" "$COLOR_QUATERNARY" 2
            print_message "RECUERDA que tiene que estar registrada en el equipo y en Gitlab ANTES de la instalación." "$COLOR_ERROR" 3 "after"

            print_message "-d | --ddbb: " "$COLOR_SECONDARY" 1 "no" 
            print_message "Descarga la base de datos de test al equipo. Los parámetros disponibles son:" "$COLOR_TERNARY"
            print_message "-d | --download-test: Descarga SOLO el backup de la bdd de test" "$COLOR_QUATERNARY" 2 
            print_message "-du | --download-update: Además de descargar el backup de test, lo aplica a las bdd locales" "$COLOR_QUATERNARY" 2
            print_message "-lu | --local-update: Aplica a las bdd locales el backup de una carpeta indicada" "$COLOR_QUATERNARY" 2 
            print_message "-lb | --local-backup: Crea un backup de la bdd local" "$COLOR_QUATERNARY" 2 "after" "after"

            print_message "-r | --reindex: " "$COLOR_SECONDARY" 1 "no"
            print_message "Reindexa los indices de Elasticsearch. Los parámetros disponibles son:" "$COLOR_TERNARY"
            print_message " -r: Borra los indices existentes antes de reindexar" "$COLOR_QUATERNARY" 2 


            print_message "-ur | --update-repos: " "$COLOR_SECONDARY" 1 "no"
            print_message "Actualiza todos los repositorios de Truedat (front y back)." "$COLOR_TERNARY"
            print_message "-b | --back | -f | --front | -l | --libs | -a | --all: Actualiza los repos indicados (Elegir una opción)" "$COLOR_QUATERNARY" 2  "after"


            print_semiheader "Importantes, pero no tanto"

            print_message "-cs | --create_ssh: " "$COLOR_SECONDARY" 1 "no" 
            print_message "Hace backup de las claves ssh existentes en ~/.ssh, crea unas nuevas y las registra" "$COLOR_TERNARY"
            print_message "Siempre busca las claves llamadas 'truedat'. Si ya exis te una, hace un backup, borra y crea una nueva." "$COLOR_ERROR" 2 "after" 

            print_message "-kr | --kong-routes: " "$COLOR_SECONDARY" 1 "no"
            print_message "Actualiza las rutas de Kong" "$COLOR_TERNARY" 

            print_message "-l | --link-modules: " "$COLOR_SECONDARY" 1 "no"
            print_message "Linkea los modulos de td-web-modules con td-web" "$COLOR_TERNARY"

            print_message "-yt | --yarn-test: " "$COLOR_SECONDARY" 1 "no"
            print_message "Lanza los test del frontal paquete a paquete, Los parámetros disponibles son:" "$COLOR_TERNARY" 
            print_message "- <paquetes>: Lista de uno o mas paquetes a los que lanzar los test. Si no se indica, se lanza en todos." "$COLOR_QUATERNARY" 2  "after"

            print_message "-ls | --load-structures: " "$COLOR_SECONDARY" 1 "no"
            print_message "Carga estructuras a partir de csv. Los parámetros son:" "$COLOR_TERNARY" 
            print_message "<path>: Ruta de la carpeta de los csv. Debe haber 2, uno llamado 'relations.csv' y otro llamado 'structures.csv'" "$COLOR_QUATERNARY" 2
            print_message "<system>: El external id del sistema en Truedat" "$COLOR_QUATERNARY" 2  "after"

            print_message "-ll | --load-linage: " "$COLOR_SECONDARY" 1 "no"
            print_message "Carga linages a partir de csv. Los parámetros son:" "$COLOR_TERNARY" 
            print_message "<path>: Ruta de la carpeta de los csv. Debe haber 2, uno llamado 'nodes.csv' y otro llamado 'rels.csv'" "$COLOR_QUATERNARY" 2 "after"

            print_message "--rest: " "$COLOR_SECONDARY" 1 "no"
            print_message "Hace llamadas sencillas que necesitan token de login a APIs usando curl. Los parámetros son:" "$COLOR_TERNARY" 
            print_message "<url>: URL del API" "$COLOR_QUATERNARY" 2
            print_message "<rest_method>: Verbo de la llamada del API" "$COLOR_QUATERNARY" 2
            print_message "<params>: Parámetros de la llamada (opcional)" "$COLOR_QUATERNARY" 2 "after"

            print_message "-at | --attach: " "$COLOR_SECONDARY" 1 "no"
            print_message "Si se ha arrancado Truedat (con '-s' o '--start') entra en la session de tmux" "$COLOR_TERNARY" 

            print_message "-dt | --detach: " "$COLOR_SECONDARY" 1 "no"
            print_message "Si se ha arrancado Truedat (con '-s' o '--start'), para salir de la sesion de tmux sin cerrarla " "$COLOR_TERNARY" 
        ;;
    esac 
    
}

main_menu(){
    local option=$(print_menu "${MAIN_MENU_OPTIONS[@]}")
 
    case "$option" in
        "--start")
            start_menu
            ;;

        "--ddbb")
            ddbb_menu
            ;;

        "--update-repos")
            repo_menu
            ;;

        "--kill" | "--help" )
            trus "$option"
            ;;
            
        "Más..." )
            secondary_menu
            ;;
                        
        "Salir")
            clear
            tput reset
            exit 0
            ;;
    esac
}

secondary_menu(){
    local option=$(print_menu "${SECONDARY_MENU_OPTIONS[@]}")

    case "$option" in
        "--reindex" | "--create_ssh" | "--kong-routes" | "--link-modules" | "--yarn-test" | "--load-structures" | "--load-linage" | "--rest" | "--attach" | "--detach")
            trus "$option"
            ;;
        "Volver")
            main_menu
            ;;
    esac
}

start_menu(){
    local option=$(print_menu "${START_MENU_SUBOPTIONS[@]}")
    
    case "$option" in
        "--start-containers" | "--start-services" | "--start-front")
            trus "$option"
            ;;
        
        "--all")
            trus -s
            ;;

        "Volver")
            main_menu
            ;;
        "*")
            echo "option => $option"
            ;;
    esac
}

ddbb_menu(){
    local option=$(print_menu "${DDBB_MENU_SUBOPTIONS[@]}")
    
    case "$option" in
        "--download-test")
            trus -d -d
            ;;

        "--download-update")
            trus -d -du
            ;;

        "--local-update")
            trus -d -lu
            ;;

        "--local-backup")
            trus -d -lb
            ;;

        "Volver")
            main_menu
            ;;
        "*")
            echo "option => $option"
            ;;
    esac
}

repo_menu(){
    local option=$(print_menu "${REPO_MENU_SUBOPTIONS[@]}")
    case "$option" in
        "--back")
            trus -ur -b
            ;;

        "--front")
            trus -ur -f
            ;;

        "--libs")
            trus -ur -l
            ;;

        "--all")
            trus -ur -a
            ;;

        "Volver")
            main_menu
            ;;
        "*")
            echo "option => $option"
            ;;
    esac
}

check_parameters() {    
    good_parameters="false"
    local command="$1"
    local parameter1=$(normalize_text "$2")
    local parameter2=$(normalize_text "$3")
    local parameter3=$(normalize_text "$4")
    
    case "$command" in
        "-i" | "--install" | "-s" | "--start" | "-k" | "--kill" | "-r" | "--reindex" | "-l" | "--link-modules" | "-kr" | "--kong-routes" | "-sc" | "--start-containers" | "-sf" | "--start-front" | "-dt" | "--dettach" | "-at" | "--attach" |"-cs" | "--create_ssh" | "-h" | "--help" )
            good_parameters="true"
            ;;

        "-d" | "--ddbb")
            case "$parameter1" in
                "-d" | "--download-test" | "-du" | "--download-update" | "-lu" | "--local-update" | "-lb" | "--local-backup" )                
                    good_parameters="true"
            esac
            ;; 
        
        "-ur" | "--update-repos" )
            case "$parameter1" in
                "-b" | "--back" | "-f" | "--front" | "-l" | "--libs" | "-a" | "--all" )                    
                    good_parameters="true"
            esac
            ;;

        "-ss" | "--start-services" )    
            if [ -n "$parameter1" ]; then
                local valid_services=true
                for service in $parameter1; do
                    local service_name=${service#"td-"}
                    
                    if [[ "$service" != "$service_name" ]] && ! [[ "${SERVICES[*]}" =~ ${service_name} ]]; then
                        valid_services=false
                        break
                    fi
                done

                if [ "$valid_services" = true ]; then
                    good_parameters="true"
                fi
            else
                good_parameters="true"
            fi
            ;;
 
        "-ls" | "--load-structures")
            if [ -n "$parameter1" ] && [ -e "$parameter1" ] && [ -n "$parameter2" ]; then
                good_parameters="true"
            fi
            ;;  

        "-ll" | "--load-linages")
            if [ -n "$parameter1" ] && [ -e "$parameter1" ]; then
                good_parameters="true"
            fi
            ;;  

        "--rest" )
             if [ ! -z "$parameter1" ] && [ ! -z "$parameter2" ]; then
                good_parameters="true"
            fi
            ;;   

        "-yt" | "--yarn-test")
                local valid_packages=true
                for package in $parameter1; do
                    local package_name=${package#"td-"}
                    
                    if [[ "$package" != "$package_name" ]] && ! [[ "${packageS[*]}" =~ ${package_name} ]]; then
                        valid_packages=false
                        break
                    fi
                done
                if [ "$valid_packages" = true ]; then
                    good_parameters="true"
                fi
            ;;
        esac    
}

 
#########################################
####         Lógica inicial
#########################################

# para mostrar mensajes, descomentar el false, para que solo salgan los mensajes propios de trus, comentarlo (o poner true)
source tools "Truedat Utils (TrUs)" "" "DOT" false "$HEADER_LOGO" "trus"
source $TRUS_PATH_CONFIG

set_vars
set_terminal_config

clear


if ! [ -e "$TRUS_PATH" ]; then 
    print_message "Trus no está instalado" "$COLOR_ERROR" 4 "both"
elif [ -z "$1" ]; then
    print_truedat_logo
    sleep 0,3
    print_header
    main_menu
else
    params=()  
    
    check_parameters "$1" "$2" "$3" 

    if [ "$good_parameters" = "true" ]; then
        case "$1" in               
            "-i" | "--install" )
                install
                ;;

            "-s" | "--start")
                shift  
                start_truedat "$@"
                ;;
        
            "-d" | "--ddbb")
                ddbb "$2"
                ;;

            "-r" | "--reindex")
                reindex_all $(normalize_text "$2")
                ;;

            "-k" | "--kill")
                kill_truedat
                ;;

            "-cs" | "--create_ssh")
                create_ssh        
                ;;

            "-ur" | "--update-repos")
                update_repositories "$2" "$3"
                ;;

            "-l" | "--link-modules")
                link_web_modules
                ;;

            "-kr" | "--kong-routes")
                kong_routes
                ;;

            "-h" | "--help")
                help $2
                ;;

            "-sc" | "--start-containers")
                start_containers
                ;;

            "-ss" |"--start-services")
                shift  
                header="$1"
                shift
                params_echo="${*}"  
                start_services "$header" "$params_echo"  
                ;;
            
            "-sf" |"--start-front")
                start_front "$1"
                ;;  

            "-ls" | "--load-structures")
                load_structures "$2" "$3"
                ;;  

            "-ll" | "--load-linages")
                load_linages "$2"
                ;;

            "--rest")
                do_api_call "$2" "$3" "$4"
                ;;

            "-at" | "--attach")
                go_to_session
                ;;

            "-dt" | "--dettach")
                go_out_session
                ;;

            "-yt" | "--yarn-test")
                shift
                yarn_test "$@"
                ;;
            
        esac
    fi    
fi