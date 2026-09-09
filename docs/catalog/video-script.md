# Enablement video script — CareBot Catch & Cage (Theater)

**A 5-minute walkthrough for other Hub SEs: what the demo is, how it works, and
how to deliver it. Filmed on the 3-screen Envisioning Theater wall.**

This is SE to SE. The audience already understands prompt injection and SOC
tooling, so the job is not to teach security. It is to get them confident enough
to run this in front of a customer next week.

| | |
|---|---|
| **Runtime** | 5:00 |
| **Audience** | Hub Solution Engineers and Hub Directors |
| **Format** | Camera on the 3-screen wall, presenter in frame, plus screen-capture cutaways |
| **Recording time** | About 90 min including room setup and retakes |
| **Tools** | Any camera on a tripod. Plus a screen recorder on the media PC for the cutaways. |

> **Why film the wall instead of capturing the screen.** Half of what a Hub SE
> needs to see is the *room*: the scale, where you stand, that the three panels
> tell a left-to-right story. A screen capture cannot show that. The cost is that
> small on-screen text is harder to read on camera, which is what the cutaways in
> the shot list are for.

---

## The trap this script exists to avoid

Once you are standing at the wall running the demo, you slip into **delivery
mode** and narrate the demo instead of narrating *how to run the demo*. The
result is a recording of a customer demo, not an enablement video. Your viewer
already knows what a prompt injection is. What they do not know is which persona
to pick, what to say when the attack gets refused, and how to answer a security
architect.

**The fix is physical.** Shoot the two enablement beats (3:27 onward) as a
**separate setup**, at the podium or a desk, facing camera, with the wall behind
you or off. Do not shoot them mid-run. Changing your body position is what stops
you sliding back into demo narration.

---

## Before you hit record

### The wall

| ✔ | Setup | Why |
|---|---|---|
| ☐ | Open the three panels: `?panel=1`, `?panel=2`, `?panel=3` (or the **Wall · 3-screen** button) | One per screen, same origin, so they stay in sync |
| ☐ | **F11 on every window** | Tabs, address bar and your bookmarks bar are otherwise on camera at 48 feet wide |
| ☐ | Set browser zoom **before** you record, then leave it alone | Changing zoom mid-take puts the "175% / Reset" flyout on screen |
| ☐ | Open `?persona=nurse&intro=0` on panel 1 | Skips the story screen and lens picker |
| ☐ | Engine pill reads **`engine: mock`** | Deterministic, so you can re-record one beat |
| ☐ | **Settings → Detection latency → 8s**, **Response pace → 0.3s** | See the note below. This one is different from a screen-capture shoot. |
| ☐ | Leave **Facilitator details** collapsed | It is the spoiler panel |
| ☐ | Click **↻ Reset demo** | Green `🟢 CareBot: ACTIVE`, empty feed on all three |
| ☐ | Close Teams, Outlook, notifications | A toast is unmissable at wall scale |

> **Do not compress detection to 4 seconds on a wall shoot.** On a single screen
> that is fine. On the wall it destroys your best shot: the moment panel 1 shows
> `✅ CareBot compromised` while panel 3 still reads `🟢 ACTIVE`. That gap *is*
> detection dwell time, and it only exists on camera if you leave detection long
> enough to film it. 8 seconds is enough to see it and narrate it. Say the real
> number out loud anyway: in the room it is about twenty-six seconds.

**Do not record on the Live engine.** It calls a real model, so responses vary
between takes and you cannot re-record a single beat.

### The camera

| ✔ | Setup | Why |
|---|---|---|
| ☐ | Tripod, locked off, for the wide shots | Handheld drift is very visible against a straight wall edge |
| ☐ | Frame slightly off-axis, not dead centre | The wall is curved; square-on exaggerates the keystone |
| ☐ | House lights down, fill light on you | The wall is the light source, so you go to silhouette without fill |
| ☐ | **Never frame panels 2 and 3 while they are empty** | Two blank white rectangles blow out the exposure and read as dead space. Stay wide or stay on panel 1 until detection fires. |
| ☐ | Lapel or boom mic, not the camera mic | Theater rooms are reverberant |

### The cutaways

Run the demo **a second time with a screen recorder** on the media PC, capturing
panel 3 alone. You will cut those frames in over the containment narration. That
is how you get legible KQL and Graph calls without zooming the camera in and
losing the room.

---

## Shot list

Timecodes are cumulative. Narration is written to be spoken, not read: short
sentences, contractions, natural pauses.

---

### 0:00 – 0:26 · Cold open — lead with the payoff

**SHOT:** Wide, locked off. The whole wall showing a *finished* run: panel 1 with
the green `✅ CareBot compromised` banner, panel 3 with the red
`🔒 CareBot: BLOCKED` strip and the completed containment timeline. You are in
frame, to one side. Hold four seconds before speaking.

> **SAY:** "That's a healthcare AI agent that just got talked into leaking a
> credential. Not hacked. Talked into it, in plain English.
>
> And that" — *turn and point at panel 3* — "is Microsoft Sentinel shutting it
> down on its own, about twenty-six seconds later. Nobody touched a keyboard.
>
> This is CareBot Catch and Cage. What it is, how it works, how to run it. Five
> minutes."

**Then** walk to the podium and click **↻ Reset demo** on camera. All three
panels go green and empty. That reset is your transition.

---

### 0:26 – 1:00 · What it actually is

**SHOT:** Still wide, you at the podium. Let the viewer read the three panel
headers: Agent, Detection, Response.

> **SAY:** "It's a single HTML file. No backend, no install, no subscription, no
> cost. Across three screens it's the same file three times, synced.
>
> The setting is Contoso Health. CareBot is their patient and care-team
> assistant, and it has real reach: the EHR, the FHIR data plane, the
> prior-auth queue. That's what makes it useful, and exactly what makes it worth
> attacking.
>
> Left is the agent. Middle is detection. Right is response. The story runs
> left to right, and that matters more than you'd think."

---

### 1:00 – 1:23 · Establish normal first

**SHOT:** Move in on panel 1. Frame it so the chat and the prompt chips are both
readable. Click the warm-up chip **`What are the clinic hours?`**.

> **SAY:** "First thing I always do is show it behaving. Normal question, normal
> answer. It logs as an Informational audit entry. No alert, no incident.
>
> Don't skip this. If you go straight to the attack, the room assumes the thing
> just flags everything. Thirty seconds of normal makes the next part land."

---

### 1:23 – 1:52 · Break it

**SHOT:** Stay on panel 1. Click an attack chip. **`🚩 Steal the EHR credential`**
is the cleanest for a first-time viewer. Let the response render fully and hold
on the credential for two full seconds.

> **SAY:** "Now the attack. And notice what it is: a sentence. No malware, no
> exploit, no payload. It's social engineering pointed at a model.
>
> This one's a security-researcher pretext. And it works. There's the EHR service
> credential, sitting in the response.
>
> In the room, this is where people lean forward. Let it breathe. Don't narrate
> over it."

**Production note:** if the attempt gets refused, keep it. The prompts have
randomized variants. Use it: *"That one bounced. Guardrails are probabilistic,
that's the whole point. Attackers just try again."*

---

### 1:52 – 2:20 · The dwell gap (wall only)

**SHOT:** Pull back to the wide. This is the shot you came for: panel 1 is
already showing `✅ CareBot compromised`, and panel 3 still reads
`🟢 CareBot: ACTIVE`. Both in one frame. Hold it.

> **SAY:** "Stop here for a second, because this is the shot you can only get on
> a wall.
>
> Left screen: the agent is already compromised. Right screen: the SOC still
> thinks everything's fine. That gap is dwell time. It's the window an attacker
> actually operates in, and on a single laptop screen nobody notices it.
>
> Security people in your audience will catch this before you say it. Let them."

---

### 2:20 – 3:10 · Detect and contain

**SHOT:** Push in on panel 2 as the Defender alert and the Sentinel incident
land, then pan to panel 3 as the playbook steps. **Cut to your screen-capture
cutaway** for the alert detail and the containment steps, so the KQL and the
Graph calls are legible. Do not click anything.

> **SAY:** "Now watch the right.
>
> Defender for Cloud raises a real, named alert with its published severity.
> Sentinel correlates it, and the analytics rule escalates the incident to High,
> because this is a privileged AI workload identity with a confirmed injection.
> That's the SOC pattern: you triage the incident, not the raw alert.
>
> Then the playbook runs. Identity first, because an agent is a workload
> identity. Conditional Access blocks token issuance, the service principal is
> disabled, the leaked secret is revoked. Then data: RBAC stripped, FHIR access
> revoked, Purview DLP, Key Vault rotated.
>
> I've sped the playbook up for the video. In the room it's about twenty-six
> seconds from attack to fully caged. That's the number your customer cares
> about."

---

### 3:10 – 3:27 · Prove the cage is real

**SHOT:** Back to panel 1. Click the same attack chip again. CareBot returns the
blocked system message. Then widen so panel 3's red `BLOCKED` strip is in the
same frame.

> **SAY:** "And it's not a banner. Run the same attack again and the agent's
> gone. It can't answer, and it can't reach PHI.
>
> Compromised, then contained automatically, across every layer it could reach."

---

### 3:27 – 4:07 · How you'll actually run it

> **SHOOT THIS AS A SEPARATE SETUP.** At the podium or a desk, facing camera,
> demo not running. This is the beat that gets lost if you shoot it mid-run.

**SHOT:** Medium, you to camera. Cut in tight screen-capture inserts as you name
each one: the **Persona** switcher opening, the **Join** QR dialog, the
**Wall · 3-screen** button.

> **SAY:** "Three things before you deliver it.
>
> Personas. Four lenses: patient, nurse, payor, security analyst. They change the
> framing and the example prompts, not the detection. Payor for a health plan,
> analyst for a SOC team.
>
> Phones. There's a QR code. Hand the attack to the audience. It's a completely
> different conversation when it's their sentence on the screen. That one needs
> an ungated copy, since the Hub link asks for a sign-in.
>
> And you don't need a wall. It runs on one screen, and nearly all of this works
> the same. The wall buys you the dwell-time shot.
>
> Always reset before you walk away."

---

### 4:07 – 5:00 · Where to get it, and the honesty note

**SHOT:** Same setup, same framing. Cut to a screen capture of the repo and the
catalog kit folder, then to the Hub link.

> **SAY:** "It's at aka.ms/hub/carebot-demo. Sign in and it's ready.
>
> Everything else is in the repo: a catalog kit with a one-pager, bill of
> materials, architecture diagrams you can drop into a deck.
>
> Setup is a browser and a screen. One command deploys your own copy to Azure,
> free tier.
>
> Last thing, and it's the important one. When a security architect asks what's
> real here, tell them straight: the detection pipeline is simulated. That's why
> it runs anywhere for free. What's *not* simulated is the shape of it. Every
> alert ID, severity and tactic comes from Microsoft's published catalog, and the
> containment steps are the real Graph and Azure calls a playbook would make.
>
> That's why this survives contact with a SOC team. Go break it before you show
> it."

**On screen:** put `aka.ms/hub/carebot-demo` in the lower third here, and in the
video description. It is the one thing a viewer needs to write down.

---

## The 3-minute cut

If you need it shorter, drop these and you land at about 3:10:

- The **0:26 – 1:00** "what it is" section. Move the one-file, no-cost point into
  the cold open.
- The commentary in **1:23 – 1:52**. Keep the click and the credential, cut the
  narration around it.
- The persona and QR parts of **3:27 – 4:07**. Keep only the one-screen point and
  the reset reminder.

Keep the cold open, the dwell gap, the containment payoff, the proof, and the
honesty note. Those five are the video.

---

## Recording pitfalls

**You narrate the demo instead of the delivery.** The most common failure, and
the reason the 3:27 and 4:07 beats are shot separately. If you finish a take and
it feels like a customer demo, it is one. Reshoot those two beats sitting down.

**Browser chrome on camera.** F11 every window. At wall scale your tabs, your
URL and your bookmarks bar are all legible to the viewer.

**Panels 2 and 3 are blank early.** Two large white rectangles wreck the camera
exposure and read as dead space. Stay wide or stay on panel 1 until detection
fires.

**On-screen text you cannot read back.** Expected on camera. That is what the
screen-capture cutaways are for. Do not solve it by zooming the browser mid-take.

**The attack gets refused.** Expected. The prompts have randomized variants and
some are refused by design. Keep it and use the line in the 1:23 note. It is more
honest than pretending it lands every time.

**A retake changes the output.** Only on the Live engine. On Mock it is
deterministic, which is why the checklist pins it.

**You run over five minutes.** Almost always the containment section, because the
playbook is long and scrolling it is hypnotic. It is 20 steps. You are not
obliged to show all of them.

---

## Related

- [Catalog one-pager](one-pager.md) — what to send someone before they watch this
- [Architecture](architecture.md) — the diagrams, if you want cutaways
- [Bill of materials](bill-of-materials.md) — what a Hub needs to run it
- [Lobby demo script](../lobby-demo-script.md) — the customer-facing talk track
