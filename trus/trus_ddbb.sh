#!/bin/bash

source trus_tools


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

create_empty_ddbb() {
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