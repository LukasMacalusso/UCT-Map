param(
    [string]$BaseUrl = 'http://localhost:8080',
    [switch]$Aplicar
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$campusId = '855f802e-311d-418e-b1a3-80cc2c360625'
$campusName = 'Campus San Juan Pablo II'
if (-not $headers -or -not $headers.Authorization) {
    throw 'Falta $headers con Authorization Bearer JWT. Inicia sesion y configura $headers en esta misma terminal.'
}
function ApiGet([string]$path) {
    return Invoke-RestMethod -Method Get -Uri "$BaseUrl$path" -Headers $headers -ErrorAction Stop
}
function ApiPost([string]$path, [hashtable]$body) {
    $json = ConvertTo-Json -InputObject $body -Depth 8
    return Invoke-RestMethod -Method Post -Uri "$BaseUrl$path" -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($json)) -ErrorAction Stop
}
function AsList($value) {
    if ($null -eq $value) { return @() }
    return @($value)
}
$buildingsCsv = @(Import-Csv (Join-Path $root 'edificios_pendientes.csv') -Encoding UTF8)
$roomsCsv = @(Import-Csv (Join-Path $root 'salas_documento.csv') -Encoding UTF8)
if (@($roomsCsv | Where-Object { $_.codigoSala -notmatch '^CJP\d\d_\d{3}$' }).Count -gt 0) { throw 'CSV contiene codigos de sala inesperados' }
if (@($roomsCsv.codigoSala | Group-Object | Where-Object Count -gt 1).Count -gt 0) { throw 'CSV contiene salas duplicadas' }
$campuses = @(ApiGet '/api/campus/campuses')
$selected = $campuses | Where-Object { $_.id -eq $campusId -and $_.name -eq $campusName } | Select-Object -First 1
if (-not $selected) { throw 'No se encontro San Juan Pablo II con el ID esperado. No se hara ninguna escritura.' }
$categories = @(ApiGet '/api/campus/categories')
$aula = $categories | Where-Object { $_.name -eq 'Aula' } | Select-Object -First 1
if (-not $aula) { throw 'No existe la categoria Aula. No se hara ninguna escritura.' }
$existingBuildings = @(ApiGet "/api/campus/buildings?campusId=$campusId")
$createdBuildings=0; $createdRooms=0; $existingRoomCount=0; $pendingBuildings=0; $failed=0; $plannedRooms=0
$invariant = [Globalization.CultureInfo]::InvariantCulture
foreach ($entry in $buildingsCsv) {
    $names = @($existingBuildings | Where-Object { $_.name -eq $entry.nombre })
    if ($names.Count -gt 1) { Write-Warning "Edificio ambiguo, omitido: $($entry.nombre)"; $failed++; continue }
    $building = if ($names.Count -eq 1) { $names[0] } else { $null }
    if (-not $building) {
        if ($entry.nombre -like '*sin confirmar*' -or [string]::IsNullOrWhiteSpace($entry.latitud) -or [string]::IsNullOrWhiteSpace($entry.longitud) -or [string]::IsNullOrWhiteSpace($entry.pisosConfirmados)) {
            Write-Host "PENDIENTE: Edificio $($entry.numeroEdificio) - $($entry.nombre) (coordenadas/pisos/nombre)"
            $pendingBuildings++
            continue
        }
        try {
            $lat = [double]::Parse($entry.latitud, $invariant)
            $lon = [double]::Parse($entry.longitud, $invariant)
            $floors = [int]::Parse($entry.pisosConfirmados)
            if ($lat -lt -90 -or $lat -gt 90 -or $lon -lt -180 -or $lon -gt 180 -or $floors -lt 1) { throw 'Coordenadas o pisos invalidos' }
            $lastFloor = @($roomsCsv | Where-Object { $_.numeroEdificio -eq $entry.numeroEdificio } | Measure-Object -Property piso -Maximum)[0].Maximum
            if ($lastFloor -and $floors -lt [int]$lastFloor) { throw "Pisos declarados ($floors) menores que los codigos de salas ($lastFloor)" }
            if (-not $Aplicar) {
                Write-Host "SIMULAR EDIFICIO $($entry.numeroEdificio): $($entry.nombre) ($lat, $lon; $floors pisos)"
                $plannedRooms += @($roomsCsv | Where-Object { $_.numeroEdificio -eq $entry.numeroEdificio }).Count
                continue
            }
            $building = ApiPost '/api/campus/buildings' @{
                campusId=$campusId; name=$entry.nombre; floorsCount=$floors;
                latitude=$lat; longitude=$lon; schedule=''; services=@()
            }
            $existingBuildings += $building
            $createdBuildings++
            Write-Host "EDIFICIO CREADO: $($entry.nombre)"
        } catch {
            Write-Warning "ERROR edificio $($entry.numeroEdificio): $($_.Exception.Message)"
            $failed++; continue
        }
    }
    $existingRooms = @(ApiGet "/api/campus/buildings/$($building.id)/rooms")
    $namesInBd = @($existingRooms | ForEach-Object { $_.name })
    foreach ($room in @($roomsCsv | Where-Object { $_.numeroEdificio -eq $entry.numeroEdificio })) {
        if ($namesInBd -contains $room.codigoSala) { $existingRoomCount++; continue }
        if (-not $Aplicar) { Write-Host "SIMULAR SALA $($room.codigoSala)"; $plannedRooms++; continue }
        try {
            $null = ApiPost '/api/campus/rooms' @{
                buildingId=$building.id; categoryId=$aula.id; name=$room.codigoSala;
                floor=[int]$room.piso; number=$room.numeroSala
            }
            $createdRooms++; $namesInBd += $room.codigoSala
            Write-Host "SALA CREADA: $($room.codigoSala)"
        } catch { Write-Warning "ERROR sala $($room.codigoSala): $($_.Exception.Message)"; $failed++ }
    }
}
Write-Host "`nRESUMEN: edificios creados=$createdBuildings | salas creadas=$createdRooms | salas ya existentes=$existingRoomCount | salas simuladas=$plannedRooms | edificios pendientes=$pendingBuildings | errores=$failed"
if (-not $Aplicar) { Write-Host 'SIMULACION: no se realizaron escrituras. Para insertar usa -Aplicar' -ForegroundColor Yellow }
