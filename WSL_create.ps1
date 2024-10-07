Clear-Host 

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:DistroName = "Ubuntu-24.04"
$script:VhdxName = "Ubuntu24.04"
$script:scriptLocation = $PSScriptRoot
$script:trusSourceFolder = Join-Path $scriptLocation "/trus"
$script:ubuntu_path ="\\wsl$\$DistroName"
$script:backupFilePath = Join-Path $scriptLocation $DistroName"_backup.tar"
$script:packagePath = "C:\Users\$env:UserName\AppData\Local\Packages"

if (-not (Get-Module -ListAvailable -Name "PSWriteColor")) {
    Write-Color -Text "El módulo 'PSWriteColor' no está instalado y es necesario. Instalando..." -Color red -StartTab 2 
    Install-Module -Name "PSWriteColor" -Force -Scope CurrentUser -ErrorAction Stop
}

Write-Color -Text "---------------------------------" -Color DarkCyan -StartTab 3 -LinesBefore 1
Write-Color -Text "--  Instalando Truedat en WSL  --" -Color DarkCyan -StartTab 3 
Write-Color -Text "---------------------------------" -Color DarkCyan -StartTab 3 -LinesAfter 1

Write-Color -Text "-- Seteando WSL a la versión 2..." -Color DarkYellow -StartTab 1 
wsl --set-default-version 1>$null 2>&1


Write-Color -Text "-- Eliminando distro ($DistroName)..." -Color DarkYellow -StartTab 1 
wsl --terminate $DistroName 1>$null 2>&1
wsl --unregister $DistroName 1>$null 2>&1


Write-Color -Text "-- Apagando WSL..." -Color DarkYellow -StartTab 1 
wsl --shutdown 1>$null 2>&1


Write-Color -Text "-- Instalando Ubuntu desde 0. Recuerda qué usuario crearás, hace falta para hacer el backup" -Color DarkYellow -StartTab 1 
wsl --install -d $DistroName


Write-Color -Text "-- Preinstalando TrUs" -Color DarkYellow -StartTab 1 
Write-Color -Text "> INTRODUCE EL USUARIO QUE CREASTE PARA $DistroName" -Color red -StartTab 2 
$userDistro = Read-Host 
$script:ubuntu_home_path = "$ubuntu_path\home\$userDistro"
$script:backupFilePath = Join-Path $scriptLocation $DistroName"_backup.tar"


Write-Color -Text "> Copiando TrUs a $DistroName" -Color DarkYellow -StartTab 2 
Copy-Item -Path "$trusSourceFolder" -Destination "$ubuntu_home_path" -Recurse -Force 1>$null 2>&1

Write-Color -Text "> Preparando distro para primer uso" -Color DarkYellow -StartTab 2 
wsl -d $DistroName sh -c "sudo chmod +x ~/trus/* && sudo apt -qq update  && sudo apt -qq -y upgrade && sudo apt -qq install dos2unix && dos2unix ~/trus/trus.sh "

Write-Color -Text "-- Haciendo Backup por si revienta..." -Color DarkYellow -StartTab 1 
wsl --export $DistroName $backupFilePath 1>$null 2>&1
 
Write-Color -Text "-- Intentando abrir VSCode apuntando a wsl" -Color DarkYellow -StartTab 1 
wsl -d $DistroName sh -c "cd && code ." 1>$null 2>&1

Write-Color -Text "-- Entrando en $DistroName" -Color Green -StartTab 1 
wsl -d $DistroName 


