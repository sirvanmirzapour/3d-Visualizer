$path = "test/services/bluetooth/bluetooth_connection_service_test.dart"
$lines = Get-Content $path
$count = $lines.Count
Write-Host "Total: $count"
for ($i = 1; $i -le 5; $i++) {
    $idx = $count - $i
    Write-Host ("Line {0} ({1}): {2}" -f (308 - $i), $idx, $lines[$idx - 1])
}
