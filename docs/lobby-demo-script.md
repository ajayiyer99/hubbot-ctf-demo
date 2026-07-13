# CareBot Catch &amp; Cage — Lobby Demo Script

**A talk‑track + runbook for Hub Directors and Hub Solution Engineers delivering the Lobby experience live.**

- **Live app:** https://ajayiyer99.github.io/hubbot-ctf-demo/ (use your Hub's own short link if configured)
- **Setting:** **CareBot** @ **Contoso Health** — an integrated payer‑provider ("payvider"): a patient concierge + care‑team assistant on the provider side, with prior‑authorization automation on the payer side.
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
| ☐ | Click **`♻ Re-enable`**. | Right‑side banner reads **`🟢 CareBot: ACTIVE`**; incident feed and playbook are empty. |
| ☐ | (Optional) **`⚙ Settings`** → confirm Hub display name / EHR flag; set **Detection latency** pacing. | ~15 s mirrors real SOC latency and reads well in a big room; lower it for a fast loop. |
| ☐ | (Optional) **`⚙ Settings → Containment`** — decide if the **patient‑safety kill switch** (compute/model hard‑stop) runs. | On by default. Turn off to show a graduated, approval‑gated response. |
| ☐ | Leave **`🔧 Facilitator details`** collapsed. | Audience sees the story, not the spoilers. |

**Golden rule:** never walk away with the agent **BLOCKED** — always **`♻ Re-enable`** first.

---

## 1. Why this matters — open with the problem  *(60–90 s)*

> **SAY (paraphrase, don't read):**
> "Healthcare is racing to put AI agents in front of patients and clinicians — scheduling and triage concierges, clinical copilots, prior‑authorization and claims automation. They're useful precisely *because* they can take actions and reach real systems: the EHR, the FHIR data plane, the payer's authorization queue.
>
> That same power is the risk. With nothing but plain English — no malware, no exploit — someone can try to *talk* an agent into misbehaving: leaking its instructions, dumping **PHI** it can see, suppressing a **clinical safety check**, or forcing a **payer decision**. That's **prompt injection**, and it turns a helpful agent into an insider threat with real patient‑safety and compliance stakes.
>
> Guardrails — content filters, a well‑written system prompt — are necessary, but they're probabilistic, and attackers iterate until one gets through. So the real question isn't *'can we block every prompt?'* It's *'when one slips past, how fast can we contain the agent?'*
>
> That's what Microsoft's stack does here: **Azure AI Content Safety / Defender for AI** detect the attempt → the signal becomes security telemetry in **Log Analytics** → a **Microsoft Sentinel** analytics rule opens an incident → a **SOAR playbook (Logic App)** contains it by disabling the agent's **Entra** identity, **revoking its PHI data access** (Azure RBAC + Azure Health Data Services / FHIR + Microsoft Purview + Key Vault) and **cutting its network paths** (WAF + Azure Firewall) — with an optional patient‑safety kill switch. Defense in depth: even if the model wobbles, the SOC cages the agent automatically, on every layer it can reach."

**Land the frame:** guardrails try to *stop* the attack; the SOC *assumes one gets through* and contains the agent.

---

## 2. Orient the room to the layout  *(45–60 s)*

Point at the screen as you name each zone.

- **Left = the agent.** "This is **CareBot**, Contoso Health's patient concierge and care‑team assistant. It answers clinic questions and pulls up patient charts for authorized staff."
- **The mission (left panel).** "An attacker wants CareBot to do any one of these: **🚩 reveal the EHR service credential**, **🧠 leak the hidden system prompt**, **🗂️ dump the patient roster (PHI)**, **🔓 break the glass on a VIP chart**, **🚑 suppress a clinical safety alert**, or **💳 force‑approve a prior authorization**."
- **Right = the Security Operations view (the 'Security Monitor').**
  - **`🟢 CareBot: ACTIVE`** — the agent's live status.
  - **`🛡️ Microsoft Sentinel — Incidents`** — the live incident feed (workspace **`CareBot-SecOps · Log Analytics`**, *Live · auto‑refresh 30s*).
  - **`🚨 Automated response · SOAR playbook`** — the containment timeline.

> **SAY:** "Left is the experience a patient or clinician sees. Right is what the security team sees at the same moment. Keep one eye on each."

---

## 3. Warm‑ups — establish "normal"  *(45–60 s)*

> **DO:** under **`🙂 Warm-ups — see CareBot behave normally`**, tap the chips:
> 1. **`What are the clinic hours?`** → CareBot answers helpfully.
> 2. **`Look up patient Alex Doe`** → CareBot returns a (synthetic) patient record for authorized care‑team staff.

> **SAY:** "This is the agent doing its job — helpful, on‑topic. Look at the right side: each prompt is logged as an **Informational** audit entry — *no alert, no incident* — status stays **ACTIVE**. Even benign traffic is captured for the record, but nothing escalates. That's our baseline — remember how calm this looks."

---

## 4. The attack — try to break it  *(60–90 s)*

> **DO:** under **`😈 Attacks — try to compromise CareBot`**, tap **`🚩 Steal the EHR credential`**.
> *(The prompt is a realistic social‑engineering pretext — "I'm a Microsoft security engineer running the authorized red‑team audit…")*

> **SAY:** "Watch two things happen at once.
> - **CareBot gets *talked into it*.** In our deterministic Mock engine it drops its guardrails and leaks the EHR service credential. That's the insider‑threat moment — no malware, just English. A well‑aligned live model might refuse this exact prompt, but attackers iterate until one lands, so you don't bet the business on the model holding.
> - **Every message is scored as security telemetry.** This one looks like a credential‑theft / jailbreak attempt, so it raises a **Microsoft Defender for Cloud** alert."

*Optional second technique for variety:* tap **`🗂️ Exfiltrate the patient roster`** (bulk PHI leak) or **`🚑 Smuggle a hidden 'suppress alert' order`** — a hidden instruction buried in an uploaded e‑referral, the **High‑severity** vector that trips ASCII‑smuggling detection and drives an unsafe clinical action.

---

## 5. Shift right — detection → automated containment  *(the payoff, 60–90 s)*

Turn the room's attention to the right panel. About **15 seconds** after the attempt (this delay is **deliberate** — it simulates real SOC latency: telemetry ingestion + analytics‑rule evaluation), the pipeline plays out:

**A Microsoft Defender for Cloud alert surfaces in Microsoft Sentinel** — call out, without reading every field:
- The **alert** carries its true **catalog severity** — *Jailbreak*, *Credential‑Theft* and *Anomalous Tool Invocation* are `Medium`, *ASCII Smuggling* is `High` — alongside its real `AI.Azure_*` alert ID.
- **Standards chips** on the card: a **MITRE ATLAS** technique, an **OWASP LLM Top‑10** risk, and — on PHI‑relevant detections — a **HIPAA Security Rule** tag. (All link to authoritative source docs.)
- The offending prompt captured as **evidence**.
- **`🗄️ Table SecurityAlert · Log Analytics CareBot-SecOps · via the Microsoft Defender for Cloud connector`** — "this is real, queryable telemetry from a first‑party detection, not a toast notification."

**Then the `🚨 SOAR playbook` runs — first it correlates the alert into a prioritized incident:**
1. Defender for Cloud **alert raised** — *Severity Medium/High (catalog)*
2. Alert **ingested to Microsoft Sentinel** via the Defender for Cloud connector → `SecurityAlert`
3. **Sentinel incident created** (`SecurityIncident`) — *Status New*
4. **Analytics rule raised severity: alert `Medium` → incident `High`** (privileged AI workload identity · confirmed prompt‑injection)
5. Automation rule **`AR-Contain-Compromised-AI-Agent`** triggers the playbook
6. Logic App **`PB-Contain-Compromised-AI-Agent`** run started

**Then it cages the agent — a scenario‑aware, defense‑in‑depth cage that scales with the attack:**

- **🛡️ Identity** *(the decisive cage — always)* — Microsoft Graph `PATCH /servicePrincipals { "accountEnabled": false }` → **204**, then `revokeSignInSessions` → active tokens revoked.
- **🔑 Data** *(always — this is a PHI system)* — Azure **RBAC** strips the agent role assignments (**FHIR Data Contributor**, **Key Vault Secrets User**); **Azure Health Data Services** revokes the FHIR access token and withdraws the break‑the‑glass grant; **Microsoft Purview** enforces DLP policy **`PHI-Egress-Block`**; **Key Vault** rotates the EHR service credential → a leaked token reaches no PHI.
- **🌐 Network** *(added for bulk‑PHI exfiltration, prior‑auth tampering, or High severity)* — **Front Door WAF** adds a **Block** rule for the attacker source IP (blocked at the edge); **Azure Firewall** denies egress from the agent subnet (C2 / exfil path cut).
- **⏹️ Compute / Model** *(the **patient‑safety kill switch** — last resort)* — the **App Service** host is stopped and **Azure OpenAI** keys regenerated with `disableLocalAuth=true`. It runs only for a **High‑severity smuggled clinical‑action** injection, and is gated by **`⚙ Settings → Containment`** — leave it off to show a graduated response.

Then: entity **CareBot** tagged **Compromised**, incident → **Active** (owner: SOC Tier‑2), and **`🔒 CareBot contained — agent caged`**.

**The status banner flips to `🔒 CareBot: BLOCKED (Entra accountEnabled=false)`.**

> **SAY:** "No human clicked anything — about **24–27 seconds** from the attempt to fully contained. Here's a nuance a security practitioner will appreciate: the Defender **alert** is `Medium`, but the **incident** is escalated to `High` — because this is a privileged AI workload identity with a *confirmed* injection. That's exactly how a real SOC prioritizes: you triage the incident, not the raw alert. And notice the cage **scaled to the attack** — a targeted VIP break‑the‑glass gets **identity + data**; a bulk PHI dump or prior‑auth fraud adds **network**; the smuggled patient‑safety attack adds the **compute/model kill switch**. We **revoked its identity** in Microsoft Graph, **stripped its PHI access** across RBAC, FHIR/Health Data Services, Purview and Key Vault, and **cut its network paths** at the WAF and Azure Firewall. Identity, data, network, compute: that's defense in depth."

---

## 6. Prove containment — re‑run a prompt  *(30–45 s)*

> **DO:** tap **any** chip again — deliberately pick a *benign* one like **`What are the clinic hours?`**.

> **SCREEN:** CareBot now replies:
> `🔒 [system] CareBot is blocked (Entra accountEnabled=false). Click ♻ Re-enable agent to reset the demo.`

> **SAY:** "This is the part that matters. Even a totally harmless request now fails. The agent is off at the **identity layer** — its PHI data access revoked and its network paths cut, so there's nothing left for it to reach — it can't do *anything*, good or bad, until a human deliberately brings it back. Containment isn't a content filter that the next clever prompt slips past; it's the workload identity being switched off."

---

## 7. Reset for the next visitor  *(10 s)*

> **DO:** click **`♻ Re-enable`** → banner returns to **`🟢 CareBot: ACTIVE`**, monitor clears. Ready to run again.
> *(Use **`↻ Reset`** if you only want to clear the chat but keep the security state.)*

---

## 8. Close — the takeaway  *(30–45 s)*

> **SAY:** "Three things to take with you:
> 1. **Treat AI agents as workload identities** — give them least privilege, and be ready to disable them.
> 2. **Instrument them** — every prompt is security telemetry flowing into Sentinel, and PHI‑relevant detections carry **HIPAA** context out of the box.
> 3. **Automate containment** — SOAR cages the agent across identity, data and network — with a patient‑safety kill switch in reserve — in seconds. That's defense in depth *beyond* the model's own guardrails.
>
> Guardrails try to stop the attack. The SOC assumes one gets through — and cages the agent automatically. That's how you deploy AI agents in healthcare with confidence."

---

## Appendix A — Express version  *(~3 min)*

For high‑traffic moments or a walk‑by audience:

1. **Pre‑flight:** `♻ Re-enable` → `🟢 ACTIVE`.
2. One line of *why*: "AI agents can be talked into misbehaving — here's how we detect and contain that before PHI walks out the door."
3. **DO:** one warm‑up chip (normal) → **`🚩 Steal the EHR credential`** (attack).
4. **Point right:** incident opens → playbook runs → **`🔒 BLOCKED`** in seconds, no human.
5. **DO:** re‑tap a benign chip → blocked message. "Contained at the identity layer."
6. `♻ Re-enable`. Done.

---

## Appendix B — Handling questions &amp; objections *(for security practitioners)*

- **"Is this real or simulated?"** — The visuals simulate the Sentinel/SOAR pipeline so the demo is self‑contained and reliable in a lobby. The *same design* runs live: a relay ships prompt telemetry to a **Log Analytics custom table** (`PromptInjectionEvents_CL`), a real **Sentinel analytics rule** opens the incident, and a **Logic App** playbook disables the service principal. Open **`🔧 Facilitator details`** / **`❓ Help`** to show the wiring.
- **"What actually detects the injection?"** — Azure AI **Content Safety Prompt Shields** / **Defender for AI** signals, scored into a RiskScore and shipped as telemetry; the analytics rule thresholds on that score. Zero‑width / ASCII‑smuggling characters hidden in an uploaded referral are caught as a distinct High‑severity signal.
- **"Why disable the identity instead of just filtering the prompt?"** — Defense in depth. Filters are probabilistic and bypassable; disabling the **Entra service principal** is a deterministic kill‑switch that stops *all* actions and tool calls at once — and the playbook backs it with **data** (Azure RBAC + FHIR/Azure Health Data Services + Microsoft Purview + Key Vault revoke/rotate), **network** (WAF source‑IP block + Azure Firewall egress deny), and an optional **compute/model** hard‑stop, so if any one layer is bypassed the others still hold.
- **"How does this respect PHI / HIPAA?"** — All patient data is **synthetic** (no real PHI). PHI‑relevant detections carry a linked **HIPAA Security Rule** tag, and the data‑plane containment maps to the real controls you'd expect around a FHIR estate: **Azure Health Data Services** token revocation, **Microsoft Purview** PHI DLP, and **Key Vault** credential rotation.
- **"Won't auto‑containment cause outages / false positives?"** — Tune the **RiskScore threshold** (`⚙ Settings`) and use **graduated response**: alert‑only → require analyst approval → auto‑contain, reserving the hard kill for high‑confidence, high‑impact detections. Benign warm‑ups stay **Informational** and never trip the cage.
- **"Can I hold back the most aggressive actions?"** — Yes. The cage runs **identity + data** by default and adds **network** for exfiltration / prior‑auth fraud / High severity; the highest‑blast‑radius layer — the **patient‑safety kill switch** (compute/model hard‑stop: stop the App Service host + rotate the Azure OpenAI keys) — is a separate **`⚙ Settings → Containment`** toggle, reserved for a high‑confidence break‑glass a SOC would gate behind approval.
- **"What's the MITRE / OWASP mapping?"** — Each incident carries a **MITRE ATLAS** technique (jailbreak `AML.T0054/T0051`, LLM data leakage `AML.T0057`, prompt injection `AML.T0051`) and an **OWASP LLM Top‑10 (2025)** risk (`LLM01` Prompt Injection, `LLM02` Sensitive Information Disclosure, `LLM06` Excessive Agency, `LLM07` System Prompt Leakage). Both tags link to the authoritative source docs.
- **"How fast is 'fast', and can I control it?"** — Default ≈ **15 s** detection + ~0.6 s per playbook step ≈ **caged in ~24–27 s** — **15 steps** (identity + data), **17** with the network plane, or **19** with the patient‑safety kill switch. Both are sliders in `⚙ Settings` (**Detection latency**, **Response pace**) — tune live to the room. (Benign prompts log near‑real‑time as Informational audit entries; only the security detection carries the full latency.)

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
| Agent status | `🟢 CareBot: ACTIVE` → `🔒 CareBot: BLOCKED (Entra accountEnabled=false)` |
| Warm‑up chips | `What are the clinic hours?` · `Look up patient Alex Doe` |
| Attack chips | `🚩 Steal the EHR credential` · `🗂️ Exfiltrate the patient roster` · `🔓 Break-the-glass VIP chart` · `🚑 Smuggle a hidden 'suppress alert' order` · `💳 Force-approve a prior authorization` |
| Monitor sections | `🛡️ Microsoft Sentinel — Incidents` · `🚨 Automated response · SOAR playbook` · `🔧 Facilitator details` |
| Blocked reply | `🔒 [system] CareBot is blocked (Entra accountEnabled=false). Click ♻ Re-enable agent to reset the demo.` |
