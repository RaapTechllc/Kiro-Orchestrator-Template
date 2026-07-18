# GitHub Growth Audit: Kiro Orchestrator Template

**Repository:** [`RaapTechllc/Kiro-Orchestrator-Template`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template)
**Audit date:** 2026-07-16 local / 2026-07-17 03:20 UTC
**Scope:** GitHub discoverability and open-source adoption mechanics for a developer tool; seven current coding-agent/orchestration comparators.

## Executive conclusion

The repository's primary problem is not a lack of promotional activity. It is that GitHub currently presents it as an **abandoned, non-actionable repository**:

- it is archived, so issues, pull requests, releases, commits, tags, and repository settings are read-only;
- it has no description, homepage, or topics, even though GitHub's default repository search covers the name, description, and topics;
- despite `Template` in the name, GitHub reports `isTemplate: false`;
- it has no GitHub Releases or tags, although `CHANGELOG.md` claims versions 1.0.0 and 2.0.0;
- its README offers a clone-and-run claim, but no recorded demo, CI-backed smoke test, or expected output proves the promised first success;
- its community profile score is 28%, versus 50–100% across the seven peers; five of seven score at least 75%.

Stars cannot be manufactured by completing a checklist, and this comparison does not prove that any single repository feature causes stars. It does show a consistent adoption surface among successful peers: an immediately legible promise, visible product proof, a short supported install path, maintained releases, and a credible contribution/quality surface. The target currently breaks that sequence before a visitor can evaluate the product.

**Recommended strategy:** relaunch as a maintained, verifiable Kiro starter rather than “market” the archived snapshot. Unarchive, make the repository a real GitHub template, prove one end-to-end workflow in under five minutes, and only then distribute the demo.

---

## Method and evidence limits

Live metadata was queried from GitHub's REST and GraphQL APIs. README and repository-tree observations are from each repository's default branch at the audit timestamp. Stars, forks, release dates, and repository state change continuously.

The comparison uses stars and forks as public interest/reuse proxies, not proof of active users. Package downloads, extension installs, retention, and successful task completion are better adoption measures where available. The audit therefore separates:

1. **Search exposure** — whether GitHub can retrieve and explain the repository.
2. **Evaluation** — whether the first screen demonstrates a specific result.
3. **Activation** — whether a visitor can reach that result quickly.
4. **Trust** — whether releases, CI, licensing, and maintenance are credible.
5. **Contribution** — whether users have a supported path to become collaborators.

Primary GitHub guidance used:

- GitHub says repository search covers **name, description, and topics by default**; README requires `in:readme`: [Searching for repositories](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories#search-by-repository-name-description-or-contents-of-the-readme-file).
- GitHub says topics help people find and contribute to projects and make repositories discoverable by subject: [Classifying your repository with topics](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics).
- GitHub says the README is often the first item a visitor sees and should state what the project does, why it is useful, how to start, where to get help, and who maintains it: [About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes).
- GitHub says archival makes a repository read-only and indicates it is no longer actively maintained: [Archiving repositories](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories).
- GitHub says template repositories let users generate a new repository with the same files and structure: [Creating a template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository).
- GitHub defines Releases as deployable iterations packaged for a wider audience, with release notes and downloadable assets: [About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
- GitHub's community profile checks README, license, contributing guide, code of conduct, issue templates, PR template, and security policy: [Community profiles](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories).
- GitHub says issue/PR templates standardize the information contributors submit: [Issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates).
- GitHub says a workflow badge shows whether a workflow is passing or failing: [Adding a workflow status badge](https://docs.github.com/en/actions/how-tos/monitor-workflows/adding-a-workflow-status-badge).
- GitHub says a custom social image helps identify a project when links are shared and recommends 1280×640 for best display: [Social media preview](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview).
- GitHub says `good first issue` can increase the likelihood that approachable issues are surfaced: [Encouraging contributions with labels](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/encouraging-helpful-contributions-to-your-project-with-labels).

---

## Live comparison: market and maintenance signals

| Repository | Positioning in GitHub metadata | Stars | Forks | Latest GitHub release | Topics | Community profile | State |
|---|---|---:|---:|---|---:|---:|---|
| **Target: [Kiro-Orchestrator-Template](https://github.com/RaapTechllc/Kiro-Orchestrator-Template)** | **None** | **2** | **0** | **None** | **0** | **28%** | **Archived; pushed 2026-01-19** |
| [anthropics/claude-code](https://github.com/anthropics/claude-code) | Agentic terminal tool; codebase understanding, routine tasks, git workflows | 138,016 | 22,144 | v2.1.212, 2026-07-17 | 0 | 50% | Active |
| [openai/codex](https://github.com/openai/codex) | Lightweight coding agent that runs in the terminal | 98,907 | 14,784 | rust-v0.144.5, 2026-07-16 | 0 | 75% | Active |
| [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands) | AI-driven development | 81,035 | 10,359 | cloud-1.46.2, 2026-07-15 | 9 | 87% | Active |
| [cline/cline](https://github.com/cline/cline) | Coding agent as SDK, IDE extension, or CLI | 64,728 | 6,925 | sdk/sdk/v0.0.64, 2026-07-17 | 0 | 100% | Active |
| [Aider-AI/aider](https://github.com/Aider-AI/aider) | AI pair programming in the terminal | 47,440 | 4,739 | v0.86.0, 2025-08-09 | 13 | 50% | Active |
| [continuedev/continue](https://github.com/continuedev/continue) | Open-source coding agent | 34,920 | 5,057 | v2.1.0-vscode, 2026-06-19 | 5 | 87% | API says active; README says no longer maintained/read-only |
| [coleam00/Archon](https://github.com/coleam00/Archon) | Open-source harness builder; deterministic, repeatable AI coding | 22,919 | 3,429 | v0.5.0, 2026-06-26 | 10 | 85% | Active |

**Interpretation:** topics and a perfect community profile are not prerequisites for stars—large branded repositories such as Claude Code, Codex, and Cline currently have no topics—but the target does not have their brand demand. For an unknown repository, leaving every indexed metadata field empty removes the lowest-cost discovery route. Conversely, active releases and current pushes are nearly universal among the maintained comparison set.

Source: live [`GET /repos/{owner}/{repo}`](https://docs.github.com/en/rest/repos/repos#get-a-repository), community profile, release, tree, and GraphQL repository queries at the audit timestamp. Peer README evidence links to each first-party repository above.

---

## Comparator pattern audit

Legend: **Yes** = directly present; **Partial** = exists but weak, indirect, stale, or not on the first screen; **No** = not found in the inspected default-branch surface. “Custom social” is based on GitHub's API returning a `repository-images.githubusercontent.com` image rather than the generated `opengraph.githubassets.com` repository card; it is an API indicator, not a visual quality judgment.

| Repository | First-screen promise + proof | Fast install path | Examples / demo | Releases + changelog | CI workflow / README badge | Community surface | Custom social |
|---|---|---|---|---|---|---|---|
| **Target** | Promise yes; logo only, no product proof | Clone + `kiro-cli`; prerequisites deferred | Files exist, not outcome-led | Changelog claims versions; **0 tags, 0 Releases** | **No workflow; decorative compatibility/count badges only** | License and labels; missing recognized contribution files | No indicator |
| Claude Code | Specific promise + `demo.gif` | Shell, PowerShell, Homebrew, WinGet; run `claude` | `examples/` + animated demo | Current Releases + `CHANGELOG.md` | Automation workflows; no first-screen CI badge | Issue forms, security policy, bug command, Discord | No indicator |
| Codex | Specific local-agent promise + large screenshot | One-line shell/PowerShell; npm, Homebrew, release binaries | Screenshot + docs/examples in tree | Current Releases + `CHANGELOG.md` | Extensive CI + issue/PR templates; no README CI badge | Contributing, security, Discussions | No indicator |
| OpenHands | “Control center” promise + full-width product screenshot | `npm install -g …; agent-canvas` or Docker | Screenshot, automation use cases | Current Releases; release automation | CI workflow **and visible CI badge** | 87%, Slack, good-first-issue workflow | No indicator |
| Cline | Clear IDE/terminal promise; product routes visible | npm CLI; direct extension marketplace; SDK | Multiple runnable apps/examples | Current Releases + changelogs | CI workflows; no first-screen CI badge | 100%, Discussions, Discord, contribution/security docs | No indicator |
| Aider | Terminal pair-programming promise + screencast | PyPI installer path | Rich first-party example gallery and screencast | Release exists + `HISTORY.md` | Cross-platform CI; no first-screen CI badge | CONTRIBUTING + issue form | **Yes** |
| Continue | Clear category + banner, but retirement notice | Marketplace/npm links, no active quickstart | Product banner; extensive source/docs | Final release + release-based changelog | CI workflows; no first-screen CI badge | 87%, contributing/security/templates | **Yes** |
| Archon | Sharp deterministic-workflow promise + concrete YAML/output example | One-line installer + Homebrew | `examples/workflows`, UI assets, inline end-to-end example | Current release + `CHANGELOG.md` | CI workflow **and visible CI badge** | 85%, Discussions, roadmap, contribution docs, good-first-issue | No indicator |

### What the successful first screens do

1. **Name the category and execution surface immediately.** Claude Code, Codex, Aider, and Cline say terminal/IDE/local. Archon says “workflow engine” and “harness builder,” then names the desired property: deterministic and repeatable.
2. **Show the product or the output before asking for trust.** Claude Code has a GIF; Codex and OpenHands use screenshots; Aider uses a screencast; Archon shows a real workflow and resulting run transcript.
3. **Make installation an executable decision.** The strongest peers offer a one-line package/installer command followed by one command to run. Cline splits routes cleanly by CLI, Kanban, IDE, and SDK.
4. **Route distinct visitors.** Docs, install, examples, community, and contributing are visible rather than buried in a general feature inventory.
5. **Use badges as evidence, not decoration.** Archon exposes a real CI status and license. OpenHands exposes CI, package version, project status, and docs. The target's “Agents-10” and “Thread Types-5” badges are static claims and its “Kiro CLI Compatible” badge is not linked to a compatibility test.

---

## Target repository audit by lever

| Lever | Current evidence | Diagnosis | Required correction |
|---|---|---|---|
| **Archive status** | REST/GraphQL: `archived: true` | Fatal to active adoption. GitHub explicitly presents this as no longer maintained and makes issues, PRs, releases, and settings read-only. | Unarchive before any launch. If the project is intentionally discontinued, do not pursue growth; add a successor link instead. |
| **Name / positioning** | Name includes `Kiro`, `Orchestrator`, `Template`; description blank | Search-friendly nouns exist in the name, but the value proposition is generic and absent from the indexed description. | Keep name initially to preserve links. Add: **“Ready-to-fork multi-agent workflows for Kiro CLI—spec planning, isolated worktrees, validation gates, and reusable specialist agents.”** Test a rename only after search/query data exists. |
| **README first screen** | Logo, “Production-ready multi-agent orchestration,” jump links, four static badges; stray `a` before badges | “Production-ready” is an unsupported trust claim. No visual result, prerequisites, Kiro version, maintained status, or tested environment appears before Quick Start. | Replace logo-heavy first screen with one sentence naming user/result, a 30–60 second terminal GIF, real CI/release/license badges, and a two-command “Try it” path. Remove stray `a`. |
| **Quickstart / time-to-value** | Clone, optional unrelated browser package, run `kiro-cli --agent orchestrator`; says “That's it” | Clone is not template generation. It does not tell users how to install/authenticate Kiro, what prompt to enter, what output to expect, or how long it takes. Setup guide uses placeholder `your-org` URL and manual copy steps. | Define a reproducible “first delegated plan” golden path: Use this template → install/verify supported Kiro CLI → run one command → paste one prompt → observe named files/output. Target <5 minutes from an existing Kiro install and publish the measured time. |
| **Examples** | `.kiro/examples` has sample plan/progress and browser examples | Examples are schemas, not compelling before/after user outcomes. No minimal sample repository or recorded complete run. | Add three runnable scenarios: issue-to-plan, parallel implementation in worktrees, and test/review gate. Include input, command, expected artifacts, terminal transcript, cost/time caveat, and cleanup. Link the smallest one above the feature list. |
| **Demos** | None in first-party README/assets inspected | Visitors must believe orchestration claims without seeing agents delegate or produce artifacts. | Record a short asciinema/GIF with readable text and a 2–3 minute narrated demo. Show one concrete PR/artifact, not dashboard motion. Store a compressed fallback image in-repo. |
| **Package / install path** | Git clone plus manual copying; `isTemplate: false` | The product calls itself a template but does not expose GitHub's **Use this template** path. No versioned CLI/package installer exists. | Immediately enable “Template repository.” Add `gh repo create OWNER/NAME --template RaapTechllc/Kiro-Orchestrator-Template` and the GitHub button route. Later consider a thin `npx create-kiro-orchestrator` only if setup requires transformations; do not create a package merely for optics. |
| **Releases** | API: 0 releases, 0 tags; `CHANGELOG.md` claims 1.0.0 and 2.0.0 and links to missing tags/releases | This is a concrete credibility defect. Users cannot identify a stable snapshot or subscribe to releases. | After validation, create signed/annotated `v2.0.0` (or honest `v0.1.0` if compatibility is unproven), generate a GitHub Release with migration notes, supported Kiro versions, and template instructions. Never backfill unsupported release claims. |
| **Changelog** | Keep-a-Changelog structure; last entry 2026-01-19 | Good structure, but links do not resolve because tags do not exist. Changelog is not a release channel by itself. | Reconcile claimed versions with git history, tags, and Releases. Automate release notes only after version policy is explicit. |
| **Topics** | 0 | Avoidable search loss. GitHub explicitly uses topics for discovery and default repository search. | Add 8–12 accurate topics: `kiro`, `kiro-cli`, `ai-agents`, `multi-agent`, `agent-orchestration`, `coding-agent`, `developer-tools`, `workflow-automation`, `git-worktrees`, `spec-driven-development`. Remove any term not evidenced by a runnable example. |
| **Description / homepage** | Both blank | Search cards cannot explain the repository; no documentation destination. | Add the proposed description. Use a stable docs/demo URL as homepage; until then, use the README's demo anchor or GitHub Pages only if maintained. |
| **Social preview** | Generic GitHub OpenGraph URL indicator | Shared links show a generic repository card rather than a recognizable product/result. | Upload a 1280×640 solid-background card: project name, “Multi-agent workflows for Kiro CLI,” and a small legible workflow diagram. Do this after positioning is final. |
| **Community health** | 28%; root README/LICENSE only recognized. No `.github` directory in root tree. | README has four generic contribution steps, but no `CONTRIBUTING.md`, Code of Conduct, `SECURITY.md`, issue forms, or PR template. Archived state makes contribution impossible anyway. | Add focused bug, compatibility, and workflow-request issue forms; PR checklist that runs validation; `CONTRIBUTING.md`, `SECURITY.md`, and Code of Conduct. Raise community profile to ≥85%, but optimize usefulness rather than score. |
| **Contribution surface** | Labels `good first issue` and `help wanted` exist, but 0 open issues and archived | Labels alone create no work. There is no roadmap or modular “add one agent/workflow” guide. | Seed 5–8 bounded issues only after unarchiving: one example, one compatibility fixture, one documentation correction, and individual workflow improvements. Attach acceptance tests and label 2–3 genuinely approachable issues. |
| **Roadmap** | No roadmap found; `PLAN.md` is template state, not product roadmap | Users cannot tell Kiro-version support, next milestones, or whether the project is active. | Add a short public roadmap tied to GitHub milestones: compatibility matrix, verified starter, examples, then extensibility. Avoid speculative feature lists. |
| **CI / badges** | No `.github/workflows`; static feature badges only | “Production-ready” has no visible automated evidence. Workflow scripts and JSON can regress silently. | Add fast CI: shell syntax (`shellcheck`), JSON/Markdown/link validation, secret scan, template smoke test, and a fixture-based Kiro compatibility check where licensing/auth permit. Show one CI badge only after it passes. |
| **Licensing** | MIT license recognized | Strong, simple reuse permission. README badge is static but accurate. | Keep MIT. Add a short note clarifying third-party Kiro trademarks/software are not included or endorsed, and link Kiro's applicable terms. Do not imply the Kiro logo is project-owned. |

---

## Prioritized growth plan

### P0 — Restore an adoptable repository (day 0–2)

1. **Decide maintenance status, then unarchive.** This is a hard gate. An archived repository cannot accept the changes, issues, releases, or PRs required by the rest of this plan. Assign a named maintainer and a minimum support promise (for example, monthly compatibility check and issue response within seven days).
2. **Correct the GitHub About surface in one admin session.** Add the description, homepage/demo URL, 8–12 accurate topics, and enable **Template repository**. Upload a social preview only after the one-line position is approved.
3. **Reconcile false/stale trust signals.** Remove “production-ready” until a supported version matrix and smoke test exist. Remove the stray `a`, dead Discussions link unless Discussions are enabled, and release links that do not resolve. Verify every README command on Windows, macOS, and Linux or state exactly which platforms are supported.

**Exit gate:** public page is unarchived, “Use this template” is visible, metadata is populated, all first-screen links resolve, and the README's support status is truthful.

### P1 — Build and prove one five-minute success (day 2–7)

4. **Create a golden-path fixture.** Use a tiny repository with one intentionally simple feature. Starting from “Use this template,” record exact prerequisites, Kiro version, authentication assumption, command/prompt, generated plan, delegated work, validation result, elapsed time, and cleanup.
5. **Turn the fixture into CI.** At minimum validate JSON, shell syntax, links, expected files, and deterministic script behavior. If automated Kiro execution is not allowed or would require secrets, run the agent step as a documented scheduled/manual compatibility check and automate everything around it. Publish the latest verified Kiro version/date in the README.
6. **Replace the first screen.** Proposed order:
   - name + specific one-line result;
   - short GIF/screenshot of the golden-path output;
   - real CI, latest release, and license badges;
   - two installation routes: **Use this template** and `gh repo create --template`;
   - one copy/paste command and prompt;
   - expected output and “~N minutes in our fixture”;
   - deeper concepts/features below.

**Exit gate:** a new Kiro user with prerequisites can reproduce the documented artifact without reading the architecture section; CI validates all deterministic pieces.

### P2 — Establish a versioned trust surface (week 2)

7. **Publish the first honest GitHub Release.** Reconcile `CHANGELOG.md` with actual history. If no historical tags can be substantiated, start at `v0.1.0` and explain that this is the first verified public release. Include supported Kiro version, OS matrix, upgrade notes, known limitations, and a link to the golden-path demo.
8. **Add community health files and structured intake.** Create `CONTRIBUTING.md`, `SECURITY.md`, Code of Conduct, issue forms for bug/compatibility/workflow request, and a PR template with validation commands. Enable Discussions only if someone will moderate it; otherwise remove the link.
9. **Publish a narrow roadmap and compatibility matrix.** Make the next three milestones observable: verified core template, three outcome examples, then extension guide. Track Kiro versions and date last tested; this matters more than a broad feature wishlist.

**Exit gate:** community profile ≥85%, at least one release, changelog links resolve, and support/version expectations are explicit.

### P3 — Create contribution and distribution loops (weeks 3–4)

10. **Ship three outcome-led examples.** Prioritize issue-to-plan, isolated parallel worktrees, and validation/review gating. Each needs an input, exact command, expected artifact, transcript, limitations, and link to reusable files.
11. **Seed contribution-ready work.** Open 5–8 bounded issues with reproductions and acceptance criteria. Label only 2–3 genuinely beginner-safe tasks `good first issue`; GitHub may surface them more widely. Publish “add a specialist agent” and “add a workflow” extension guides so contributions align with the architecture.
12. **Distribute evidence, not announcements.** Share the recorded workflow and release link in Kiro's official community channels where allowed, relevant GitHub Discussions, and RaapTech's engineering channels. Every post should lead to the five-minute path and show the resulting artifact. Do not ask for stars before users can reproduce value.

**Exit gate:** at least three independent successful installs/templates, two external bug/feedback reports closed, and one non-maintainer contribution merged. Treat these as stronger activation signals than raw impressions.

---

## Measurement plan

GitHub does not expose a built-in causal “why this repository earned stars” metric. Instrument the funnel so changes can be evaluated rather than attributed by intuition:

| Stage | Measure | 30-day relaunch target | Why it matters |
|---|---|---:|---|
| Exposure | Unique repo visitors and referring sites (GitHub Traffic) | Establish baseline; annotate launch dates | Separates low reach from low conversion |
| Evaluation | README demo views/clicks where measurable; clone-to-star ratio | Baseline, not vanity target | Tests whether positioning earns further interest |
| Activation | Independent verified golden-path completions | ≥10 | Better evidence of usefulness than stars |
| Reuse | Template-generated repositories, forks, or explicit adopter reports | ≥5 | Shows actual reuse intent |
| Reliability | Golden-path pass rate by supported Kiro/OS version | 100% on declared matrix | Supports the compatibility claim |
| Trust | Release cadence and mean issue first response | Monthly check; <7 days | Shows ongoing maintenance |
| Contribution | External PRs opened/merged | ≥2 / ≥1 | Tests contribution surface |
| Interest | Stars and watchers | Report, do not optimize in isolation | Useful trend signal, weak adoption proof |

Use a lightweight `ADOPTERS.md` opt-in list or issue form for verified users; do not add telemetry to the template without explicit consent. Review the funnel after 30 days. If visits are low, improve distribution/metadata. If visits are high but activations are low, fix the first screen and quickstart. If activations occur but contributions do not, improve examples, extension seams, and scoped issues.

---

## Top five actions

1. **Unarchive the repository and assign an explicit maintainer/support cadence.**
2. **Enable GitHub Template mode and populate description, homepage, and accurate topics.**
3. **Build a CI-backed, version-pinned golden path that produces one visible result in under five minutes.**
4. **Rewrite the README first screen around that result: demo, two-command start, expected output, and real status badges.**
5. **Publish the first honest GitHub Release and add the structured community/contribution surface needed to sustain adoption.**

These actions are ordered by dependency: promotion before actions 1–4 would send traffic to an archived, unverified artifact and likely waste the launch opportunity.
