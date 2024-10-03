¡Nuevo! Combinaciones de teclas … Las combinaciones de teclas de Drive se han actualizado para que puedas navegar escribiendo las primeras letras


___
# General
## Proyectos reporting
- Proyecto "sin asignacion": 821 - TMUI Active Learning
- Proyecto "Energya": 646 - Energya AM 2021/2022
- Proyecto "Truedat": 97 - ISDevTDDGCore

## Cursos aprovados actualmente
- 1026 - BigData y Spark: Ingenieria de datos con Python y PySpark
- 1094 - Curso completo de Data Science en Python desde 0 [2023]
- 464 - The complete Elixir and Phoenix bootcamp


___
# Linux
## Modificar tamaño de la swap
1. Desactiva la swap: ****sudo** swapoff /swapfile**
2. Crea nuevo archivo de swap de 16GB (el 16 es el tamaño, pones el que quieras): **sudo fallocate -l 16G /swapfile**
3. Asigna permisos de acceso solo al usuario root al archivo de swap: **sudo chmod 600 /swapfile**
4. Formatea el archivo swap como un espacio de intercambioi: **sudo mkswap /swapfile**
5. Activa la swap: **sudo swapon /swapfile**
6. Para que los cambios sean permanentes, edite el archivo /etc/fstab: **echo '/swapfile swap swap sw 0 0' | sudo tee -a /etc/fstab**


### Otros apuntes
Estado de la swap: **sudo swapon --show**
Estado de la ram y de la swap: **free -h**
Borrado de la swap (por si al cambiarla sigue con el tamaño antiguo, se borra y se relanza el comando de arriba): **sudo rm /swapfile**
### Comando para vagos (a veces hay que desactivar la swap por un lado y lo demas por otro)
**sudo swapoff /swapfile && sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile swap swap sw 0 0' | sudo tee -a /etc/fstab**

## Kubernetes (de Guille)
Esto se utiliza cuando queremos ver los logs de test
1. Listar pods de kubernetes
- Lo primero que hay que hacer es listar los pods, para poder ver el *NAME* del pod al que queremos conectarnos:

        **kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" get pods**
2. Despues nos conectaremos al pod: 

        **kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" exec -it dd-6db797d977-kl8gz    /bin/bash**
3. Podemos mirar los logs de un pod: 
   
        **kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" logs -f dd-757cf99cd8-82rpf **
4. Tambien podemos conectarnos a la terminal del pod para, por ejemplo, lanzar comandos en su iex: 

kubectl get secrets postgres -o json | jq '.data | map_values(@base64d)'
para ver usuario y contrasña

 "PGDATABASE": "postgres",
  "PGHOST": "postgres",
  "PGPASSWORD": "1",
  "PGUSER": "pgadmin"

para conectarse a las bdd de test
kubectl port-forward svc/haproxy-rds 5432

1º paramos el contenedor de postgres
2º lanzamos:
    kubectl port-forward svc/haproxy-rds 5432
3º conectamos a bdd como hacemos en dev

        **bin/td_dd remote**
local CONTEXT="test-truedat-eks"
local PSQL=$(kubectl get pods -l run=psql -o name | cut -d/ -f2)    
kubectl --context "${CONTEXT}" exec "${PSQL}" -- pg_dump -d "td_dd" -U "pgadmin" -f "td_dd_dev.sql" -S postgres -x -Ofkube


## Docker
para parar los contenedores y borrarlos
~~~
#!/bin/bash
sudo docker stop $(sudo docker ps -a -q)

# Delete all containers
sudo docker rm $(sudo docker ps -a -q)

# Delete all images
sudo docker rmi -f $(sudo docker images -q)
~~~
Si queremos hacerlo solo con un contenedor, solo hay que hacer al principio los comandos que se lanzan dentro del $() (*sudo docker ps -a -q* y *sudo docker images -q*) y meter el id que deseemos.


___
# GIT
- Ver los archivos modificados de la rama: **git satus**
- Crea una nueva rama y cambia a ella: **git checkout -b "NombreDeRama"**
- Añadir archivos al commit (stage changes) => Si haces "git add ." se añaden todos los archivos modificados: **git add <archivo>**
- Subir cambios a la rama local => (a) Añade los ficheros (m) comentario del commit: **git commit -am "Comentario"**
- Cambia a la rama: **git checkout "rama"**
- Saca los cambios de la rama, como un shelve de TFS, para poder moverte a otra rama o lo que sea. Admite hacer varios que se meten en una pila: **git stash**
- Volcar los cambios que llevé a stash. Se van soltando como una pila: **git stash pop**
- Vaciar la pila: **git stash drop**
- Traer todo de master (no sé si a la rama en la que estoy): **git pull origin master**
- Borrar rama (local): **git branch -D <NOMBRE_RAMA>**
- Borrar rama (local): **git push origin --delete <NOMBRE_RAMA>**
- Prefijos para commits ([link|[https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c7116]):
    - feat: (new feature for the user, not a new feature for build script)
    - fix: (bug fix for the user, not a fix to a build script)
    - docs: (changes to the documentation)
    - style: (formatting, missing semi colons, etc; no production code change)
    - refactor: (refactoring production code, eg.  sudo docker stop $(sudo docker ps -a -q)

renaming a variable)
    - test: (adding missing tests, refactoring tests; no production code change)
    - chore: (updating grunt tasks etc; no production code change)

___
# TrueDat
Antes de arrancar la aplicación, recuerda dar permisos al sock de docker (solo cada vez que arranque el pc): **sudo chmod 666 /var/run/docker.sock**
Por si es necesario logearse en aws: **aws ecr get-login-password --profile truedat --region eu-west-1 | sudo docker login --username AWS --password-stdin 576759405678.dkr.ecr.eu-west-1.amazonaws.com**


### Arrancar aplicación
1. Arrancar contenedores: **true-dev/run.sh**
2. Actualiza los servicios: **back/update_all.sh**
3. Para arrancar el back (elixir): **back/launch_all.sh**
4. Para arrancar front (react): **front/td-web/yarn start**
5. Parar contenedores: **true-dev/stop.sh**


### Otros scripts e info
Para hacer backup de la db local: **dump_local_db.sh**
Para hacer dump de test y ponermelo en local (Despues de esto, es muy recomendable reindexar todo): **get_ddbb_test.sh**
Reindexa todo elasticsearch: **reindex_all.sh**
Actualiza los servicios (git): **update_all.sh**
Desde **back/kong-setup**, lanzar: ++scripts/entrypoint.sh** (para cuando se modifican los endpoints)
Mostrar todos los logs de la carpeta según se generan la carpeta "logs" se crea al arrancar): **tail -f -n 1 ***
Url local: **localhost:8080**
Reindexar una implementacion (desde iex): **TdDq.search.Indexer.reindex_implementations([implementation_id])**

___
# Cuando se termina una tarea
1. Formateo de codigo: 
**- mix format**

2. Comprobaciones de buenas practicas
**- mix credo --strict**

3. Subir a git cambios
**git commit -am "comentario"**

4. Modificar changeset y hacer un commit solo con eso
**git commit -am "chore: <jira> Update changelog"**

___
# Tagear version
lanzar update_all.sh
rellenar plantilla tageo        

___
# Elixir  


## Cosas a tener en cuenta
Lo ultimo que haya en un método es lo que devuelve, tanto si es una linea como si es un bloque. Por lo que si lo ultimo que hay son 2 bucles anidados, el resultado será un array de arrays.
Extension: .exs
Extension compilado: .ex
Para compilar: recompile
Para definir un modulo (como una clase): def module do ... end
Para definir un método: def <nombreFuncion>() do ... end
Para que sea privada, poner "defp" en vez de "def"

## Herencia
En elixir no existe. Lo que hay son las siguientes clausulas:
1. import => Copìa las funciones de un modulo y se las mete al otro (algo parecido a la herencia, solo que todo se unifica en un modulo, no hay super())
1. alias => Hace que no tengas que escribir toda la referencia para usar una funcion. Por ejemplo, si pones "alias Enum", despues no te hace falta escribir "Enum.flatten", con poner "flatten" ya lo pilla
ojo, esto permite usar dentro de un módulo funciones de otro, pero si externamente se llama al 1º, pero para usar una funcion del 2º, va a petar porque esas funciones son del 2º y no del 1º
1. use =>  ni idea, pero en el curso dicen que es complejo de usar

## Código
- Bucle: 
for que itera en un array
    for element <- elements do                
    end
    
For que itera en varios arrays (para hacer lo mismo que List.flatten())
    for element <- elements, element2 <- elements2 do                
    end

Nota: Se puede asignar un bucle a una variable para que se quede el resultado directamente (en vez de hacer un .Add8())
            
- Operador pipe (|)
Sirve para encadenar llamadas. Va metiendo el resultado de un método al parámetro del metodo siguiente. 
Se entiende que el parámetro de las siguientes llamadas debe tener la misma estructura que el resultado del método anterior
No hace falta ir metiendo el resultado de un método y meterlo como parámetro. Elixir lo hace solo

En otros lenguajes:
    deck = Cards.create_deck
    deck = Cards.suffle(deck)
    deck = Cards.deal(deck, hand_size)

En elixir, con pipe: 
    Cards.create_deck
    |> Cards.suffle
    |> Cards.deal(hand_size)

En los parámetros de entrada de suffle() y deal() se omite el parámetro deck, porque elixir ya lo mete al usar pipe
OJO: Tanto para el pipe como el pattern matching y otros, se basa en posiciones y que tengan las mismas estructuras.

- Maps
listas clave-valor
Se declaran asi: 
    m = %{key1: "value1",key2: "value2",key3: "value3",key4: "value4"}

Se accede a los valores como si fueran propiedades de un objeto
    m.key1 => value1
    m.key2 => value2
    m.key3 => value3

Se puede trabajar los maps con pattern matching    
    colors = %{primary: "red", secondary: "blue"}
    %{secondary: secondary_color} = colors
    secondary_color => "blue"


## Mix
- mix new <nombre de proyecto> => Para crear nuevo proyecto
- mix deps.get => Baja todas las dependencias que falten segun se configure en la funcion "deps" del archivo - mix.exs
- mix ecto.drop => Borra la base de datos (se configure en algun lado, todavia no se donde)
- mix ecto.create => Crea la base de datos (se configure en algun lado, todavia no se donde)
- mix ecto.gen.migration <nombre> => Genera archivo de migracion
- mix ecto.migrate => Aplica todos los archivos de migración en orden
- mix ecto.rollback => Deshace la ultima migración
- mix phoenix.new <nombre> => Para crear nuevo proyecto de Phoenix
- mix phoenix.start => Arranca el servidor de Phoenix
- mix phx.gen.json carpeta modulo tabla campo:tipo => Crea controller, vista (lo que monta el json), esquema y crea la tabla en postgre
- mix.exs => aliases => Como los alias de Angular, para agrupar comandos en uno solo
- mix.exs: Archivo que se encarga de gestionar los paquetes instalados en el proyecto (del estilo a gradle en android). 
            Tambien es donde se gestiona la version de la aplicacion, el nombre del proyecto, version de elixir, 
            las dependencias se gestiionan en el metodo "deps". Para instalar un nuevo paquete, se mete una tupla (por ejemnplo: {:ex_doc, "~> 0.12"}) en el array de ese método y despues, 
            desde consola, se instala en consola usando "- mix deps get"
- mix test => Pasar todos los test (si se pone iex -S al principio, los lanza con iex activo para cacharrear)        
- mix test <ruta del archivo>:<linea del test en el archivo> - mix test <ruta del archivo>:<linea del test en el archivo>

## Otros
- iex -S phoenix.server => Arrancar servicio con consola para cacharrear
- iex --sname dd -S mix phx.server => Lo mismo que antes, pero conectado al cluster (donde "dd" es el nombre unico para identiicarle)
- require IEX; IEX.pry() => Para el codigo en ejecucion para que, desde la consola, se puedan consultar cosas (no permite debugear como en .NET pero 
puedes revisar)
- |> tap(fn _ -> require IEx; IEx.pry end) Para sacar los datos de una variable (lo de netto)

## Funciones utiles
- Enum.suffle(array) => Mezcla un array
- Enum.member?(array, elemento) => Hace un .Contains (el interrogante solo dice que es probable que el resultado de la funcion devuelva un booleano)
- Enum.split(array, cantidad)=> Parte un array en 2 (devuelve una tupla con 2 elementos. El primero con la cantidad indicada y el segundo con el resto)
- List.flatten (array) => Recibe un arraay de arrays y devuelve un array con todos los elementos de todos los arrays
- Map.put(map, :key, "value") => Para meter una nueva key con el value indicado. La key debe ir con :
- Map.update(map, key, "value") => Para actualizar el value de una key en un mapa 
    Hay otra manera de hacerlo, pero la key debe existir en el mapa (si no, da error):
        %{map | key: "value} 
- Enum.chunk(array, 3): Divide el array en trozos de 3 (devuelve un array de arrays). Si hay elementos sobrantes (al final no puede hacerse un lote de 3), se eliminan
- array ++ nuevo_array: al poner el ++ se concatenan los 2 arrays
- kernel.++ => Para hacerlo en un pipe
- Enum.filter(array, fn(x) -> rem(x, 2) == 0 end): Filtra el array segun el resultado de la funcion (el resultado es booleano)
- Enum.map(array, func) => itera por los elementos, lanzando la funcion en cada elemento y devuelve un array resultante
- Enum.each => como Enum.map pero sin devolver array
- Repo.to_sql(:all, <query>) => Para ver que consulta sql genera ecto

## Pattern Matching
Al asignar valor a una variable, se pueden asignar valores a varias metiendolas en una estructura siempre y cuando esa estructura de origen sea la misma que la de destino

    color = "rojo"

    [color] = ["rojo"] => es lo mismo que lo anterior, 

    color = ["rojo"] => Es parecido, solo que en vez de asignar un string "rojo", asigna un array que solo tiene un string con el valor "rojo"

    {color1, color2} = {"rojo", "azul"} => Seria como hacer lo 1º 2 veces, una por variable


Aqui hay que tener en cuenta que, si uno de los elementos de destino es un atomo, en el origen debe haber el mismo atomo
    
    {:ok, datos} = {:ok, ["datos"]} => va ok

    {:error, mensaje} = {:ok, "mensaje"} => da error porque en destino tengo :error y en origen tengo :ok

Se puede usar pattertn matching tambien en case:
    case File.read(filename) do
        {:ok, binary} -> :erlang.binary_to_term binary
        {:error, _mensaje} -> "Archivo no existe" # la barra baja indica que esa variable no se va a usar, solo está porque hace falta para el pattern matching
    end



## Documentacion
- Hay que instalar ex_doc (ver mas arriba)
- Para generar la documentacion, en consola: - mix docs => Genera un html con la misma estetica que la documentacion de elixir
- Hay que describir lo que hace el módulo y lo que hace cada funcion. Para los modulos, despues de defmodule; para las funciones, antes del def: 

~~~
     @doc """
        Descripción

        ##Examples
            Con esta marca se genera un bloque en el html para escribir código
    """
~~~


## Tests
Al lanzar el recompile en el proyecto, se crea una carpeta llamada "test". Esto crea un archivo "test_helper.exs" para
la configuración global y luego un archivo "<modulo>_test.exs" por cada archivo (modulo) que haya en el proyecto

Para lanzar las pruebas: - mix test
Al principio del módulo de tests, hay esta linea:
    doctests Cards

assert: Afirma que la expresion es correcta (true)
refute: Rechaza la validez de la expresion (false)


Es para lanzar los tests con los códigos que se hayan puesto en los ejemplos. Para testear tanto el código como los comentarios 
Para ello, el comentario debe ir con el siguiente formato:

comentario Examples, una linea vacia y la siguiente con tres tabulaciones

~~~
@doc """
    Descripción de lo que hace la funcion 

    ## Examples
            <codigo>
"""
~~~


___
# Phoenix

## Crear proyecto
- Instalar
    * Elixir
    * Phoenix: - mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
    * Herramientas de phoenix (el servidor, para generar archivos y demas) - mix archive.install hex phx_new
### Crear proyecto 
**
- mix phx.new <nombre>
**

___
# Cluster
- Para añadir al cluster:
- td-cluster:
    En lib/td_cluster/cluster añadir fichero que represente al servicio. Por ejemplo:
    - para td-lm => lib/td_cluster/cluster/td_lm.ex
      Ese archivo, tendrá este contenido:
~~~
defmodule TdCluster.Cluster.TdLm do
@moduledoc """
Cluster handler for TdLm
"""

alias TdCluster.ClusterHandler

def list_relations(params \\ %{}) do
    call_lm(TdLm.Resources, :list_relations, [params])
end

defp call_lm(module, function, args), do: ClusterHandler.call(:lm, module, function, args)
end
~~~
    "list_relations" será la funcion que se utilizará desde otro servicio cuando se quiera usar esa funcion de LM. Se recibirán los parmámetros que se deseen y se llamara a "call_lm".
            "call_lm" es una funcion privada que se encargará de llamar, a traves de "ClusterHandler" a la funcion del servicio.
                1º parámetro: Será el contenedor del modulo donde se encuentra la funcion
                2º parámetro: un átomo con el nombre de la funcion que se quiere usar
                3º parámetro: los parámetros que tiene que recibir dicha funcion

    Servicio a suscribir (en el ejemplo, td-lm)
            mix.exs => Apuntar td-cluster al path local para que pille los cambios que estamos haciendo
            config/config.exs => Añadir las siguientes lineas despues del "mix.env()" del servicio
                config :td_cluster, :env, Mix.env()
                config :td_cluster, groups: [:lm]

                Con esto, le decimos al cluster que estamos disponibles, con el alias :lm, el cual será el mismo que se usa en "ClusterHandler.call"
            En la carpeta "test" creamos una carpeta llamada "td_cluster" y dentro, un archivo llamado "cluster_td_lm_test.exs". Aqui hay que meter un test por cada funcion que se exponga al cluster, para verificar que si se modifica algo que afecte a esa funcion, no sé está jodiendo la del cluster (tambien deberia haber donde proceda, un test a esa funcion directamente, sin pasar por el cluster)

    Tests
        A la hora de hacer tests, hay que simular la llamada al cluster, de la misma manera que ocurre con ElasticSearch. Se hace de la siguiente manera:
            En td-cluster: En la carpeta "test_helpers" crear un archivo llamado "td_lm_mock.ex". Ese archivo contendrá lo siguiente:

            defmodule TdCluster.TestHelpers.TdLmMock do
                @moduledoc """
                Mocks Clusters for tests
                """
              
                def list_relations(expect, params, expected) do
                  expect.(MockClusterHandler, :call, 1, fn :lm, TdLm.Resources, :list_relations, [arg]
                                                           when arg == params ->
                    expected
                  end)
                end
              end

            Conm 
            
            Esto permitirá crear mocks para los tests.  Cuando queramos simular una llamada al cluster:
                TdLmMock.list_relations(
                  &Mox.expect/4,
                  %{resource_type: "implementation", resource_id: 123},
                  [%{relation_id: 1}]
                )

    Por ultimo, para utilizar el cluster, se hace asi:
        def get_implementation_relations do
            TdCluster.Cluster.TdLm.list_relations(%{resource_type: "implementation", resource_id: 123})
        end

            






___
# PostgreSQL
## Query para consultar datos de un campo JSONB[]
~~~
select distinct id
from (
	select *, jsonb_array_elements(unnest("content") -> 'fields') ->> 'type' as tipo_campo  
	from templates t
) x
where
	 tipo_campo = 'hierarchy'
 

select x.*
from templates t

left join (
			SELECT id, unnest(content) ->> 'name'  as group_name, content
			FROM templates
			where scope = 'bg'	   
		  ) x on t.id = x.id and x.group_name is not null and group_name = 'df_description_group_migrate'
where 
	--scope = 'bg'	and 
	x.id is not null


/*
	{
    "name": "Grupo 1",
    "fields": [
        {
            "name": "Jerar",
            "type": "hierarchy",
            "label": "Jerarquias ",
            "values": {
                "hierarchy": 8
            },
            "widget": "dropdown",
            "default": "",
            "cardinality": "?",
            "subscribable": false
        }
    ]
}
*/
~~~



___
# Screen
sudo apt install screen
link simbolico
    sudo ln -s ~/workspace/truedat/true-dev/td.sh /usr/local/bin/td

screen -r <servicio> => entrar a la terminal
ctrl + a + d (dentro del screen) salir sin cerrar
td start <servicio> 
td stop <servicio> 
td status

#!/bin/bash
 
all_services=(audit auth bg dd df i18n ie lm qx se)

declare -A startcommands

truedat_home="~/workspace/truedat/back"
 
startcommands=(
    [audit]='iex --sname audit -S mix phx.server'
    [auth]='iex --sname auth -S mix phx.server'
    [bg]='iex --sname bg -S mix phx.server'
    [dd]='iex --sname dd -S mix phx.server'
    [df]='iex --sname df -S mix phx.server'
    [i18n]='iex --sname i18n -S mix phx.server'
    [ie]='iex --sname ie -S mix phx.server'
    [lm]='iex --sname lm -S mix phx.server'
    [qx]='iex --sname qx -S mix phx.server'
    [se]='iex --sname se -S mix phx.server'
)
 
if [ "$#" -eq 1 ]; then
    if [ "$1" = "start" ] || [ "$1" = "stop" ] || [ "$1" = "restart" ]; then
        services=(${all_services[@]})
    elif [ "$1" = "status" ]; then
        screen -ls
    else
        echo "COMMAND not valid: can be start, stop or status"
        exit 1
    fi
elif [ "$#" -eq 2 ]; then
    if [ "$1" = "attach" ]; then
        screen -r "td-$2"
    elif [ "$1" = "start" ] || [ "$1" = "stop" ] || [ "$1" = "restart" ]; then
        services=("${@:2}")
    else
        echo "invalid command attach"
        exit 1
    fi
elif [ "$#" -gt 1 ]; then
    services=("${@:2}")
else
    echo "Usage: td COMMAND [SERVICE...]"
    echo "COMMAND can be start, stop or status"
    echo "SERVICE one or serveral from:"
    echo "\t${all_services[@]}"
fi

# https://unix.stackexchange.com/a/47279
for service in ${services[@]}; do
    if [ "$1" = "stop" ] || [ "$1" = "restart" ]; then
        echo "Stopping session for $service: "
        screen -ls | grep $service | awk '{print $1}' | xargs -I % screen -X -S % quit
    fi
 
    if [ "$1" = "start" ] || [ "$1" = "restart" ]; then
        echo "Starting session for $service: "
        # https://stackoverflow.com/questions/34595150/execute-bash-after-terminating-webpack-dev-server
        # https://unix.stackexchange.com/a/47279
        # El trap SIGINT es por si ejecutamos Ctrl-C, y el ";exec zsh" final es por
        # si el programa termina de forma normal (con exit 0, o pulsando Ctrl-\, etc).
        screen -h 10000 -mdS "td-$service" bash -c "cd $truedat_home/td-$service && ${startcommands[$service]}"
    fi
done




Para hacer el flujo de aprovacion y que se creen los grants
    Solicitar con un usuario sin permisos (romualdo_data_consumer)
    Aprovar con un usuario con permisos (romualdo_data_manager)
    Lanzar postman => {{url}}/api/grant_requests/:grant_request_id/status
        approved → processing
        processing → processed
        processing → failed (si hace falta)
    Lanzar postman => {{url}}/api/data_structures/:data_structure_external_id/grants
        ojo, aqui no se actualiza el grant_id en el grant_request


Para subir estructuras


clear 

token="eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhbXIiOlsicHdkIl0sImF1ZCI6InRydWVkYXQiLCJlbnRpdGxlbWVudHMiOlsicCJdLCJleHAiOjE3MDg2OTIzNjYsImdyb3VwcyI6W10sImlhdCI6MTcwODYwNTk2NiwiaXNzIjoidGRhdXRoIiwianRpIjoiMnVyMzA0bzFlb3VhbXRlbTRzMDAwMDBjIiwibmJmIjoxNzA4NjA1OTY2LCJyb2xlIjoiYWRtaW4iLCJzdWIiOiJ7XCJpZFwiOjEsXCJ1c2VyX25hbWVcIjpcImFkbWluXCJ9IiwidXNlcl9uYW1lIjoiYWRtaW4ifQ.bK7PogSeaOc_sHua9X4EeXBDQpD7j1oKsxQ0VKLdyXi2tGP5QnH575odw3Fz_Q-wli6ix6XNJBfog7pYfa5tHA"
 
cd ~/Escritorio/sigma/Microstrategy/catalog/CRM && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/IBIS && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/ILAB && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/Laboratoire && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/MDM && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/ME && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata

cd ~/Escritorio/sigma/Microstrategy/catalog/Master\ Data/ && curl -X POST -H "Authorization: Bearer ${token}" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/microstrategy/metadata




para subir linajes

curl -X PUT -H "Authorization: Bearer " -F 'nodes=@nodes.csv' -F 'rels=@rels.csv' http://localhost:4005/api/units/test



cd /home/lorenzosanchez/Escritorio/Oracle/catalog 

curl -X POST -H "Authorization: Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhbXIiOlsicHdkIl0sImF1ZCI6InRydWVkYXQiLCJlbnRpdGxlbWVudHMiOlsicCJdLCJleHAiOjE3MDg2MTc3NDIsImdyb3VwcyI6W10sImlhdCI6MTcwODUzMTM0MiwiaXNzIjoidGRhdXRoIiwianRpIjoiMnVxdW9kMXUxb2tybWt0MWpvMDAwMDY4IiwibmJmIjoxNzA4NTMxMzQyLCJyb2xlIjoiYWRtaW4iLCJzdWIiOiJ7XCJpZFwiOjEsXCJ1c2VyX25hbWVcIjpcImFkbWluXCJ9IiwidXNlcl9uYW1lIjoiYWRtaW4ifQ.yhpLTGwsSTlZW9lu4eieAjC5ljFgIc8Cvys9ivNdtYTMtjnGcdG5Q52QbSfMUBgiVntTClRRHg789SDEe-nBNg" -F 'data_structures=@structures.csv' -F 'data_structure_relations=@relations.csv' http://localhost:4005/api/systems/oracle/metadata



Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m24
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m25
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m26
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m27
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m28
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m29
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m3
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m30
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m31
Snowflake%3A%2F%2FUS_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET%2FPUBLIC%2F2019_CBG_B08%2FB08134m32



{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC%2FTEST_CONNECTOR/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC%2FTEST_CONNECTOR%2FCUSTKEY/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC%2FTEST_CONNECTOR%2FORDERDATE/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC%2FTEST_CONNECTOR%2FORDERSTATUS/grants
{{url}}/api/data_structures/Snowflake%3A%2F%2FLAGUNARO%2FPUBLIC%2FTEST_CONNECTOR%2FPRICE/grants



 Implementation notes

Needed increase liveness probe value because the migration may take time if there is a lot of data volume




**kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" get pods**
**kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" exec -it dd-6db797d977-kl8gz    /bin/bash**
**kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" logs -f dd-757cf99cd8-82rpf **
kubectl get secrets postgres -o json | jq '.data | map_values(@base64d)'
kubectl port-forward svc/haproxy-rds 5432
kubectl port-forward svc/haproxy-rds 5432
kubectl get pods -l run=psql -o name | cut -d/ -f2)    
kubectl --context "${CONTEXT}" exec "${PSQL}" -- pg_dump -d "td_dd" -U "pgadmin" -f "td_dd_dev.sql" -S postgres -x -Ofkube


kubectl --context "arn:aws:eks:eu-west-1:576759405678:cluster/truedat" logs -f dd-d999f499b-p977q

para arrancar linux si grub arranca en consola y hay que hacerlo a mano

set root=(hd0,gpt2)
linux /boot/vmlinuz-5.15.0-60-generic root=/dev/nvme0n1p2
initrd /boot/initrd.img-5.15.0-60-generic
boot

sudo update-grub
sudo grub-install /dev/nvme0n1
