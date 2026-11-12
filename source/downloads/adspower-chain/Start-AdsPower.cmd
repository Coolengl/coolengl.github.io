@echo off
chcp 65001 >nul
pwsh -NoProfile -File "%~dp0start-adspower.ps1"
if errorlevel 1 pause
