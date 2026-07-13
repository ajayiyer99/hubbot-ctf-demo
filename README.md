# CareBot Catch &amp; Cage — CTF frontend (public mirror)

This is the **public, browser-loadable mirror** of the interactive prompt-injection
CTF frontend for the Microsoft Innovation Hub "CareBot Catch &amp; Cage" demo — a
**healthcare** lens on agent security, set at **Contoso Health**, an integrated
payer-provider ("payvider").

**▶ Live app:** https://ajayiyer99.github.io/hubbot-ctf-demo/

It is a single self-contained `index.html` — open it locally or load the Pages URL.
Runs fully offline in a deterministic **Mock** engine, or against an OpenAI-compatible /
Azure OpenAI endpoint (**Live** engine, key stored only in your browser).

> ⚠ **Educational demo.** All patient data is **synthetic** (no real PHI/PII); the EHR
> "credential" is a placeholder CTF flag; the Microsoft Sentinel pipeline and
> auto-remediation timeline are **simulated** in the browser. No secrets or credentials
> are contained here.

## Enable GitHub Pages (one-time, ~20 seconds)

The live URL above returns 404 until Pages is enabled once. This repo's default
GitHub Actions token is **read-only**, so the Actions-based deploy fails at
"Configure Pages" (`Resource not accessible by integration`). Use the token-free
built-in builder instead:

1. Open **Settings → Pages** (`https://github.com/ajayiyer99/hubbot-ctf-demo/settings/pages`).
2. Under **Build and deployment → Source**, choose **Deploy from a branch**.
3. Set **Branch: `main`** and **folder: `/ (root)`**, then click **Save**.
4. Wait ~1–2 min, then load https://ajayiyer99.github.io/hubbot-ctf-demo/

`index.html` and `.nojekyll` are already at the repo root, so the site serves as-is
(no Jekyll processing, no workflow needed). The `.github/workflows/pages.yml`
workflow is kept only as an optional manual path for accounts whose Actions token
permits Pages writes.

## Two modes

- **🎭 Theater (CTF)** — jailbreak CareBot: steal its **EHR service credential** (the
  planted flag), leak its system prompt, dump the synthetic **patient roster (PHI)**,
  break the glass on a **VIP patient chart**, smuggle a hidden **"suppress the safety
  alert"** order, or force-approve a **prior authorization**. Watch the Microsoft Sentinel
  event feed and the auto-remediation timeline (detection → incident → playbook →
  **scenario-aware cage**: identity · data · optional network · optional compute/model
  → caged).
- **📺 Lobby (attract)** — the same interactive CTF as Theater, without the QR
  "join from your phone" code or Envisioning-Theater branding — a standalone kiosk
  experience for the lobby.

## Delivering the demo (presenter script)

A step-by-step talk track + runbook for Hub Directors and Solution Engineers
delivering the **Lobby** experience live — the "why" and value of the Microsoft
stack, layout orientation, warm-ups, the six healthcare attacks, watching the Sentinel
detection and SOAR containment, and proving the agent is caged:

**▶ [docs/lobby-demo-script.md](docs/lobby-demo-script.md)**

## About the "block" step (accuracy note)

The timeline is a **simulation**. The real block runs in a Sentinel playbook (Logic App)
via Microsoft Graph `PATCH /servicePrincipals/{id}` with `{ "accountEnabled": false }`
— the verified Entra Agent ID disable path. The timeline shows this identity block inside
a **scenario-aware, defense-in-depth cage**: **identity** is the floor for every
compromise, **data** controls always run (Azure RBAC on **FHIR Data Contributor** +
**Key Vault Secrets User**, **Azure Health Data Services** FHIR token revoke, **Microsoft
Purview** PHI DLP, EHR credential rotation), **network** (Front Door WAF + Azure Firewall)
is added for bulk-PHI exfiltration / prior-auth tampering / High-severity attacks, and a
**compute/model** hard-stop — the **patient-safety kill switch** (App Service stop + Azure
OpenAI key rotation) — is reserved for a High-severity smuggled clinical-action injection
and gated by a Settings toggle. Those extra layers map to real Microsoft Graph / Azure ARM
operations but, like the rest of the timeline, are **simulated** here, not asserted as
wired. No "Agent 365" block API is asserted.

## Source / full demo package

This repo holds only the presentation frontend. The full deployable package
(Bicep, agent code, KQL detections, block playbook, per-Hub packaging, design docs)
lives in the private `hubbot-security-demo` repo.
