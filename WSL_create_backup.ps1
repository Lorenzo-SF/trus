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
    Write-Color -Text "El módulo 'PSWriteColor' no está instalado y es necesario. Instalando..." -Color red -StartTab 2 -LinesBefore 2 -LinesAfter 2
    Install-Module -Name "PSWriteColor" -Force -Scope CurrentUser -ErrorAction Stop

}

Write-Color -Text "---------------------------------" -Color DarkCyan -StartTab 3 -LinesBefore 1
Write-Color -Text "--   Aplicando backup  en WSL  --" -Color DarkCyan -StartTab 3 
Write-Color -Text "---------------------------------" -Color DarkCyan -StartTab 3 -LinesAfter 1

Write-Color -Text "> INTRODUCE EL USUARIO QUE CREASTE PARA $DistroName" -Color red -StartTab 2 -LinesBefore 1 -LinesAfter 1
$userDistro = Read-Host 
$script:ubuntu_home_path = "$ubuntu_path\home\$userDistro"
$script:backupFilePath = Join-Path $scriptLocation $DistroName"_backup.tar"

Write-Color -Text "-- Aplicando Backup porque reventó..." -Color DarkYellow -StartTab 1 -LinesBefore 1
wsl --import $DistroName $ubuntu_path $backupFilePath

Write-Color -Text "-- Intentando abrir VSCode apuntando a wsl" -Color DarkYellow -StartTab 1 -LinesBefore 1
wsl -d $DistroName sh -c "cd && code ." 1>$null 2>&1

Write-Color -Text "-- Entrando en $DistroName" -Color Green -StartTab 1 -LinesBefore 1
wsl -d $DistroName 

