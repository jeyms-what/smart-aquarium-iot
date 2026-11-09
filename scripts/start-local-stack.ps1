$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repoRoot 'infra\mosquitto\passwordfile'))) {
  throw 'Mosquitto passwordfile not found. Run .\scripts\setup-local-mqtt.ps1 first.'
}
docker compose -f (Join-Path $repoRoot 'infra\docker-compose.yml') up -d
