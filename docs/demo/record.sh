#!/usr/bin/env bash
# Records docs/demo.gif in a throwaway environment with fake data.
# Requires: vhs, gifsicle (optional), JetBrainsMono Nerd Font.
#
#   docs/demo/record.sh [DEMO_HOME]
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
demo=${1:-${TMPDIR:-/tmp}/hsd}

bash "$here/setup.sh" "$demo"
trap 'bash "$here/setup.sh" "$demo" stop' EXIT

cd "$root"
env -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_ENV -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
	DEMO_ENV="$(cd "$demo" && pwd)/env.sh" vhs "$here/demo.tape"

if command -v gifsicle >/dev/null; then
	gifsicle -O3 --batch docs/demo.gif
fi
ls -lh docs/demo.gif
