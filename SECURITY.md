# Security policy

## Supported versions

The project is currently preparing the provider-neutral v3 beta. Security fixes target the latest `main` branch and active prerelease branch. Historical 1.x/2.x workflow scripts are not treated as hardened execution paths unless `VERIFICATION.md` says otherwise.

## Report privately

Do not open a public issue for command injection, permission bypass, secret exposure, destructive Git behavior, or sandbox escape concerns.

Use GitHub's **Report a vulnerability** flow:

https://github.com/RaapTechllc/Kiro-Orchestrator-Template/security/advisories/new

If private advisories are unavailable, contact RaapTech through the organization profile without including exploit details in the first message.

Include:

- affected path and revision;
- operating system and Bash/provider CLI versions;
- exact reproduction with secrets removed;
- expected versus actual behavior;
- impact and any known mitigation.

We will acknowledge a valid report as capacity permits and coordinate disclosure after a fix is available. This open-source project does not promise a commercial SLA.

## Security boundaries

- The harness executes local coding-agent CLIs with the current user's permissions.
- `--verify` is an operator-supplied shell command and must never contain untrusted input.
- `--unsafe` intentionally activates materially dangerous provider-specific behavior.
- Provider sandboxes, approval policies, network controls, tool trust, and external-directory access are different controls.
- Raw run logs can contain proprietary code, file paths, or provider output. `.orchestrator/` is ignored by Git but should still be handled as sensitive local data.
- The timeout watchdog is not a container sandbox and may not kill detached descendants.
- Legacy `.kiro/workflows/` paths can contain destructive Git/worktree operations and are excluded from the supported-core safety claim unless explicitly documented.

For hostile or untrusted tasks, use disposable credentials and an OS/container/VM boundary in addition to provider controls.
