$ErrorActionPreference = 'SilentlyContinue'

$hdc = 'E:\DevEco Studio6.0.1\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
$target = '127.0.0.1:5555'
$mapping = 'tcp:5200 tcp:5200'

while ($true) {
  if (Test-Path -LiteralPath $hdc) {
    $targets = & $hdc list targets 2>$null
    if ($targets -match [regex]::Escape($target)) {
      $ports = & $hdc -t $target fport ls 2>$null
      if ($ports -notmatch 'tcp:5200\s+tcp:5200') {
        & $hdc -t $target rport tcp:5200 tcp:5200 >$null 2>$null
      }
    }
  }
  Start-Sleep -Seconds 3
}
