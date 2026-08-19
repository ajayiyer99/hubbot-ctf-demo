<#
.SYNOPSIS
    Provisions and deploys the CareBot @ Contoso Health prompt-injection CTF demo
    to Azure Static Web Apps, end to end, from one script.

.DESCRIPTION
    Creates every Azure artifact the demo needs and publishes the site:

      1. Resource group
      2. Static Web App (Free by default, Standard when the Entra gate is on)
      3. Optional: single-tenant Entra app registration + client secret +
         redirect URI + the matching Static Web App application settings
      4. Staged content upload (index.html plus the correct
         staticwebapp.config.json for the chosen mode)

    The demo is a static, mock-only single page app. There is no backend, no
    database and no container, so this is the whole footprint.

    ANONYMOUS BY DEFAULT (important)
    The demo is built for walk-up Innovation Hub audiences who join from their
    phones by scanning a QR code. Those phones are not in your tenant, so the
    default deployment is anonymous on the Free plan, which also costs nothing.
    Add -EnableEntraGate only when you want the whole site behind a tenant
    sign-in, and accept that it blocks anonymous phone and QR joins.

    CONFIG SAFETY
    The staticwebapp.config.json committed to this repository gates every route
    behind a custom OpenID Connect provider whose tenant id is still the
    REPLACE_WITH_TENANT_ID placeholder. Uploading it unchanged would make the
    entire site return 401. This script never uploads it as-is: it stages a
    clean anonymous config for a normal deployment, or substitutes your real
    tenant id when -EnableEntraGate is used. Your working tree is never edited.

    The script is idempotent. Re-running reuses an existing resource group,
    Static Web App and app registration, and simply redeploys the content.
    Supports -WhatIf to preview every action without changing anything.

.PARAMETER ResourceGroup
    Resource group to create or reuse. Default: rg-carebot-ctf. If the group
    already exists and you have Contributor on it, the deployment needs no
    subscription-level permission at all, which is the usual arrangement on a
    governed landing zone.

.PARAMETER Name
    Static Web App name (must be globally unique-ish within the region).
    Default: carebot-ctf plus a short random suffix on first run.

.PARAMETER Location
    Azure region. Static Web Apps is only offered in five regions; centralus and
    eastus2 are the cheapest US options. Default: centralus.

.PARAMETER Sku
    Free or Standard. Defaults to Free, and is forced to Standard when
    -EnableEntraGate is set because custom identity providers need Standard.

.PARAMETER EnableEntraGate
    Put the entire site behind a single-tenant Microsoft Entra ID sign-in.
    Creates the app registration, a client secret and the app settings, and
    deploys the gated config. This blocks anonymous phone and QR joins.

.PARAMETER TenantId
    Tenant to restrict to when -EnableEntraGate is set. Default: the tenant of
    the currently signed-in az session.

.PARAMETER AppRegistrationName
    Display name of the Entra app registration. Default: CareBot Demo (SWA).

.PARAMETER RotateSecret
    Force creation of a new client secret even when one is already configured.

.PARAMETER SubscriptionId
    Subscription to deploy into. Default: the current az subscription.

.PARAMETER SourcePath
    Folder holding index.html. Default: the repository root (the parent of the
    folder this script lives in).

.PARAMETER SkipContentDeploy
    Provision the Azure resources but do not upload the site content.

.PARAMETER UploadMethod
    How to publish the site content:
      Native (default) - downloads Microsoft's StaticSitesClient binary, the same
                         native uploader the Static Web Apps CLI drives under the
                         hood. Needs no Node.js. Cached after the first run.
      SwaCli           - runs the Static Web Apps CLI through npx. Needs Node.js.

.PARAMETER StaticSitesClientPath
    Path to an already-downloaded StaticSitesClient binary. Use this on locked
    down or offline machines: download it once elsewhere and point at the copy.

.EXAMPLE
    # Preview everything without creating a single resource
    .\Deploy-AzureDemo.ps1 -WhatIf

.EXAMPLE
    # Standard hub deployment: anonymous, Free plan, no ongoing cost
    .\Deploy-AzureDemo.ps1

.EXAMPLE
    # Internal deployment behind a tenant sign-in (Standard plan, ~9 USD/month)
    .\Deploy-AzureDemo.ps1 -EnableEntraGate

.EXAMPLE
    # Pin the names so the URL is stable across rebuilds
    .\Deploy-AzureDemo.ps1 -ResourceGroup rg-carebot-stl -Name carebot-ctf-stl

.NOTES
    Prerequisites : Azure CLI (az login). Node.js is NOT required.
    Teardown      : .\Remove-AzureDemo.ps1 -ResourceGroup <rg>
    Runbook       : docs/azure-deploy-scripts.md
    Public source : https://github.com/ajayiyer99/hubbot-ctf-demo
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ResourceGroup = 'rg-carebot-ctf',
    [string]$Name,
    [ValidateSet('centralus', 'eastus2', 'westus2', 'westeurope', 'eastasia')]
    [string]$Location = 'centralus',
    [ValidateSet('Free', 'Standard')]
    [string]$Sku = 'Free',
    [switch]$EnableEntraGate,
    [string]$TenantId,
    [string]$AppRegistrationName = 'CareBot Demo (SWA)',
    [switch]$RotateSecret,
    [string]$SubscriptionId,
    [string]$SourcePath,
    [switch]$SkipContentDeploy,
    [ValidateSet('Native', 'SwaCli')]
    [string]$UploadMethod = 'Native',
    [string]$StaticSitesClientPath
)

$ErrorActionPreference = 'Stop'

function Write-Step  ([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    ([string]$m) { Write-Host "    [ok] $m" -ForegroundColor Green }
function Write-Note  ([string]$m) { Write-Host "    $m" -ForegroundColor DarkGray }
function Write-Warn2 ([string]$m) { Write-Host "    [warn] $m" -ForegroundColor Yellow }

# Runs an az command and throws on a non-zero exit code. az writes its own errors
# to stderr, so we surface those rather than swallowing them.
function Invoke-Az {
    param([Parameter(Mandatory)][string[]]$AzArgs, [switch]$AllowFail)
    # Windows PowerShell 5.1 converts a native command's stderr into ErrorRecords.
    # With ErrorActionPreference=Stop that becomes a terminating NativeCommandError
    # before we ever reach the $LASTEXITCODE check, which would defeat -AllowFail
    # and surface a raw az stack trace. Relax it just around the call.
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $out = & az @AzArgs 2>&1 }
    finally { $ErrorActionPreference = $prevEap }
    $text = ($out | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        # Keep the message even when the caller tolerates the failure, so a later
        # error can report what Azure actually said instead of guessing.
        $script:LastAzError = $text
        if ($AllowFail) { return $null }
        throw ("az {0} failed:`n{1}" -f ($AzArgs -join ' '), $text)
    }
    $script:LastAzError = $null
    return $text
}

<#
Printed only when a real deployment step has failed. Deliberately does NOT probe
every subscription: on a corporate account that is a dozen-plus round trips
taking minutes, and silently enumerating someone's whole estate is more than this
script needs to do. It prints the two things that actually resolve the failure
and the one command the user can run themselves.
#>
function Show-DeployTargetGuidance {
    if ($script:LastAzError) {
        Write-Host ''
        Write-Note 'Azure reported:'
        foreach ($line in (($script:LastAzError -split "`r?`n") | Select-Object -First 4)) {
            if ($line.Trim()) { Write-Note "  $line" }
        }
    }
    Write-Host ''
    Write-Host '  Two ways forward:' -ForegroundColor White
    Write-Host ''
    Write-Note '  1. Deploy into a resource group you already have rights on. This needs no'
    Write-Note '     subscription-level permission and is the usual answer on a governed'
    Write-Note '     landing zone:'
    Write-Note '        .\Deploy-AzureDemo.ps1 -ResourceGroup <existing-group>'
    Write-Host ''
    Write-Note '  2. Or deploy into a different subscription:'
    Write-Note '        az account list -o table          # see what you have'
    Write-Note '        .\Deploy-AzureDemo.ps1 -SubscriptionId <id>'
    Write-Host ''
}

# True on Windows. $IsWindows only exists in PowerShell 6+, and its absence means
# we are on Windows PowerShell 5.1, which is Windows by definition.
function Test-IsWindows {
    if ($null -eq $IsWindows) { return $true }
    return [bool]$IsWindows
}

<#
Runs a native executable and returns its exit code.

Windows PowerShell 5.1 turns anything a native process writes to stderr into an
ErrorRecord, and with ErrorActionPreference=Stop that is a terminating
NativeCommandError even when the process succeeds. StaticSitesClient and npx both
log to stderr, so every native call has to be made with the preference relaxed and
judged on its exit code instead.
#>
function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$CommandArgs
    )
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $FilePath @CommandArgs 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        return $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prevEap }
}

<#
Fetches Microsoft's StaticSitesClient, the native uploader that the Static Web
Apps CLI downloads and drives internally. Going straight to it means the whole
deployment needs no Node.js, npm or npx.

The published manifest carries a SHA256 for every platform build, so the download
is verified before we ever execute it. Binaries are cached per build id under
LOCALAPPDATA, so only the first run pays the download.
#>
function Get-StaticSitesClient {
    [CmdletBinding()]
    param([string]$Channel = 'stable')

    $manifestUrl = 'https://swalocaldeploy.azureedge.net/downloads/versions.json'

    if (Test-IsWindows) { $key = 'win-x64'; $leaf = 'StaticSitesClient.exe' }
    elseif ($IsMacOS)   { $key = 'osx-x64'; $leaf = 'StaticSitesClient' }
    else                { $key = 'linux-x64'; $leaf = 'StaticSitesClient' }

    Write-Note "Resolving StaticSitesClient ($Channel, $key)..."
    try {
        $resp = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing -TimeoutSec 60
    }
    catch {
        throw ("Could not reach the StaticSitesClient manifest ($manifestUrl): {0}. " -f $_.Exception.Message) +
        'Check outbound internet or a proxy, or re-run with -UploadMethod SwaCli, or pass -StaticSitesClientPath.'
    }

    # Invoke-WebRequest -UseBasicParsing returns bytes here, so decode explicitly.
    $raw = if ($resp.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($resp.Content) } else { [string]$resp.Content }
    $entry = ($raw | ConvertFrom-Json) | Where-Object { $_.version -eq $Channel } | Select-Object -First 1
    if (-not $entry) { throw "Channel '$Channel' not found in the StaticSitesClient manifest." }

    $file = $entry.files.$key
    if (-not $file -or -not $file.url) { throw "No StaticSitesClient build published for platform '$key'." }

    $root = if (Test-IsWindows) { $env:LOCALAPPDATA } else { Join-Path $HOME '.cache' }
    $cacheDir = Join-Path (Join-Path $root 'CareBotDeploy') $entry.buildId
    $exePath = Join-Path $cacheDir $leaf

    if (Test-Path $exePath) {
        $have = (Get-FileHash $exePath -Algorithm SHA256).Hash.ToLower()
        if ($have -eq $file.sha.ToLower()) {
            Write-Ok "StaticSitesClient found in cache (build $($entry.buildId.Substring(0,8)))."
            return $exePath
        }
        Write-Warn2 'Cached StaticSitesClient failed its checksum; downloading a fresh copy.'
        Remove-Item $exePath -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    Write-Note 'Downloading StaticSitesClient (about 70 MB, one time)...'
    $tmp = "$exePath.download"
    try {
        $prev = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'   # a progress bar makes this far slower
        try { Invoke-WebRequest -Uri $file.url -OutFile $tmp -UseBasicParsing -TimeoutSec 600 }
        finally { $ProgressPreference = $prev }

        # Never execute an unverified binary.
        $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $file.sha.ToLower()) {
            throw "Checksum mismatch for StaticSitesClient. Expected $($file.sha), got $actual. Refusing to run it."
        }
        Move-Item $tmp $exePath -Force
        if (-not (Test-IsWindows)) { & chmod +x $exePath }
        Write-Ok ("StaticSitesClient verified and cached ({0:N0} MB)." -f ((Get-Item $exePath).Length / 1MB))
        return $exePath
    }
    finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'CareBot @ Contoso Health - Azure deployment' -ForegroundColor White
Write-Host '-------------------------------------------' -ForegroundColor White

# --- Preflight ---------------------------------------------------------------
Write-Step 'Preflight checks'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI not found. Install it from https://aka.ms/installazurecli then run: az login'
}
Write-Ok 'Azure CLI found.'

$acct = Invoke-Az @('account', 'show', '-o', 'json') -AllowFail
if (-not $acct) {
    throw 'Not signed in to Azure. Run: az login'
}
$account = $acct | ConvertFrom-Json
Write-Ok ("Signed in as {0}" -f $account.user.name)

if ($SubscriptionId) {
    Invoke-Az @('account', 'set', '--subscription', $SubscriptionId) | Out-Null
    $account = (Invoke-Az @('account', 'show', '-o', 'json')) | ConvertFrom-Json
}
Write-Ok ("Subscription: {0} ({1})" -f $account.name, $account.id)

# Resolve the content source folder (repo root by default).
if (-not $SourcePath) { $SourcePath = Split-Path -Parent $PSScriptRoot }
$SourcePath = (Resolve-Path $SourcePath).Path
$indexPath = Join-Path $SourcePath 'index.html'
if (-not (Test-Path $indexPath)) {
    throw "index.html not found in $SourcePath. Pass -SourcePath <repo root>."
}
Write-Ok "Content source: $SourcePath"

if (-not $SkipContentDeploy) {
    if ($StaticSitesClientPath) {
        if (-not (Test-Path $StaticSitesClientPath)) {
            throw "StaticSitesClient not found at '$StaticSitesClientPath'."
        }
        $StaticSitesClientPath = (Resolve-Path $StaticSitesClientPath).Path
        $UploadMethod = 'Native'
        Write-Ok "Upload method: Native (using the copy you supplied)."
    }
    elseif ($UploadMethod -eq 'SwaCli') {
        # Only this opt-in path needs Node.js.
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw 'Node.js not found, and -UploadMethod SwaCli requires it. Drop that switch to use the default Native uploader instead, which needs no Node.js.'
        }
        Write-Ok 'Upload method: Static Web Apps CLI via npx (Node.js found).'
    }
    else {
        Write-Ok 'Upload method: Native StaticSitesClient (no Node.js required).'
    }
}

# The Entra gate needs a custom identity provider, which is a Standard plan feature.
if ($EnableEntraGate -and $Sku -ne 'Standard') {
    $Sku = 'Standard'
    Write-Warn2 'Entra gate requires the Standard plan; SKU switched to Standard (about 9 USD/month).'
}
if ($EnableEntraGate) {
    if (-not $TenantId) { $TenantId = $account.tenantId }
    Write-Ok "Entra gate ON, restricted to tenant $TenantId"
    Write-Warn2 'A tenant gate blocks anonymous phone and QR joins. Attendees must be in this tenant.'
}
else {
    Write-Ok 'Entra gate OFF (anonymous access, so QR joins work). Use -EnableEntraGate to gate it.'
}

# Does the resource group already exist? This is only a hint. It decides whether
# we attempt to create the group and whether we look for a Static Web App to
# reuse — it is deliberately NOT a gate.
#
# Reading resource groups at subscription scope is a broader permission than
# deploying into one particular group, so a Forbidden here does not mean the
# deployment would fail. Governed landing zones commonly deny the subscription
# wide read while still granting Contributor on a pre-created group. Blocking on
# the weaker signal would refuse deployments that are perfectly allowed, so the
# real operations are left to be the authority.
$rgProbe = Invoke-Az @('group', 'exists', '-n', $ResourceGroup) -AllowFail
$rgState = if ($null -eq $rgProbe) { 'unknown' } elseif ($rgProbe -eq 'true') { 'exists' } else { 'missing' }
if ($rgState -eq 'unknown') {
    Write-Warn2 ("Cannot read resource groups in '{0}'." -f $account.name)
    Write-Note 'Common in a governed subscription, and not necessarily a blocker. Continuing:'
    Write-Note 'the deployment itself will confirm what this account is allowed to do.'
}
$rgExists = $rgState -eq 'exists'
if (-not $Name) {
    $existing = $null
    if ($rgExists) {
        $existing = Invoke-Az @('staticwebapp', 'list', '-g', $ResourceGroup, '--query', '[0].name', '-o', 'tsv') -AllowFail
    }
    if ($existing) {
        $Name = $existing
        Write-Ok "Reusing existing Static Web App: $Name"
    }
    else {
        $Name = 'carebot-ctf-' + -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
        Write-Ok "Generated Static Web App name: $Name"
        Write-Note 'Pass -Name to pin this and keep the URL stable across rebuilds.'
    }
}

# --- Plan --------------------------------------------------------------------
Write-Host ''
Write-Step 'Deployment plan'
Write-Note ("Resource group   : {0} ({1})" -f $ResourceGroup, $(switch ($rgState) { 'exists' { 'exists, reuse' } 'missing' { 'create' } default { 'cannot read, will try' } }))
Write-Note ("Static Web App   : {0}" -f $Name)
Write-Note ("Region           : {0}" -f $Location)
Write-Note ("Plan             : {0}" -f $Sku)
Write-Note ("Entra gate       : {0}" -f $(if ($EnableEntraGate) { "yes (tenant $TenantId)" } else { 'no (anonymous)' }))
Write-Note ("Content upload   : {0}" -f $(if ($SkipContentDeploy) { 'skipped' } else { 'yes' }))
Write-Host ''

# --- Resource provider -------------------------------------------------------
$regState = Invoke-Az @('provider', 'show', '--namespace', 'Microsoft.Web', '--query', 'registrationState', '-o', 'tsv') -AllowFail
if ($regState -and $regState -ne 'Registered') {
    Write-Step 'Registering the Microsoft.Web resource provider (one time, can take a minute)'
    if ($PSCmdlet.ShouldProcess('Microsoft.Web', 'Register resource provider')) {
        Invoke-Az @('provider', 'register', '--namespace', 'Microsoft.Web', '--wait') | Out-Null
        Write-Ok 'Provider registered.'
    }
}

# --- Resource group ----------------------------------------------------------
Write-Step "Resource group: $ResourceGroup"
if ($rgState -eq 'exists') {
    Write-Ok 'Already exists, reusing (needs no subscription-level rights).'
}
elseif ($PSCmdlet.ShouldProcess($ResourceGroup, "Create resource group in $Location")) {
    $rgCreated = Invoke-Az @('group', 'create', '-n', $ResourceGroup, '-l', $Location, '-o', 'none') -AllowFail
    if ($null -ne $rgCreated) {
        Write-Ok 'Created.'
    }
    elseif ($rgState -eq 'unknown') {
        # We could not read the group earlier either, so it may well already exist
        # and simply not be visible to this account. Keep going and let the Static
        # Web App step decide, since that is the operation that actually matters.
        Write-Warn2 'Could not create the resource group. It may already exist here; continuing.'
    }
    else {
        Show-DeployTargetGuidance
        throw "Could not create resource group '$ResourceGroup' in subscription '$($account.name)'."
    }
}

# --- Static Web App ----------------------------------------------------------
Write-Step "Static Web App: $Name"
$swaShow = Invoke-Az @('staticwebapp', 'show', '-n', $Name, '-g', $ResourceGroup, '-o', 'json') -AllowFail
if ($swaShow) {
    $swa = $swaShow | ConvertFrom-Json
    Write-Ok "Already exists, reusing (plan: $($swa.sku.name))."
    if ($swa.sku.name -ne $Sku -and $PSCmdlet.ShouldProcess($Name, "Change plan to $Sku")) {
        Invoke-Az @('staticwebapp', 'update', '-n', $Name, '-g', $ResourceGroup, '--sku', $Sku, '-o', 'none') | Out-Null
        Write-Ok "Plan changed to $Sku."
    }
}
elseif ($PSCmdlet.ShouldProcess($Name, "Create $Sku Static Web App in $Location")) {
    # No --source/--branch: this creates a manual-deploy app that we publish to
    # with a deployment token, so no GitHub connection or build pipeline is needed.
    # This is the first operation that genuinely proves the account can deploy
    # here, so a failure is terminal and gets the full guidance.
    $made = Invoke-Az @('staticwebapp', 'create', '-n', $Name, '-g', $ResourceGroup,
        '-l', $Location, '--sku', $Sku, '-o', 'none') -AllowFail
    if ($null -eq $made) {
        Show-DeployTargetGuidance
        throw "Could not create the Static Web App in resource group '$ResourceGroup' (subscription '$($account.name)')."
    }
    Write-Ok 'Created.'
}

$hostName = Invoke-Az @('staticwebapp', 'show', '-n', $Name, '-g', $ResourceGroup,
    '--query', 'defaultHostname', '-o', 'tsv') -AllowFail
if (-not $hostName) {
    if ($WhatIfPreference) {
        $hostName = '<swa-hostname>.azurestaticapps.net'
        Write-Note "WhatIf: hostname will be assigned at creation time."
    }
    else { throw "Could not read the Static Web App hostname for $Name." }
}
$siteUrl = "https://$hostName"
Write-Ok "Hostname: $siteUrl"

# --- Entra app registration (only when gating) -------------------------------
if ($EnableEntraGate) {
    Write-Step "Entra app registration: $AppRegistrationName"
    $redirectUri = "$siteUrl/.auth/login/entraid/callback"

    $appId = Invoke-Az @('ad', 'app', 'list', '--display-name', $AppRegistrationName,
        '--query', '[0].appId', '-o', 'tsv') -AllowFail

    if ($appId) {
        Write-Ok "Already exists (appId $appId), reusing."
        if ($PSCmdlet.ShouldProcess($AppRegistrationName, "Ensure redirect URI $redirectUri")) {
            # Merge rather than overwrite so custom domains added earlier survive.
            $currentJson = Invoke-Az @('ad', 'app', 'show', '--id', $appId, '--query', 'web.redirectUris', '-o', 'json')
            $uris = @($currentJson | ConvertFrom-Json)
            if ($uris -notcontains $redirectUri) {
                $uris += $redirectUri
                Invoke-Az (@('ad', 'app', 'update', '--id', $appId, '--web-redirect-uris') + $uris) | Out-Null
                Write-Ok "Redirect URI added: $redirectUri"
            }
            else { Write-Ok 'Redirect URI already present.' }
        }
    }
    elseif ($PSCmdlet.ShouldProcess($AppRegistrationName, 'Create single-tenant app registration')) {
        # AzureADMyOrg is what actually enforces the single-tenant restriction.
        $created = Invoke-Az @('ad', 'app', 'create', '--display-name', $AppRegistrationName,
            '--sign-in-audience', 'AzureADMyOrg', '--web-redirect-uris', $redirectUri, '-o', 'json')
        $appId = ($created | ConvertFrom-Json).appId
        Write-Ok "Created (appId $appId)."
    }

    # Only mint a secret when one is not already wired up, so re-runs do not
    # pile up credentials on the app registration.
    $settingsJson = Invoke-Az @('staticwebapp', 'appsettings', 'list', '-n', $Name,
        '-g', $ResourceGroup, '-o', 'json') -AllowFail
    $hasSecret = $false
    if ($settingsJson) {
        $props = ($settingsJson | ConvertFrom-Json).properties
        $hasSecret = [bool]($props.PSObject.Properties.Name -contains 'ENTRA_CLIENT_SECRET')
    }

    if ($hasSecret -and -not $RotateSecret) {
        Write-Ok 'Client secret already configured, leaving it alone (use -RotateSecret to replace).'
        if ($appId -and $PSCmdlet.ShouldProcess($Name, 'Refresh ENTRA_CLIENT_ID app setting')) {
            Invoke-Az @('staticwebapp', 'appsettings', 'set', '-n', $Name, '-g', $ResourceGroup,
                '--setting-names', "ENTRA_CLIENT_ID=$appId", '-o', 'none') | Out-Null
        }
    }
    elseif ($PSCmdlet.ShouldProcess($AppRegistrationName, 'Create client secret and store it in Static Web App settings')) {
        $cred = Invoke-Az @('ad', 'app', 'credential', 'reset', '--id', $appId, '--append',
            '--display-name', 'swa-auth', '--years', '1', '-o', 'json')
        $secret = ($cred | ConvertFrom-Json).password
        Write-Ok 'Client secret created (valid 1 year).'
        Invoke-Az @('staticwebapp', 'appsettings', 'set', '-n', $Name, '-g', $ResourceGroup,
            '--setting-names', "ENTRA_CLIENT_ID=$appId", "ENTRA_CLIENT_SECRET=$secret", '-o', 'none') | Out-Null
        Write-Ok 'App settings ENTRA_CLIENT_ID and ENTRA_CLIENT_SECRET stored in Azure.'
        Write-Note 'The secret lives only in Static Web App configuration, never in this repository.'
        Write-Note 'Diary note: rotate it within a year with -RotateSecret.'
    }
}

# --- Stage content -----------------------------------------------------------
if (-not $SkipContentDeploy) {
    Write-Step 'Staging content'
    $staging = Join-Path ([IO.Path]::GetTempPath()) ('carebot_swa_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    try {
        Copy-Item $indexPath (Join-Path $staging 'index.html') -Force
        Write-Ok 'index.html staged.'

        $configOut = Join-Path $staging 'staticwebapp.config.json'
        if ($EnableEntraGate) {
            # Substitute the real tenant id into the gated config from the repo.
            $srcConfig = Join-Path $SourcePath 'staticwebapp.config.json'
            if (-not (Test-Path $srcConfig)) { throw "staticwebapp.config.json not found in $SourcePath." }
            $cfg = Get-Content -Raw $srcConfig
            if ($cfg -notmatch 'REPLACE_WITH_TENANT_ID' -and $cfg -notmatch [regex]::Escape($TenantId)) {
                Write-Warn2 'Config has no REPLACE_WITH_TENANT_ID placeholder; uploading it unchanged.'
            }
            $cfg = $cfg.Replace('REPLACE_WITH_TENANT_ID', $TenantId)
            [IO.File]::WriteAllText($configOut, $cfg, (New-Object Text.UTF8Encoding($false)))
            Write-Ok "Gated config staged (tenant $TenantId)."
        }
        else {
            # Anonymous config. The repo copy gates every route behind a provider
            # whose tenant id is a placeholder, which would 401 the whole site.
            $anon = [ordered]@{
                navigationFallback = [ordered]@{ rewrite = '/index.html' }
                globalHeaders      = [ordered]@{
                    'X-Content-Type-Options' = 'nosniff'
                    'X-Frame-Options'        = 'SAMEORIGIN'
                    'Referrer-Policy'        = 'strict-origin-when-cross-origin'
                }
            }
            $json = $anon | ConvertTo-Json -Depth 6
            [IO.File]::WriteAllText($configOut, $json, (New-Object Text.UTF8Encoding($false)))
            Write-Ok 'Anonymous config staged (no auth gate, QR joins work).'
        }

        # --- Upload ----------------------------------------------------------
        Write-Step 'Uploading content'
        if ($PSCmdlet.ShouldProcess($Name, 'Deploy site content')) {
            $token = Invoke-Az @('staticwebapp', 'secrets', 'list', '-n', $Name, '-g', $ResourceGroup,
                '--query', 'properties.apiKey', '-o', 'tsv')
            if (-not $token) { throw 'Could not read the deployment token.' }

            if ($UploadMethod -eq 'SwaCli') {
                Write-Note 'Running: npx @azure/static-web-apps-cli deploy (first run downloads the CLI)'
                $npx = (Get-Command npx -ErrorAction Stop).Source
                $code = Invoke-NativeCommand -FilePath $npx -CommandArgs @(
                    '--yes', '@azure/static-web-apps-cli@latest', 'deploy', $staging,
                    '--deployment-token', $token, '--env', 'production')
                if ($code -ne 0) {
                    throw "Static Web Apps CLI deploy failed with exit code $code."
                }
            }
            else {
                # StaticSitesClient is the native uploader the Static Web Apps CLI
                # drives internally, so calling it directly skips Node entirely.
                $client = $StaticSitesClientPath
                if (-not $client) { $client = Get-StaticSitesClient }

                # It reads the token and the deployment context from the environment.
                $prevToken = $env:DEPLOYMENT_TOKEN
                $prevProvider = $env:DEPLOYMENT_PROVIDER
                $prevAction = $env:DEPLOYMENT_ACTION
                $env:DEPLOYMENT_TOKEN = $token
                $env:DEPLOYMENT_PROVIDER = 'CareBotDeployScript'
                $env:DEPLOYMENT_ACTION = 'upload'
                try {
                    # --skipAppBuild: the demo is a single prebuilt HTML file, so
                    # there is nothing for Oryx to build.
                    $code = Invoke-NativeCommand -FilePath $client -CommandArgs @(
                        'upload',
                        '--app', $staging,
                        '--apiToken', $token,
                        '--skipAppBuild', 'true',
                        '--verbose', 'false')
                    if ($code -ne 0) {
                        throw "StaticSitesClient upload failed with exit code $code."
                    }
                }
                finally {
                    $env:DEPLOYMENT_TOKEN = $prevToken
                    $env:DEPLOYMENT_PROVIDER = $prevProvider
                    $env:DEPLOYMENT_ACTION = $prevAction
                }
            }
            Write-Ok 'Content deployed.'
        }
    }
    finally {
        Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Step 'Content upload skipped (-SkipContentDeploy).'
}

# --- Summary -----------------------------------------------------------------
Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host ''
Write-Host '  Demo URLs' -ForegroundColor White
Write-Host ("    Theater (CTF)   : {0}/" -f $siteUrl)
Write-Host ("    Lobby (attract) : {0}/?mode=lobby" -f $siteUrl)
Write-Host ("    3-screen wall   : {0}/?panel=wall" -f $siteUrl)
Write-Host ("    Attendee join   : {0}/" -f $siteUrl)
Write-Host ''
Write-Host '  Azure' -ForegroundColor White
Write-Host ("    Resource group  : {0}" -f $ResourceGroup)
Write-Host ("    Static Web App  : {0} ({1}, {2})" -f $Name, $Sku, $Location)
if ($EnableEntraGate) {
    Write-Host ("    Entra app       : {0} (single tenant {1})" -f $AppRegistrationName, $TenantId)
}
Write-Host ''
if ($Sku -eq 'Free') { Write-Note 'Free plan: no ongoing cost for this demo.' }
else { Write-Note 'Standard plan: about 9 USD per month while it exists.' }
Write-Note 'Attendee QR: open the demo, go to Settings (gear icon) and set the join URL to'
Write-Note "  $siteUrl/   (or repoint your is.gd short link at it, which keeps printed QR codes valid)."
Write-Note "Tear it all down with: .\Remove-AzureDemo.ps1 -ResourceGroup $ResourceGroup"
Write-Host ''
