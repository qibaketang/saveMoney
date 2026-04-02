$ErrorActionPreference = 'Stop'

$missing = @()
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += 'Node.js' }
if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) { $missing += 'npm' }
if (-not (Get-Command flutter.bat -ErrorAction SilentlyContinue)) { $missing += 'Flutter' }

function Test-MongoLocal {
  return (Test-NetConnection -ComputerName localhost -Port 27017 -WarningAction SilentlyContinue).TcpTestSucceeded
}

$envPath = Join-Path $PSScriptRoot '..\..\backend\.env'
$mongoUri = $null

if (Test-Path $envPath) {
  $uriLine = Get-Content $envPath | Where-Object { $_ -match '^MONGODB_URI=' } | Select-Object -First 1
  if ($uriLine) {
    $mongoUri = $uriLine.Substring('MONGODB_URI='.Length).Trim()
  }
}

if (-not $mongoUri) {
  $missing += 'MONGODB_URI in backend/.env'
} elseif ($mongoUri -match 'localhost|127\.0\.0\.1') {
  $mongoOk = Test-MongoLocal
  if (-not $mongoOk) {
    $mongoService = Get-Service -Name 'MongoDB' -ErrorAction SilentlyContinue
    if ($mongoService -and $mongoService.Status -ne 'Running') {
      try {
        Start-Service -Name 'MongoDB'
        Start-Sleep -Seconds 2
        $mongoOk = Test-MongoLocal
        if ($mongoOk) {
          Write-Host 'MongoDB service started automatically'
        }
      } catch {
        Write-Host 'MongoDB service exists but could not be started automatically'
      }
    }
  }

  if (-not $mongoOk) { $missing += 'MongoDB(localhost:27017)' }
} else {
  Write-Host 'Remote MongoDB URI detected in backend/.env'
}

if ($missing.Count -gt 0) {
  Write-Error ('Missing/Unavailable: ' + ($missing -join ', '))
  exit 1
}

Write-Host 'Environment check passed'