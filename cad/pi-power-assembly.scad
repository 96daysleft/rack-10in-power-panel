// Main module with three pcb/pi-power boards and their leads, for a fit check only
// (stand-in parts, not for printing). Board-local positions are KiCad coordinates
// from pcb/generate.py minus (100, 100); the terminals face the rear.
include <pi-power-panel.scad>

$fn = 16;
RED = "red"; BLK = [0.15, 0.15, 0.15]; CAB = [0.25, 0.25, 0.28];

module wire(pts, c = RED, d = 1.8)
    color(c) for (i = [0 : len(pts) - 2])
        hull() { translate(pts[i]) sphere(d = d); translate(pts[i + 1]) sphere(d = d); }

bz  = floor_t + pp_standoff_h;  // board underside
top = bz + 1.6;

module board(x) {
    c = pp_corner(x);
    translate([c[0], c[1], 0]) {
        color("darkgreen") translate([0, 0, bz]) cube([pp_size[0], pp_size[1], 1.6]);
        color([0.12, 0.12, 0.12]) translate([16.46 - 3.21, 2, top]) cube([11.5, 8.5, 17.5]);    // R-78B
        for (p = [6, 26]) {                                                                    // MKDS terminals
            color("limegreen") translate([p - 2.54, 11.8, top]) cube([10.2, 9.8, 9.8]);
            color("silver") for (dx = [0, 5.08]) translate([p + dx, 17, top + 9.8]) cylinder(d = 3, h = 0.4);
        }
        color("lime") translate([35.5, 7.7, top]) cube([2, 1.2, 0.8]);                        // status LED
    }
}

module wago_block(p, n) color([0.85, 0.85, 0.85]) translate([p[0] - n * 2, p[1] - 9.4, floor_t]) cube([n * 4, 18.8, 8.5]);

module leads() {
    nz = wall_h - notch_depth + 2.5;
    for (i = [0 : len(bx) - 1]) {
        c = pp_corner(bx[i]);
        e = c[1] + 21.6;  // terminal wire entries
        // 12 V in: from the Wago, looping round into the rear-facing entries
        wire([[wago_pos[0] + 6 - i * 2, wago_pos[1] + 9.4, floor_t + 5], [wago_pos[0] + 6 - i * 2, e + 6 + i * 2, 14],
              [c[0] + 6, e + 6 + i * 2, 14], [c[0] + 6, e + 1, top + 4]]);
        wire([[wago_pos[0] - 6 + i * 2, wago_pos[1] + 9.4, floor_t + 5], [wago_pos[0] - 6 + i * 2, e + 7 + i * 2, 13],
              [c[0] + 11.08, e + 7 + i * 2, 13], [c[0] + 11.08, e + 1, top + 4]], BLK);
        // 5 V out: micro-USB pigtail from the OUT terminal out its rear notch
        nx = pi_nx[i];
        wire([[c[0] + 28.5, e + 1, top + 4], [c[0] + 28.5, e + 10, nz], [nx, tray_d - wall_t - 1, nz], [nx, tray_d + 14, nz]], CAB, 3.5);
        color([0.1, 0.1, 0.1]) translate([nx - 4, tray_d + 14, nz - 2]) cube([8, 14, 4]);
    }
}

translate([tray_x0, -0.5, 0]) {
    for (x = bx) board(x);
    wago_block(wago_pos, 5);
    leads();
}
