param([string]$CorePath = 'D:\FlClash\FlClashCore.exe')
#requires -Version 7.0
$ErrorActionPreference = 'Stop'
$serverScript = Join-Path $PSScriptRoot 'serve.ps1'
$pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
$arguments = @('-NoProfile', '-File', ('"' + $serverScript + '"'), '-CorePath', ('"' + $CorePath + '"'))
Start-Process -FilePath $pwshPath -ArgumentList $arguments -WindowStyle Hidden | Out-Null
