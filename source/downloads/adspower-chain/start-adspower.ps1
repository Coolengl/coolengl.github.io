param(
    [string]$AdsPowerPath = 'D:\AdsPower\AdsPower Global\AdsPower Global.exe',
    [string]$CorePath = 'D:\FlClash\FlClashCore.exe'
)
#requires -Version 7.0
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $AdsPowerPath -PathType Leaf)) { throw 'Set AdsPowerPath to the installed AdsPower executable.' }
if (Get-Process -Name 'AdsPower Global' -ErrorAction SilentlyContinue) {
    Write-Output '请先保存当前环境并完全退出 AdsPower，然后再次运行此脚本。'
    exit 1
}

& (Join-Path $PSScriptRoot 'start-chain.ps1') -CorePath $CorePath

foreach ($name in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'SOCKS_PROXY', 'http_proxy', 'https_proxy', 'all_proxy', 'socks_proxy')) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
Start-Process -FilePath $AdsPowerPath -WindowStyle Normal | Out-Null
Write-Output 'AdsPower 已通过清理代理变量的启动环境打开。本地链式代理为 127.0.0.1:17891。'
