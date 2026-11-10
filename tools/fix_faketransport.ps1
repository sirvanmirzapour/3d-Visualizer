$path = "test/services/bluetooth/bluetooth_connection_service_test.dart"
$classFile = "tools\FixedFakeTransport.txt"
$newClass = Get-Content $classFile -Raw

$content = Get-Content $path -Raw

$start = $content.IndexOf("class FakeTransport implements BluetoothConnectionTransport {")
if ($start -eq -1) {
    Write-Host "START NOT FOUND"
    exit
}
$endMarker = "FakeBluetoothLink? get link => _link;"
$end = $content.IndexOf($endMarker, $start)
if ($end -eq -1) {
    Write-Host "END NOT FOUND"
    exit
}
$end = $end + $endMarker.Length

$newContent = $content.Substring(0, $start) + $newClass + $content.Substring($end)
$newContent > $path
Write-Host "Fixed FakeTransport class"
