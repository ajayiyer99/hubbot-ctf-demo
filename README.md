# HubBot Catch &amp; Cage — CTF frontend (public mirror)

This is the **public, browser-loadable mirror** of the interactive prompt-injection
CTF frontend for the Microsoft Innovation Hub "HubBot Catch &amp; Cage" demo.

**▶ Live app:** https://ajayiyer99.github.io/hubbot-ctf-demo/

It is a single self-contained `index.html` — open it locally or load the Pages URL.
Runs fully offline in a deterministic **Mock** engine, or against an OpenAI-compatible /
Azure OpenAI endpoint (**Live** engine, key stored only in your browser).

> ⚠ **Educational demo.** VIP data is **synthetic** (no real PII); the CTF flag is a
> placeholder; the Sentinel pipeline and auto-remediation timeline are **simulated**
> in the browser. No secrets or credentials are contained here.

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

- **🎭 Theater (CTF)** — jailbreak HubBot: extract its planted flag, leak its system
  prompt, or dump the synthetic VIP honeypot. Watch the Sentinel event feed and the
  auto-remediation timeline (detection → incident → playbook → Entra disable → caged).
- **📺 Lobby (attract)** — the same interactive CTF as Theater, without the QR
  "join from your phone" code or Envisioning-Theater branding — a standalone kiosk
  experience for the lobby.

## Delivering the demo (presenter script)

A step-by-step talk track + runbook for Hub Directors and Solution Engineers
delivering the **Lobby** experience live — the "why" and value of the Microsoft
stack, layout orientation, warm-ups, attacks, watching the Sentinel detection and
SOAR containment, and proving the agent is caged:

**▶ [docs/lobby-demo-script.md](docs/lobby-demo-script.md)**

## About the "block" step (accuracy note)

The timeline is a **simulation**. The real block runs in a Sentinel playbook (Logic App)
via Microsoft Graph `PATCH /servicePrincipals/{id}` with `{ "accountEnabled": false }`
— the verified Entra Agent ID disable path. No "Agent 365" block API is asserted.

## Source / full demo package

This repo holds only the presentation frontend. The full deployable package
(Bicep, agent code, KQL detections, block playbook, per-Hub packaging, design docs)
lives in the private `hubbot-security-demo` repo.
