# Kiro CLI status and repository compatibility — 2026-07-16

**Research date:** 2026-07-16
**Repository inspected:** [`RaapTechllc/Kiro-Orchestrator-Template`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template), commit [`8fd8cec`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/commit/8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83) (2026-01-19). GitHub marks the repository archived/read-only as of 2026-03-29.[^repo-status]
**Evidence policy:** Primary sources only: official Kiro documentation and changelog, the official `kirodotdev/Kiro` repository, AWS documentation/announcements, and the repository being assessed.

## Executive finding

The `kiro-cli` command used by this repository is **still active and is not deprecated or renamed**. It remains the unambiguous command that always launches the CLI. The actively maintained production line is Kiro CLI **2.x**; the latest official changelog entry available on the research date is **2.12.0 (2026-07-09)**.[^changelog]

There are two separate transitions that are easy to conflate:

1. **Amazon Q Developer CLI → Kiro CLI:** AWS says Amazon Q Developer CLI was rebranded to Kiro. Kiro's migration guide calls Kiro CLI “the next update of the Q CLI.” The legacy `q` and `q chat` entry points remain backward-compatible, but new features and fixes are Kiro-only. In this lineage, **Kiro supersedes Q CLI**.[^aws-rebrand][^q-migration]
2. **Kiro CLI 2.x → Kiro CLI V3 early access:** V3 is an opt-in preview invoked with `kiro-cli --v3`; it runs alongside the existing 2.x installation and does not alter the 2.x setup unless selected. Therefore V3 is **not yet verified as the default replacement** as of this date, although it is clearly the next-generation harness.[^v3-release][^v3-compare]

For this repository, the top-level `kiro-cli --agent orchestrator` launch assumption remains broadly valid on Kiro CLI 2.x. However, substantial parts of the claimed orchestration are stale or were never wired up: the parallel Ralph script's Kiro execution is commented out and uses an undocumented `--prompt` option; current subagents use the `subagent` tool rather than the repository's `use_subagent`; native Windows support now exists; and V3 requires agent/permission/hook schema migration.[^repo-readme][^repo-ralph][^repo-agent][^subagents][^install][^v3-compare]

## Verified product status

| Question | Verified answer | Evidence |
|---|---|---|
| Is `kiro-cli` active? | **Yes.** Current installation, command reference, CloudShell documentation, changelog, and a June 2026 AWS Security post all use it. | [Get started](https://kiro.dev/docs/cli/), [command reference](https://kiro.dev/docs/cli/reference/cli-commands/), [AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/q-cli-features-in-cloudshell.html), [AWS Security Blog](https://aws.amazon.com/blogs/security/accelerate-security-investigations-with-kiro-cli/) |
| Was Kiro CLI renamed? | **No verified rename of Kiro CLI.** Instead, **Amazon Q Developer CLI was rebranded/superseded by Kiro CLI**. | [AWS “Upgrade to Kiro”](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/upgrade-to-kiro.html), [Kiro Q migration guide](https://kiro.dev/docs/cli/migrating-from-q/) |
| Is `kiro` now the required command? | **No.** An optional command router can make `kiro` launch either IDE or CLI. `kiro-cli` always launches the CLI. | [CLI command reference — Kiro Command Router](https://kiro.dev/docs/cli/reference/cli-commands/#kiro-command-router-v1260) |
| Is 2.x still maintained? | **Yes.** Releases 2.9 through 2.12 followed the V3 preview announcement, including 2.12.0 on July 9. | [Official CLI changelog](https://kiro.dev/changelog/cli/) |
| Has V3 superseded 2.x? | **Not yet as a default, based on available official evidence.** It is early access, opt-in via `--v3`, and explicitly runs alongside 2.x. | [2.8.0 V3 announcement](https://kiro.dev/changelog/cli/2-8/), [V3 feature comparison](https://kiro.dev/docs/cli/v3/feature-overview/) |
| Is the official GitHub repository a source/release repository? | The official repository describes Kiro and accepts issues, but its visible tree is documentation/community material and GitHub reports no published Releases. It should not be treated as proof that the proprietary CLI implementation is open source. | [`kirodotdev/Kiro`](https://github.com/kirodotdev/Kiro), [README](https://github.com/kirodotdev/Kiro/blob/main/README.md) |
| Is there current maintenance evidence beyond docs? | **Yes.** AWS published a Kiro CLI security fix: versions before 1.28.0 were affected by CVE-2026-9255, fixed in 1.28.0, and AWS recommended upgrading to latest. Current changelog releases are 2.x. | [AWS Security Bulletin 2026-035](https://aws.amazon.com/security/security-bulletins/2026-035-aws/), [1.28.0 changelog](https://kiro.dev/changelog/cli/1-28/) |
| What is the template repository's own status? | **Archived/read-only.** GitHub reports its last push as 2026-01-19 and archive/update date as 2026-03-29. This is repository status, not evidence that Kiro CLI itself was retired. | [Public repository](https://github.com/RaapTechllc/Kiro-Orchestrator-Template) |

## Current Kiro CLI capabilities relevant to orchestration

The current official documentation verifies these capabilities in the 2.x product line:

- **Interactive and non-interactive chat:** `kiro-cli`, `kiro-cli chat`, persisted sessions, resume/list/delete operations, model selection, and launch-time reasoning effort.[^commands]
- **Headless CI/CD execution:** API-key authentication through `KIRO_API_KEY`; `kiro-cli chat --no-interactive`; selective `--trust-tools`; `--trust-all-tools`; MCP startup failure handling; documented exit codes.[^headless]
- **Custom agents:** repository-local `.kiro/agents` configurations can set prompts, models, built-in/MCP tools, pre-approved tools, path/tool restrictions, resources, hooks, skills, and knowledge bases.[^agents-config]
- **Native subagents:** isolated contexts, live monitoring, result aggregation, up to four concurrent subagents, DAG dependencies, and bounded review loops. Custom agents inherit their own tools and permissions.[^subagents]
- **MCP:** local/remote MCP servers, OAuth, agent-specific access, and hot-reload in 2.10.0.[^agents-config][^changelog]
- **Steering, prompts, hooks, skills, knowledge and code intelligence:** all are first-class CLI features; current configuration can be relocated with `KIRO_HOME`.[^get-started][^agents-config][^changelog]
- **Goal-driven autonomous loops:** 2.7.0 added `/goal`, which iterates toward acceptance criteria with a configurable safety limit and self-verification.[^changelog]
- **Cross-platform install:** native macOS, Linux, and **Windows 11 PowerShell** installation is documented. The Windows package auto-updates in the background unless disabled.[^install]
- **AWS integration:** AWS documents Kiro CLI in CloudShell and demonstrates natural-language AWS security investigation workflows with explicit approval gates.[^cloudshell][^aws-security-blog]

### V3 early-access direction

V3 uses the same unified agent harness as Kiro IDE and Kiro Web and adds built-in spec-driven development, capability-based permissions, enhanced standalone hooks, trusted workspaces, and tag-based agent configuration. It also removes `aws_tool` in favor of MCP and removes supervised mode in favor of `permissions.yaml`.[^v3-release][^v3-compare]

This is strategically relevant to a modernization effort, but V3 should be treated as a **separate compatibility target**, not assumed to accept every 2.x agent file unchanged.

## Repository assumptions versus current reality

### Compatibility matrix

| Repository assumption at `8fd8cec` | 2026-07-16 assessment | Confidence |
|---|---|---|
| `kiro-cli --agent orchestrator` starts the local orchestrator. | **Still supported in 2.x.** `--agent` remains a global argument, and `.kiro/agents` remains the workspace agent location.[^repo-readme][^commands][^q-migration] | High |
| `.kiro/agents/*.json`, `.kiro/prompts`, `.kiro/steering`, `.kiro/settings`, and hooks are native concepts. | **Still supported in 2.x.** These are current Kiro locations and concepts.[^q-migration][^agents-config] | High |
| Windows users must install WSL/Ubuntu and use the Linux package. | **Outdated.** Current docs provide native Windows 11 installation through PowerShell and native uninstall/update behavior.[^repo-cli-ref][^install] | High |
| An orchestrator agent can delegate through a `use_subagent` built-in tool. | **Likely stale.** Current docs name the tool `subagent`; troubleshooting explicitly says a custom orchestrator must include `subagent` (or `@builtin`). The Q migration guide's documented legacy aliases do **not** list `use_subagent`, so backward compatibility for this exact name is unverified.[^repo-agent][^subagents][^q-migration] | High that docs diverge; runtime behavior uncertain |
| `ralph-kiro.sh` launches multiple autonomous Kiro agents. | **Not implemented in the inspected commit.** The only Kiro command is under “REPLACE WITH ACTUAL EXECUTION” and commented out; the active loop merely writes a log entry and sleeps.[^repo-ralph] | High |
| The commented command `kiro-cli --agent "$agent" --prompt "…"` is the headless interface. | **Not current documented syntax.** Current docs use a positional prompt with `kiro-cli chat --no-interactive`, plus explicit tool trust for automation. `--prompt` is absent from the current command reference.[^repo-ralph][^commands][^headless] | High |
| Up to 15 shell-spawned agents is the natural concurrency model. | Current built-in subagent orchestration supports **up to four at once**, plus DAGs and review loops. External process-level concurrency may still be possible, but limits, quotas, session collisions, and safety are not established by the repository or official docs. | High for built-in limit; external behavior uncertain |
| Exact model IDs such as `claude-opus-4-5-20251101` remain selectable. | **Unverified and fragile.** Current agent docs say unavailable configured models fall back to the default. The report did not have an authenticated local Kiro installation with which to enumerate account-specific models.[^repo-agent][^agents-config] | Medium |
| Current JSON agents can be used unchanged under V3. | **False as a blanket assumption.** V3 changes custom-agent tool lists to tags, `toolsSettings` to `permissions`, and hooks to a new schema.[^v3-compare] | High |
| The project is “production-ready multi-agent orchestration.” | **Not demonstrated by the source at this commit.** Configuration assets exist, but the flagship parallel launcher is a stub. No runtime validation was possible because `kiro-cli` is not installed in the research environment. | High for source observation; runtime unknown |

### Important version drift

The repository's last commit predates several material capabilities:

- native Windows support and first-class headless mode (2.0),
- native subagent pipelines and later review loops,
- `/goal` autonomous verification loops,
- custom-agent resource inheritance and hot-reload,
- the opt-in V3 harness and its permission/configuration model,
- MCP OAuth expansion through 2.12.[^changelog]

The repository therefore should not be discarded merely because it is Kiro-specific: many of its concepts now map to supported Kiro primitives. But it should not present the January 2026 shell scripts and agent JSON as current, tested production orchestration without a compatibility and execution rewrite.

## Implications for a multi-CLI modernization

1. **Keep Kiro as an adapter, not the core abstraction.** The stable executable remains `kiro-cli`; implement a Kiro 2.x adapter using `kiro-cli chat --no-interactive` and positional prompts.
2. **Separate Kiro 2.x and V3 adapters/config generation.** V3's permissions, tags, and hooks differ enough that “one JSON file for both” is unsafe without a translator and validation tests.
3. **Replace the shell stub with a real runner.** Capture exit status, stdout/stderr, timeout, session identity, worktree path, and completion criteria. Do not retain the undocumented `--prompt` flag.
4. **Prefer native Kiro subagents/DAG/review loops when operating inside one Kiro session.** Use external process spawning only where isolation or cross-CLI orchestration requires it, and document that it is outside Kiro's verified four-subagent native model.
5. **Normalize capabilities across CLIs.** Model generic concepts such as prompt, agent/profile, working directory, non-interactive mode, permissions, resume/session, MCP, output format, and exit code; map each CLI explicitly rather than leaking Kiro flags into the orchestration layer.
6. **Add capability probes.** At minimum: executable/version detection, `--help` capture, headless smoke test, agent-config validation, subagent availability, and V3 opt-in detection.
7. **Update security posture.** Require a current 2.x version, use least-privilege `--trust-tools`, and account for the piped-stdin authorization vulnerability fixed in 1.28.0.[^security-bulletin][^headless]
8. **Refresh docs.** Replace the WSL-only Windows instructions, mark supported Kiro lines clearly, and distinguish “configuration supplied” from “runtime tested.”

## Uncertainties and limits

- The exact latest binary patch after 2.12.0 cannot be inferred from the changelog landing page; 2.12.0 is the latest **published changelog entry observed** on 2026-07-16, not a claim that no unpublished patch exists.
- V3 is officially labeled early access and opt-in. The sources do not provide a date when it will become default or when 2.x will be deprecated.
- The official `kirodotdev/Kiro` GitHub repository has no GitHub Releases and does not expose the CLI implementation in its visible tree. Product activity is established from official docs/changelog/AWS sources, not inferred from open-source release artifacts.
- Kiro CLI was not installed in the research environment, so account-specific model availability and direct runtime compatibility of this repository's JSON files were not tested.
- The repository was inspected at its current public `main` commit. Claims about intended behavior were separated from executable behavior; commented code and README claims were not treated as runtime proof.
- The upstream template repository is archived. Any modernization will require unarchiving it or working in a writable successor/fork; this does not affect the product-status conclusion about Kiro CLI.

## Bottom line

**Do not remove Kiro support on the premise that its CLI disappeared.** `kiro-cli` is active, current, and substantially more capable than when this repository was last updated. The historical product that was renamed/superseded is **Amazon Q Developer CLI**, not this repository's `kiro-cli` entry point. The immediate modernization risk is instead **schema and execution drift**: Kiro 2.x is current, V3 is an opt-in next-generation target, and the repository's claimed external multi-agent runner is presently a stub.

---

## Sources

[^get-started]: Kiro, [“Get started — CLI”](https://kiro.dev/docs/cli/) (page updated 2026-04-19).
[^install]: Kiro, [“Installation — CLI”](https://kiro.dev/docs/cli/installation/) (page updated 2026-06-03).
[^commands]: Kiro, [“CLI commands”](https://kiro.dev/docs/cli/reference/cli-commands/) (page updated 2026-06-05).
[^headless]: Kiro, [“Headless mode”](https://kiro.dev/docs/cli/headless/) (page updated 2026-06-04).
[^agents-config]: Kiro, [“Agent configuration reference”](https://kiro.dev/docs/cli/custom-agents/configuration-reference/) (page updated 2026-07-02).
[^subagents]: Kiro, [“Subagents”](https://kiro.dev/docs/cli/chat/subagents/) (page updated 2026-05-29).
[^q-migration]: Kiro, [“Upgrading from Amazon Q Developer CLI”](https://kiro.dev/docs/cli/migrating-from-q/) (page updated 2026-07-01).
[^aws-rebrand]: AWS, [“Upgrade to Kiro — Amazon Q Developer”](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/upgrade-to-kiro.html).
[^changelog]: Kiro, [“CLI Changelog”](https://kiro.dev/changelog/cli/) (latest observed entry: 2.12.0, 2026-07-09).
[^v3-release]: Kiro, [“CLI v3 Early Access,” Kiro CLI 2.8.0](https://kiro.dev/changelog/cli/2-8/) (2026-06-17).
[^v3-compare]: Kiro, [“V3 Feature comparison”](https://kiro.dev/docs/cli/v3/feature-overview/) (page updated 2026-06-17).
[^security-bulletin]: AWS, [“CVE-2026-9255 — Tool Execution Without Authorization via Piped Stdin in Kiro CLI”](https://aws.amazon.com/security/security-bulletins/2026-035-aws/) (2026-05-22).
[^cloudshell]: AWS, [“Using Kiro CLI in CloudShell”](https://docs.aws.amazon.com/cloudshell/latest/userguide/q-cli-features-in-cloudshell.html).
[^aws-security-blog]: AWS Security Blog, [“Accelerate security investigations with Kiro CLI”](https://aws.amazon.com/blogs/security/accelerate-security-investigations-with-kiro-cli/) (2026-06-16).
[^repo-status]: GitHub, [`RaapTechllc/Kiro-Orchestrator-Template`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template) (public repository metadata observed 2026-07-16: archived; last push 2026-01-19; archive/update date 2026-03-29).
[^repo-readme]: RaapTech LLC, [`README.md`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/blob/8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83/README.md#L28-L42) at `8fd8cec`.
[^repo-cli-ref]: RaapTech LLC, [`.kiro/docs/kiro-cli-reference.md`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/blob/8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83/.kiro/docs/kiro-cli-reference.md#L5-L35) at `8fd8cec`.
[^repo-agent]: RaapTech LLC, [`.kiro/agents/orchestrator.json`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/blob/8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83/.kiro/agents/orchestrator.json#L1-L18) at `8fd8cec`.
[^repo-ralph]: RaapTech LLC, [`.kiro/workflows/ralph-kiro.sh`](https://github.com/RaapTechllc/Kiro-Orchestrator-Template/blob/8fd8cec89bb9c1c83a76ea4e0cbe69dd77fdbb83/.kiro/workflows/ralph-kiro.sh#L388-L443) at `8fd8cec`.
