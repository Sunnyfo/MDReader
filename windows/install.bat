@echo off
REM 安装（需管理员）：注册本地服务端口权限 + 关联 .md 文件
REM 用法：右键本文件 → 以管理员身份运行
cd /d "%~dp0"
netsh http add urlacl url=http://127.0.0.1:18999/ user=Everyone
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0MDReader.ps1" -Associate
echo.
echo 安装完成：
echo   1) 已注册本地端口 18999 的访问权限
echo   2) 已将 .md/.markdown/.mdown/.mkd 关联到 MD Reader
echo.
echo 之后双击任意 Markdown 文件即可用 MD Reader 打开。
pause
