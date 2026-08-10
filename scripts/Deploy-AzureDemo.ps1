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
    Resource group to create or reuse. Default: rg-carebot-ctf.

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
    Prerequisites : Azure CLI (az login), Node.js (for the content upload only).
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
    [switch]$SkipContentDeploy
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
    $out = & az @AzArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFail) { return $null }
        throw ("az {0} failed:`n{1}" -f ($AzArgs -join ' '), ($out | Out-String).Trim())
    }
    return ($out | Out-String).Trim()
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

if (-not $SkipContentDeploy -and -not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js not found; it is required to upload content via the Static Web Apps CLI. Install it from https://nodejs.org, or re-run with -SkipContentDeploy.'
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

# Pick a name on first run. SWA hostnames are derived from the name, so we add a
# short suffix to avoid collisions with other people running this same script.
# A Forbidden here means the account cannot read resource groups at all, so fail
# with something actionable instead of a raw error later on.
$rgProbe = Invoke-Az @('group', 'exists', '-n', $ResourceGroup) -AllowFail
if ($null -eq $rgProbe) {
    throw ("Cannot query resource groups in subscription '{0}' ({1}). " -f $account.name, $account.id) +
    'The signed-in account most likely lacks Contributor rights there, or the subscription is policy-locked. ' +
    'Run "az account list -o table" to see what else you can use, then re-run with -SubscriptionId <id>.'
}
$rgExists = $rgProbe -eq 'true'
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
Write-Note ("Resource group   : {0} ({1})" -f $ResourceGroup, $(if ($rgExists) { 'exists' } else { 'create' }))
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
if ($rgExists) {
    Write-Ok 'Already exists, reusing.'
}
elseif ($PSCmdlet.ShouldProcess($ResourceGroup, "Create resource group in $Location")) {
    Invoke-Az @('group', 'create', '-n', $ResourceGroup, '-l', $Location, '-o', 'none') | Out-Null
    Write-Ok 'Created.'
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
    Invoke-Az @('staticwebapp', 'create', '-n', $Name, '-g', $ResourceGroup,
        '-l', $Location, '--sku', $Sku, '-o', 'none') | Out-Null
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
        Write-Step 'Uploading content via the Static Web Apps CLI'
        if ($PSCmdlet.ShouldProcess($Name, 'Deploy site content')) {
            $token = Invoke-Az @('staticwebapp', 'secrets', 'list', '-n', $Name, '-g', $ResourceGroup,
                '--query', 'properties.apiKey', '-o', 'tsv')
            if (-not $token) { throw 'Could not read the deployment token.' }
            Write-Note 'Running: npx @azure/static-web-apps-cli deploy (first run downloads the CLI)'
            & npx --yes '@azure/static-web-apps-cli@latest' deploy $staging `
                --deployment-token $token --env production
            if ($LASTEXITCODE -ne 0) {
                throw "Static Web Apps CLI deploy failed with exit code $LASTEXITCODE."
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
