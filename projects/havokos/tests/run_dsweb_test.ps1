# Dead Souls' own web server on the Star driver (todo.md HavokOS P1 #8): boot
# DS3.9 with tools/havokos.exe and fetch pages from the HTTP service its inet
# daemon runs on the game port + 1 (secure/lib/net/http.c over a
# STREAM_BINARY socket, serving files through secure/lib/file.c's buffers).
# Every body must be byte for byte the file under E:\ds3.9\lib\www --
# including images, whose NUL bytes only survive if buffers carry them all
# the way from read_buffer() to socket_write().
#
# There is no reference transcript: on the reference every request fails
# on read_buffer(), which it doesn't have (NOTES.md deviation #25). The
# oracle is the files themselves.
#
# Usage: powershell -File projects/havokos/tests/run_dsweb_test.ps1 [-DsRoot E:\ds3.9]
# (rebuild tools/havokos.exe first if any .star file changed; see
# tests/run_login_test.ps1's header)
# Exits 0 when every page matches its file, 1 otherwise. About 10 s.

param([string]$DsRoot = "E:\ds3.9")

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$driver = Join-Path $root "tools\havokos.exe"
if (-not (Test-Path $driver)) {
    Write-Error "$driver not found -- build it first (see this script's header)."
    exit 1
}

# the pages: HTML of a few sizes, and binary files
$pages = @("index.html", "demo.html", "debugging.html", "favicon.ico", "function.jpg", "images/lpuni_afiliated.png")

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("havokos_dsweb_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force (Join-Path $scratch "bin") | Out-Null
Copy-Item -Recurse (Join-Path $DsRoot "lib") (Join-Path $scratch "lib")
Copy-Item (Join-Path $DsRoot "bin\mudos.cfg") (Join-Path $scratch "bin")
# two free ports in a row, the game's and its HTTP service's, below the
# ephemeral range: a client connecting to an ephemeral port no one listens on
# yet can be handed that same port as its own and connect to itself (TCP's
# simultaneous open), reading back what it sent
$port = 0
for ($p0 = 24000; $p0 -lt 25000 -and $port -eq 0; $p0 += 10) {
    try {
        foreach ($q in @($p0, $p0 + 1)) {
            $l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $q)
            $l.Start()
            $l.Stop()
        }
        $port = $p0
    } catch {}
}

function Get-Raw([int]$p, [string]$req) {
    $c = New-Object System.Net.Sockets.TcpClient
    $c.Connect("127.0.0.1", $p)
    $s = $c.GetStream()
    $bytes = [Text.Encoding]::ASCII.GetBytes($req)
    $s.Write($bytes, 0, $bytes.Length)
    $ms = New-Object System.IO.MemoryStream
    $buf = New-Object byte[] 65536
    $s.ReadTimeout = 10000
    try { while (($n = $s.Read($buf, 0, $buf.Length)) -gt 0) { $ms.Write($buf, 0, $n) } } catch {}
    $c.Close()
    return ,$ms.ToArray()
}

$log = Join-Path $scratch "driver.log"
$proc = Start-Process -FilePath $driver -ArgumentList @((Join-Path $scratch "bin\mudos.cfg"), $port) -RedirectStandardOutput $log -PassThru -NoNewWindow
try {
    $deadline = (Get-Date).AddSeconds(60)
    while (-not ((Test-Path $log) -and (Select-String -Path $log -Pattern "Accepting connections" -Quiet))) {
        if ((Get-Date) -gt $deadline -or $proc.HasExited) {
            Write-Host "FAIL: the driver did not start listening"
            exit 1
        }
        Start-Sleep -Milliseconds 200
    }
    # the inet daemon starts its services a moment after the boot
    $up = $false
    while (-not $up -and (Get-Date) -lt $deadline.AddSeconds(30)) {
        try {
            $t = New-Object System.Net.Sockets.TcpClient
            $t.Connect("127.0.0.1", $port + 1)
            $t.Close()
            $up = $true
        } catch { Start-Sleep -Milliseconds 300 }
    }
    $failed = 0
    foreach ($page in $pages) {
        $resp = Get-Raw ($port + 1) "GET /$page HTTP/1.0`r`n`r`n"
        $text = [Text.Encoding]::GetEncoding(28591).GetString($resp)
        $sep = $text.IndexOf("`r`n`r`n")
        $file = [IO.File]::ReadAllBytes((Join-Path $DsRoot "lib\www\$page"))
        [byte[]]$body = @()
        if ($sep -ge 0 -and $sep + 4 -lt $resp.Length) { $body = [byte[]]$resp[($sep + 4)..($resp.Length - 1)] }
        $status = "(no reply)"
        if ($sep -ge 0) { $status = ($text.Substring(0, $sep) -split "`n")[0].Trim() }
        $same = ($body.Length -eq $file.Length) -and ([Convert]::ToBase64String($body) -eq [Convert]::ToBase64String($file))
        if ($status -eq "HTTP/1.0 200 OK" -and $same) {
            Write-Host "$page`: $($file.Length) bytes match"
        } else {
            Write-Host "FAIL $page`: $status, $($body.Length) bytes for a $($file.Length)-byte file"
            $failed++
        }
    }
    if ($failed -eq 0) {
        Write-Host "PASS: Dead Souls' web server serves every page byte for byte"
        exit 0
    }
    Select-String -Path $log -Pattern "rror" | Select-Object -First 10 | ForEach-Object { Write-Host $_.Line }
    exit 1
} finally {
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
    $proc.WaitForExit()
    Remove-Item -Recurse -Force $scratch
}
