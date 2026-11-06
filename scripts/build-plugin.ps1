[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    # Si se indica, copia la DLL a la solución desempaquetada (p. ej. AXZ_Core)
    [string]$Solution,

    # Versión de build para FileVersion (AssemblyVersion se mantiene en 1.0.0.0)
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$project = Join-Path $root 'plugins/Axz.Plugins/Axz.Plugins.csproj'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw 'dotnet SDK no encontrado.' }
if (-not (Test-Path (Join-Path $root 'plugins/Axz.Plugins/axazure.snk'))) { throw 'Falta plugins/Axz.Plugins/axazure.snk: el ensamblado debe ir firmado.' }

$buildArgs = @('build', $project, '-c', $Configuration, '--nologo')
if ($Version) { $buildArgs += "-p:FileVersion=$Version" }

Write-Host "Compilando ($Configuration)..." -ForegroundColor Cyan
& dotnet @buildArgs
if ($LASTEXITCODE -ne 0) { throw "La compilación falló (código $LASTEXITCODE)." }

$dll = Get-ChildItem (Join-Path $root "plugins/Axz.Plugins/bin/$Configuration") -Recurse -Filter 'Axz.Plugins.dll' | Select-Object -First 1
if (-not $dll) { throw 'No se encontró Axz.Plugins.dll tras compilar.' }

$name = [System.Reflection.AssemblyName]::GetAssemblyName($dll.FullName)
$token = ($name.GetPublicKeyToken() | ForEach-Object { $_.ToString('x2') }) -join ''
if (-not $token) { throw 'El ensamblado no está firmado (sin PublicKeyToken).' }

Write-Host "OK: $($dll.FullName)" -ForegroundColor Green
Write-Host "    Version=$($name.Version) PublicKeyToken=$token"

if ($Solution) {
    $dest = Get-ChildItem (Join-Path $root "solutions/$Solution/src/PluginAssemblies") -Recurse -Filter 'Axz.Plugins.dll' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dest) { throw "No hay Axz.Plugins.dll en solutions/$Solution/src/PluginAssemblies. Registra y exporta el plugin primero." }
    Copy-Item $dll.FullName $dest.FullName -Force
    Write-Host "Copiada a $($dest.FullName)" -ForegroundColor Green
}
