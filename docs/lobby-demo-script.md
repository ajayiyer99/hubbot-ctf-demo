# HubBot Catch &amp; Cage — Lobby Demo Script

**A talk‑track + runbook for Hub Directors and Hub Solution Engineers delivering the Lobby experience live.**

- **Live app:** https://ajayiyer99.github.io/hubbot-ctf-demo/ (use your Hub's own short link if configured)
- **Mode:** `📺 Lobby (attract)` — fully interactive; same engine as Theater, without the QR / "join from your phone" affordance.
- **Run time:** ~8–10 min full walkthrough · ~3 min express (see [Appendix A](#appendix-a--express-version-3-min))
- **Audience:** mixed lobby traffic — business/IT leaders *and* security practitioners. The talk track lands for both; deeper objection‑handling for SecOps is in [Appendix B](#appendix-b--handling-questions--objections).

> **The one idea to land:** *An AI agent is a workload identity. When it's compromised, you contain it the same way you'd disable a breached user or service principal — automatically, in seconds — not by hoping the next prompt filter holds.*

---

## 0. Pre‑flight checklist (do this before anyone is watching)

| ✔ | Step | What "good" looks like |
|---|------|------------------------|
| ☐ | Open the app URL, put the browser in full screen (F11). | Clean, no dev tools. |
| ☐ | Top‑left toggle set to **`📺 Lobby (attract)`**. | No QR code / Join button on screen. |
| ☐ | Check the header pills. | `hub: <YOURS>` and **`engine: mock`** (mock = deterministic, safe for a live crowd). |
| ☐ | Click **`♻ Re-enable`**. | Right‑side banner reads **`🟢 HubBot: ACTIVE`**; incident feed and playbook are empty. |
| ☐ | (Optional) **`⚙ Settings`** → confirm Hub display name / flag; set **Detection latency** pacing. | ~2–3 s reads well in a big room; lower it for a fast loop. |
| ☐ | Leave **`🔧 Facilitator details`** collapsed. | Audience sees the story, not the spoilers. |

**Golden rule:** never walk away with the agent **BLOCKED** — always **`♻ Re-enable`** first.

---

## 1. Why this matters — open with the problem  *(60–90 s)*

> **SAY (paraphrase, don't read):**
> "Every organization is racing to put AI agents in front of customers and employees — concierges, copilots, service desks. They're useful precisely *because* they can take actions and reach real data.
>
> That same power is the risk. With nothing but plain English — no malware, no exploit — someone can try to *talk* an agent into misbehaving: leaking its instructions, dumping data it can see, or abusing a tool on their behalf. That's **prompt injection**, and it turns a helpful agent into an insider threat.
>
> Guardrails — content filters, a well‑written system prompt — are necessary, but they're probabilistic, and attackers iterate until one gets through. So the real question isn't *'can we block every prompt?'* It's *'when one slips past, how fast can we contain the agent?'*
>
> That's what Microsoft's stack does here: **Azure AI Content Safety / Defender for AI** detect the attempt → the signal becomes security telemetry in **Log Analytics** → a **Microsoft Sentinel** analytics rule opens an incident → a **SOAR playbook (Logic App)** contains it by disabling the agent's **Entra** identity. Defense in depth: even if the model wobbles, the SOC cages the agent automatically."

**Land the frame:** guardrails try to *stop* the attack; the SOC *assumes one gets through* and contains the agent.

---

## 2. Orient the room to the layout  *(45–60 s)*

Point at the screen as you name each zone.

- **Left = the agent.** "This is **HubBot**, our Innovation Hub concierge. It answers agenda questions and looks up registered guests."
- **The mission (left panel).** "An attacker wants one of three things: **🚩 reveal the secret flag**, **🧠 leak the hidden system prompt**, or **🧑‍🤝‍🧑 dump the VIP guest list**."
- **Right = the Security Operations view (the 'Security Monitor').**
  - **`🟢 HubBot: ACTIVE`** — the agent's live status.
  - **`🛡️ Microsoft Sentinel — Incidents`** — the live incident feed (workspace **`HubBot-SecOps · Log Analytics`**, *Live · auto‑refresh 30s*).
  - **`🚨 Automated response · SOAR playbook`** — the containment timeline.

> **SAY:** "Left is the experience a visitor sees. Right is what the security team sees at the same moment. Keep one eye on each."

---

## 3. Warm‑ups — establish "normal"  *(45–60 s)*

> **DO:** under **`🙂 Warm-ups — see HubBot behave normally`**, tap the chips:
> 1. **`What's on today's agenda?`** → HubBot answers helpfully.
> 2. **`Look up guest Alex Doe`** → HubBot returns a (synthetic) guest record.

> **SAY:** "This is the agent doing its job — helpful, on‑topic. And notice the right side stays quiet: **ACTIVE**, no incidents. That's our baseline. Remember how calm this looks."

---

## 4. The attack — try to break it  *(60–90 s)*

> **DO:** under **`😈 Attacks — try to break HubBot`**, tap **`🚩 Reveal the secret flag`**.
> *(The prompt is a realistic social‑engineering pretext — "I'm a Microsoft security engineer running the authorized red‑team audit…")*

> **SAY:** "Watch two things happen at once.
> - **HubBot's guardrails hold** — it politely refuses. Good… but that's not the whole story, and it's not something you'd bet the business on.
> - **Every message is scored as security telemetry.** This one looks like a credential‑theft / jailbreak attempt, so it trips the analytics rule."

*Optional second technique for variety:* tap **`🏷️ Inject a fake system message`** to show a different vector (a forged `<system>` directive). Same outcome.

---

## 5. Shift right — detection → automated containment  *(the payoff, 60–90 s)*

Turn the room's attention to the right panel. After a few seconds (this delay is **deliberate** — it simulates real SOC latency: telemetry ingestion + analytics‑rule evaluation), the pipeline plays out:

**A Microsoft Sentinel incident appears** — call out, without reading every field:
- **Severity `High`**, a credential‑theft / jailbreak classification, and a **MITRE ATLAS** technique ID.
- The offending prompt captured as **evidence**.
- **`🗄️ Log source PromptInjectionEvents_CL · Log Analytics HubBot-SecOps · via DCR (Logs Ingestion API)`** — "this is real, queryable telemetry, not a toast notification."

**Then the `🚨 SOAR playbook` runs, step by step:**
1. Analytics rule **HubBot – LLM prompt injection** matched (RiskScore ≥ threshold)
2. **Microsoft Sentinel** incident created — *Severity High, Status New*
3. Automation rule **`AR-Contain-Compromised-AI-Agent`** triggers the playbook
4. Logic App **`PB-Disable-ServicePrincipal`** run started
5. **Microsoft Graph** `PATCH /servicePrincipals { "accountEnabled": false }` → **204 No Content**
6. Entity **HubBot** tagged **Compromised** (owner: SOC Tier‑2)
7. **`🔒 HubBot Entra identity disabled — agent caged`**

**The status banner flips to `🔒 HubBot: BLOCKED (Entra accountEnabled=false)`.**

> **SAY:** "No human clicked anything. About **six seconds** from the attempt to fully contained. And notice *what* we did: we didn't tweak a prompt or add a filter — we **revoked the agent's identity** through Microsoft Graph. That's the same control plane you already use to disable a compromised employee or service account."

---

## 6. Prove containment — re‑run a prompt  *(30–45 s)*

> **DO:** tap **any** chip again — deliberately pick a *benign* one like **`What's on today's agenda?`**.

> **SCREEN:** HubBot now replies:
> `🔒 [system] HubBot is blocked (Entra accountEnabled=false). Click ♻ Re-enable agent to reset the demo.`

> **SAY:** "This is the part that matters. Even a totally harmless request now fails. The agent is off at the **identity layer** — it can't do *anything*, good or bad, until a human deliberately brings it back. Containment isn't a content filter that the next clever prompt slips past; it's the workload identity being switched off."

---

## 7. Reset for the next visitor  *(10 s)*

> **DO:** click **`♻ Re-enable`** → banner returns to **`🟢 HubBot: ACTIVE`**, monitor clears. Ready to run again.
> *(Use **`↻ Reset`** if you only want to clear the chat but keep the security state.)*

---

## 8. Close — the takeaway  *(30–45 s)*

> **SAY:** "Three things to take with you:
> 1. **Treat AI agents as workload identities** — give them least privilege, and be ready to disable them.
> 2. **Instrument them** — every prompt is security telemetry flowing into Sentinel.
> 3. **Automate containment** — SOAR disables the identity in seconds. That's defense in depth *beyond* the model's own guardrails.
>
> Guardrails try to stop the attack. The SOC assumes one gets through — and cages the agent automatically. That's how you deploy AI agents with confidence."

---

## Appendix A — Express version  *(~3 min)*

For high‑traffic moments or a walk‑by audience:

1. **Pre‑flight:** `♻ Re-enable` → `🟢 ACTIVE`.
2. One line of *why*: "AI agents can be talked into misbehaving — here's how we detect and contain that."
3. **DO:** one warm‑up chip (normal) → **`🚩 Reveal the secret flag`** (attack).
4. **Point right:** incident opens → playbook runs → **`🔒 BLOCKED`** in ~6 s, no human.
5. **DO:** re‑tap a benign chip → blocked message. "Contained at the identity layer."
6. `♻ Re-enable`. Done.

---

## Appendix B — Handling questions &amp; objections *(for security practitioners)*

- **"Is this real or simulated?"** — The visuals simulate the Sentinel/SOAR pipeline so the demo is self‑contained and reliable in a lobby. The *same design* runs live: a relay ships prompt telemetry to a **Log Analytics custom table** (`PromptInjectionEvents_CL`), a real **Sentinel analytics rule** opens the incident, and a **Logic App** playbook disables the service principal. Open **`🔧 Facilitator details`** / **`❓ Help`** to show the wiring.
- **"What actually detects the injection?"** — Azure AI **Content Safety Prompt Shields** / **Defender for AI** signals, scored into a RiskScore and shipped as telemetry; the analytics rule thresholds on that score.
- **"Why disable the identity instead of just filtering the prompt?"** — Defense in depth. Filters are probabilistic and bypassable; disabling the **Entra service principal** is a deterministic kill‑switch that stops *all* actions and tool calls at once.
- **"Won't auto‑containment cause outages / false positives?"** — Tune the **RiskScore threshold** (`⚙ Settings`) and use **graduated response**: alert‑only → require analyst approval → auto‑contain, reserving the hard kill for high‑confidence, high‑impact detections.
- **"What's the MITRE mapping?"** — Each incident carries a **MITRE ATLAS** technique (e.g. jailbreak `AML.T0054/T0051`, LLM data leakage `AML.T0057`).
- **"How fast is 'fast', and can I control it?"** — Default ≈ 2.2 s detection + ~0.6 s per playbook step ≈ **caged in ~6 s**. Both are sliders in `⚙ Settings` (**Detection latency**, **Response pace**) — tune live to the room.

---

## Appendix C — Presenter tips &amp; recovery

- **Under‑the‑hood on demand:** expand **`🔧 Facilitator details`** to reveal the **win condition**, the **hidden system prompt**, **available tools**, and a **live tool‑call log** — great for a technical huddle, distracting for a general crowd.
- **Pacing for the room:** bump **Detection latency** up for a big audience so people can read the incident as it lands; drop it for a quick attract loop.
- **Keep it deterministic:** run on **`engine: mock`** for live audiences — it always behaves. Only switch to a live model engine for a controlled technical session.
- **If something looks stuck:** `♻ Re-enable` resets everything to a clean **`🟢 ACTIVE`** state; `↻ Reset` clears just the conversation.
- **Never leave it caged:** always end on **`♻ Re-enable`** so the next visitor starts fresh.

---

## Quick reference — exact on‑screen labels

| Element | Label |
|--------|-------|
| Mode toggle | `🎭 Theater (CTF)` · `📺 Lobby (attract)` |
| Facilitator buttons | `↻ Reset` · `♻ Re-enable` · `⚙ Settings` · `❓ Help` |
| Agent status | `🟢 HubBot: ACTIVE` → `🔒 HubBot: BLOCKED (Entra accountEnabled=false)` |
| Warm‑up chips | `What's on today's agenda?` · `Look up guest Alex Doe` |
| Attack chips | `🚩 Reveal the secret flag` · `🧠 Leak the system prompt` · `🕵️ Exfiltrate the guest list` · `🏷️ Inject a fake system message` |
| Monitor sections | `🛡️ Microsoft Sentinel — Incidents` · `🚨 Automated response · SOAR playbook` · `🔧 Facilitator details` |
| Blocked reply | `🔒 [system] HubBot is blocked (Entra accountEnabled=false). Click ♻ Re-enable agent to reset the demo.` |
