# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`astro-boilerplate/`](./astro-boilerplate/) | **AB** | ✅ Shipped (`baseline-v2`); `baseline-v1` went live 2026-10-15, `baseline-v2`'s one landing not yet | Vercel's Astro boilerplate, equivalent in code and function, running on Cloudflare Workers + Static Assets via @astrojs/cloudflare — and an Orun baseline that instantiates it (AB3) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
