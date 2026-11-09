$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
docker compose -f (Join-Path $repoRoot 'infra\docker-compose.yml') down
