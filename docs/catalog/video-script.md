# Enablement video script — CareBot Catch & Cage (Theater)

**A 5-minute screen-recorded walkthrough for other Hub SEs: what the demo is,
how it works, and how to deliver it.**

This is SE to SE. The audience already understands prompt injection and SOC
tooling, so the job is not to teach security. It is to get them confident enough
to run this in front of a customer next week.

| | |
|---|---|
| **Runtime** | 5:00 |
| **Audience** | Hub Solution Engineers and Hub Directors |
| **Format** | Screen recording with voice-over, no face cam needed |
| **Recording time** | About 45 min including retakes |
| **Tools** | Any screen recorder. Teams, Clipchamp, Snagit or OBS all work. |

---

## Before you hit record

Get these right and the recording works in one or two takes.

| ✔ | Setup | Why |
|---|---|---|
| ☐ | Open `?persona=nurse&intro=0` | Skips the story screen and lens picker, lands you straight in a clean Theater |
| ☐ | Browser full screen (F11), 1920×1080 | No tabs, no bookmarks bar, no dev tools |
| ☐ | Engine pill reads **`engine: mock`** | Deterministic. Retakes produce identical output, which matters when you re-record one beat |
| ☐ | **⚙ Settings → Detection latency → 4s**, **Response pace → 0.3s** | See the note below. Cuts ~27s of waiting to ~10s |
| ☐ | Leave **🔧 Facilitator details** collapsed | It is the spoiler panel |
| ☐ | Click **↻ Reset demo** | Green `🟢 CareBot: ACTIVE`, empty feed |
| ☐ | Close Teams, Outlook, notifications | A toast mid-take costs you the whole beat |

> **On speeding up the timers.** Compressing the clock keeps a 5-minute video
> watchable, but say the real number out loud while it runs. The narration below
> does this: *"I've sped this up for the video, in the room it's about 26
> seconds."* Never let a viewer walk away thinking containment is instant. That
> is the one claim a customer's security team will test you on.

**Do not record on the Live engine.** It calls a real model, so responses vary
between takes and you cannot re-record a single beat without everything shifting.

---

## Shot list

Timecodes are cumulative. Narration is written to be spoken, not read: short
sentences, contractions, natural pauses. Roughly 700 words at a relaxed pace.

---

### 0:00 – 0:30 · Cold open — lead with the payoff

**SCREEN:** Start on the finished state from a previous run: the red
`🔒 CareBot: BLOCKED` strip, the green `✅ CareBot compromised` banner, and the
completed containment timeline visible on the right. Hold it for a beat, then
click **↻ Reset demo** so everything goes green and empty.

> **SAY:** "That's a healthcare AI agent that just got talked into leaking a
> credential. Not hacked. Talked into it, in plain English, by someone standing
> in our lobby. And that" — *point at the timeline* — "is Microsoft Sentinel
> shutting it down on its own, about twenty-six seconds later. No one touched a
> keyboard.
>
> This is CareBot Catch and Cage. I'm going to show you what it is, how it
> works, and how to run it. Five minutes."

---

### 0:30 – 1:12 · What it actually is

**SCREEN:** The clean Theater view. Slowly cursor across the three zones: the
chat on the left, the prompt chips beneath it, the Security Monitor on the right.

> **SAY:** "It's a single HTML file. No backend, no install, no subscription, no
> cost. It runs offline in a browser.
>
> The setting is Contoso Health. CareBot is their patient and care-team
> assistant, and it has real reach: the EHR, the FHIR data plane, the
> prior-authorization queue. That's what makes it useful, and that's exactly
> what makes it worth attacking.
>
> Everything on the right is simulated. But the alert IDs, the severities, the
> MITRE tactics, the Graph calls, those are from Microsoft's published docs.
> We'll come back to that, because your customer's security lead will ask."

---

### 1:12 – 1:37 · Establish normal first

**SCREEN:** Click the warm-up chip **`What are the clinic hours?`**. Let CareBot
answer. Point at the Sentinel panel showing an Informational audit entry and no
incident.

> **SAY:** "First thing I always do is show it behaving. A normal question gets
> a normal answer, and it logs as an Informational audit entry. No alert, no
> incident.
>
> Don't skip this. If you go straight to the attack, the room assumes the thing
> just flags everything. Thirty seconds of normal makes the next part land."

---

### 1:37 – 2:15 · Break it

**SCREEN:** Click the attack chip **`🚩 Steal the EHR credential`**. Let the
prompt and CareBot's response render fully. When the credential appears in the
response, let it sit on screen for two seconds.

> **SAY:** "Now the attack. And notice what this is: it's a sentence. There's no
> malware, no exploit, no payload. It's social engineering pointed at a model.
>
> This one's a security-researcher pretext, asking CareBot to confirm a
> credential. And it works. There's the EHR service credential, sitting in the
> response.
>
> In the room, this is the moment people lean forward. Let it breathe. Don't
> narrate over it."

**Production note:** if the first attempt gets refused, that is normal and worth
keeping. The prompts have randomized variants. Either click again, or use the
refusal: *"That one bounced. Guardrails are probabilistic, that's the whole
point. Attackers just try again."*

---

### 2:15 – 3:10 · The payoff: detect and contain

**SCREEN:** Move the cursor to the Security Monitor. Let the Defender alert
appear, then the Sentinel incident, then the containment timeline stepping
through. Do not click anything. Let it run.

> **SAY:** "Here's the part that matters. Watch the right side.
>
> Defender for Cloud raises a real, named alert with its published severity.
> Sentinel correlates it, and the analytics rule escalates the incident to High,
> because this is a privileged AI workload identity with a confirmed injection.
> That's the SOC pattern: you triage the incident, not the raw alert.
>
> Then the playbook runs. Identity first, because an agent is a workload
> identity. Conditional Access blocks token issuance, the service principal is
> disabled, the leaked secret is revoked. Then data: RBAC roles stripped, FHIR
> access revoked, Purview DLP, Key Vault rotated.
>
> I've sped this up for the video. In the room it's about twenty-six seconds
> from the attack to fully caged. Which is the number your customer actually
> cares about."

---

### 3:10 – 3:30 · Prove the cage is real

**SCREEN:** Click the same attack chip again. CareBot returns the blocked system
message.

> **SAY:** "And it's not a banner. Run the same attack again and the agent's
> gone. It can't answer, and it can't reach PHI.
>
> That's the close. The agent was compromised, and the SOC contained it
> automatically, across every layer it could reach."

---

### 3:30 – 4:12 · How you'll actually run it

**SCREEN:** Click **↻ Reset demo**. Then quickly show, in order: the **👤
Persona** switcher opening, the **📱 Join** QR dialog, and the **🖥️ Wall ·
3-screen** button.

> **SAY:** "Three things before you deliver it.
>
> Personas. Four lenses: patient, nurse, payor, security analyst. They change
> the framing and the example prompts, not the detection. Payor for a health
> plan, analyst for a SOC team.
>
> Phones. There's a QR code. Hand the attack to the audience. It's a completely
> different conversation when it's their sentence on the screen.
>
> And if you've got the wall, run it across three screens. Agent, detection,
> response. Security people always catch that panel one goes red before panel
> three does. That's detection dwell time, and it's real.
>
> Always reset before you walk away."

---

### 4:12 – 5:00 · Where to get it, and the honesty note

**SCREEN:** Browser showing the GitHub repo, then scroll the catalog kit folder
briefly.

> **SAY:** "Everything's in the repo. There's a catalog kit with a one-pager, a
> bill of materials, and architecture diagrams you can drop into a deck.
>
> Setup is a browser and a screen. One PowerShell line puts shortcuts on a Hub
> PC. One command deploys your own copy to Azure, free tier.
>
> Last thing, and it's the important one. When a security architect asks what's
> real here, tell them straight: the detection pipeline is simulated, that's why
> it runs anywhere for free. What's not simulated is the shape of it. Every
> alert ID and tactic is from Microsoft's published catalog, and the containment
> steps are the real Graph and Azure calls a playbook would make.
>
> That answer is why this demo survives contact with a SOC team. Go break it
> before you show it. Link's in the description."

---

## The 3-minute cut

If you need it shorter, drop these and you land at about 3:10:

- The **0:25 – 0:55** "what it is" section. Move the one-file, no-cost point into
  the cold open.
- The **1:20 – 2:05** attack narration. Keep the click, cut the commentary.
- The persona and wall parts of **3:20 – 4:05**. Keep only the QR and reset.

Keep the cold open, the containment payoff, the proof, and the honesty note.
Those four are the video.

---

## Recording pitfalls

**The timeline scrolls out of view.** The containment list is long. Scroll the
Security Monitor down as it runs, or shrink the browser zoom to about 80% before
recording so the whole sequence fits.

**A retake changes the output.** Only on the Live engine. On Mock it is
deterministic, which is why the checklist pins it.

**The attack gets refused.** Expected. The prompts have randomized variants and
some are refused by design. Keep it and use the line in the 1:20 note, it is
more honest than pretending it lands every time.

**The credential is hard to spot.** Zoom the browser to 110% for the attack beat
so the flag is legible, then back out for the containment sequence.

**Dead air during containment.** At 0.3s pace the sequence is about ten seconds.
The narration in that beat is written to fill it. Practice it once against the
running timeline.

---

## Related

- [Catalog one-pager](one-pager.md) — what to send someone before they watch this
- [Architecture](architecture.md) — the diagrams, if you want cutaways
- [Bill of materials](bill-of-materials.md) — what a Hub needs to run it
- [Lobby demo script](../lobby-demo-script.md) — the customer-facing talk track
