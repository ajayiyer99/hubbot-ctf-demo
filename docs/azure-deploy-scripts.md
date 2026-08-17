# Deploying the demo to Azure with scripts

Two PowerShell scripts stand the whole demo up in Azure and tear it back down.
They wrap the Azure CLI, so there is no portal clicking and nothing to remember.

| Script | What it does |
| --- | --- |
| [`scripts/Deploy-AzureDemo.ps1`](../scripts/Deploy-AzureDemo.ps1) | Creates every Azure artifact and publishes the site |
| [`scripts/Remove-AzureDemo.ps1`](../scripts/Remove-AzureDemo.ps1) | Deletes everything again |

Prefer clicking through the portal yourself? The manual walkthrough for the
gated build is still in [azure-hosting.md](azure-hosting.md). These scripts
automate that same shape and add the anonymous option.

## Quick start

```powershell
az login
cd scripts

# 1. See exactly what would happen. Creates nothing.
.\Deploy-AzureDemo.ps1 -WhatIf

# 2. Do it for real.
.\Deploy-AzureDemo.ps1
```

The run prints the live URLs when it finishes:

```
  Theater (CTF)   : https://<name>.azurestaticapps.net/
  Lobby (attract) : https://<name>.azurestaticapps.net/?mode=lobby
  3-screen wall   : https://<name>.azurestaticapps.net/?panel=wall
```

## What gets created

| Artifact | Notes |
| --- | --- |
| Resource group | `rg-carebot-ctf` by default |
| Static Web App | Free plan by default, so no ongoing cost |
| Site content | `index.html` plus a generated `staticwebapp.config.json` |
| Entra app registration | **Only** with `-EnableEntraGate` (single tenant) |
| Client secret + app settings | **Only** with `-EnableEntraGate` |

That is the entire footprint. The demo is a static, mock-only single page app:
no backend, no database, no container, no Azure OpenAI resource. Every Sentinel
incident, Defender alert and SOAR playbook step you see on screen is simulated
in the browser.
## Prerequisites

- **Azure CLI** — <https://aka.ms/installazurecli>, then `az login`.
- **Contributor** on the target subscription. If the account cannot create
  resource groups, the script probes your other subscriptions and prints the
  ones that do work, so you can re-run with `-SubscriptionId`.

**Node.js is not required.** The script publishes with `StaticSitesClient`,
Microsoft's native uploader — the same binary the Static Web Apps CLI downloads
and drives under the hood. It is fetched on first use (about 70 MB), verified
against the SHA256 in Microsoft's published manifest before it is ever executed,
and cached under `%LOCALAPPDATA%\CareBotDeploy` so later runs start immediately.

Both Windows PowerShell 5.1 and PowerShell 7 are supported.

## Anonymous by default, and why

The demo is built for walk-up Innovation Hub audiences who scan a QR code and
play from their own phones. Those phones are not in your tenant, so the default
deployment is **anonymous on the Free plan**:

- Anyone with the link can open it, which is what makes the QR join work.
- The Free plan costs nothing.
- Nothing sensitive is exposed. The "credentials" in the demo are synthetic
  honeypots and the source is already public on GitHub.

Add `-EnableEntraGate` to put the whole site behind a single-tenant Microsoft
Entra sign-in instead:

```powershell
.\Deploy-AzureDemo.ps1 -EnableEntraGate
```

That switches the app to the **Standard** plan (roughly 9 USD per month, since
custom identity providers are a Standard feature), creates the app registration
and secret, wires the redirect URI and stores the credentials as app settings.

> **Trade-off:** a tenant gate blocks anonymous phone and QR joins. Only people
> in your tenant can open the demo. Use it for internal-only runs, not for a
> public hub floor.

## The config trap this avoids

`staticwebapp.config.json` in this repository is the **gated** config. It
requires the `authenticated` role on every route and points at a custom OpenID
Connect provider whose tenant id is still the literal `REPLACE_WITH_TENANT_ID`
placeholder.

Uploading that file unchanged would make the entire site return 401 and never
load. The deploy script never does that. It stages content into a temp folder
and writes the correct config for the mode you chose:

- **Anonymous run:** a clean config with an SPA fallback and security headers,
  and no auth block at all.
- **Gated run:** the repository config with your real tenant id substituted in.

Your working tree is never modified either way.

## Common options

```powershell
# Pin the names so the URL stays stable across rebuilds
.\Deploy-AzureDemo.ps1 -ResourceGroup rg-carebot-stl -Name carebot-ctf-stl

# Choose a region (Static Web Apps only exists in these five)
.\Deploy-AzureDemo.ps1 -Location eastus2

# Deploy into a specific subscription
.\Deploy-AzureDemo.ps1 -SubscriptionId <sub-id>

# Provision the resources but do not upload content
.\Deploy-AzureDemo.ps1 -SkipContentDeploy

# Replace the Entra client secret before it expires
.\Deploy-AzureDemo.ps1 -EnableEntraGate -RotateSecret

# Publish with the Static Web Apps CLI instead of the native uploader (needs Node.js)
.\Deploy-AzureDemo.ps1 -UploadMethod SwaCli

# Air-gapped or locked-down machine: download StaticSitesClient elsewhere and reuse it
.\Deploy-AzureDemo.ps1 -StaticSitesClientPath D:\tools\StaticSitesClient.exe
```

Valid regions: `centralus` (default), `eastus2`, `westus2`, `westeurope`,
`eastasia`. `centralus` and `eastus2` are the cheapest US options, though the
Free plan is free in all of them.

## Re-running is safe

The script is idempotent. Re-running it:

- reuses an existing resource group, Static Web App and app registration,
- adds the redirect URI only if it is missing, so a custom domain you added
  earlier survives,
- leaves an existing client secret alone unless you pass `-RotateSecret`,
- redeploys the current `index.html`.

So the normal way to publish a content change is simply to run it again.

## Point the attendee QR at the new host

The in-app QR code and short link come from the **join URL**, which defaults to
the `is.gd` short link, not to wherever you deployed. After deploying, either:

1. open the demo, click **⚙ Settings**, and set the join URL to your new
   `https://<name>.azurestaticapps.net/` address (it is saved per browser), or
2. repoint the existing `is.gd` short link at the new host, which keeps any
   printed QR codes and signage valid.

Option 2 is the better choice once you have printed materials.

## Teardown

```powershell
# Preview
.\Remove-AzureDemo.ps1 -WhatIf

# Delete the resource group (prompts for the group name to confirm)
.\Remove-AzureDemo.ps1

# Also delete the Entra app registration
.\Remove-AzureDemo.ps1 -RemoveAppRegistration
```

The app registration is a separate switch on purpose: it lives in Entra ID, not
in the resource group, so deleting the group alone would leave it orphaned.

## Troubleshooting

**`ERROR: Operation returned an invalid status 'Forbidden'`**
The signed-in account cannot create resource groups in the selected
subscription, which is common when the default subscription is corporate and
policy-locked. The script now probes your other subscriptions and prints the
ones you can deploy into:

```
  Subscriptions you can deploy into:
    My Subscription
      xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Re-run with `-SubscriptionId <id>`. If nothing is listed, no subscription on the
account can create resources: ask for the **Contributor** role, or use an Azure
free trial or Visual Studio benefit subscription. `az account list -o table`
shows everything the account can see.

**`Node.js not found`**
Node.js is no longer needed. The default `-UploadMethod Native` publishes with
Microsoft's `StaticSitesClient` binary and never touches Node. If you see this,
you either passed `-UploadMethod SwaCli` explicitly or are running an older copy
of the script, so pull the latest.

**`az.cmd : ERROR ...` with `FullyQualifiedErrorId : NativeCommandError`**
An older copy of the script. Windows PowerShell 5.1 turns a native command's
stderr into a terminating error, which masked the real message. Current versions
handle this. Pull the latest and re-run.

**Download of StaticSitesClient fails or is blocked**
On a restricted network, download `StaticSitesClient.exe` on another machine
from the URL in
<https://swalocaldeploy.azureedge.net/downloads/versions.json>, copy it over, and
run with `-StaticSitesClientPath <path>`. If the checksum ever fails to match the
manifest, the script refuses to execute the binary by design.

**Node.js is installed and you would rather use the official CLI**
Run with `-UploadMethod SwaCli`.

**The site loads but the 3-screen wall does not stay in sync**
The wall syncs across browser windows using `BroadcastChannel` and
`localStorage`, which need one shared https origin. Launch all three panels from
the same deployed hostname, not from `file://` paths or different hosts.

**Sign-in loops after `-EnableEntraGate`**
The redirect URI must exactly match the deployed hostname. Confirm the app
registration has `https://<host>/.auth/login/entraid/callback`, and that
`ENTRA_CLIENT_ID` and `ENTRA_CLIENT_SECRET` are set in the Static Web App
configuration. Re-running the script repairs both.

**Still serving an old build**
Static Web Apps caches at the edge. Hard-refresh, or add a cache-busting query
string such as `?cb=1` when checking.

## Retiring the GitHub Pages copy

Deploying to Azure does not disable the existing GitHub Pages site. If the Azure
copy is now the canonical one, go to the repository **Settings → Pages** and set
the source to **None**, then update any links, signage and QR codes.
