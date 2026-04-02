$ErrorActionPreference = 'SilentlyContinue'

$procs = Get-CimInstance Win32_Process | Where-Object {
  $_.Name -ieq 'node.exe' -and $_.CommandLine -like '*backend*src\server.js*'
}

if ($procs) {
  $procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
  Write-Host 'Backend stopped'
} else {
  Write-Host 'Backend not running'
}