@echo off
REM MD Reader 启动器：隐藏运行 PowerShell 服务，用默认浏览器打开阅读器
REM 直接双击本文件 = 打开空白阅读器；双击 .md 文件（已关联后）= 直接打开该文档
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0MDReader.ps1" "%~1"
