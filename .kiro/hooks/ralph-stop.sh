#!/usr/bin/env bash
# Legacy Ralph stop hook intentionally disabled.
# Completion authority now belongs to `bin/orch loop --verify ...`.

printf '%s\n' '[ralph-stop] disabled: use bin/orch loop with an external verification command' >&2
exit 0
