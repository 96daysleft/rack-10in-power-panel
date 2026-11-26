// Six-output carrier board in its tray, with stand-ins for the tall parts and the
// off-board leads, for a fit check only (not for printing).
// Board positions are KiCad coordinates from pcb/generate.py, converted to tray
// coordinates with tray_x = x - 56, tray_y = y - 98.
include <six-pcb-panel.scad>
use <six-assembly.scad>   // wire()

$fn = 16;
RED = "red"; BLK = [0.15, 0.15, 0.15]; CAB = [0.25, 0.25, 0.28]; wire_d = 1.8;
function t(p) = [p[0] - 56, p[1] - 98];       // KiCad -> tray

board_z = floor_t + standoff_h;                 // underside of the board
top     = board_z + 1.6;
pi_c    = [153, 169, 193, 209, 231, 247];        // must match PI_C in generate.py
gs308_c = 114;

// MKDS 1,5/2-5,08 stand-in; p = pin 1 (KiCad), rot 0 = wire entry toward the rear edge
module terminal(p, rot = 0) {
    q = t(p);
    translate([q[0], q[1], top]) rotate([0, 0, rot]) {
        color("limegreen") translate([-2.6, -4.6, 0]) cube([10.2, 9.2, 9.8]);
        color("silver") for (dx = [0, 5.08]) translate([dx, 0, 9.8]) cylinder(d = 3, h = 0.4);
    }
}
module regulator(c) {   // RECOM R-78B: 11.5 x 8.5 x 17.5, pins along x at y = 150
    q = t([c - 2.54, 150]);
    color([0.12, 0.12, 0.12]) translate([q[0] - 3.21, q[1] - 2, top]) cube([11.5, 8.5, 17.5]);
}
module fuse_holder() {  // Keystone 3568 with a mini blade fuse fitted
    q = t([208, 104]);
    color([0.1, 0.1, 0.1]) translate([q[0] - 3, q[1] - 2.5, top]) cube([16, 8.4, 7.6]);
    color("tan") translate([q[0] + 0.5, q[1] - 0.6, top + 7.6]) cube([9, 4, 8]);
}

module board() {
    color("darkgreen") translate([t([100, 100])[0], t([100, 100])[1], board_z]) cube([160, 84, 1.6]);
    terminal([110, 108]); terminal([124, 108]); terminal([194, 108]);   // PANEL LED, ROCKER, 12V IN (entry faces rear)
    terminal([gs308_c - 2.54, 176]);
    for (c = pi_c) { terminal([c - 2.54, 176]); regulator(c); }
    fuse_holder();
}

rk_x = rocker_x - tray_x0;
jx   = jack_front_x - tray_x0;
lx   = led_x - tray_x0;
module front_parts() {
    color([0.1, 0.1, 0.1]) translate([rk_x - rocker[0] / 2, 0.5, panel_h / 2 - rocker[1] / 2]) cube([rocker[0], 16, rocker[1]]);
    color("red") translate([rk_x - rocker[0] / 2 + 1, -4.6, panel_h / 2 - rocker[1] / 2 + 1]) cube([rocker[0] - 2, 1, rocker[1] - 2]);
    color("silver") translate([jx, 0.5, panel_h / 2]) rotate([-90, 0, 0]) cylinder(d = 10, h = 12);       // panel jack body
    color([0.1, 0.1, 0.1]) translate([jx, -panel_t, panel_h / 2]) rotate([90, 0, 0]) cylinder(d = 10, h = 16); // brick plug
    color("lime") translate([lx, -1, panel_h / 2]) rotate([-90, 0, 0]) cylinder(d = 5, h = 6);
}

module leads() {
    // front leads loop over the terminals and drop into their rear-facing wire entries
    ey = t([0, 115])[1];                  // just behind the wire entries
    module lead(from, kx, c, d = wire_d, h = 24)
        wire([from, [from[0], from[1] + 4, h], [t([kx, 0])[0], 9, h], [t([kx, 0])[0], ey + 3, top + 8], [t([kx, 0])[0], ey, top + 4]], c, d);
    lead([jx + 2, 12.5, panel_h / 2], 199.08, RED, h = 26);        // panel jack + -> J1 pin 2
    lead([jx - 2, 12.5, panel_h / 2 - 2], 194, BLK, h = 25);       // panel jack - -> J1 pin 1
    lead([rk_x - 4, 16.5, panel_h / 2], 124, RED, h = 22);         // rocker -> J2
    lead([rk_x + 4, 16.5, panel_h / 2], 129.08, RED, h = 23);
    lead([lx, 5, panel_h / 2], 115.08, RED, 1.2, 28);              // LED anode -> J3 pin 2
    lead([lx + 1, 5, panel_h / 2 - 1], 110, BLK, 1.2, 27);         // LED cathode -> J3 pin 1
    // rear terminals -> pigtails out their notches
    nz = wall_h - notch_depth + 2.5;
    outs = concat([[gs308_c, gs308_x]], [for (i = [0 : 5]) [pi_c[i], pi6_notch_x[i]]]);
    for (o = outs) {
        x0 = t([o[0], 0])[0];
        wire([[x0, t([0, 180])[1], top + 4], [x0, t([0, 183])[1], nz], [o[1], tray_d - wall_t - 1, nz], [o[1], tray_d + 14, nz]], CAB, 3.5);
        if (o[1] == gs308_x) color([0.1, 0.1, 0.1]) translate([o[1], tray_d + 14, nz]) rotate([-90, 0, 0]) cylinder(d = 8, h = 12);
        else color([0.1, 0.1, 0.1]) translate([o[1] - 4, tray_d + 14, nz - 2]) cube([8, 14, 4]);
    }
}

translate([tray_x0, -0.5, 0]) { board(); front_parts(); leads(); }
