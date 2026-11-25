function Download-PSModule {
    <#
    .SYNOPSIS
        Downloads the Az PowerShell modules from the PowerShell Gallery as .nupkg files.
    .DESCRIPTION
        Uses curl.exe first (it often works where Invoke-WebRequest is blocked), retries
        without the certificate revocation check, then falls back to Invoke-WebRequest.
        Each package is saved to "<OutDir>\<ModuleName>\<ModuleName>.nupkg" and checked to make
        sure it is a real package and not a proxy error page.
    .PARAMETER OutDir
        Base folder. Each module is saved in its own subfolder named after the module.
    .EXAMPLE
        Download-PSModule
    .EXAMPLE
        Download-PSModule -OutDir 'D:\Packages'
    #>
    [CmdletBinding()]
    param(
        [string]$OutDir = "$HOME\Downloads\powershellModule"
    )

    $modules = 'Az.Accounts', 'Az.Advisor', 'Az.Aks', 'Az.AnalysisServices', 'Az.ApiManagement', 'Az.App',
    'Az.AppConfiguration', 'Az.ApplicationInsights', 'Az.ArcResourceBridge', 'Az.Attestation', 'Az.Automanage',
    'Az.Automation', 'Az.Batch', 'Az.Billing', 'Az.Cdn', 'Az.CloudService', 'Az.CognitiveServices', 'Az.Compute',
    'Az.ConfidentialLedger', 'Az.ConnectedMachine', 'Az.ContainerInstance', 'Az.ContainerRegistry', 'Az.CosmosDB',
    'Az.DataBoxEdge', 'Az.Databricks', 'Az.DataFactory', 'Az.DataLakeAnalytics', 'Az.DataLakeStore',
    'Az.DataProtection', 'Az.DataShare', 'Az.DesktopVirtualization', 'Az.DevCenter', 'Az.DevTestLabs', 'Az.Dns',
    'Az.DnsResolver', 'Az.ElasticSan', 'Az.EventGrid', 'Az.EventHub', 'Az.FrontDoor', 'Az.Functions', 'Az.HDInsight',
    'Az.HealthcareApis', 'Az.IotHub', 'Az.KeyVault', 'Az.Kusto', 'Az.LoadTesting', 'Az.LogicApp',
    'Az.MachineLearning', 'Az.MachineLearningServices', 'Az.Maintenance', 'Az.ManagedServiceIdentity',
    'Az.ManagedServices', 'Az.MarketplaceOrdering', 'Az.Migrate', 'Az.Monitor', 'Az.MySql', 'Az.Network',
    'Az.NetworkCloud', 'Az.Nginx', 'Az.NotificationHubs', 'Az.OperationalInsights', 'Az.PolicyInsights',
    'Az.PostgreSql', 'Az.PowerBIEmbedded', 'Az.PrivateDns', 'Az.RecoveryServices', 'Az.RedisCache',
    'Az.RedisEnterpriseCache', 'Az.Relay', 'Az.ResourceMover', 'Az.Resources', 'Az.Security', 'Az.SecurityInsights',
    'Az.ServiceBus', 'Az.ServiceFabric', 'Az.SignalR', 'Az.Sql', 'Az.SqlVirtualMachine', 'Az.StackHCI', 'Az.Storage',
    'Az.StorageMover', 'Az.StorageSync', 'Az.StreamAnalytics', 'Az.Support', 'Az.Synapse', 'Az.TrafficManager',
    'Az.Websites'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $failed = @()

    foreach ($m in $modules) {
        $url    = "https://www.powershellgallery.com/api/v2/package/$m"
        $modDir = Join-Path $OutDir $m
        $out    = Join-Path $modDir "$m.nupkg"
        New-Item -ItemType Directory -Path $modDir -Force | Out-Null
        Write-Host "Downloading $m ..." -NoNewline

        & curl.exe -sSfL -o $out $url 2>$null
        if ($LASTEXITCODE -ne 0) {
            & curl.exe -sSfL --ssl-no-revoke -o $out $url 2>$null
        }
        if ($LASTEXITCODE -ne 0) {
            try { Invoke-WebRequest $url -OutFile $out -UseBasicParsing -ErrorAction Stop } catch {}
        }

        # A real .nupkg is a zip file, which starts with "PK"
        $ok = $false
        if (Test-Path -LiteralPath $out) {
            $fs = [IO.File]::OpenRead($out)
            try {
                $buf = New-Object byte[] 2
                $ok = ($fs.Read($buf, 0, 2) -eq 2 -and $buf[0] -eq 0x50 -and $buf[1] -eq 0x4B)
            }
            finally { $fs.Dispose() }
        }

        if ($ok) { Write-Host " OK" -ForegroundColor Green }
        else {
            Write-Host " FAILED" -ForegroundColor Red
            Remove-Item -LiteralPath $out -ErrorAction SilentlyContinue
            if (-not (Get-ChildItem -LiteralPath $modDir -Force)) { Remove-Item -LiteralPath $modDir -ErrorAction SilentlyContinue }
            $failed += $m
        }
    }

    if ($failed) {
        Write-Host "`nThese failed - download them in your browser instead:" -ForegroundColor Yellow
        $failed | ForEach-Object { "  https://www.powershellgallery.com/api/v2/package/$_" }
    }
    else {
        Write-Host "`nAll downloads succeeded. Saved under $OutDir" -ForegroundColor Green
    }
}
