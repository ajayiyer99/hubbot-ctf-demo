<#
.SYNOPSIS
    Deploys the CareBot @ Contoso Health prompt-injection CTF demo to a Microsoft
    Innovation Hub PC: clones (or refreshes) an offline copy of the public repo and
    drops desktop shortcuts to the live demo entry points.

.DESCRIPTION
    The shortcuts point at the hosted GitHub Pages URL (not the local clone) on
    purpose: the 3-screen Theater wall syncs across browser windows via
    BroadcastChannel + localStorage, which only works over a real shared https
    origin. On a file:// path each window is a distinct opaque origin and wall
    sync breaks. The local clone is therefore an offline backup / source copy,
    while day-to-day launching uses the always-current hosted URL.

    Three internet shortcuts are created by default:
      * CareBot CTF - Theater          -> <BaseUrl>/
      * CareBot CTF - Lobby (attract)  -> <BaseUrl>/?mode=lobby
      * CareBot CTF - 3-Screen Wall    -> <BaseUrl>/?panel=wall
    Plus a folder shortcut to the offline clone. Use -IncludePanels to also add
    direct shortcuts to the individual wall panels (?panel=1|2|3).

    The script is idempotent: re-running refreshes the clone (git pull / re-download)
    and overwrites the shortcuts.

.PARAMETER InstallRoot
    Folder for the offline clone. Default: %PUBLIC%\CareBot-CTF-Demo.

.PARAMETER DesktopPath
    Where shortcuts are written. Default: the current user's Desktop. Overridden
    automatically when -AllUsers is set. Also handy for testing (point at a temp dir).

.PARAMETER BaseUrl
    Base URL of the hosted demo. Default: https://ajayiyer99.github.io/hubbot-ctf-demo

.PARAMETER RepoUrl
    Git URL of the public repo. Default: https://github.com/ajayiyer99/hubbot-ctf-demo.git

.PARAMETER AllUsers
    Write shortcuts to the All-Users (Public) Desktop so every account on the PC
    sees them. Requires an elevated (Administrator) PowerShell session.

.PARAMETER IncludePanels
    Also create direct shortcuts to the individual wall panels (Agent / Detection /
    Response). Normally you launch these from the "3-Screen Wall" launcher instead.

.PARAMETER SkipClone
    Only (re)create the desktop shortcuts; do not clone or refresh the offline copy.

.EXAMPLE
    # Standard hub deployment (run once per hub PC)
    powershell -ExecutionPolicy Bypass -File .\Deploy-HubDemo.ps1

.EXAMPLE
    # Deploy for every user on a shared hub PC (run as Administrator)
    powershell -ExecutionPolicy Bypass -File .\Deploy-HubDemo.ps1 -AllUsers

.NOTES
    Public source: https://github.com/ajayiyer99/hubbot-ctf-demo
    Live demo:     https://ajayiyer99.github.io/hubbot-ctf-demo/
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:PUBLIC 'CareBot-CTF-Demo'),
    [string]$DesktopPath,
    [string]$BaseUrl = 'https://ajayiyer99.github.io/hubbot-ctf-demo',
    [string]$RepoUrl = 'https://github.com/ajayiyer99/hubbot-ctf-demo.git',
    [switch]$AllUsers,
    [switch]$IncludePanels,
    [switch]$SkipClone
)

$ErrorActionPreference = 'Stop'
$BaseUrl = $BaseUrl.TrimEnd('/')

function Write-Step  ([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    ([string]$m) { Write-Host "    [ok] $m" -ForegroundColor Green }
function Write-Note  ([string]$m) { Write-Host "    $m" -ForegroundColor DarkGray }
function Write-Warn2 ([string]$m) { Write-Host "    [warn] $m" -ForegroundColor Yellow }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Writes a classic .url internet shortcut (opens in the default browser).
function New-UrlShortcut {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Url,
        [string]$IconFile,
        [int]$IconIndex = 0
    )
    $lines = @('[InternetShortcut]', "URL=$Url")
    if ($IconFile) { $lines += "IconFile=$IconFile"; $lines += "IconIndex=$IconIndex" }
    # .url files are INI/ASCII; write without a BOM.
    Set-Content -Path $Path -Value $lines -Encoding Ascii -Force
}

# Writes a .lnk shortcut (used here to open the offline folder in Explorer).
function New-FolderShortcut {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target
    )
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut($Path)
    $lnk.TargetPath = $Target
    $lnk.Description = 'Offline copy of the CareBot CTF demo (source backup)'
    $lnk.Save()
    [Runtime.InteropServices.Marshal]::ReleaseComObject($wsh) | Out-Null
}

Write-Host ''
Write-Host 'CareBot @ Contoso Health - Hub demo deployment' -ForegroundColor White
Write-Host '----------------------------------------------' -ForegroundColor White

# --- Resolve the desktop target --------------------------------------------
if (-not $DesktopPath) {
    if ($AllUsers) {
        if (-not (Test-Admin)) {
            throw '-AllUsers writes to the Public Desktop and requires an elevated (Run as Administrator) session.'
        }
        $DesktopPath = Join-Path $env:PUBLIC 'Desktop'
    }
    else {
        $DesktopPath = [Environment]::GetFolderPath('Desktop')
    }
}
if (-not (Test-Path $DesktopPath)) { New-Item -ItemType Directory -Path $DesktopPath -Force | Out-Null }
Write-Step "Desktop target: $DesktopPath"

# --- Clone / refresh the offline copy --------------------------------------
if ($SkipClone) {
    Write-Step 'Skipping clone (-SkipClone).'
}
else {
    Write-Step "Offline copy: $InstallRoot"
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        if (Test-Path (Join-Path $InstallRoot '.git')) {
            Write-Note 'Existing clone found - pulling latest...'
            & git -C $InstallRoot pull --ff-only
            Write-Ok 'Offline copy updated (git pull).'
        }
        else {
            if ((Test-Path $InstallRoot) -and (Get-ChildItem $InstallRoot -Force | Select-Object -First 1)) {
                Write-Warn2 "$InstallRoot exists and is not empty; cloning into a fresh temp folder and merging."
                $tmp = Join-Path ([IO.Path]::GetTempPath()) ("carebot_" + [Guid]::NewGuid().ToString('N'))
                & git clone --depth 1 $RepoUrl $tmp
                Copy-Item (Join-Path $tmp '*') $InstallRoot -Recurse -Force
                Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                & git clone --depth 1 $RepoUrl $InstallRoot
            }
            Write-Ok 'Offline copy cloned (git).'
        }
    }
    else {
        Write-Warn2 'git not found - falling back to ZIP download.'
        $zipUrl = ($RepoUrl -replace '\.git$', '') + '/archive/refs/heads/main.zip'
        $zip = Join-Path ([IO.Path]::GetTempPath()) ('carebot_' + [Guid]::NewGuid().ToString('N') + '.zip')
        $unzip = $zip + '_x'
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
            Expand-Archive -Path $zip -DestinationPath $unzip -Force
            # GitHub zips extract into a single <repo>-main subfolder; flatten it.
            $inner = Get-ChildItem $unzip -Directory | Select-Object -First 1
            if (-not (Test-Path $InstallRoot)) { New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null }
            Copy-Item (Join-Path $inner.FullName '*') $InstallRoot -Recurse -Force
            Write-Ok 'Offline copy downloaded (ZIP).'
        }
        finally {
            Remove-Item $zip, $unzip -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- Create the desktop shortcuts ------------------------------------------
Write-Step 'Creating desktop shortcuts (targets = live hosted demo)...'

# Prefer the browser's own favicon; fall back to Edge's icon if present.
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$iconArgs = @{}
if (Test-Path $edge) { $iconArgs = @{ IconFile = $edge; IconIndex = 0 } }

$shortcuts = [ordered]@{
    'CareBot CTF - Theater.url'         = "$BaseUrl/"
    'CareBot CTF - Lobby (attract).url' = "$BaseUrl/?mode=lobby"
    'CareBot CTF - 3-Screen Wall.url'   = "$BaseUrl/?panel=wall"
}
if ($IncludePanels) {
    $shortcuts['CareBot CTF - Wall Panel 1 (Agent).url']     = "$BaseUrl/?panel=1"
    $shortcuts['CareBot CTF - Wall Panel 2 (Detection).url'] = "$BaseUrl/?panel=2"
    $shortcuts['CareBot CTF - Wall Panel 3 (Response).url']  = "$BaseUrl/?panel=3"
}

$created = @()
foreach ($name in $shortcuts.Keys) {
    $path = Join-Path $DesktopPath $name
    New-UrlShortcut -Path $path -Url $shortcuts[$name] @iconArgs
    Write-Ok "$name  ->  $($shortcuts[$name])"
    $created += $path
}

# Folder shortcut to the offline copy (source backup), unless clone was skipped.
if (-not $SkipClone -and (Test-Path $InstallRoot)) {
    $folderLnk = Join-Path $DesktopPath 'CareBot CTF - Offline Copy.lnk'
    New-FolderShortcut -Path $folderLnk -Target $InstallRoot
    Write-Ok "CareBot CTF - Offline Copy.lnk  ->  $InstallRoot"
    $created += $folderLnk
}

# --- Summary ----------------------------------------------------------------
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host ("  Shortcuts created : {0}" -f $created.Count)
Write-Host ("  Desktop           : {0}" -f $DesktopPath)
if (-not $SkipClone) { Write-Host ("  Offline copy      : {0}" -f $InstallRoot) }
Write-Host ''
Write-Note 'Shortcuts open the live hosted demo so the 3-screen wall syncs correctly.'
Write-Note 'For the wall: launch "3-Screen Wall", then click "Open all 3 panels" (allow pop-ups).'
