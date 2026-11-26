#!/usr/bin/env bash
# Regenerate the carrier board, run ERC/DRC, and export previews, fab and assembly files.
# Usage: pcb/build.sh            (outputs land in pcb/out/)
set -euo pipefail

cd "$(dirname "$0")"
NAME=pi-power
# Run KiCad with a clean environment: a parent AppImage (e.g. a launcher) can leak
# LD_LIBRARY_PATH/APPDIR/PYTHONHOME, which breaks kicad-cli and the pcbnew module.
run() {
  env -i HOME="$HOME" USER="${USER:-}" PATH=/usr/local/bin:/usr/bin:/bin \
    DISPLAY="${DISPLAY:-}" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" "$@"
}

mkdir -p out
run /usr/bin/python3 generate.py

echo "== ERC"
run kicad-cli sch erc --severity-all --exit-code-violations -o out/erc.rpt $NAME.kicad_sch \
  || { cat out/erc.rpt; exit 1; }

echo "== DRC (with schematic parity)"
run kicad-cli pcb drc --schematic-parity --severity-error --exit-code-violations -o out/drc.rpt $NAME.kicad_pcb \
  || { cat out/drc.rpt; exit 1; }
# Warnings don't fail the build, but list them so they're never hidden.
run kicad-cli pcb drc --schematic-parity --severity-all -o out/drc-all.rpt $NAME.kicad_pcb >/dev/null || true
echo "   warnings (count by type):"; { grep -E '^\[' out/drc-all.rpt || true; } | sort | uniq -c | sed 's/^/   /'
grep -E '^\*\* Found' out/drc-all.rpt | sed 's/^/   /'

echo "== Exports"
run kicad-cli sch export pdf -o out/$NAME-schematic.pdf $NAME.kicad_sch
run kicad-cli pcb export svg --mode-single --exclude-drawing-sheet --fit-page-to-board \
  --layers F.Cu,F.SilkS,F.Fab,Edge.Cuts -o out/$NAME-top.svg $NAME.kicad_pcb
run kicad-cli pcb render --side top --width 1600 --height 900 --quality basic -o out/$NAME-3d.png $NAME.kicad_pcb
run kicad-cli pcb export gerbers --use-drill-file-origin -o out/gerbers/ $NAME.kicad_pcb
run kicad-cli pcb export drill --drill-origin plot -o out/gerbers/ $NAME.kicad_pcb

echo "== Assembly files (PCBWay PCBA quote)"
run kicad-cli sch export bom -o out/$NAME-bom.csv \
  --fields 'Reference,Value,Footprint,MPN,${QUANTITY}' --labels 'Designator,Value,Footprint,MPN,Qty' \
  --group-by 'Value,Footprint,MPN' --ref-range-delimiter '' $NAME.kicad_sch
run kicad-cli pcb export pos --format csv --units mm --side both --use-drill-file-origin -o out/$NAME-pos.csv $NAME.kicad_pcb
(cd out && rm -f $NAME-gerbers.zip && zip -qj $NAME-gerbers.zip gerbers/*)
echo "done: see pcb/out/ (gerbers zip, BOM and placement CSVs for the fab)"
