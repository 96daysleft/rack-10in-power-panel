#!/usr/bin/env bash
# Regenerate the carrier board, run ERC/DRC, and export previews + fab files.
# Usage: pcb/build.sh            (outputs land in pcb/out/)
set -euo pipefail

cd "$(dirname "$0")"
# Run KiCad with a clean environment: a parent AppImage (e.g. a launcher) can leak
# LD_LIBRARY_PATH/APPDIR/PYTHONHOME, which breaks kicad-cli and the pcbnew module.
run() {
  env -i HOME="$HOME" USER="${USER:-}" PATH=/usr/local/bin:/usr/bin:/bin \
    DISPLAY="${DISPLAY:-}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" "$@"
}

mkdir -p out
run /usr/bin/python3 generate.py

echo "== ERC"
run kicad-cli sch erc --severity-all --exit-code-violations -o out/erc.rpt carrier.kicad_sch \
  || { cat out/erc.rpt; exit 1; }

echo "== DRC (with schematic parity)"
run kicad-cli pcb drc --schematic-parity --severity-error --exit-code-violations -o out/drc.rpt carrier.kicad_pcb \
  || { cat out/drc.rpt; exit 1; }

echo "== Exports"
run kicad-cli sch export pdf -o out/carrier-schematic.pdf carrier.kicad_sch
run kicad-cli pcb export svg --mode-single --exclude-drawing-sheet --fit-page-to-board \
  --layers F.Cu,F.SilkS,F.Fab,Edge.Cuts -o out/carrier-top.svg carrier.kicad_pcb
run kicad-cli pcb render --side top --width 1600 --height 900 --quality basic -o out/carrier-3d.png carrier.kicad_pcb
run kicad-cli pcb export gerbers -o out/gerbers/ carrier.kicad_pcb
run kicad-cli pcb export drill -o out/gerbers/ carrier.kicad_pcb
echo "done: see pcb/out/"
