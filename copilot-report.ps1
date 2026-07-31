<#
.SYNOPSIS
    Genera un reporte HTML de actividad estimada por usuario de GitHub Copilot.

.DESCRIPTION
  Consulta la Copilot Billing Seats API y la Copilot Usage Metrics Reports API
  para producir un reporte legible para management con métricas de uso por usuario.

.PARAMETER Token
    Personal Access Token de GitHub con scopes: manage_billing:copilot o read:org.
    Pásalo como parámetro o defínelo como variable de entorno GH_TOKEN.

.EXAMPLE
    .\copilot-report.ps1 -Token "ghp_xxxxxxxxxxxx"
    .\copilot-report.ps1   # usa $env:GH_TOKEN si está definido
#>

param(
  [string]$Token = $env:GH_TOKEN,
  [string]$Org = "CleveritDemo",
  [switch]$PromptToken,
  [double]$SeatPriceUsd = 39,
  [double]$VariableCostWeight = 0.30,
  [int]$BillingDaysPerMonth = 30
)

# ── Configuración ─────────────────────────────────────────────────────────────
$ORG      = $Org
$API_VER  = "2026-03-10"
$SINCE    = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddT00:00:00Z")
$UNTIL    = (Get-Date).ToString("yyyy-MM-ddT23:59:59Z")
$OUT_FILE = Join-Path $PSScriptRoot "copilot-report.html"
# ──────────────────────────────────────────────────────────────────────────────

if ($PromptToken -or -not $Token) {
  $secureToken = Read-Host "Ingresa tu GitHub Token (entrada oculta)" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
  try {
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

if (-not $Token) {
  Write-Error "Token no encontrado. Usa -PromptToken, -Token o define la variable de entorno GH_TOKEN."
  exit 1
}

if ($VariableCostWeight -lt 0 -or $VariableCostWeight -gt 1) {
  Write-Warning "VariableCostWeight fuera de rango [0..1]. Se ajustará a 0.30 por defecto."
  $VariableCostWeight = 0.30
}

if ($BillingDaysPerMonth -le 0) {
  Write-Warning "BillingDaysPerMonth debe ser > 0. Se ajustará a 30 por defecto."
  $BillingDaysPerMonth = 30
}

$headers = @{
    "Accept"               = "application/vnd.github+json"
    "Authorization"        = "Bearer $Token"
    "X-GitHub-Api-Version" = $API_VER
}

Write-Host "Modo seguro habilitado: el script realiza SOLO operaciones de lectura (HTTP GET). No crea, edita ni elimina datos en tu organización." -ForegroundColor DarkCyan

$script:LastApiError = $null
$script:ApiAudit = @()

function Get-SafeUrlForAudit {
  param([string]$Url)
  try {
    $uri = [System.Uri]$Url
    if ($uri.Host -eq "api.github.com") {
      return "$($uri.Scheme)://$($uri.Host)$($uri.AbsolutePath)"
    }

    # Para links firmados externos, no exponer query string ni firma.
    return "$($uri.Scheme)://$($uri.Host)$($uri.AbsolutePath)"
  }
  catch {
    return $Url
  }
}

function Add-AuditEntry {
  param(
    [string]$Method,
    [string]$Url,
    [int]$StatusCode,
    [string]$Result
  )

  $script:ApiAudit += [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Method = $Method
    Url = (Get-SafeUrlForAudit -Url $Url)
    StatusCode = $StatusCode
    Result = $Result
  }
}

function Invoke-GHApi {
    param([string]$Url)
    try {
    $script:LastApiError = $null
        $resp = Invoke-RestMethod -Uri $Url -Headers $headers -Method GET -ErrorAction Stop
    Add-AuditEntry -Method "GET" -Url $Url -StatusCode 200 -Result "OK"
        return $resp
    }
    catch {
    $resp = $_.Exception.Response
    $code = if ($resp) { [int]$resp.StatusCode } else { -1 }
    $sso = if ($resp -and $resp.Headers["X-GitHub-SSO"]) { $resp.Headers["X-GitHub-SSO"] } else { $null }

    $script:LastApiError = [PSCustomObject]@{
      StatusCode = $code
      Url = $Url
      SsoHeader = $sso
    }

    Add-AuditEntry -Method "GET" -Url $Url -StatusCode $code -Result "ERROR"

        Write-Warning "Error $code al consultar: $Url"

    if ($code -eq 401) {
      Write-Warning "Token inválido o expirado."
    }
    if ($code -eq 403) {
      Write-Warning "Sin permisos. Verifica scopes del token (manage_billing:copilot o read:org)."
    }
    if ($code -eq 404) {
      Write-Warning "404 suele indicar: token sin autorización SSO para la organización, usuario no owner de la org, o Copilot Business/Enterprise no habilitado."
      if ($sso) {
        Write-Warning "Tu token requiere autorización SSO para la org. Revisa 'Configure SSO' en GitHub para este PAT."
      }
    }
        if ($code -eq 422) { Write-Warning "La API de Copilot Usage Metrics no está habilitada o no hay datos disponibles para el período." }
        return $null
    }
}

    function Invoke-ReportDownload {
      param([string]$Url)
      $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) ("copilot-usage-" + [guid]::NewGuid().ToString() + ".bin")
      try {
        $resp = Invoke-WebRequest -Uri $Url -Method GET -OutFile $tmpFile -PassThru -ErrorAction Stop
        $bytes = [System.IO.File]::ReadAllBytes($tmpFile)
        Add-AuditEntry -Method "GET" -Url $Url -StatusCode 200 -Result "OK"

        $contentType = ""
        if ($resp.Headers -and $resp.Headers["Content-Type"]) {
          $contentType = "" + $resp.Headers["Content-Type"]
        }

        $contentEncoding = ""
        if ($resp.Headers -and $resp.Headers["Content-Encoding"]) {
          $contentEncoding = "" + $resp.Headers["Content-Encoding"]
        }

        return [PSCustomObject]@{
          Url = $Url
          Bytes = $bytes
          ContentType = $contentType
          ContentEncoding = $contentEncoding
        }
      }
      catch {
        $statusCode = -1
        if ($_.Exception.Response) {
          try {
            $statusCode = [int]$_.Exception.Response.StatusCode
          }
          catch {
            $statusCode = -1
          }
        }
        Add-AuditEntry -Method "GET" -Url $Url -StatusCode $statusCode -Result "ERROR"
        Write-Warning "No se pudo descargar reporte desde link firmado: $Url"
        return $null
      }
      finally {
        if (Test-Path $tmpFile) {
          Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        }
      }
    }

    function ConvertTo-Int {
      param($Value)
      if ($null -eq $Value) { return 0 }
      try { return [int64]$Value } catch { return 0 }
    }

    function Parse-JsonContent {
      param([string]$Content)

      $items = @()
      if ([string]::IsNullOrWhiteSpace($Content)) { return $items }

      # Intenta JSON completo primero.
      try {
        $parsed = $Content | ConvertFrom-Json -ErrorAction Stop
        if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
          $items += @($parsed)
        } else {
          $items += $parsed
        }
        return $items
      }
      catch {
      }

      # Fallback JSONL (una línea = un objeto JSON).
      foreach ($line in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
          $items += ($line | ConvertFrom-Json -ErrorAction Stop)
        }
        catch {
        }
      }

      return $items
    }

    function Get-TextFromBytes {
      param([byte[]]$Bytes)

      if (-not $Bytes -or $Bytes.Length -eq 0) {
        return ""
      }

      $payloadBytes = $Bytes

      # gzip magic bytes: 1F 8B
      if ($payloadBytes.Length -ge 2 -and $payloadBytes[0] -eq 0x1F -and $payloadBytes[1] -eq 0x8B) {
        try {
          $inStream = New-Object System.IO.MemoryStream(,$payloadBytes)
          $gzipStream = New-Object System.IO.Compression.GzipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
          $outStream = New-Object System.IO.MemoryStream
          $gzipStream.CopyTo($outStream)
          $gzipStream.Dispose()
          $inStream.Dispose()
          $payloadBytes = $outStream.ToArray()
          $outStream.Dispose()
        }
        catch {
          return ""
        }
      }

      try {
        return [System.Text.Encoding]::UTF8.GetString($payloadBytes)
      }
      catch {
        return ""
      }
    }

    function Parse-ReportDownload {
      param($Download)

      $items = @()
      if (-not $Download -or -not $Download.Bytes) {
        return $items
      }

      $bytes = $Download.Bytes

      # zip magic bytes: 50 4B 03 04
      if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B -and $bytes[2] -eq 0x03 -and $bytes[3] -eq 0x04) {
        try {
          $zipStream = New-Object System.IO.MemoryStream(,$bytes)
          $zip = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Read)
          foreach ($entry in $zip.Entries) {
            if ($entry.Length -le 0) { continue }

            $entryStream = $entry.Open()
            $reader = New-Object System.IO.StreamReader($entryStream)
            $text = $reader.ReadToEnd()
            $reader.Dispose()
            $entryStream.Dispose()

            $items += Parse-JsonContent -Content $text
          }
          $zip.Dispose()
          $zipStream.Dispose()
          return @($items)
        }
        catch {
          return @()
        }
      }

      $textContent = Get-TextFromBytes -Bytes $bytes
      if ([string]::IsNullOrWhiteSpace($textContent)) {
        return @()
      }

      $items += Parse-JsonContent -Content $textContent
      return @($items)
    }

    function Get-FeatureMetric {
      param(
        $DayTotal,
        [string]$FeaturePattern,
        [string]$PropertyName
      )

      $sum = 0
      if ($DayTotal.totals_by_feature) {
        foreach ($feature in $DayTotal.totals_by_feature) {
          $featureName = "" + $feature.feature
          if ($featureName.ToLower() -match $FeaturePattern) {
            $sum += ConvertTo-Int $feature.$PropertyName
          }
        }
      }
      return $sum
    }

Write-Host "`n[0/4] Verificando usuario autenticado y rol en la organización..." -ForegroundColor Cyan

# Verificar usuario autenticado
$authUser = Invoke-GHApi -Url "https://api.github.com/user"
if (-not $authUser) {
    Write-Error "No se pudo autenticar con el token. Verifica que sea válido y no haya expirado."
    exit 1
}

$username = $authUser.login
Write-Host "      Usuario autenticado: $username" -ForegroundColor Green

# Verificar rol en la organización
$userOrgMembership = Invoke-GHApi -Url "https://api.github.com/user/memberships/orgs/$ORG"
if (-not $userOrgMembership) {
    Write-Error "No se pudo obtener información de membresía en '$ORG'. Verifica que seas miembro de la org."
    exit 1
}

$userRole = $userOrgMembership.role
$orgState = $userOrgMembership.state
Write-Host "      Tu rol en $ORG : $userRole (estado: $orgState)" -ForegroundColor Cyan

if ($userRole -ne "admin") {
    Write-Warning "⚠️  Tu rol es '$userRole', pero necesitas ser 'admin' (owner) para acceder a billing y métricas de Copilot."
    Write-Warning "    Contacta a un owner de la org para que te otorgue acceso, o verifica si tienes otro rol que permita ver estos datos."
}

Write-Host "`n[1/4] Validando acceso a la organización '$ORG'..." -ForegroundColor Cyan
$orgCheck = Invoke-GHApi -Url "https://api.github.com/orgs/$ORG"
if (-not $orgCheck) {
  Write-Error "No se pudo acceder a la organización '$ORG'. Verifica nombre de org y autorización del token (incluyendo SSO)."
  exit 1
}

$billingCheck = Invoke-GHApi -Url "https://api.github.com/orgs/$ORG/copilot/billing"
if (-not $billingCheck) {
  Write-Warning "No se pudo validar configuración de Copilot Billing en la org. El reporte puede salir parcial."
}

Write-Host "[2/4] Consultando seats (usuarios con licencia)..." -ForegroundColor Cyan

$seatsUrl  = "https://api.github.com/orgs/$ORG/copilot/billing/seats?per_page=100"
$seatsData = Invoke-GHApi -Url $seatsUrl
$seats     = @()
$seatsWarning = "No se pudieron obtener los seats. Verifica permisos del token."

if ($seatsData -and $seatsData.seats) {
    $seats = $seatsData.seats
    Write-Host "      Seats encontrados: $($seats.Count)" -ForegroundColor Green
} else {
  if ($script:LastApiError -and $script:LastApiError.StatusCode -eq 404) {
    $seatsWarning = "No se pudieron obtener seats (404). Verifica: 1) token autorizado en SSO (Configure SSO), 2) que seas owner de la org, 3) que la org tenga Copilot Business/Enterprise activo."
  }
    Write-Warning "No se obtuvieron seats. Continuando solo con métricas agregadas."
}

Write-Host "[3/4] Consultando métricas de uso (reportes nuevos de 28 días)..." -ForegroundColor Cyan

$orgUsageManifestUrl = "https://api.github.com/orgs/$ORG/copilot/metrics/reports/organization-28-day/latest"
$userUsageManifestUrl = "https://api.github.com/orgs/$ORG/copilot/metrics/reports/users-28-day/latest"

$metricsWarning = "⚠️ No se obtuvieron métricas de Usage Reports. Posibles causas:<br>
  • La policy <code>Copilot usage metrics</code> no está habilitada<br>
  • El token no tiene permisos necesarios (<code>read:org</code>)<br>
  • No hay datos procesados para el período solicitado"

$totalSuggestions   = 0
$totalAcceptances   = 0
$totalLinesAccepted = 0
$totalChats         = 0
$dailyRows          = @()

$orgManifest = Invoke-GHApi -Url $orgUsageManifestUrl
$orgReportObjects = @()

if ($orgManifest -and $orgManifest.download_links) {
  Write-Host "      Links de reporte org obtenidos: $($orgManifest.download_links.Count)" -ForegroundColor Green

  foreach ($link in $orgManifest.download_links) {
    $download = Invoke-ReportDownload -Url $link
    if (-not $download) { continue }

    if ($download.ContentType -or $download.ContentEncoding) {
      Write-Host "      Formato reporte org: type='$($download.ContentType)' encoding='$($download.ContentEncoding)'" -ForegroundColor DarkGray
    }

    $parsed = Parse-ReportDownload -Download $download
    if ($parsed.Count -gt 0) {
      $orgReportObjects += $parsed
    } else {
      Write-Warning "No se pudo parsear contenido JSON/JSONL del reporte org descargado."
    }
  }
}

$usersManifest = Invoke-GHApi -Url $userUsageManifestUrl
$usersReportObjects = @()

if ($usersManifest -and $usersManifest.download_links) {
  Write-Host "      Links de reporte usuarios obtenidos: $($usersManifest.download_links.Count)" -ForegroundColor Green

  foreach ($link in $usersManifest.download_links) {
    $download = Invoke-ReportDownload -Url $link
    if (-not $download) { continue }

    if ($download.ContentType -or $download.ContentEncoding) {
      Write-Host "      Formato reporte user: type='$($download.ContentType)' encoding='$($download.ContentEncoding)'" -ForegroundColor DarkGray
    }

    $parsed = Parse-ReportDownload -Download $download
    if ($parsed.Count -gt 0) {
      $usersReportObjects += $parsed
    } else {
      Write-Warning "No se pudo parsear contenido JSON/JSONL del reporte user descargado."
    }
  }
}

if ($orgManifest -and $orgManifest.report_start_day) {
  $SINCE = "$($orgManifest.report_start_day)T00:00:00Z"
}
if ($orgManifest -and $orgManifest.report_end_day) {
  $UNTIL = "$($orgManifest.report_end_day)T23:59:59Z"
}

$dayAgg = @{}

foreach ($record in $orgReportObjects) {
  $dayTotals = @()

  if ($record.day_totals) {
    $dayTotals = @($record.day_totals)
  }
  elseif ($record.day -or $record.date) {
    $dayTotals = @($record)
  }

  foreach ($day in $dayTotals) {
    $dayKey = if ($day.day) { "$($day.day)" } elseif ($day.date) { "$($day.date)" } else { $null }
    if (-not $dayKey) { continue }

    $daySugg  = ConvertTo-Int ($day.code_generation_activity_count)
    $dayAcc   = ConvertTo-Int ($day.code_acceptance_activity_count)
    $dayLines = ConvertTo-Int ($day.loc_added_sum)

    $chatFromFeature = Get-FeatureMetric -DayTotal $day -FeaturePattern "chat" -PropertyName "user_initiated_interaction_count"
    $dayChats = if ($chatFromFeature -gt 0) { $chatFromFeature } else { ConvertTo-Int ($day.user_initiated_interaction_count) }

    if ($daySugg -eq 0 -and $day.totals_by_feature) {
      foreach ($feature in $day.totals_by_feature) {
        $daySugg += ConvertTo-Int ($feature.code_generation_activity_count)
        $dayAcc += ConvertTo-Int ($feature.code_acceptance_activity_count)
        $dayLines += ConvertTo-Int ($feature.loc_added_sum)
      }
    }

    $activeUsers = ConvertTo-Int ($day.daily_active_users)
    $engagedUsers = if ($day.weekly_active_users) { ConvertTo-Int $day.weekly_active_users } else { $activeUsers }

    if (-not $dayAgg.ContainsKey($dayKey)) {
      $dayAgg[$dayKey] = [PSCustomObject]@{
        Date = $dayKey
        ActiveUsers = 0
        Engaged = 0
        Suggestions = 0
        Acceptances = 0
        LinesAccepted = 0
        Chats = 0
      }
    }

    $row = $dayAgg[$dayKey]
    $row.ActiveUsers += $activeUsers
    $row.Engaged += $engagedUsers
    $row.Suggestions += $daySugg
    $row.Acceptances += $dayAcc
    $row.LinesAccepted += $dayLines
    $row.Chats += $dayChats
  }
}

if ($dayAgg.Count -gt 0) {
  foreach ($k in ($dayAgg.Keys | Sort-Object)) {
    $r = $dayAgg[$k]
    $acceptRate = if ($r.Suggestions -gt 0) { [math]::Round(($r.Acceptances / $r.Suggestions) * 100, 1) } else { 0 }

    $dailyRows += [PSCustomObject]@{
      Date = $r.Date
      ActiveUsers = $r.ActiveUsers
      Engaged = $r.Engaged
      Suggestions = $r.Suggestions
      Acceptances = $r.Acceptances
      AcceptRate = "$acceptRate%"
      LinesAccepted = $r.LinesAccepted
      Chats = $r.Chats
    }

    $totalSuggestions += $r.Suggestions
    $totalAcceptances += $r.Acceptances
    $totalLinesAccepted += $r.LinesAccepted
    $totalChats += $r.Chats
  }

  Write-Host "      Días consolidados con datos: $($dailyRows.Count)" -ForegroundColor Green
  Write-Host "      Registros org descargados: $($orgReportObjects.Count)" -ForegroundColor Green
  if ($usersReportObjects.Count -gt 0) {
    Write-Host "      Registros user descargados: $($usersReportObjects.Count)" -ForegroundColor Green
  }
} else {
  if ($script:LastApiError -and $script:LastApiError.StatusCode -eq 404) {
    $metricsWarning = "⚠️ No se obtuvieron métricas (404). El endpoint legacy fue retirado. Verifica que tu organización tenga habilitada la policy de Copilot usage metrics para los nuevos reportes."
  }
  Write-Warning "No se obtuvieron métricas consolidadas. El reporte incluirá solo información de seats."
}

$globalAcceptRate = if ($totalSuggestions -gt 0) {
    [math]::Round(($totalAcceptances / $totalSuggestions) * 100, 1)
} else { 0 }

# ── Modelo de costos en USD (estimación contable) ────────────────────────────
$periodDays = 30
try {
  $periodDays = (([datetime]$UNTIL) - ([datetime]$SINCE)).Days + 1
  if ($periodDays -le 0) { $periodDays = 30 }
}
catch {
  $periodDays = 30
}

$seatCount = $seats.Count
$orgMonthlyCostUsd = [math]::Round($seatCount * $SeatPriceUsd, 2)
$orgPeriodCostUsd = [math]::Round($orgMonthlyCostUsd * ($periodDays / $BillingDaysPerMonth), 2)

$baseCostWeight = [math]::Round((1 - $VariableCostWeight), 4)
$baseCostPoolUsd = [math]::Round($orgPeriodCostUsd * $baseCostWeight, 2)
$variableCostPoolUsd = [math]::Round($orgPeriodCostUsd * $VariableCostWeight, 2)

$usageByLogin = @{}
foreach ($u in $usersReportObjects) {
  $login = "" + $u.user_login
  if ([string]::IsNullOrWhiteSpace($login)) { continue }

  $accCount = ConvertTo-Int $u.code_acceptance_activity_count
  $chatCount = ConvertTo-Int $u.user_initiated_interaction_count

  if ($chatCount -eq 0 -and $u.totals_by_feature) {
    foreach ($feature in $u.totals_by_feature) {
      $featureName = ("" + $feature.feature).ToLower()
      if ($featureName -match "chat") {
        $chatCount += ConvertTo-Int $feature.user_initiated_interaction_count
      }
    }
  }

  $interactionCount = $accCount + $chatCount

  if (-not $usageByLogin.ContainsKey($login)) {
    $usageByLogin[$login] = [PSCustomObject]@{
      Login = $login
      Acceptances = 0
      Chats = 0
      Interactions = 0
    }
  }

  $usageByLogin[$login].Acceptances += $accCount
  $usageByLogin[$login].Chats += $chatCount
  $usageByLogin[$login].Interactions += $interactionCount
}

$totalInteractionsAllUsers = 0
foreach ($v in $usageByLogin.Values) {
  $totalInteractionsAllUsers += $v.Interactions
}

$costRows = @()
$seatsSorted = @($seats | Sort-Object { $_.assignee.login })
foreach ($s in $seatsSorted) {
  $login = $s.assignee.login
  $uData = if ($usageByLogin.ContainsKey($login)) { $usageByLogin[$login] } else { $null }

  $uAccept = if ($uData) { $uData.Acceptances } else { 0 }
  $uChats = if ($uData) { $uData.Chats } else { 0 }
  $uInteractions = if ($uData) { $uData.Interactions } else { 0 }

  $baseUsd = if ($seatCount -gt 0) { [math]::Round($baseCostPoolUsd / $seatCount, 2) } else { 0 }
  $variableUsd = if ($totalInteractionsAllUsers -gt 0) {
    [math]::Round($variableCostPoolUsd * ($uInteractions / $totalInteractionsAllUsers), 2)
  } else { 0 }

  $estimatedUsd = [math]::Round($baseUsd + $variableUsd, 2)

  $costRows += [PSCustomObject]@{
    Login = $login
    Acceptances = $uAccept
    Chats = $uChats
    Interactions = $uInteractions
    BaseUsd = $baseUsd
    VariableUsd = $variableUsd
    EstimatedUsd = $estimatedUsd
  }
}

$costRows = @($costRows | Sort-Object EstimatedUsd -Descending)
$costModelWarning = ""
if ($usersReportObjects.Count -eq 0) {
  $costModelWarning = "⚠️ No hubo reporte de usuarios parseado. La distribución queda en modo base por licencia (componente variable = USD 0)."
}
elseif ($totalInteractionsAllUsers -eq 0) {
  $costModelWarning = "⚠️ Se obtuvo reporte de usuarios, pero sin interacciones para el período. La distribución queda en modo base por licencia (componente variable = USD 0)."
}

Write-Host "[4/4] Generando reporte HTML..." -ForegroundColor Cyan

# ── Helpers de HTML ───────────────────────────────────────────────────────────
function Badge {
    param([string]$text, [string]$color = "#4a90d9")
    return "<span style='background:$color;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;font-weight:600'>$text</span>"
}

function StatusBadge {
    param([string]$status)
    $map = @{
        "active"    = "#28a745"
        "pending_invitation" = "#ffc107"
        "inactive"  = "#6c757d"
    }
    $color = if ($map[$status]) { $map[$status] } else { "#6c757d" }
    return Badge -text $status.ToUpper() -color $color
}

# ── Tabla de seats ─────────────────────────────────────────────────────────────
$seatsHtml = ""
if ($seats.Count -gt 0) {
    $rows = ""
    foreach ($s in $seats | Sort-Object { $_.assignee.login }) {
        $login      = $s.assignee.login
        $avatar     = $s.assignee.avatar_url
        $lastActive = if ($s.last_activity_at) {
            $d = [datetime]$s.last_activity_at
            $diff = (Get-Date) - $d
            if ($diff.TotalDays -lt 1)       { "<span style='color:#28a745'>Hoy</span>" }
            elseif ($diff.TotalDays -lt 2)   { "<span style='color:#28a745'>Ayer</span>" }
            elseif ($diff.TotalDays -lt 7)   { "<span style='color:#ffc107'>Hace $([math]::Round($diff.TotalDays)) días</span>" }
            else                             { "<span style='color:#dc3545'>Hace $([math]::Round($diff.TotalDays)) días</span>" }
        } else { "<span style='color:#aaa'>Sin actividad</span>" }

        $editor  = if ($s.last_activity_editor) { $s.last_activity_editor } else { "—" }
        $created = if ($s.created_at) { ([datetime]$s.created_at).ToString("dd/MM/yyyy") } else { "—" }
        $status  = if ($s.pending_cancellation_date) { "pending_cancellation" } else { "active" }

        $rows += @"
        <tr>
          <td style='padding:10px 12px'>
            <img src='$avatar' width='28' height='28' style='border-radius:50%;vertical-align:middle;margin-right:8px'>
            <a href='https://github.com/$login' target='_blank' style='color:#0969da;text-decoration:none;font-weight:600'>$login</a>
          </td>
          <td style='padding:10px 12px;text-align:center'>$(StatusBadge -status $status)</td>
          <td style='padding:10px 12px;text-align:center'>$lastActive</td>
          <td style='padding:10px 12px;text-align:center'>$editor</td>
          <td style='padding:10px 12px;text-align:center'>$created</td>
        </tr>
"@
    }

    $seatsHtml = @"
    <section class='card'>
      <h2>👥 Usuarios con Licencia Copilot <span class='badge'>$($seats.Count) seats</span></h2>
      <p class='subtitle'>Última actividad y estado de cada asiento asignado en la organización.</p>
      <div style='overflow-x:auto'>
        <table>
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Estado</th>
              <th>Última Actividad</th>
              <th>Editor</th>
              <th>Asignado desde</th>
            </tr>
          </thead>
          <tbody>$rows</tbody>
        </table>
      </div>
    </section>
"@
} else {
  $seatsHtml = "<section class='card'><h2>👥 Seats</h2><p class='warning'>$seatsWarning</p></section>"
}

# ── Tabla de métricas diarias ──────────────────────────────────────────────────
$metricsHtml = ""
if ($dailyRows.Count -gt 0) {
    $rows = ""
    foreach ($d in $dailyRows | Sort-Object Date -Descending) {
        $rateColor = if ([double]($d.AcceptRate -replace '%','') -ge 30) { "#28a745" }
                     elseif ([double]($d.AcceptRate -replace '%','') -ge 15) { "#ffc107" }
                     else { "#dc3545" }
        $rows += @"
        <tr>
          <td style='padding:10px 12px;font-weight:600'>$($d.Date)</td>
          <td style='padding:10px 12px;text-align:center'>$($d.ActiveUsers)</td>
          <td style='padding:10px 12px;text-align:center'>$($d.Engaged)</td>
          <td style='padding:10px 12px;text-align:right'>$($d.Suggestions.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:right'>$($d.Acceptances.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:center'><span style='color:$rateColor;font-weight:700'>$($d.AcceptRate)</span></td>
          <td style='padding:10px 12px;text-align:right'>$($d.LinesAccepted.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:right'>$($d.Chats.ToString("N0"))</td>
        </tr>
"@
    }

    $metricsHtml = @"
    <section class='card'>
      <h2>📊 Métricas Diarias de Uso (últimos 30 días)</h2>
      <p class='subtitle'>Actividad agregada por día. La tasa de aceptación indica qué porcentaje de sugerencias fueron aceptadas por los desarrolladores.</p>
      <div style='overflow-x:auto'>
        <table>
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Usuarios Activos</th>
              <th>Usuarios Engaged</th>
              <th>Sugerencias</th>
              <th>Aceptadas</th>
              <th>Tasa Aceptación</th>
              <th>Líneas Aceptadas</th>
              <th>Chats</th>
            </tr>
          </thead>
          <tbody>$rows</tbody>
        </table>
      </div>
    </section>
"@
} else {
    $metricsHtml = @"
    <section class='card'>
      <h2>📊 Métricas Diarias</h2>
      <p class='warning'>$metricsWarning</p>
    </section>
"@
}

# ── KPI Cards ─────────────────────────────────────────────────────────────────
$kpiHtml = @"
    <section class='kpi-grid'>
      <div class='kpi-card'>
        <div class='kpi-icon'>💺</div>
        <div class='kpi-value'>$($seats.Count)</div>
        <div class='kpi-label'>Seats Activos</div>
      </div>
      <div class='kpi-card'>
        <div class='kpi-icon'>💡</div>
        <div class='kpi-value'>$($totalSuggestions.ToString("N0"))</div>
        <div class='kpi-label'>Sugerencias Generadas</div>
      </div>
      <div class='kpi-card'>
        <div class='kpi-icon'>✅</div>
        <div class='kpi-value'>$($totalAcceptances.ToString("N0"))</div>
        <div class='kpi-label'>Sugerencias Aceptadas</div>
      </div>
      <div class='kpi-card'>
        <div class='kpi-icon'>📈</div>
        <div class='kpi-value'>$globalAcceptRate%</div>
        <div class='kpi-label'>Tasa de Aceptación</div>
      </div>
      <div class='kpi-card'>
        <div class='kpi-icon'>📝</div>
        <div class='kpi-value'>$($totalLinesAccepted.ToString("N0"))</div>
        <div class='kpi-label'>Líneas de Código Aceptadas</div>
      </div>
      <div class='kpi-card'>
        <div class='kpi-icon'>💬</div>
        <div class='kpi-value'>$($totalChats.ToString("N0"))</div>
        <div class='kpi-label'>Conversaciones de Chat</div>
      </div>
    </section>
"@

# ── Tabla de costo estimado por usuario (USD) ─────────────────────────────────
$costRowsHtml = ""
foreach ($c in $costRows) {
  $costRowsHtml += @"
        <tr>
          <td style='padding:10px 12px;font-weight:600'>$($c.Login)</td>
          <td style='padding:10px 12px;text-align:right'>$($c.Acceptances.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:right'>$($c.Chats.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:right'>$($c.Interactions.ToString("N0"))</td>
          <td style='padding:10px 12px;text-align:right'>USD $($c.BaseUsd.ToString("N2"))</td>
          <td style='padding:10px 12px;text-align:right'>USD $($c.VariableUsd.ToString("N2"))</td>
          <td style='padding:10px 12px;text-align:right;font-weight:700;color:#0969da'>USD $($c.EstimatedUsd.ToString("N2"))</td>
        </tr>
"@
}

$costWarningHtml = ""
if ($costModelWarning) {
  $costWarningHtml = "<p class='warning' style='margin-top:12px'>$costModelWarning</p>"
}

$costHtml = @"
    <section class='card'>
      <h2>💵 Estimación de Costo por Usuario (USD)</h2>
      <p class='subtitle'>Modelo de asignación contable para management: combina costo base por licencia y componente variable por uso.</p>

      <div class='kpi-grid' style='margin-bottom:16px'>
        <div class='kpi-card'>
          <div class='kpi-icon'>🏷️</div>
          <div class='kpi-value'>USD $([math]::Round($SeatPriceUsd,2).ToString("N2"))</div>
          <div class='kpi-label'>Precio Licencia Mensual</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>📦</div>
          <div class='kpi-value'>USD $($orgMonthlyCostUsd.ToString("N2"))</div>
          <div class='kpi-label'>Costo Org Mensual (Seats x Precio)</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>🗓️</div>
          <div class='kpi-value'>USD $($orgPeriodCostUsd.ToString("N2"))</div>
          <div class='kpi-label'>Costo Prorrateado del Período ($periodDays días)</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>⚖️</div>
          <div class='kpi-value'>$([math]::Round($VariableCostWeight*100,0))%</div>
          <div class='kpi-label'>Peso Variable por Uso</div>
        </div>
      </div>

      <div style='background:#f6f8fa; border-radius:8px; padding:14px; border-left:4px solid #0969da; margin-bottom:14px'>
        <p style='font-size:13px; line-height:1.7'>
          <strong>Fórmula de asignación (no facturación oficial por usuario):</strong><br>
          Costo usuario = Base + Variable<br>
          Base = (Costo período × $("{0:P0}" -f $baseCostWeight)) / seats<br>
          Variable = (Costo período × $("{0:P0}" -f $VariableCostWeight)) × (interacciones_usuario / interacciones_totales)
        </p>
      </div>

      <div style='overflow-x:auto'>
        <table>
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Aceptaciones</th>
              <th>Chats</th>
              <th>Interacciones</th>
              <th>USD Base</th>
              <th>USD Variable</th>
              <th>USD Estimado</th>
            </tr>
          </thead>
          <tbody>$costRowsHtml</tbody>
        </table>
      </div>
      $costWarningHtml
    </section>
"@

# ── Estimación de consumo por usuario ─────────────────────────────────────────
$estimationHtml = ""

# Contar usuarios activos (última actividad reciente)
$activeUsers = @()
if ($seats.Count -gt 0) {
    $cutoffDate = (Get-Date).AddDays(-7)  # Activos en últimos 7 días
    $activeUsers = @($seats | Where-Object { 
        if ($_.last_activity_at) {
            [datetime]$_.last_activity_at -gt $cutoffDate
        } else {
            $false
        }
    })
}

$totalAcceptances = 0
$totalChats = 0
$totalEngagedUsers = 0

if ($dailyRows.Count -gt 0) {
    $totalAcceptances = ($dailyRows | Measure-Object -Property Acceptances -Sum).Sum
    $totalChats = ($dailyRows | Measure-Object -Property Chats -Sum).Sum
    $totalEngagedUsers = ($dailyRows | Measure-Object -Property Engaged -Maximum).Maximum
}

if ($activeUsers.Count -eq 0) {
    $activeUserCount = $seats.Count
} else {
    $activeUserCount = $activeUsers.Count
}

if ($activeUserCount -eq 0) { $activeUserCount = 1 }  # Evitar división por cero

$consumoRelativo = ($totalAcceptances + $totalChats) / $activeUserCount
$consumoPromedio = [math]::Round($consumoRelativo, 2)

$estimationHtml = @"
    <section class='card'>
      <h2>📈 Estimación de Consumo por Usuario</h2>
      <p class='subtitle'>Cálculo de consumo relativo usando datos agregados de la organización.</p>
      
      <div class='kpi-grid' style='margin-bottom:24px'>
        <div class='kpi-card'>
          <div class='kpi-icon'>👤</div>
          <div class='kpi-value'>$activeUserCount</div>
          <div class='kpi-label'>Usuarios Activos (7 días)</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>✅</div>
          <div class='kpi-value'>$($totalAcceptances.ToString("N0"))</div>
          <div class='kpi-label'>Aceptaciones Totales</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>💬</div>
          <div class='kpi-value'>$($totalChats.ToString("N0"))</div>
          <div class='kpi-label'>Conversaciones Totales</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>📊</div>
          <div class='kpi-value'>$consumoPromedio</div>
          <div class='kpi-label'>Consumo por Usuario</div>
        </div>
      </div>

      <div style='background:#f6f8fa; border-radius:8px; padding:16px; margin-bottom:16px; border-left:4px solid #0969da'>
        <p style='font-size:13px; line-height:1.8; color:#57606a; font-family:monospace'>
          <strong>Fórmula utilizada:</strong><br>
          Consumo relativo = (aceptaciones + chats) ÷ usuarios_activos<br>
          Consumo relativo = ($totalAcceptances + $totalChats) ÷ $activeUserCount = <strong style='color:#0969da;font-size:15px'>$consumoPromedio</strong>
        </p>
      </div>

      <div style='font-size:13px; line-height:1.6; color:#57606a'>
        <p><strong>Interpretación:</strong></p>
        <p style='margin-top:8px'>En los últimos 30 días, cada usuario activo generó o participó en un promedio de <strong>$consumoPromedio interacciones</strong> (aceptaciones de sugerencias + conversaciones de chat). Este es el proxy más cercano disponible en la API de GitHub para estimar consumo relativo, ya que no se exponen tokens de LLM por usuario.</p>
        <p style='margin-top:8px'><em>Nota:</em> Las métricas de uso están agregadas a nivel organización. Un consumo más alto puede indicar mayor adopción de Copilot y mejores prácticas de pair programming con IA.</p>
      </div>
    </section>
"@

# ── Nota metodológica ──────────────────────────────────────────────────────────
$totalApiCalls = $script:ApiAudit.Count
$failedApiCalls = @($script:ApiAudit | Where-Object { $_.Result -eq "ERROR" }).Count
$okApiCalls = $totalApiCalls - $failedApiCalls
$writeCalls = @($script:ApiAudit | Where-Object { $_.Method -match "POST|PUT|PATCH|DELETE" }).Count

$auditRows = ""
if ($totalApiCalls -gt 0) {
    foreach ($entry in ($script:ApiAudit | Select-Object -Last 25)) {
        $statusColor = if ($entry.Result -eq "OK") { "#28a745" } else { "#dc3545" }
        $statusText = if ($entry.StatusCode -ge 0) { "$($entry.Result) ($($entry.StatusCode))" } else { "$($entry.Result)" }

        $auditRows += @"
        <tr>
          <td style='padding:8px 10px'>$($entry.Timestamp)</td>
          <td style='padding:8px 10px;text-align:center'><code>$($entry.Method)</code></td>
          <td style='padding:8px 10px'><code style='font-size:12px'>$($entry.Url)</code></td>
          <td style='padding:8px 10px;text-align:center'><span style='color:$statusColor;font-weight:700'>$statusText</span></td>
        </tr>
"@
    }
}

$auditHtml = @"
    <section class='card'>
      <h2>🛡️ Auditoría de Ejecución (Solo Lectura)</h2>
      <p class='subtitle'>Evidencia técnica para compliance: este script usa exclusivamente operaciones HTTP GET.</p>

      <div class='kpi-grid' style='margin-bottom:16px'>
        <div class='kpi-card'>
          <div class='kpi-icon'>🌐</div>
          <div class='kpi-value'>$totalApiCalls</div>
          <div class='kpi-label'>Llamadas HTTP Totales</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>✅</div>
          <div class='kpi-value'>$okApiCalls</div>
          <div class='kpi-label'>GET Exitosas</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>⚠️</div>
          <div class='kpi-value'>$failedApiCalls</div>
          <div class='kpi-label'>GET con Error</div>
        </div>
        <div class='kpi-card'>
          <div class='kpi-icon'>🔒</div>
          <div class='kpi-value'>$writeCalls</div>
          <div class='kpi-label'>Operaciones de Escritura</div>
        </div>
      </div>

      <div class='warning' style='margin-bottom:14px'>
        <strong>Resultado de auditoría:</strong> Operaciones de escritura (POST/PUT/PATCH/DELETE) = <strong>$writeCalls</strong>. Valor esperado para este script: <strong>0</strong>.
      </div>

      <div style='overflow-x:auto'>
        <table>
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Método</th>
              <th>Endpoint</th>
              <th>Resultado</th>
            </tr>
          </thead>
          <tbody>$auditRows</tbody>
        </table>
      </div>
      <p class='subtitle' style='margin-top:10px'>Se muestran hasta 25 llamadas recientes. Los links firmados se enmascaran sin query string para seguridad.</p>
    </section>
"@

$noteHtml = @"
    <section class='card note'>
      <h2>📋 Nota Metodológica</h2>
      <ul>
        <li><strong>Fuente de datos:</strong> GitHub Copilot Usage Metrics Reports API (v$API_VER) y Billing Seats API.</li>
        <li><strong>Período analizado:</strong> $($SINCE.Substring(0,10)) al $($UNTIL.Substring(0,10)) (últimos 30 días).</li>
        <li><strong>Tokens quemados:</strong> La API de GitHub Copilot <em>no expone tokens de LLM por usuario</em>. Las métricas disponibles son: sugerencias, aceptaciones, líneas y chats.</li>
        <li><strong>Actividad por usuario:</strong> El campo <code>last_activity_at</code> de cada seat es el proxy más preciso disponible. Las métricas de uso (sugerencias/chats) son <em>agregadas a nivel organización</em>, no desglosadas por usuario individual.</li>
        <li><strong>Tasa de aceptación:</strong> Principal KPI de efectividad. Un valor ≥ 30% se considera excelente en la industria.</li>
        <li><strong>Consolidación:</strong> El script descarga todos los <code>download_links</code> de reportes de organización y usuarios, y consolida los días en un único dataset.</li>
        <li><strong>Seguridad:</strong> El script ejecuta únicamente operaciones HTTP <code>GET</code> (solo lectura). No modifica configuración, licencias ni usuarios de la organización.</li>
        <li><strong>Estimación de consumo:</strong> Se calcula como (aceptaciones + chats) ÷ usuarios_activos. Esta es la <em>alternativa viable</em> más cercana para estimar consumo por usuario cuando no hay datos de tokens de LLM disponibles en la API.</li>
      </ul>
    </section>
"@

# ── HTML completo ──────────────────────────────────────────────────────────────
$generatedAt = Get-Date -Format "dd/MM/yyyy HH:mm"
$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reporte GitHub Copilot — $ORG</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f6f8fa; color: #1f2328; }

    header {
      background: linear-gradient(135deg, #24292f 0%, #1a7f64 100%);
      color: white; padding: 32px 40px;
    }
    header h1 { font-size: 28px; font-weight: 700; }
    header p  { opacity: 0.8; margin-top: 6px; font-size: 14px; }
    .header-meta { margin-top: 12px; font-size: 13px; opacity: 0.7; }

    main { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }

    .card {
      background: white; border-radius: 12px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
      padding: 24px 28px; margin-bottom: 24px;
    }
    .card h2 { font-size: 18px; font-weight: 600; margin-bottom: 8px; }
    .subtitle { color: #57606a; font-size: 13px; margin-bottom: 16px; }

    .kpi-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 16px; margin-bottom: 24px;
    }
    .kpi-card {
      background: white; border-radius: 12px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
      padding: 20px; text-align: center;
    }
    .kpi-icon  { font-size: 28px; margin-bottom: 8px; }
    .kpi-value { font-size: 30px; font-weight: 700; color: #0969da; }
    .kpi-label { font-size: 12px; color: #57606a; margin-top: 4px; }

    table { width: 100%; border-collapse: collapse; font-size: 14px; }
    thead tr { background: #f6f8fa; }
    th { padding: 10px 12px; text-align: left; font-weight: 600; color: #57606a; font-size: 12px; text-transform: uppercase; letter-spacing: .5px; border-bottom: 2px solid #e0e0e0; }
    tbody tr:hover { background: #f6f8fa; }
    tbody tr { border-bottom: 1px solid #f0f0f0; }

    .badge { background: #0969da; color: white; padding: 2px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-left: 8px; vertical-align: middle; }

    .warning { background: #fff8e1; border-left: 4px solid #ffc107; padding: 14px 16px; border-radius: 6px; font-size: 13px; line-height: 1.6; }

    .note { background: #f0f7ff; border-left: 4px solid #0969da; }
    .note ul { padding-left: 20px; }
    .note li { margin-top: 8px; font-size: 13px; line-height: 1.6; }

    footer { text-align: center; padding: 24px; color: #57606a; font-size: 12px; }
  </style>
</head>
<body>

<header>
  <h1>📊 Reporte de Uso — GitHub Copilot</h1>
  <p>Organización: <strong>$ORG</strong></p>
  <div class="header-meta">Generado el $generatedAt · Período: últimos 30 días · Fuente: GitHub Copilot API</div>
</header>

<main>
  $kpiHtml
  $seatsHtml
  $metricsHtml
  $estimationHtml
  $costHtml
  $auditHtml
  $noteHtml
</main>

<footer>
  Reporte generado automáticamente por copilot-report.ps1 · GitHub Copilot Usage Metrics Reports API v$API_VER
</footer>

</body>
</html>
"@

$html | Out-File -FilePath $OUT_FILE -Encoding UTF8
Write-Host "`n✅ Reporte generado exitosamente:" -ForegroundColor Green
Write-Host "   $OUT_FILE" -ForegroundColor White
Write-Host ""

# Abrir automáticamente en el navegador por defecto
Start-Process $OUT_FILE
Write-Host "🌐 Abriendo en navegador..." -ForegroundColor Cyan
