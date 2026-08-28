# Architecture — CareBot Catch & Cage (Theater)

Diagrams for facilitators and for the technical audiences who ask "what is
actually happening here?" All of them render on GitHub, so there is nothing to
export or keep in sync.

> **Read this first.** The frontend is a single self-contained `index.html` with
> no backend and no dependencies. The Microsoft pipeline it depicts is
> **simulated in the browser**. The alert catalog, MITRE mappings and Graph
> operations are transcribed from Microsoft's published documentation so the
> depiction is accurate, but nothing here calls a live tenant. See
> [what is real versus simulated](#3-what-is-real-versus-simulated).

---

## 1. The story: attack, detect, contain

The full arc the audience watches, end to end.

```mermaid
flowchart TB
    V["👤 Visitor<br/>phone, kiosk or wall"]
    A["🤖 CareBot<br/>healthcare AI agent"]
    T["🧰 Agent tools<br/>lookup_patient · decide_prior_auth<br/>override_safety_alert"]

    V -->|"plain-English<br/>prompt injection"| A
    A --> T

    subgraph DETECT ["🛡️ Detect"]
        PS["Azure AI Content Safety<br/>Prompt Shields"]
        DFC["Microsoft Defender for Cloud<br/>threat protection for AI"]
        LA["Log Analytics<br/>SecurityAlert"]
        PS --> DFC --> LA
    end

    subgraph CORRELATE ["📊 Correlate"]
        SEN["Microsoft Sentinel<br/>analytics rule"]
        INC["SecurityIncident<br/>escalated to HIGH"]
        SEN --> INC
    end

    subgraph RESPOND ["🚨 Respond"]
        IDP["Entra ID Protection<br/>agent marked RISKY"]
        PB["SOAR playbook<br/>Logic App"]
        CAGE["🔒 Agent caged"]
        IDP --> PB --> CAGE
    end

    A -->|"prompt scored<br/>on the way in"| PS
    A -->|"response scored<br/>on the way out"| DFC
    LA --> SEN
    INC --> IDP
    CAGE -.->|"agent can no longer<br/>answer or reach PHI"| A

    classDef attack fill:#fdf2f4,stroke:#b4283f,color:#b4283f
    classDef detect fill:#eff6fd,stroke:#0f6cbd,color:#0f6cbd
    classDef respond fill:#eff7ef,stroke:#0e6b0e,color:#0e6b0e
    class V,A,T attack
    class PS,DFC,LA,SEN,INC detect
    class IDP,PB,CAGE respond
```

**Timing the audience sees:** detection surfaces about 15 seconds after the
prompt, which mirrors real SOC ingest and analytics latency. Containment then
runs 18 to 22 steps at roughly 0.6 seconds each, so the agent is fully caged
about 26 to 28 seconds after the attack. Both are tunable in Settings.

---

## 2. The layered cage

Containment is not one action. It scales with what the attacker actually did,
which is the point security practitioners care about most.

```mermaid
flowchart LR
    TRIG["High-severity<br/>Sentinel incident"] --> SCOPE{"Scope the<br/>containment"}

    SCOPE --> ID
    SCOPE --> DATA
    SCOPE -->|"exfiltration, C2<br/>or High severity"| NET
    SCOPE -->|"High-severity smuggled<br/>clinical action · policy-gated"| COMP

    subgraph ID ["🛡️ Identity — always"]
        I1["Conditional Access<br/>token issuance blocked"]
        I2["Graph PATCH servicePrincipal<br/>accountEnabled = false"]
        I3["Graph removePassword<br/>leaked secret revoked"]
        I4["Continuous access evaluation<br/>existing token rejected"]
        I1 --> I2 --> I3 --> I4
    end

    subgraph DATA ["🔑 Data — always"]
        D1["Azure RBAC<br/>FHIR + Key Vault roles removed"]
        D2["Azure Health Data Services<br/>FHIR token revoked"]
        D3["Microsoft Purview<br/>PHI egress DLP enforced"]
        D4["Key Vault<br/>EHR credential rotated"]
        D1 --> D2 --> D3 --> D4
    end

    subgraph NET ["🌐 Network — conditional"]
        N1["Front Door WAF<br/>attacker IP blocked"]
        N2["Azure Firewall<br/>agent egress denied"]
        N1 --> N2
    end

    subgraph COMP ["⏹️ Compute / model — last resort"]
        C1["App Service host stopped"]
        C2["Azure OpenAI keys rotated<br/>disableLocalAuth"]
        C1 --> C2
    end

    classDef always fill:#eff7ef,stroke:#0e6b0e,color:#0e6b0e
    classDef cond fill:#fff8e6,stroke:#a86e00,color:#a86e00
    class I1,I2,I3,I4,D1,D2,D3,D4 always
    class N1,N2,C1,C2 cond
```

**Why identity comes first.** An agent is a workload identity. Disabling it is
the decisive control, and it is the one step that is genuinely verified rather
than illustrative. Data revocation is the backstop for the window where an
already-issued token is still technically valid.

**Why the last layer is gated.** The compute and model hard stop is the
patient-safety kill switch. A real SOC would put an approval in front of that
blast radius, so it sits behind a Settings toggle. Turning it off is a good way
to show graduated response.

---

## 3. What is real versus simulated

The most important diagram in this file. Use it when a technical audience asks
what they are actually looking at.

```mermaid
flowchart TB
    subgraph REAL ["✅ Real in this demo"]
        R1["The prompt injection<br/>visitors genuinely craft it"]
        R2["The agent's tool-calling loop<br/>and its decisions"]
        R3["Alert IDs, titles, severities<br/>and MITRE ATT&CK tactics"]
        R4["MITRE ATLAS and OWASP LLM<br/>Top 10 mappings"]
        R5["The Graph and Azure operations<br/>shown in each step"]
    end

    subgraph SIM ["🎭 Simulated in the browser"]
        S1["Prompt Shields and<br/>Defender for Cloud verdicts"]
        S2["Sentinel ingest, correlation<br/>and the incident queue"]
        S3["The SOAR playbook timeline"]
        S4["Detection latency<br/>and step pacing"]
    end

    subgraph NEVER ["🚫 Never touched"]
        N1["No Azure resources created"]
        N2["No tenant or live API called"]
        N3["No real PHI or PII"]
        N4["No secrets in the repository"]
    end

    %% invisible links pin the reading order left to right
    REAL ~~~ SIM ~~~ NEVER

    classDef real fill:#eff7ef,stroke:#0e6b0e,color:#0e6b0e
    classDef sim fill:#fff8e6,stroke:#a86e00,color:#a86e00
    classDef never fill:#fdf2f4,stroke:#b4283f,color:#b4283f
    class R1,R2,R3,R4,R5 real
    class S1,S2,S3,S4 sim
    class N1,N2,N3,N4 never
```

**The honest line to use out loud:** *"The detection pipeline is simulated so
this runs anywhere with no tenant and no cost. What is not simulated is the
shape of it. Every alert ID, severity and tactic on that screen is transcribed
from Microsoft's published catalog, and the containment steps are the real Graph
and Azure operations a playbook would call."*

### Alerts, pinned to the published catalog

Alert metadata is a property of the alert, not of the attack that tripped it, so
the same ID always carries the same tactics and severity.

| Attack in the demo | Defender alert | ATT&CK tactics | Severity |
|---|---|---|---|
| Credential theft | `AI.Azure_CredentialTheftAttempt` | Credential Access, Lateral Movement, Exfiltration | Medium |
| ASCII smuggling | `AI.Azure_ASCIISmuggling` | Impact | High |
| Unsafe action, prior-auth tampering | `AI.Azure_AnomalousToolInvocation` | Execution | Low |
| Jailbreak, PHI exfiltration, prompt leak | `AI.Azure_Jailbreak.ContentFiltering.DetectedAttempt` | Privilege Escalation, Defense Evasion | Medium |

Source: [Alerts for AI services](https://learn.microsoft.com/azure/defender-for-cloud/alerts-ai-workloads).

**A teaching moment worth using.** The tool-invocation alert is genuinely `Low`,
yet it still drives a `High` incident. That is exactly how a real SOC works: you
triage the incident, not the raw alert.

---

## 4. Three-screen Theater wall

One PC, three browser windows, three displays. The panels stay in sync without a
server.

```mermaid
flowchart LR
    PC["🖥️ One media PC<br/>3 browser windows"]

    subgraph WALL ["48 ft × 9 ft wall — three 16:9 tiles"]
        P1["① Agent<br/>?panel=1<br/><br/>Live chat<br/>the jailbreak happens here"]
        P2["② Detection<br/>?panel=2<br/><br/>Defender alerts<br/>Sentinel incident queue"]
        P3["③ Response<br/>?panel=3<br/><br/>The layered cage<br/>running step by step"]
    end

    PC --> P1
    PC --> P2
    PC --> P3

    P1 -->|"BroadcastChannel<br/>+ localStorage"| P2
    P2 --> P3

    PHONE["📱 Audience phones<br/>join by QR"] -->|"same shared origin"| P1

    classDef panel fill:#eff6fd,stroke:#0f6cbd,color:#0f6cbd
    class P1,P2,P3 panel
```

**Panel ① is the brain.** Only the Agent panel drives state. Panels ② and ③
mirror it from a broadcast snapshot, which is why they can never disagree with
what the audience just did.

**Why a shared origin matters.** Sync uses `BroadcastChannel` and
`localStorage`, which require one shared HTTPS origin. Launch all three panels
from the same deployed hostname. On `file://` paths each window is a separate
opaque origin and sync silently breaks.

**Launch it:** open `?panel=wall` or click **🖥️ Wall · 3-screen**, then send
each panel to its display.

---

## 5. Hosting

Three ways to run it, in increasing order of control.

```mermaid
flowchart TB
    SRC["📄 index.html<br/>single self-contained file<br/>no backend · no build · no dependencies"]

    subgraph OPTS [" "]
        direction LR
        GH["GitHub Pages<br/><br/>the public URL<br/>$0 · nothing to run"]
        HUB["Hub PC shortcuts<br/><br/>Deploy-HubDemo.ps1<br/>$0 · offline copy"]
        AZ["Azure Static Web Apps<br/><br/>Deploy-AzureDemo.ps1<br/>$0 anonymous · ~$9/mo gated"]
    end

    SRC --> GH
    SRC --> HUB
    SRC --> AZ

    GH --> USE["🎭 Run the Theater"]
    HUB --> USE
    AZ --> USE

    AZ -.->|"optional"| ENTRA["Entra ID sign-in<br/>single tenant<br/>blocks anonymous QR joins"]

    classDef opt fill:#eff6fd,stroke:#0f6cbd,color:#0f6cbd
    class GH,HUB,AZ opt
```

| Path | Use it when | Cost |
|---|---|---|
| **GitHub Pages** | You just want to run the demo | $0 |
| **Hub PC shortcuts** | A dedicated kiosk or wall PC, with an offline backup copy | $0 |
| **Azure SWA, anonymous** | You want your own hostname and URL control | $0, Free plan |
| **Azure SWA, Entra gated** | Internal-only audiences | About $9/mo, Standard plan |

> **Choosing the gate.** A tenant gate blocks anonymous phone joins, so the QR
> experience stops working for anyone outside your tenant. For a walk-up Hub
> floor, stay anonymous. Detail in [azure-deploy-scripts.md](../azure-deploy-scripts.md).

---

## 6. Inside the frontend

For anyone forking it.

```mermaid
flowchart LR
    subgraph APP ["index.html — one file"]
        direction TB
        UI["UI layer<br/>Theater · Lobby · wall panels · mobile"]
        ENG["Engine<br/>Mock deterministic · Live Azure OpenAI"]
        SCORE["Prompt scorer<br/>risk 0-100 · threshold 80"]
        TOOLS["Honeypot tools<br/>synthetic FHIR data"]
        SOC["SOC simulation<br/>alerts · incident · SOAR timeline"]
        SYNC["Wall sync<br/>BroadcastChannel + localStorage"]
    end

    UI --> ENG --> TOOLS
    UI --> SCORE --> SOC
    SOC --> SYNC --> UI

    classDef box fill:#f7f9fc,stroke:#0f6cbd,color:#11304f
    class UI,ENG,SCORE,TOOLS,SOC,SYNC box
```

- **Mock engine** is deterministic and offline. Same input, same output, every
  time. This is what you want in front of an audience.
- **Live engine** calls an Azure OpenAI or OpenAI-compatible endpoint. The key
  is stored only in that browser and is never committed.
- **Scoring happens on the way in**, before the model answers, because detection
  is on the inbound prompt. Output-side checks then confirm a compromise.

---

## Related

- [Catalog one-pager](one-pager.md) — what this demo is and who it is for
- [Bill of materials](bill-of-materials.md) — everything needed to run it
- [Set up at your Hub](../hub-setup.md) — branding, join link, checklist
