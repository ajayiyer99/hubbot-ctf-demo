<#
.SYNOPSIS
    Removes everything Deploy-AzureDemo.ps1 created for the CareBot CTF demo.

.DESCRIPTION
    Deletes the resource group (which takes the Static Web App with it) and,
    optionally, the Entra app registration used for the tenant sign-in gate.

    The app registration is deliberately a separate prompt: it lives in Entra ID,
    not in the resource group, so deleting the resource group alone leaves it
    behind as an orphan. Anything else you created in the same resource group is
    also deleted, so pass -Force only when you are certain the group holds
    nothing but this demo.

.PARAMETER ResourceGroup
    Resource group to delete. Default: rg-carebot-ctf.

.PARAMETER RemoveAppRegistration
    Also delete the Entra app registration created for the gate.

.PARAMETER AppRegistrationName
    Display name of the app registration. Default: CareBot Demo (SWA).

.PARAMETER SubscriptionId
    Subscription to act against. Default: the current az subscription.

.PARAMETER Force
    Skip the confirmation prompt.

.PARAMETER NoWait
    Return immediately instead of waiting for the resource group delete.

.EXAMPLE
    # Preview what would be deleted
    .\Remove-AzureDemo.ps1 -WhatIf

.EXAMPLE
    # Delete the resource group and the Entra app registration
    .\Remove-AzureDemo.ps1 -RemoveAppRegistration

.NOTES
    Runbook: docs/azure-deploy-scripts.md
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ResourceGroup = 'rg-carebot-ctf',
    [switch]$RemoveAppRegistration,
    [string]$AppRegistrationName = 'CareBot Demo (SWA)',
    [string]$SubscriptionId,
    [switch]$Force,
    [switch]$NoWait
)

$ErrorActionPreference = 'Stop'

function Write-Step  ([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    ([string]$m) { Write-Host "    [ok] $m" -ForegroundColor Green }
function Write-Note  ([string]$m) { Write-Host "    $m" -ForegroundColor DarkGray }
function Write-Warn2 ([string]$m) { Write-Host "    [warn] $m" -ForegroundColor Yellow }

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
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFail) { return $null }
        throw ("az {0} failed:`n{1}" -f ($AzArgs -join ' '), ($out | Out-String).Trim())
    }
    return ($out | Out-String).Trim()
}

Write-Host ''
Write-Host 'CareBot @ Contoso Health - Azure teardown' -ForegroundColor White
Write-Host '-----------------------------------------' -ForegroundColor White

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI not found. Install it from https://aka.ms/installazurecli then run: az login'
}
if (-not (Invoke-Az @('account', 'show', '-o', 'json') -AllowFail)) {
    throw 'Not signed in to Azure. Run: az login'
}
if ($SubscriptionId) { Invoke-Az @('account', 'set', '--subscription', $SubscriptionId) | Out-Null }
$account = (Invoke-Az @('account', 'show', '-o', 'json')) | ConvertFrom-Json
Write-Ok ("Subscription: {0} ({1})" -f $account.name, $account.id)

# --- Show what will go --------------------------------------------------------
# A Forbidden here means the account cannot read resource groups at all, so fail
# with something actionable instead of a raw error.
$probe = Invoke-Az @('group', 'exists', '-n', $ResourceGroup) -AllowFail
if ($null -eq $probe) {
    throw ("Cannot query resource groups in subscription '{0}' ({1}). " -f $account.name, $account.id) +
    'The signed-in account most likely lacks Contributor rights there, or the subscription is policy-locked. ' +
    'Run "az account list -o table" to see what else you can use, then re-run with -SubscriptionId <id>.'
}
$exists = $probe -eq 'true'
if (-not $exists) {
    Write-Warn2 "Resource group '$ResourceGroup' does not exist; nothing to delete."
}
else {
    Write-Step "Resources in '$ResourceGroup' that will be deleted"
    $list = Invoke-Az @('resource', 'list', '-g', $ResourceGroup,
        '--query', '[].{name:name, type:type}', '-o', 'tsv') -AllowFail
    if ($list) { $list -split "`r?`n" | ForEach-Object { Write-Note $_ } }
    else { Write-Note '(none)' }

    if (-not $Force -and -not $WhatIfPreference) {
        Write-Host ''
        $answer = Read-Host "Delete resource group '$ResourceGroup' and everything above? Type the group name to confirm"
        if ($answer -ne $ResourceGroup) {
            Write-Warn2 'Confirmation did not match. Nothing was deleted.'
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($ResourceGroup, 'Delete resource group and all resources in it')) {
        $delArgs = @('group', 'delete', '-n', $ResourceGroup, '--yes')
        if ($NoWait) { $delArgs += '--no-wait' }
        Invoke-Az $delArgs | Out-Null
        Write-Ok $(if ($NoWait) { 'Delete started (running in the background).' } else { 'Resource group deleted.' })
    }
}

# --- Entra app registration ---------------------------------------------------
if ($RemoveAppRegistration) {
    Write-Step "Entra app registration: $AppRegistrationName"
    $appId = Invoke-Az @('ad', 'app', 'list', '--display-name', $AppRegistrationName,
        '--query', '[0].appId', '-o', 'tsv') -AllowFail
    if (-not $appId) {
        Write-Warn2 'Not found; nothing to delete.'
    }
    elseif ($PSCmdlet.ShouldProcess($AppRegistrationName, "Delete app registration $appId")) {
        Invoke-Az @('ad', 'app', 'delete', '--id', $appId) | Out-Null
        Write-Ok "Deleted (appId $appId)."
    }
}
else {
    Write-Note 'Entra app registration left in place. Re-run with -RemoveAppRegistration to delete it.'
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host ''
