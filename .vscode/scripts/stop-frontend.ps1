$ErrorActionPreference = 'SilentlyContinue'

$procs = Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -ieq 'flutter.exe' -or $_.Name -ieq 'dart.exe') -and $_.CommandLine -like '*frontend*'
}

if ($procs) {
  $procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
  Write-Host 'Frontend stopped'
} else {
  Write-Host 'Frontend not running'
}