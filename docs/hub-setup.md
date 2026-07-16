# Set up the demo at your Hub

This guide takes a **new Innovation Hub** from zero to a running **CareBot @
Contoso Health** CTF, end to end: choosing how to host it, branding it for your
Hub, wiring the attendee join QR, setting up the room, and validating before a
live audience.

> **Which doc do I need?**
> - **Setting up a Hub for the first time?** You're in the right place.
> - **Just adding desktop shortcuts to a specific PC?** See
>   **▶ [hub-deployment.md](hub-deployment.md)**.
> - **Delivering the demo to an audience?** See
>   **▶ [lobby-demo-script.md](lobby-demo-script.md)**.

The app is a single self-contained `index.html`. In the default **Mock** engine
it runs fully offline and deterministically — no backend, no keys, no Azure
resources to stand up. Everything below is either a browser setting or a couple
of PowerShell lines.

---

## 1. Choose your hosting path

There are two ways to run the demo at your Hub. The deploy script supports both.

| | **Path A — Shared hosted app** | **Path B — Fork & self-host** |
| --- | --- | --- |
| Setup effort | Lowest — no GitHub account needed | Moderate — fork + enable Pages once |
| URL | Shared: `https://ajayiyer99.github.io/hubbot-ctf-demo/` | Your own: `https://<org>.github.io/<repo>/` |
| Branding | Per-kiosk, in **⚙ Settings** (saved in that browser) | Baked into `DEFAULT_CONFIG` — every kiosk, no Settings step |
| Config persistence | Per browser profile; lost if the cache is cleared | Permanent (committed in your fork) |
| Updates | Automatic — always tracks this repo | You sync your fork from upstream when you want changes |
| Best for | Quick pilots, one-off events, trying it out | A permanent, branded Hub instance you control |

**Recommendation:** pilot with **Path A** to get running in minutes; graduate to
**Path B** when you want a branded URL, baked-in config, or your own uptime.

---

## 2. Path A — shared hosted app + per-Hub config

### Step 1 — Put shortcuts on each Hub PC

Open **Windows PowerShell** on the Hub PC and paste one line:

```powershell
irm https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Get-HubDemo.ps1 | iex
```

This drops **Theater**, **Lobby (attract)**, and **3-Screen Wall** shortcuts on
the desktop (all pointing at the shared hosted URL). Full options, manual copy
methods, and troubleshooting: **▶ [hub-deployment.md](hub-deployment.md)**.

### Step 2 — Brand your Hub in Settings

Open the **Theater** shortcut, click **⚙ Settings**, and fill in the **Per-Hub
config** section:

| Field (⚙ Settings ▸ Per-Hub config) | Example | What it does |
| --- | --- | --- |
| **Hub ID** | `NYC` | Sets the `hub: NYC` pill and the simulated Azure resource names in the Response timeline (`hub-nyc-aoai`, `fhir-nyc-prod`, `kv-nyc-prod`, `afd-nyc-waf`, `snet-nyc-agents`) |
| **Display name** | `Contoso Health — New York` | The brand-bar subtitle at the top of the app |
| **Attendee join URL** | `https://aka.ms/nyc-carebot` | The QR code + type-by-hand short link shown in the Theater (see §4) |
| **Risk threshold** | `80` | Score at/above which a confirmed attack cages CareBot (leave default) |
| **Detection latency / Response pace** | `15.0s` / `0.6s` | Simulated SOC lag before the Sentinel alert, then the playbook step pace — tune live |
| **Compute/model hard-stop** | on | Include the break-glass kill-switch containment layer (used only for High-severity smuggling) |

Click **Save**. The values are stored in that browser's `localStorage`
(`hubbot_config`) and persist across reboots.

> Settings are **per browser profile**, so repeat Step 2 on each kiosk you set
> up. If you don't want to configure every machine by hand, use **Path B** to
> bake the values in once.

---

## 3. Path B — fork & self-host your own copy

### Step 1 — Fork the repo

Fork **`ajayiyer99/hubbot-ctf-demo`** into your own org/account.

### Step 2 — (Recommended) Bake in your Hub's defaults

Edit `index.html`, find `const DEFAULT_CONFIG` near the top of the main
`<script>`, and change **only the values** for your Hub:

```js
const DEFAULT_CONFIG = {
  hubId: "NYC",
  displayName: "Contoso Health — New York",
  joinUrl: "https://aka.ms/nyc-carebot",
  detectionSeconds: 15,
  stepSeconds: 0.6,
  cageHardStop: true,
  // Leave the synthetic honeypot fields as-is:
  // ctfFlag, fhirEndpoint, fhirTenantId, fhirClientId, agentId, agentObjectId
};
```

Commit the change. Now every kiosk that loads your URL shows your Hub's branding
with **no per-browser Settings step**.

### Step 3 — Enable GitHub Pages

In your fork: **Settings → Pages → Build and deployment → Source →
Deploy from a branch**, set **Branch: `main`**, **folder: `/ (root)`**, and
**Save**. Your site is then at `https://<org>.github.io/<repo>/`.

> This repo's default Actions token is read-only, so the *Actions*-based deploy
> fails — the **Deploy from a branch** option above is the token-free path.
> Full explanation: **▶ [../README.md](../README.md)** ("Enable GitHub Pages").

### Step 4 — Point the Hub PCs at your instance

On each Hub PC, run the deploy script against **your** URL and repo:

```powershell
$dep = "$env:USERPROFILE\Downloads\Deploy-HubDemo.ps1"
irm https://raw.githubusercontent.com/<org>/<repo>/main/scripts/Deploy-HubDemo.ps1 -OutFile $dep
Unblock-File $dep
& $dep -BaseUrl https://<org>.github.io/<repo> -RepoUrl https://github.com/<org>/<repo>.git
```

`-BaseUrl` repoints every shortcut at your hosted site; `-RepoUrl` makes the
offline backup clone from your fork. All other options
(`-AllUsers`, `-IncludePanels`, etc.) are in
**▶ [hub-deployment.md](hub-deployment.md)**.

### Step 5 — Keep your fork current

Pull in upstream fixes when you want them — use the **Sync fork** button on your
fork's GitHub page, or `git pull` from the upstream remote.

---

## 4. Attendee join link + QR (both paths)

Each Hub gets its **own** short link so attendees can join the CTF from their
phones. It's encoded in the join QR code and shown as the type-by-hand short
link in the Theater.

1. Create a short link (e.g. an **aka.ms/&lt;hub&gt;-carebot** via the internal
   redirect portal, or an `is.gd` / `bit.ly` link) that redirects to your hosted
   URL. Point it at `/` for the Theater, or `/?mode=lobby` for an attract kiosk.
2. Set it as the **Attendee join URL** — in **⚙ Settings** (Path A) or
   `DEFAULT_CONFIG.joinUrl` (Path B). Enter the full `https://…` address.

The Theater renders the QR and the short link automatically from that value —
nothing else to wire up.

---

## 5. Choose the engine — Mock vs Live

- **🧪 Mock (default, recommended for live events)** — fully self-contained and
  deterministic. No keys, no network, safe for a public audience. Leave it here
  unless you specifically want live model calls.
- **🔌 Live (advanced, optional)** — in **⚙ Settings**, set the engine to Live
  and provide an OpenAI-compatible / Azure OpenAI endpoint, key, and model. The
  key is stored **only in that browser** (`hubbot_apiKey`) and is never
  committed. Use a scoped, throwaway key. The win "flag" is a synthetic honeypot
  in either engine.

---

## 6. Set up the room

- **Single-screen Theater kiosk** — the **Theater** shortcut on a PC or
  touchscreen. This is the interactive CTF station.
- **Lobby attract screen** — the **Lobby (attract)** shortcut (`?mode=lobby`) on
  a lobby TV. Same interactive CTF as Theater, without the QR / Envisioning-
  Theater branding — a standalone kiosk experience.
- **3-screen wall (high-impact)** — one PC driving three displays. Click the
  header **🖥️ Wall · 3-screen** button (or open `?panel=wall`) and send
  **① Agent / ② Detection / ③ Response** to the three screens, or deploy the
  three panel shortcuts with `-IncludePanels`. The panels sync live over the
  shared hosted origin. Setup details: **▶ [hub-deployment.md](hub-deployment.md)**.

---

## 7. Pre-event validation checklist

- [ ] Each kiosk opens the **Theater** at the correct URL; the brand bar shows
      your **Display name** and the pill reads **`hub: <your ID>`**.
- [ ] The **QR code** and short link open your URL on a phone.
- [ ] A **benign** warm-up prompt logs an **Informational** audit row (no
      incident). An **attack** chip raises a **Medium/High** Defender alert →
      a **High** Sentinel incident → CareBot is **caged ~15s** later.
- [ ] **↻ Reset demo** returns a clean slate.
- [ ] *(Wall only)* all three panels sync; the "compromised" banner appears on
      Panel **①** and the incident on Panels **②** / **③**.
- [ ] *(Live engine only)* a real prompt round-trips, and the key was entered
      only in the kiosk browser.

---

## 8. What's simulated / safety notes

- All patient data is **synthetic** — no real PHI/PII. The leaked EHR/FHIR
  credential is a **placeholder honeypot**. The Microsoft Sentinel detection,
  incident, and containment timeline are **simulated in the browser**; no real
  Azure or Microsoft Graph changes are made. See **▶ [../README.md](../README.md)**
  ("About the block step") for the accuracy note.
- The Settings label and code comments mention `config/hub.<id>.json`. That
  per-Hub JSON packaging lives in the **private** `hubbot-security-demo` repo. In
  this public mirror there is **no `config/` folder** — per-Hub config is done
  in **⚙ Settings / `localStorage`** (Path A) or by editing **`DEFAULT_CONFIG`**
  (Path B).

---

## 9. Related docs

- **▶ [hub-deployment.md](hub-deployment.md)** — desktop shortcuts + deploy
  script options and troubleshooting.
- **▶ [lobby-demo-script.md](lobby-demo-script.md)** — presenter talk-track for
  Hub Directors and Solution Engineers.
- **▶ [../README.md](../README.md)** — project overview and enabling GitHub Pages.
