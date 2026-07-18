#!/usr/bin/env bash
set -u

ROOT=$(cd "$(dirname "$0")/../.." && pwd)

cat >&2 <<'EOF'
NOTICE: ralph-kiro.sh is now a compatibility entry point for the verified core.
The historical parallel runner only simulated Kiro execution and is no longer used.
Use bin/orch loop directly for new automation.
EOF

exec "$ROOT/bin/orch" loop --cli kiro "$@"
