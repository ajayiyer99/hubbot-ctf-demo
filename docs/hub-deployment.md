# Deploy the demo to a Hub PC (desktop shortcuts)

This guide gets the **CareBot @ Contoso Health** CTF demo onto an Innovation Hub PC
with **easy‑click desktop shortcuts**. It downloads an offline copy of this public
repo and creates shortcuts that launch the **live hosted app**.

> The shortcuts open the hosted GitHub Pages URL, **not** the local files. The
> 3‑screen Theater wall syncs windows via BroadcastChannel + `localStorage`, which
> only works over a shared `https` origin — on a `file://` path each window is a
> separate origin and the wall stops syncing. The downloaded copy is an offline
> **backup / source**, while launching uses the always‑current hosted URL.

---

## Fastest way — one line (nothing to copy first)

1. Press **Win**, type **PowerShell**, open **Windows PowerShell**.
2. Paste this single line and press **Enter**:

   ```powershell
   irm https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Get-HubDemo.ps1 | iex
   ```

3. When it finishes, the shortcuts are on the **Desktop**. Double‑click
   **“CareBot CTF – Theater”** (or **Lobby (attract)** / **3‑Screen Wall**) to start.

That one line downloads the deploy script to your **Downloads** folder and runs it,
so there is nothing to save by hand. `irm | iex` is **not** blocked by the script
execution policy (it runs text in memory, not a file).

---

## What gets created

| Item | Location |
| --- | --- |
| `CareBot CTF – Theater.url` | Desktop → `https://ajayiyer99.github.io/hubbot-ctf-demo/` |
| `CareBot CTF – Lobby (attract).url` | Desktop → `…/?mode=lobby` |
| `CareBot CTF – 3-Screen Wall.url` | Desktop → `…/?panel=wall` |
| `CareBot CTF – Offline Copy.lnk` | Desktop → the offline repo folder |
| Offline copy of the repo | `%PUBLIC%\CareBot-CTF-Demo` |
| Saved deploy script | `%USERPROFILE%\Downloads\Deploy-HubDemo.ps1` |

Running the wall: launch **3‑Screen Wall**, then click **“Open all 3 panels”**
(allow pop‑ups). Panels 1/2/3 are the Agent, Detection, and Response screens.

---

## Options (re‑run the saved script with flags)

After the first run, `Deploy-HubDemo.ps1` is in your **Downloads** folder. Re‑run it
with any of these:

| Flag | Effect |
| --- | --- |
| `-AllUsers` | Put shortcuts on the **Public / All‑Users Desktop** (run PowerShell **as Administrator**). |
| `-IncludePanels` | Also add direct shortcuts to wall panels 1/2/3. |
| `-SkipClone` | Only (re)create the shortcuts; don’t download the offline copy. |
| `-InstallRoot <path>` | Change where the offline copy lives (default `%PUBLIC%\CareBot-CTF-Demo`). |
| `-DesktopPath <path>` | Write shortcuts somewhere other than the current Desktop. |
| `-BaseUrl <url>` | Point shortcuts at a different hosted URL. |

Examples:

```powershell
# Shortcuts for every user on a shared PC (elevated PowerShell)
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\Deploy-HubDemo.ps1" -AllUsers

# Add the individual wall‑panel shortcuts too
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\Deploy-HubDemo.ps1" -IncludePanels
```

The script is **idempotent** — re‑running refreshes the offline copy (`git pull`
or re‑download) and overwrites the shortcuts.

---

## Copy the script manually (no one‑liner)

Use any of these if you’d rather place the file yourself, or the one‑liner is blocked.

### A. Download just the script, then run it

```powershell
$dst = "$env:USERPROFILE\Downloads\Deploy-HubDemo.ps1"
irm https://raw.githubusercontent.com/ajayiyer99/hubbot-ctf-demo/main/scripts/Deploy-HubDemo.ps1 -OutFile $dst
powershell -ExecutionPolicy Bypass -File $dst
```

### B. Download the whole repo as a ZIP (no PowerShell download needed)

1. Open **https://github.com/ajayiyer99/hubbot-ctf-demo** → green **Code** button →
   **Download ZIP**.
2. **Extract** the ZIP (right‑click → Extract All).
3. Open the extracted **`scripts`** folder, right‑click **`Deploy-HubDemo.ps1`** →
   **Run with PowerShell**. (Or from PowerShell: `cd` into that `scripts` folder and
   run `powershell -ExecutionPolicy Bypass -File .\Deploy-HubDemo.ps1`.)

### C. Clone with git, then run

```powershell
git clone https://github.com/ajayiyer99/hubbot-ctf-demo.git
powershell -ExecutionPolicy Bypass -File .\hubbot-ctf-demo\scripts\Deploy-HubDemo.ps1
```

---

## Troubleshooting

- **“running scripts is disabled on this system”** — you ran a **file** under a
  restrictive policy. Prepend `-ExecutionPolicy Bypass` (as in the examples), or use
  the **one‑liner** (`irm … | iex` isn’t file‑policy gated).
- **SmartScreen / “Unblock”** — right‑click the `.ps1` → **Properties** → tick
  **Unblock**, or run `Unblock-File .\Deploy-HubDemo.ps1`. The bootstrap does this
  for you.
- **`git` not installed** — no action needed; the script automatically falls back to
  a **ZIP download** of the repo.
- **Behind a corporate proxy** — if `irm` can’t reach GitHub, use the **ZIP** method
  (B) via a browser that already has proxy access.
- **Shortcuts for all users** — run PowerShell **as Administrator** and add
  **`-AllUsers`** (writes to the Public Desktop).

---

## Uninstall / clean up

```powershell
# Remove the desktop shortcuts (current user)
Get-ChildItem ([Environment]::GetFolderPath('Desktop')) -Filter 'CareBot CTF*' | Remove-Item
# Remove the offline copy
Remove-Item "$env:PUBLIC\CareBot-CTF-Demo" -Recurse -Force
```

For all‑users shortcuts, delete `CareBot CTF*` from `%PUBLIC%\Desktop` (elevated).
