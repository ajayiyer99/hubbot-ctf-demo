# Bill of materials — CareBot Catch & Cage (Theater)

Everything needed to deliver the Theater experience, with real costs and setup
times. Nothing here is aspirational: it is what the demo actually uses today.

**Short version:** the Theater Main PC, Edge, and the Theater display. No
install, no Azure, no cost.

---

## 1. What the Theater needs

This runs the full demo. Nothing else is required.

| Item | Requirement | Cost |
|---|---|---|
| Main PC | Windows 10/11, 8 GB RAM | Existing |
| Browser | Edge, current version | $0 |
| Display | Envisioning Theater display | Existing |
| URL | [aka.ms/hub/carebot-demo](https://aka.ms/hub/carebot-demo), sign in with your Microsoft account | $0 |
| Network | To load the page once. Runs offline after that. | $0 |
| Software | None. No install, no runtime, no dependencies. | $0 |
| Azure | None. Nothing is provisioned. | **$0** |
| Model cost | None in the default Mock engine. | **$0** |

**Setup time:** open the URL and go full screen. Under a minute.

> **The Hub link is tenant gated.** You sign in once on the Main PC and it is
> remembered. Attendee phones cannot join it anonymously, so run the demo from
> the room's screen. If you specifically want the phone-join QR, host an
> anonymous copy of your own.

> **Why it is this light.** The app is a single self-contained `index.html`. No
> backend, no build step, no package manager. The Microsoft pipeline it shows is
> simulated in the browser, so there is nothing to provision and nothing to bill.

---

## 2. Three-screen Theater wall (optional, high impact)

The showcase configuration, and the only one that makes detection dwell time
visible: panel 1 goes red before panel 3 does.

| Item | Spec | Notes |
|---|---|---|
| Displays | Three 16:9 panels, 1080p or 4K | Forms a 48 ft by 9 ft canvas at 5.33:1 |
| Media PC | The Main PC, three video outputs | Discrete GPU or a triple-head adapter |
| Browser windows | Three, one per display, full screen | `?panel=1`, `?panel=2`, `?panel=3` |
| Origin | One shared HTTPS origin for all three | **Required.** Sync breaks on `file://`. |

**Setup time:** about 15 minutes the first time, then it is a saved shortcut.

Launch with `?panel=wall`, or the **🖥️ Wall · 3-screen** header button, then send
each panel to its display. Add `-IncludePanels` to
[`scripts/Deploy-HubDemo.ps1`](../../scripts/Deploy-HubDemo.ps1) for direct
per-panel desktop shortcuts on the Main PC.

> **The one thing that breaks a wall.** Panels sync through `BroadcastChannel`
> and `localStorage`, which need a single shared origin. Opening the panels from
> local files makes each window a separate opaque origin and they will not sync.
> Always launch from the hosted URL.

---

## 3. People and time

| Role | Needed | Time |
|---|---|---|
| Facilitator | 1 | 12 to 15 min per delivery, 3 min express |
| Security background | **Not required** | The talk track carries it |
| Prep, first time | Read the script once | ~20 min |
| Prep, thereafter | Reset the demo | ~1 min |
| AV support | Only for the 3-screen wall | One-time |

---

## 4. Risk and compliance

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
