#!/usr/bin/env bash
# Render every panel variant to STL + PNG preview, and fail if OpenSCAD reports
# a warning, an error, or a non-manifold mesh.
# Usage: cad/render.sh                         (outputs land in cad/out/)
#        OPENSCAD=/path/to/OpenSCAD.AppImage cad/render.sh
set -euo pipefail

cd "$(dirname "$0")"
OPENSCAD="${OPENSCAD:-$(command -v openscad || ls "$HOME"/AppImages/OpenSCAD*.AppImage 2>/dev/null | head -1)}"
[[ -x "$OPENSCAD" ]] || { echo "OpenSCAD not found; set OPENSCAD=/path/to/openscad" >&2; exit 1; }

# Clean environment: a parent AppImage can leak LD_LIBRARY_PATH/APPDIR into this shell.
run() { env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin DISPLAY="${DISPLAY:-}" "$OPENSCAD" "$@"; }

mkdir -p out
status=0
for f in rack-power-panel expansion-panel pcb-panel; do
  log=$(run -o "out/$f.stl" "$f.scad" 2>&1)
  if grep -qE "WARNING|ERROR" <<<"$log" || ! grep -qE "Simple:\s+yes" <<<"$log"; then
    echo "FAIL $f"; grep -E "WARNING|ERROR|Simple:" <<<"$log"; status=1
  else
    echo "ok   $f -> out/$f.stl"
  fi
  run -o "out/$f.png" --render --imgsize=1400,900 --camera=127,60,10,55,0,215,520 \
    --colorscheme=Tomorrow "$f.scad" >/dev/null 2>&1
done
exit $status
