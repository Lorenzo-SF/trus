#!/bin/bash

# Preguntar al usuario qué quiere hacer
clear 
echo ''
echo '#####################################'
echo '### Intento de ñapa para solucionar bug "kill signal 9"'
echo '#####################################'
echo ''
echo ''


echo "¿Qué quieres hacer?"
echo "1) Activar optimizaciones"
echo "2) Desactivar optimizaciones"
read -p "Elige una opción (1 o 2): " opcion

# Validar la entrada del usuario
if [[ "$opcion" == "1" ]]; then
    ACTIVAR_OPTIMIZACION=true
    echo "Has elegido activar las optimizaciones."
elif [[ "$opcion" == "2" ]]; then
    ACTIVAR_OPTIMIZACION=false
    echo "Has elegido desactivar las optimizaciones."
else
    echo "Opción no válida. Por favor, elige 1 o 2."
    exit 1
fi

##########################################################################
### Procesos fantasma (Se queda tal cual)

echo ''
echo ''
echo '#####################################'
echo '### Gestor de procesos Fantasma'
echo '#####################################'
echo ''
echo ''


echo "      Desactivar la sincronización para pruebas"
adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
echo "      Verificar"
adb shell "/system/bin/device_config get_sync_disabled_for_tests"

echo "      Ajustar los procesos fantasma al valor máximo"
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
echo "      Verificar"
adb shell "/system/bin/device_config get activity_manager max_phantom_processes"

echo "      Desactivar la monitorización de procesos fantasma (configuración global)"
adb shell settings put global settings_enable_monitor_phantom_procs false
echo "      Verificar"
adb shell settings get global settings_enable_monitor_phantom_procs

echo "      Alternativa para asegurar que el valor esté en 0"
adb shell settings put global settings_enable_monitor_phantom_procs 0
echo "      Verificar"
adb shell settings get global settings_enable_monitor_phantom_procs


##########################################################################
### Termux

echo ''
echo ''
echo '#####################################'
echo '### Termux'
echo '#####################################'
echo ''
echo ''

if [ "$ACTIVAR_OPTIMIZACION" = false ]; then
    echo "      Desactivar la inactividad para Termux"
    adb shell am set-inactive com.termux false
    echo "      Permitir que Termux se ejecute en segundo plano"
    adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
    adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow
    echo "      Añadir Termux a la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist +com.termux
else
    echo "      Activar la inactividad para Termux"
    adb shell am set-inactive com.termux true
    echo "      Prohibir que Termux se ejecute en segundo plano"
    adb shell cmd appops set com.termux RUN_IN_BACKGROUND ignore
    adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND ignore
    echo "      Eliminar Termux de la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist -com.termux
fi
echo "      Verificar"
adb shell dumpsys package com.termux | grep "inactive="
adb shell cmd appops get com.termux RUN_IN_BACKGROUND
adb shell cmd appops get com.termux RUN_ANY_IN_BACKGROUND
adb shell dumpsys deviceidle whitelist | grep com.termux


##########################################################################
### Termux-x11

echo ''
echo ''
echo '#####################################'
echo '### Termux-X11'
echo '#####################################'
echo ''
echo ''

if [ "$ACTIVAR_OPTIMIZACION" = false ]; then
    echo "      Desactivar la inactividad para Termux-X11"
    adb shell am set-inactive com.termux.x11 false
    echo "      Permitir que Termux-X11 se ejecute en segundo plano"
    adb shell cmd appops set com.termux.x11 RUN_IN_BACKGROUND allow
    adb shell cmd appops set com.termux.x11 RUN_ANY_IN_BACKGROUND allow
    echo "      Añadir Termux-X11 a la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist +com.termux.x11
else
    echo "      Activar la inactividad para Termux-X11"
    adb shell am set-inactive com.termux.x11 true
    echo "      Prohibir que Termux-X11 se ejecute en segundo plano"
    adb shell cmd appops set com.termux.x11 RUN_IN_BACKGROUND ignore
    adb shell cmd appops set com.termux.x11 RUN_ANY_IN_BACKGROUND ignore
    echo "      Eliminar Termux-X11 de la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist -com.termux.x11
fi
echo "      Verificar"
adb shell dumpsys package com.termux.x11 | grep "inactive="
adb shell cmd appops get com.termux.x11 RUN_IN_BACKGROUND
adb shell cmd appops get com.termux.x11 RUN_ANY_IN_BACKGROUND
adb shell dumpsys deviceidle whitelist | grep com.termux.x11


##########################################################################
### Winlator

echo ''
echo ''
echo '#####################################'
echo '### Winlator'
echo '#####################################'
echo ''
echo ''

if [ "$ACTIVAR_OPTIMIZACION" = false ]; then
    echo "Desactivar la inactividad para Winlator"
    adb shell am set-inactive com.winlator false
    echo "Permitir que Winlator se ejecute en segundo plano"
    adb shell cmd appops set com.winlator RUN_IN_BACKGROUND allow
    adb shell cmd appops set com.winlator RUN_ANY_IN_BACKGROUND allow
    echo "Añadir Winlator a la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist +com.winlator
else
    echo "Activar la inactividad para Winlator"
    adb shell am set-inactive com.winlator true
    echo "Prohibir que Winlator se ejecute en segundo plano"
    adb shell cmd appops set com.winlator RUN_IN_BACKGROUND ignore
    adb shell cmd appops set com.winlator RUN_ANY_IN_BACKGROUND ignore
    echo "Eliminar Winlator de la lista blanca de optimización de batería"
    adb shell dumpsys deviceidle whitelist -com.winlator
fi
echo "Verificar"
adb shell dumpsys package com.winlator | grep "inactive="
adb shell cmd appops get com.winlator RUN_IN_BACKGROUND
adb shell cmd appops get com.winlator RUN_ANY_IN_BACKGROUND
adb shell dumpsys deviceidle whitelist | grep com.winlator
