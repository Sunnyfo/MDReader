# MDReader 服务端（Windows）
# 功能：启动本地 HTTP 服务，用系统默认浏览器渲染 Markdown；
#       -ArgFile 传入 .md 路径（双击 .md 时由 MDReader.bat 传入）
#       -Associate  仅写入注册表，将 .md 关联到本程序（无需管理员）
param(
    [string]$ArgFile = "",
    [switch]$Associate = $false
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$htmlPath = Join-Path $root 'reader.html'

# 端口：固定端口，便于一次性注册 URL 权限（见 install.bat）
$Port = 18999

# ---------- 仅做文件关联（无需管理员，写入 HKCU） ----------
if ($Associate) {
    $bat = Join-Path $root 'MDReader.bat'
    $progId = 'MDReader.mdfile'
    $cmd = '\"' + $bat + '\" \"%1\"'
    $exts = @('.md', '.markdown', '.mdown', '.mkd')
    foreach ($ext in $exts) {
        & reg add "HKCU\Software\Classes\$ext" /ve /t REG_SZ /d $progId /f | Out-Null
    }
    & reg add "HKCU\Software\Classes\$progId" /ve /t REG_SZ /d "Markdown Document" /f | Out-Null
    & reg add "HKCU\Software\Classes\$progId\DefaultIcon" /ve /t REG_SZ /d ("`"" + $bat + "`",0") /f | Out-Null
    & reg add "HKCU\Software\Classes\$progId\shell\open\command" /ve /t REG_SZ /d $cmd /f | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        "已关联 .md / .markdown / .mdown / .mkd 到 MD Reader。`n之后双击 Markdown 文件即可用 MD Reader 打开。",
        "MD Reader") | Out-Null
    exit 0
}

# ---------- 文本读取：自动识别 UTF-8 / GBK(系统默认) ----------
function Get-FileText([string]$p) {
    $bytes = [System.IO.File]::ReadAllBytes($p)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    try {
        $s = [System.Text.Encoding]::UTF8.GetString($bytes)
        if ($s.IndexOf([char]0xFFFD) -lt 0) { return $s }
    } catch { }
    return [System.Text.Encoding]::Default.GetString($bytes)
}

# ---------- 启动本地 HTTP 服务 ----------
if (-not (Test-Path $htmlPath)) {
    [System.Windows.Forms.MessageBox]::Show("找不到 reader.html，请确认本程序文件完整。", "MD Reader") | Out-Null
    exit 1
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
try {
    $listener.Start()
}
catch {
    # 尝试自动注册 URL 权限（需管理员）；失败则提示用户
    try {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"netsh http add urlacl url=http://127.0.0.1:$Port/ user=Everyone`"" -Wait
        $listener.Start()
    }
    catch {
        Write-Warning "无法在端口 $Port 启动本地服务。请右键 install.bat → 以管理员身份运行一次，或手动执行：`n netsh http add urlacl url=http://127.0.0.1:$Port/ user=Everyone"
        exit 1
    }
}

$mdFile = $ArgFile
if ($mdFile -and -not (Test-Path $mdFile)) { $mdFile = "" }

$url = "http://127.0.0.1:$Port/"
if ($mdFile) { $url += "?file=1" }
Start-Process $url

$running = $true
while ($listener.IsListening) {
    try { $ctx = $listener.GetContext() }
    catch { break }
    $req = $ctx.Request
    $resp = $ctx.Response
    $local = $req.Url.LocalPath

    try {
        if ($local -eq '/' -or $local -eq '/index.html') {
            $buf = [System.Text.Encoding]::UTF8.GetBytes([System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8))
            $resp.ContentType = 'text/html; charset=utf-8'
            $resp.OutputStream.Write($buf, 0, $buf.Length)
        }
        elseif ($local -eq '/api/content') {
            if ($mdFile -and (Test-Path $mdFile)) {
                $text = Get-FileText $mdFile
                $name = Split-Path $mdFile -Leaf
                $obj = @{ text = $text; path = $mdFile; name = $name } | ConvertTo-Json -Compress
                $buf = [System.Text.Encoding]::UTF8.GetBytes($obj)
                $resp.ContentType = 'application/json; charset=utf-8'
                $resp.OutputStream.Write($buf, 0, $buf.Length)
            }
            else { $resp.StatusCode = 204 }
        }
        elseif ($local -eq '/api/reveal' -and $req.HttpMethod -eq 'POST') {
            $rd = New-Object System.IO.StreamReader($req.InputStream)
            $body = $rd.ReadToEnd()
            $p = ($body | ConvertFrom-Json).path
            if ($p) {
                $arg = '/select,"' + $p + '"'
                Start-Process explorer -ArgumentList $arg
            }
            $resp.StatusCode = 200
        }
        elseif ($local -eq '/api/exit') {
            $running = $false
            $resp.StatusCode = 200
        }
        else {
            $resp.StatusCode = 404
        }
    }
    catch {
        try { $resp.StatusCode = 500 } catch { }
    }
    finally {
        try { $resp.OutputStream.Close() } catch { }
    }
    if (-not $running) { break }
}
$listener.Stop()
$listener.Close()
exit 0
