$f = 'd:\project\3D app\test\services\bluetooth\bluetooth_connection_service_test.dart'
if (Test-Path $f) {
  $c = (Get-Content $f | Measure-Object -Line).Lines
  Write-Host "LINES=$c"
} else {
  Write-Host "MISSING"
}
