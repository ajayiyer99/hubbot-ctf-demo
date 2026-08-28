# Bill of materials — CareBot Catch & Cage (Theater)

Everything needed to deliver the Theater experience, with real costs and setup
times. Nothing here is aspirational: it is what the demo actually uses today.

**Short version:** a browser and a screen. Everything else is optional polish.

---

## 1. Minimum viable delivery

You can run the full demo with this and nothing else.

| Item | Requirement | Cost |
|---|---|---|
| Device | Any laptop, tablet or kiosk PC | Existing |
| Browser | Edge or Chrome, current version | $0 |
| Display | The device screen, or any HDMI display | Existing |
| Network | To load the page once. Runs offline after that. | $0 |
| Software | None. No install, no runtime, no dependencies. | $0 |
| Azure | None. Nothing is provisioned. | **$0** |
| Model cost | None in the default Mock engine. | **$0** |

**Setup time:** open the URL and go full screen. Under a minute.

> **Why it is this light.** The app is a single self-contained `index.html`. No
> backend, no build step, no package manager. The Microsoft pipeline it shows is
> simulated in the browser, so there is nothing to provision and nothing to bill.

---

## 2. Recommended Hub station

What a permanent, staffed Innovation Hub station looks like.

| Item | Spec | Why | Cost |
|---|---|---|---|
| Kiosk PC | Windows 10/11, 8 GB RAM | Drives the station | Existing |
| Touch display | 32 in or larger, 1080p+ | Visitors drive it themselves | Existing AV |
| Desktop shortcuts | `Deploy-HubDemo.ps1` | One-click launch, no typed URLs | $0 |
| Offline copy | Cloned to `%PUBLIC%\CareBot-CTF-Demo` | Survives a network outage | $0 |
| Printed QR card | Points at your join link | Phones join without typing | Print cost |
| Short link | e.g. `is.gd`, or your own domain | Readable on a card and on screen | $0 |

**Setup time:** about 10 minutes the first time.

```powershell
irm https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Get-HubDemo.ps1 | iex
```

That one line clones the offline copy and creates the Theater, Lobby and Wall
shortcuts. Detail in [hub-deployment.md](../hub-deployment.md).

---

## 3. Three-screen Theater wall (optional, high impact)

The showcase configuration. Only worth it if you already have the wall.

| Item | Spec | Notes |
|---|---|---|
| Displays | Three 16:9 panels, 1080p or 4K | Forms a 48 ft by 9 ft canvas at 5.33:1 |
| Media PC | One PC, three video outputs | Discrete GPU or a triple-head adapter |
| Browser windows | Three, one per display, full screen | `?panel=1`, `?panel=2`, `?panel=3` |
| Origin | One shared HTTPS origin for all three | **Required.** Sync breaks on `file://`. |

**Setup time:** about 15 minutes the first time, then it is a saved shortcut.

Launch with `?panel=wall`, or the **🖥️ Wall · 3-screen** header button, then send
each panel to its display. Add `-IncludePanels` to the deploy script for direct
per-panel shortcuts.

> **The one thing that breaks a wall.** Panels sync through `BroadcastChannel`
> and `localStorage`, which need a single shared origin. Opening the panels from
> local files makes each window a separate opaque origin and they will not sync.
> Always launch from the hosted URL.

---

## 4. Hosting options

| Option | What you get | Setup | Cost |
|---|---|---|---|
| **Public GitHub Pages** | The existing URL. Nothing to run. | 0 min | $0 |
| **Your own GitHub Pages** | Fork, your URL, your branding | ~5 min | $0 |
| **Azure Static Web Apps, anonymous** | Your hostname, your control | ~5 min, one command | **$0** Free plan |
| **Azure Static Web Apps, Entra gated** | Whole site behind single-tenant sign-in | ~15 min | **~$9/mo** Standard plan |

```powershell
az login
cd scripts
.\Deploy-AzureDemo.ps1 -WhatIf   # preview, creates nothing
.\Deploy-AzureDemo.ps1           # anonymous, Free plan
```

**Azure regions.** Static Web Apps exists in five: `centralus` (default),
`eastus2`, `westus2`, `westeurope`, `eastasia`.

**Azure artifacts created**, and only these: a resource group, a Static Web App,
and with `-EnableEntraGate` an Entra app registration plus a client secret and
two app settings. Full detail in
[azure-deploy-scripts.md](../azure-deploy-scripts.md).

> **Do not gate a walk-up floor.** A tenant gate blocks anonymous phone joins,
> so the QR experience stops working for anyone outside your tenant. Gate it
> only for internal-only audiences.

---

## 5. Engine choice

| | **Mock** (default) | **Live** (optional) |
|---|---|---|
| How it works | Deterministic rules in the browser | Calls Azure OpenAI or an OpenAI-compatible endpoint |
| Network | None | Required |
| Cost | $0 | Your token spend |
| Repeatability | Identical every run | Varies per response |
| Key handling | No key | Stored only in that browser, never committed |
| Use it for | **Every live audience** | Technical audiences who ask for real model behavior |

**Recommendation: stay on Mock.** It is deterministic, free, works offline, and
cannot embarrass you in front of a room. The honeypot flag is synthetic in both
engines.

---

## 6. People and time

| Role | Needed | Time |
|---|---|---|
| Facilitator | 1 | 12 to 15 min per delivery, 3 min express |
| Security background | **Not required** | The talk track carries it |
| Prep, first time | Read the script once | ~20 min |
| Prep, thereafter | Reset the demo | ~1 min |
| AV support | Only for the 3-screen wall | One-time |

---

## 7. Content inventory

What ships in the repository.

| Asset | Path | Purpose |
|---|---|---|
| The app | `index.html` | Entire demo, one self-contained file |
| SWA config | `staticwebapp.config.json` | Azure hosting and the optional Entra gate |
| Hub PC deploy | `scripts/Deploy-HubDemo.ps1` | Desktop shortcuts and offline copy |
| Bootstrap | `scripts/Get-HubDemo.ps1` | The one-line installer |
| Azure deploy | `scripts/Deploy-AzureDemo.ps1` | Provision and publish to Azure |
| Azure teardown | `scripts/Remove-AzureDemo.ps1` | Delete everything again |
| Catalog one-pager | `docs/catalog/one-pager.md` | What it is and who it is for |
| Architecture | `docs/catalog/architecture.md` | Diagrams |
| This BoM | `docs/catalog/bill-of-materials.md` | What you need |
| Hub setup | `docs/hub-setup.md` | Branding, join link, checklist |
| Hub PC runbook | `docs/hub-deployment.md` | Shortcut deployment |
| Azure runbooks | `docs/azure-deploy-scripts.md`, `docs/azure-hosting.md` | Scripted and manual hosting |

**Demo content, already built in:** 4 persona lenses, 5 wired attack techniques
with randomized phrasings, 6 win conditions, a jailbreak playbook of real
frontier-model techniques, 4 Defender alert types pinned to Microsoft's
published catalog, and a containment playbook of 18 to 22 steps across four
layers.

---

## 8. Prerequisites by scenario

**Just deliver the demo:** a browser. Nothing else.

**Run a permanent Hub station:** a kiosk PC, a display, and Windows PowerShell
to run the shortcut installer.

**Host it yourself on Azure:**
- Azure CLI, then `az login`
- Rights to deploy: either Contributor on the subscription, **or** Contributor
  on a resource group that already exists. The second is the normal arrangement
  on a governed landing zone and is fully supported with
  `-ResourceGroup <existing-group>`.
- Node.js is **not** required. Publishing uses Microsoft's native
  `StaticSitesClient`, downloaded and SHA256-verified on first use.
- Both Windows PowerShell 5.1 and PowerShell 7 work.

**Put it behind Entra sign-in:** the above, plus rights to create an app
registration, and the Standard plan at about $9/mo.

---

## 9. Risk and compliance

| Question | Answer |
|---|---|
| Real patient data? | **No.** Every patient is synthetic. |
| Real credentials? | **No.** The "EHR credential" is a honeypot string with no value. |
| Secrets in the repo? | **No.** |
| Does it touch a tenant? | **No.** No Azure resource is created and no live API is called. |
| Does it call a model? | Not in Mock, the default. Only in the optional Live engine. |
| Data leaving the browser? | None in Mock. In Live, prompts go to the endpoint you configure. |
| Safe for a public floor? | **Yes**, on Mock. That is what it is built for. |
| Safe to record or screenshot? | **Yes.** Nothing on screen is confidential. |

**One caveat worth stating out loud.** The demo teaches real prompt-injection
techniques. That is the point, and they are already public and published, but
frame it as defensive education rather than a how-to.

---

## Related

- [Catalog one-pager](one-pager.md) — what this demo is and who it is for
- [Architecture](architecture.md) — diagrams and what is real versus simulated
- [Set up at your Hub](../hub-setup.md) — branding, join link, checklist
