param([string]$CorePath = 'D:\FlClash\FlClashCore.exe')
#requires -Version 7.0
$ErrorActionPreference = 'Stop'
$chainHome = $PSScriptRoot
if (-not (Test-Path -LiteralPath $CorePath -PathType Leaf)) { throw 'Set CorePath to the installed FlClashCore.exe path.' }
$configPath = Join-Path $chainHome 'config.yaml'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { throw 'Create config.yaml from config.template.yaml and fill in the subscription nodes.' }
if ((Get-Content -LiteralPath $configPath -Raw) -match 'REPLACE_') { throw 'Fill in every REPLACE_ field in config.yaml before starting.' }
$created = $false
$instanceMutex = [Threading.Mutex]::new($true, 'Local\CodexAdsPowerChain17891', [ref]$created)
if (-not $created) { $instanceMutex.Dispose(); exit 0 }
$coreProcess = $null
$pipe = $null
$script:rpcId = 0

function Read-Exact([int]$Count) {
    $bytes = [byte[]]::new($Count)
    $offset = 0
    while ($offset -lt $Count) {
        $cts = [Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(30))
        try { $read = $pipe.ReadAsync($bytes, $offset, $Count - $offset, $cts.Token).GetAwaiter().GetResult() }
        finally { $cts.Dispose() }
        if ($read -eq 0) { throw 'Chain core IPC closed' }
        $offset += $read
    }
    return ,$bytes
}

function Invoke-Core([string]$Method, $Arguments) {
    $script:rpcId++
    $requestId = [string]$script:rpcId
    $payload = [Text.Encoding]::UTF8.GetBytes((@{ id=$requestId; method=$Method; arguments=$Arguments } | ConvertTo-Json -Depth 25 -Compress))
    $prefix = [BitConverter]::GetBytes([uint32]$payload.Length)
    $pipe.Write($prefix, 0, 4)
    $pipe.Write($payload, 0, $payload.Length)
    $pipe.Flush()
    while ($true) {
        $length = [BitConverter]::ToUInt32((Read-Exact 4), 0)
        if ($length -gt 67108864) { throw 'Invalid chain core IPC frame' }
        $frame = [Text.Encoding]::UTF8.GetString((Read-Exact $length)) | ConvertFrom-Json -Depth 30
        if ($frame.id -ne $requestId) { continue }
        if ($frame.error) { throw ($frame.error | ConvertTo-Json -Compress) }
        return $frame.result
    }
}

try {
    while ($true) {
        try {
            $pipeName = 'FlClashCore_AdsPower_' + [Guid]::NewGuid().ToString('N')
            $pipe = [IO.Pipes.NamedPipeServerStream]::new($pipeName, [IO.Pipes.PipeDirection]::InOut, 1, [IO.Pipes.PipeTransmissionMode]::Byte, [IO.Pipes.PipeOptions]::Asynchronous)
            $coreProcess = Start-Process -FilePath $CorePath -ArgumentList ('\\.\pipe\' + $pipeName) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $chainHome 'core.stdout.log') -RedirectStandardError (Join-Path $chainHome 'core.stderr.log')
            $cts = [Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds(15))
            try { $pipe.WaitForConnectionAsync($cts.Token).GetAwaiter().GetResult() }
            finally { $cts.Dispose() }
            Invoke-Core 'core.init' @{ 'home-dir'=$chainHome; version=36 } | Out-Null
            Invoke-Core 'config.setup' @{ 'selected-map'=@{}; options=@{ 'test-url'='https://www.gstatic.com/generate_204' } } | Out-Null
            Invoke-Core 'listener.start' $null | Out-Null
            @{ broker_pid=$PID; core_pid=$coreProcess.Id; proxy='socks5://127.0.0.1:17891'; started_at=(Get-Date).ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $chainHome 'running.json') -Encoding utf8
            $pipe.CopyToAsync([IO.Stream]::Null).GetAwaiter().GetResult()
        } catch {
            ('{0} {1}' -f (Get-Date).ToString('o'), $_.Exception.Message) | Add-Content -LiteralPath (Join-Path $chainHome 'broker.log') -Encoding utf8
        } finally {
            if ($null -ne $pipe) { $pipe.Dispose(); $pipe = $null }
            if ($null -ne $coreProcess -and -not $coreProcess.HasExited) { Stop-Process -Id $coreProcess.Id -Force }
            $coreProcess = $null
        }
        Start-Sleep -Seconds 10
    }
} finally {
    $instanceMutex.ReleaseMutex()
    $instanceMutex.Dispose()
}
