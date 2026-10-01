#!/usr/bin/env bash
# Fake coding agent for the demo: prints a canned transcript and reports a
# state to herdr, then idles. Usage: fake-agent.sh NAME STATE
set -euo pipefail

name=$1 state=$2
dim=$'\e[90m' acc=$'\e[35m' ok=$'\e[32m' warn=$'\e[33m' red=$'\e[31m' b=$'\e[1m' r=$'\e[0m'

report() {
	"$HERDR_BIN_PATH" pane report-agent "$HERDR_PANE_ID" \
		--source "demo-$name" --agent "$name" --state "$1" --seq "$2" >/dev/null 2>&1 || true
}

clear
case $name in
claude)
	cat <<EOF

 ${acc}✻${r} ${b}claude${r} ${dim}· ~/code/orbit${r}

 ${dim}>${r} add rate limiting to the public API

 ${acc}●${r} I'll add a token-bucket limiter as middleware and cover it with tests.

 ${ok}●${r} Read ${dim}(src/middleware/index.ts)${r}
 ${ok}●${r} Write ${dim}(src/middleware/rate-limit.ts)${r}
   ${dim}⎿  Wrote 48 lines${r}
 ${ok}●${r} Update ${dim}(src/server.ts)${r}
   ${dim}⎿  +3 -1${r}

 ${warn}✶${r} Running tests… ${dim}(esc to interrupt)${r}
EOF
	;;
codex)
	cat <<EOF

 ${b}codex${r} ${dim}· ~/code/orbit__worktrees/feat-billing${r}

 ${dim}›${r} wire the payment webhooks into the billing service

 ${ok}•${r} Explored ${dim}src/billing/${r}
 ${ok}•${r} Edited src/billing/webhooks.rs ${ok}+62${r} ${red}-4${r}
 ${ok}•${r} Edited src/billing/mod.rs ${ok}+3${r}

 ${red}▌${r} ${b}Allow command?${r}
 ${red}▌${r}   cargo test -p billing
 ${red}▌${r}
 ${red}▌${r}   ${acc}› Yes${r}   No, and tell codex what to do
EOF
	;;
opencode)
	cat <<EOF

 ${b}opencode${r} ${dim}· ~/code/orbit-web${r}

 ${dim}>${r} migrate the dashboard to the new design tokens

 ${ok}✓${r} Updated 14 components in src/components/dashboard
 ${ok}✓${r} Replaced hardcoded colors in theme.css
 ${ok}✓${r} pnpm typecheck ${dim}passed${r}

 Done. The dashboard now uses the shared tokens only.
EOF
	;;
esac

seq=$(date +%s)0
if [ "$state" = done ]; then
	report working "$seq"
	sleep 1
	report idle "$((seq + 1))"
else
	report "$state" "$seq"
fi
exec sleep 86400
