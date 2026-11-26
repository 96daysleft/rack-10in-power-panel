// Main module with pcb/pi-power boards instead of bare buck modules: one board per
// Pi on two standoffs (M3 heat-set inserts) and two support posts.
// For the expansion panel, add `buck_mount = "pi-power";` below the include in
// expansion-panel.scad the same way.
include <rack-power-panel.scad>
buck_mount = "pi-power";
