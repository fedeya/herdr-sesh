#!/usr/bin/env bash
# Builds an isolated, fake environment for recording docs/demo.gif:
# a throwaway HOME with fake projects, zoxide history, sesh configs and a
# headless herdr server with this plugin linked and simulated agents.
#
#   docs/demo/setup.sh DEMO_HOME    # set up and start the demo server
#   docs/demo/setup.sh DEMO_HOME stop
#
# DEMO_HOME must be short: the herdr socket lives inside it.
set -euo pipefail

demo=${1:?usage: setup.sh DEMO_HOME [stop]}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)

env_file="$demo/env.sh"
in_demo() { env -i PATH="$PATH" TERM="${TERM:-xterm-256color}" LANG=en_US.UTF-8 bash -c ". '$env_file' && \"\$@\"" _ "$@"; }

if [ "${2:-}" = stop ]; then
	[ -f "$env_file" ] && in_demo herdr server stop >/dev/null 2>&1 || true
	exit 0
fi

[ -f "$env_file" ] && in_demo herdr server stop >/dev/null 2>&1 || true
rm -rf "$demo"
mkdir -p "$demo"
demo=$(cd "$demo" && pwd)

cat >"$env_file" <<EOF
unset HERDR_SOCKET_PATH HERDR_BIN_PATH HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME FZF_DEFAULT_OPTS
export HOME='$demo' ZDOTDIR='$demo' SHELL=/bin/zsh
export _ZO_DATA_DIR='$demo/.local/share/zoxide'
cd "\$HOME"
EOF

cat >"$demo/.zshrc" <<'EOF'
PROMPT='%F{magenta}%1~%f %F{8}❯%f '
EOF

# --- fake projects ------------------------------------------------------------

mk() { mkdir -p "$demo/$1"; shift; }
files() { local dir=$demo/$1; shift; for f in "$@"; do mkdir -p "$dir/$(dirname "$f")"; : >"$dir/$f"; done; }

files code/orbit README.md package.json tsconfig.json src/server.ts src/middleware/index.ts src/routes/users.ts tests/api.test.ts .gitignore
files code/orbit-web README.md package.json vite.config.ts src/main.tsx src/components/dashboard/Chart.tsx src/theme.css public/favicon.svg
files code/dotfiles README.md install.sh zsh/.zshrc git/.gitconfig nvim/init.lua
files code/blog README.md astro.config.mjs src/pages/index.astro src/content/posts/hello-world.md
files code/rustlings README.md Cargo.toml src/main.rs exercises/01_variables/variables1.rs
files code/raytracer README.md Cargo.toml src/main.rs src/vec3.rs src/camera.rs
files notes inbox.md ideas.md journal/2026-10-01.md
files .config/nvim init.lua lua/plugins.lua lua/keymaps.lua

git_demo() { git -C "$1" -c user.name=demo -c user.email=demo@example.com "${@:2}" >/dev/null 2>&1; }
git_demo "$demo/code/orbit" init -b main
git_demo "$demo/code/orbit" add -A
git_demo "$demo/code/orbit" commit -m init
git_demo "$demo/code/orbit" worktree add -b feat/billing "$demo/code/orbit__worktrees/feat-billing"
files code/orbit__worktrees/feat-billing src/billing/webhooks.rs src/billing/mod.rs

mkdir -p "$demo/.config/sesh"
cat >"$demo/.config/sesh/sesh.toml" <<EOF
[[session]]
name = "dotfiles"
path = "$demo/code/dotfiles"

[[session]]
name = "notes"
path = "$demo/notes"
startup_command = "ls"

[[session]]
name = "nvim config"
path = "$demo/.config/nvim"
EOF

for d in code/blog code/rustlings code/raytracer notes .config/nvim code/orbit code/orbit-web code/dotfiles; do
	in_demo zoxide add "$demo/$d"
done

# --- herdr --------------------------------------------------------------------

mkdir -p "$demo/.config/herdr"
cat >"$demo/.config/herdr/config.toml" <<'EOF'
onboarding = false

[update]
version_check = false
manifest_check = false

[theme]
name = "rose-pine"

[ui]
hide_tab_bar_when_single_tab = true

[keys]
prefix = "ctrl+a"

[[keys.command]]
key = "prefix+o"
type = "plugin_action"
command = "fedeya.herdr-sesh.open"

[[keys.command]]
key = "prefix+shift+l"
type = "plugin_action"
command = "fedeya.herdr-sesh.last"
EOF

in_demo herdr plugin link "$root" >/dev/null
(in_demo nohup herdr server >"$demo/server.log" 2>&1 &)

for _ in $(seq 50); do in_demo herdr status server 2>/dev/null | grep -q 'status: running' && break; sleep 0.2; done

ws() { in_demo herdr workspace create --cwd "$demo/$1" --label "$2" --focus | jq -r '.result.root_pane.pane_id'; }
agent() { in_demo herdr pane run "$1" "bash '$here/fake-agent.sh' $2 $3" >/dev/null; }

p=$(ws code/dotfiles dotfiles)
p=$(ws code/orbit-web orbit-web)
agent "$p" opencode done
in_demo herdr worktree open --cwd "$demo/code/orbit" --path "$demo/code/orbit__worktrees/feat-billing" \
	--label feat/billing --focus --trust-repository >/dev/null
pane_at() { in_demo herdr pane list | jq -r --arg c "$demo/$1" '[.result.panes[] | select(.cwd == $c)][0].pane_id'; }
# worktree open also opens the main checkout as the group's parent workspace.
agent "$(pane_at code/orbit__worktrees/feat-billing)" codex blocked
p=$(pane_at code/orbit)
agent "$p" claude working
in_demo herdr workspace focus "${p%%:*}" >/dev/null

sleep 2
in_demo herdr workspace list | jq -r '.result.workspaces[] | "\(.workspace_id) \(.label) \(.agent_status)"'
