$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configDir = Join-Path $repoRoot 'infra\mosquitto'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Docker was not found. Install and start Docker Desktop first.'
}

Write-Host 'Create the local MQTT backend account.' -ForegroundColor Cyan
docker run --rm -it -v "${configDir}:/mosquitto/config" eclipse-mosquitto:2 mosquitto_passwd -c /mosquitto/config/passwordfile aquarium_backend
if ($LASTEXITCODE -ne 0) { throw 'Failed to create backend MQTT password.' }

Write-Host 'Create the local aquarium_001 device account.' -ForegroundColor Cyan
docker run --rm -it -v "${configDir}:/mosquitto/config" eclipse-mosquitto:2 mosquitto_passwd /mosquitto/config/passwordfile aquarium_001
if ($LASTEXITCODE -ne 0) { throw 'Failed to create device MQTT password.' }

Write-Host 'Password file created. Copy the backend password into backend/.env as MQTT_PASSWORD.' -ForegroundColor Green
Write-Host 'Use the aquarium_001 password later for device provisioning. Do not commit these credentials.'
