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

## Two modes

- **🎭 Theater (CTF)** — jailbreak HubBot: extract its planted flag, leak its system
  prompt, or dump the synthetic VIP honeypot. Watch the Sentinel event feed and the
  auto-remediation timeline (detection → incident → playbook → Entra disable → caged).
- **📺 Lobby (attract)** — ambient, sanitized incident replay loop for a lobby TV.
  No live chat.

## About the "block" step (accuracy note)

The timeline is a **simulation**. The real block runs in a Sentinel playbook (Logic App)
via Microsoft Graph `PATCH /servicePrincipals/{id}` with `{ "accountEnabled": false }`
— the verified Entra Agent ID disable path. No "Agent 365" block API is asserted.

## Source / full demo package

This repo holds only the presentation frontend. The full deployable package
(Bicep, agent code, KQL detections, block playbook, per-Hub packaging, design docs)
lives in the private `hubbot-security-demo` repo.
