# ==========================================================================
#  CareBot @ Contoso Health - CTF demo : one-line bootstrap
# --------------------------------------------------------------------------
#  Downloads the full deploy script from the public repo and runs it. The
#  deploy script then clones an OFFLINE copy of the demo and drops desktop
#  shortcuts (Theater / Lobby / 3-Screen Wall) that open the live hosted app.
#
#  Run it straight from the web - nothing to copy first. Open Windows
#  PowerShell and paste ONE line:
#
#     irm https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Get-HubDemo.ps1 | iex
#
#  This bootstrap is intentionally PARAMETER-FREE so it is safe to pipe into
#  iex. It saves the full Deploy-HubDemo.ps1 into your Downloads folder; for
#  options (-AllUsers, -IncludePanels, ...) re-run that saved file - the path
#  is printed at the end.
# ==========================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$raw = 'https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Deploy-HubDemo.ps1'
$dst = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads\Deploy-HubDemo.ps1'

$dstDir = Split-Path $dst
if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

Write-Host ''
Write-Host 'CareBot CTF - bootstrap' -ForegroundColor White
Write-Host '-----------------------' -ForegroundColor White
Write-Host ("Downloading deploy script -> {0}" -f $dst) -ForegroundColor Cyan
Invoke-WebRequest -Uri $raw -OutFile $dst -UseBasicParsing
try { Unblock-File -Path $dst } catch {}

Write-Host 'Running deployment (clone offline copy + desktop shortcuts)...' -ForegroundColor Cyan
# Launch in a child process with Bypass so it runs regardless of the machine's
# script-execution policy (piping this file into iex is not policy-gated, but
# executing the downloaded .ps1 file is).
& powershell -NoProfile -ExecutionPolicy Bypass -File $dst

Write-Host ''
Write-Host ("Deploy script saved at: {0}" -f $dst) -ForegroundColor Green
Write-Host 'Re-run with options, for example:' -ForegroundColor DarkGray
Write-Host ("  powershell -ExecutionPolicy Bypass -File `"{0}`" -AllUsers -IncludePanels" -f $dst) -ForegroundColor DarkGray
