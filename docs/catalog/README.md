# Catalog kit — CareBot Catch & Cage (Theater)

Everything needed to **share this demo with others** and deliver it to
customers. Written for people who did not build it.

| Asset | Answers | Read it when |
|---|---|---|
| **[One-pager](one-pager.md)** | What is this, who is it for, what do they take away? | You are listing it on a catalog page or pitching it internally |
| **[Architecture](architecture.md)** | What is actually happening, and what is real versus simulated? | A technical audience asks, or you are briefing an SE |
| **[Bill of materials](bill-of-materials.md)** | What does the Theater need, what does it cost, how long is setup? | You are planning a Theater delivery |
| **[Video script](video-script.md)** | How do I record a 5-minute walkthrough for other SEs? | You are making an enablement video, or learning to deliver it yourself |

The architecture diagrams are **Excalidraw** drawings in
[`diagrams/`](diagrams/). Each ships as an `.svg` that renders on GitHub and an
`.excalidraw` source you can open at [excalidraw.com](https://excalidraw.com) to
rebrand, translate or lift a panel straight into a slide.

## Send-ready downloads

For emailing, printing, or dropping into a deck without needing to render
anything yourself.

| Format | Where | Use it for |
|---|---|---|
| **PDF** | [`pdf/`](pdf/) | Emailing a customer or a Hub Director, printing a checklist |
| **PNG** | [`diagrams/png/`](diagrams/png/) | Pasting a diagram into PowerPoint or Word |

The PNGs are rendered at 3x (about 3200 to 4200 px wide), so they stay sharp
full-bleed on a slide. Prefer the `.svg` wherever it renders, since it scales
without loss.

> **These are generated, not source.** Every PDF is rendered from the markdown
> next to it, and every PNG from the matching `.svg`. **The markdown and the
> `.excalidraw` files are the source of truth.** Edit those, never these. A PDF
> footer carries the date it was generated, so you can tell when one has fallen
> behind the doc it came from.

**Live demo:** https://ajayiyer99.github.io/hubbot-ctf-demo/

**In one line:** visitors talk a healthcare AI agent into leaking a credential
or dumping patient records using nothing but plain English, then watch Microsoft
Sentinel and a SOAR playbook cage it automatically in about 26 seconds.

> **Scope.** This kit covers the **Theater** experience: the facilitated,
> interactive CTF. Delivery guidance for the unattended Lobby attract screen is
> in [lobby-demo-script.md](../lobby-demo-script.md).

## Operator docs

Once you have decided to run it:

- [Set up at your Hub](../hub-setup.md) — branding, join link, engine, checklist
- [Deploy to a Hub PC](../hub-deployment.md) — desktop shortcuts in one line
- [Deploy to Azure](../azure-deploy-scripts.md) — your own Static Web App
