[CmdletBinding()]
param(
    # GUID del ensamblado ya registrado en el entorno (pluginassemblyid). También vale $env:AXZ_PLUGIN_ID
    [string]$PluginId = $env:AXZ_PLUGIN_ID,

    # URL del entorno destino. Si se omite, se usa el perfil de pac activo
    [string]$EnvironmentUrl,

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    # Evita volver a compilar
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw 'Power Platform CLI (pac) no encontrado. Instálalo con: dotnet tool install --global Microsoft.PowerApps.CLI.Tool'
}
if (-not $PluginId) {
    throw 'Falta el PluginId. Pásalo con -PluginId <guid> o define $env:AXZ_PLUGIN_ID (el ensamblado debe estar registrado antes, con pac tool prt).'
}

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'build-plugin.ps1') -Configuration $Configuration
}

$dll = Get-ChildItem (Join-Path $root "plugins/Axz.Plugins/bin/$Configuration") -Recurse -Filter 'Axz.Plugins.dll' | Select-Object -First 1
if (-not $dll) { throw 'No hay DLL compilada. Ejecuta sin -SkipBuild.' }

if ($EnvironmentUrl) {
    Write-Host "Seleccionando entorno $EnvironmentUrl..." -ForegroundColor Cyan
    & pac auth create --url $EnvironmentUrl
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo autenticar contra el entorno.' }
}

Write-Host 'Entorno activo:' -ForegroundColor Cyan
& pac org who

Write-Host "Publicando $($dll.Name) ($PluginId)..." -ForegroundColor Cyan
& pac plugin push --pluginId $PluginId --pluginFile $dll.FullName --type Assembly --configuration $Configuration
if ($LASTEXITCODE -ne 0) { throw "pac plugin push falló (código $LASTEXITCODE)." }

Write-Host 'Plugin publicado.' -ForegroundColor Green
