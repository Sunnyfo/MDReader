@echo off
REM 仅将 .md 等文件关联到 MD Reader（无需管理员，写入当前用户注册表）
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0MDReader.ps1" -Associate
