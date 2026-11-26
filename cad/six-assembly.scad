// Six-buck panel with stand-in parts and wiring, for a visual check only.
// Not for printing: parts are simple blocks sized like the real ones.
// Render a colour preview with cad/render.sh (it writes out/six-assembly*.png).
include <six-panel.scad>

$fn = 16;
wire_d  = 1.8;   // 18-20 AWG with insulation
cable_d = 3.5;   // micro-USB / barrel pigtail jacket
RED = "red"; BLK = [0.15, 0.15, 0.15]; CAB = [0.25, 0.25, 0.28];

// polyline of hulled spheres
module wire(pts, c = RED, d = wire_d)
    color(c) for (i = [0 : len(pts) - 2])
        hull() { translate(pts[i]) sphere(d = d); translate(pts[i + 1]) sphere(d = d); }

// ---------- stand-in parts (tray coordinates) ----------
board_z = floor_t;

module buck(p) translate([p[0], p[1], board_z]) {     // MP1584-style module, IN left, OUT right
    color("seagreen") translate([-10.5, -8, 0]) cube([21, 16, 1.6]);
    color([0.1, 0.1, 0.1]) translate([-1, -3.5, 1.6]) cube([7, 7, 4]);       // inductor
    color([0.2, 0.2, 0.2]) translate([-7, -2, 1.6]) cube([4, 4, 1.2]);       // regulator IC
    color("gold") for (dx = [-9, 9], dy = [-4, 4]) translate([dx, dy, 1.6]) cylinder(d = 2, h = 0.4);
}

wago_y = 18.8;
module wago(p, face) translate([p[0], p[1], board_z]) {   // 221-415; face = -1 wires enter front, +1 rear
    color([0.85, 0.85, 0.85, 0.85]) translate([-10.1, -wago_y / 2, 0]) cube([20.2, wago_y, 8.5]);
    color("orange") for (k = [0 : 4]) translate([-8 + 4 * k - 1.4, -face * 1 - 6, 8.5]) cube([2.8, 12, 1.5]);
}

module fuse_holder() color([0.1, 0.1, 0.1]) translate([fuse_pos[0] - 5, fuse_pos[1] - 12, floor_t]) cube([10, 24, 9]);

rk_x = rocker_x - tray_x0;  // rocker centre in tray coordinates
module rocker_body() {
    color([0.1, 0.1, 0.1]) translate([rk_x - rocker[0] / 2, 0.5, panel_h / 2 - rocker[1] / 2]) cube([rocker[0], 16, rocker[1]]);
    color("silver") for (dx = [-4, 4]) translate([rk_x + dx - 1, 16.5, panel_h / 2 - 3]) cube([2, 5, 6]);
    color("red") translate([rk_x - rocker[0] / 2 + 1, -4.6, panel_h / 2 - rocker[1] / 2 + 1]) cube([rocker[0] - 2, 1, rocker[1] - 2]);
}

module jack_body() {
    color("silver") translate([jack_x, tray_d - wall_t, jack_z]) rotate([90, 0, 0]) cylinder(d = 10, h = 11);
    color([0.1, 0.1, 0.1]) translate([jack_x, tray_d + 0.1, jack_z]) rotate([-90, 0, 0]) cylinder(d = 10, h = 16);  // brick plug
    wire([[jack_x, tray_d + 16, jack_z], [jack_x, tray_d + 30, jack_z - 6]], BLK, 4);                            // brick cable
}

module panel_led() {
    lx = led_x - tray_x0;
    color("lime") translate([lx, -1, panel_h / 2]) rotate([-90, 0, 0]) cylinder(d = 5, h = 6);
}

// ---------- connection points ----------
wA = wago6_pos[0]; wB = wago6_pos[1]; gA = wago6_pos[2]; gB = wago6_pos[3];
function port(w, k, face) = [w[0] - 8 + 4 * k, w[1] + face * wago_y / 2, board_z + 4];
function out_pt(p, s, dist = 4, z = 9) = [p[0], p[1] + s * dist, z];
top = board_z + 2.1;  // buck pad height
function bin(b, pol)  = [b[0] - 9, b[1] + pol * 4, top];   // pol -1 = +, +1 = -
function bout(b, pol) = [b[0] + 9, b[1] + pol * 4, top];

bucks = buck_pos;  // [front row x3, rear row x3]
// +12V ports: A = in, jumper, GS308, buck1, buck2; B = jumper, buck3..6 (GND the same)
red_src = [port(wA, 3, -1), port(wA, 4, -1), port(wB, 1, -1), port(wB, 2, -1), port(wB, 3, -1), port(wB, 4, -1)];
blk_src = [port(gA, 3, 1),  port(gA, 4, 1),  port(gB, 1, 1),  port(gB, 2, 1),  port(gB, 3, 1),  port(gB, 4, 1)];

module wiring() {
    // input: jack + -> fuse -> rocker -> +12V Wago A port 0; jack - -> GND Wago A port 0
    wire([[jack_x - 2, tray_d - 13, jack_z + 2], [fuse_pos[0], fuse_pos[1] + 13, 8]]);
    wire([[fuse_pos[0], fuse_pos[1] - 13, 8], [fuse_pos[0], 30, 12], [rk_x - 4, 24, panel_h / 2], [rk_x - 4, 21.5, panel_h / 2]]);
    wire([[rk_x + 4, 21.5, panel_h / 2], [rk_x + 4, 26, 16], [port(wA, 0, -1)[0], 17, 10], out_pt(port(wA, 0, -1), -1, 1, 7), port(wA, 0, -1)]);
    wire([[jack_x + 2, tray_d - 13, jack_z - 2], [30, 81, 9], [port(gA, 0, 1)[0], 80, 9], port(gA, 0, 1)], BLK);
    // panel LED: no free Wago port, so + piggybacks on the rocker's output tab (1k resistor in
    // the lead) and - shares GND Wago A's jumper port in a twin ferrule
    wire([[rk_x + 4, 21.5, panel_h / 2 + 2], [led_x - tray_x0, 8, panel_h / 2 + 2], [led_x - tray_x0, 5, panel_h / 2]], RED, 1.2);
    wire([[led_x - tray_x0 + 1, 5, panel_h / 2 - 1], [32.5, 10, 14], [32.5, 79, 10],
          [port(gA, 1, 1)[0] + 1, 79, 8], out_pt(port(gA, 1, 1), 1, 2, 6.5)], BLK, 1.2);
    // jumpers A <-> B on both rails
    wire([port(wA, 1, -1), out_pt(port(wA, 1, -1), -1, 3, 7), out_pt(port(wB, 0, -1), -1, 3, 7), port(wB, 0, -1)]);
    wire([port(gA, 1, 1), out_pt(port(gA, 1, 1), 1, 3, 7), out_pt(port(gB, 0, 1), 1, 3, 7), port(gB, 0, 1)], BLK);
    // GS308 pigtail: +12V A port 2 and GND A port 2 -> cable out the GS308 notch
    gx = 31;  // lane between the fuse holder and the Wagos
    wire([port(wA, 2, -1), out_pt(port(wA, 2, -1), -1, 5, 9), [gx, 17.5, 9], [gx, 80, 12], [gs308_x - 2, 84, 15]]);
    wire([port(gA, 2, 1), out_pt(port(gA, 2, 1), 1, 5, 10), [gs308_x - 2, 84, 15]], BLK);
    wire([[gs308_x - 2, 84, 15], [gs308_x, tray_d - wall_t - 1, wall_h - notch_depth + 2], [gs308_x, tray_d + 18, wall_h - notch_depth + 2]], CAB, cable_d);
    color([0.1, 0.1, 0.1]) translate([gs308_x, tray_d + 18, wall_h - notch_depth + 2]) rotate([-90, 0, 0]) cylinder(d = 8, h = 12);

    for (i = [0 : 5]) {
        b = bucks[i]; front = i < 3; col = i % 3;
        // 12 V in: front lane near the panel, then down a lane left of the buck column
        ly = 19 - i * 1.6; lx = b[0] - (front ? 14.5 : 16.5);
        wire([red_src[i], [red_src[i][0], ly, 8], [lx, ly, 8], [lx, b[1] - 4, 8], bin(b, -1)]);
        // GND in: rear lane near the back wall, then down a lane further left
        gy = 80.5 + i * 1.0; gxl = b[0] - (front ? 20 : 18.5);
        wire([blk_src[i], [blk_src[i][0], gy, 8.5], [gxl, gy, 8.5], [gxl, b[1] + 4, 8.5], bin(b, 1)], BLK);
        // 5 V out: two short leads into the micro-USB pigtail, cable out its own rear notch
        j = [b[0] + (front ? 15 : 13), b[1], 8];
        wire([bout(b, -1), [j[0], b[1] - 2, 7], j]);
        wire([bout(b, 1), [j[0], b[1] + 2, 7], j], BLK);
        nx = pi6_notch_x[col * 2 + (front ? 1 : 0)];
        nz = wall_h - notch_depth + 2.5;
        path = front ? [j, [b[0] + 17, 50, 12], [b[0] + 17, 84, 15], [nx, tray_d - wall_t - 1, nz]]
                     : [j, [b[0] + 13, 80, 18], [nx, 84, 18], [nx, tray_d - wall_t - 1, nz]];
        wire(concat(path, [[nx, tray_d + 14, nz]]), CAB, cable_d);
        color([0.1, 0.1, 0.1]) translate([nx - 4, tray_d + 14, nz - 2]) cube([8, 14, 4]);   // micro-USB plug
    }
}

translate([tray_x0, -0.5, 0]) {
    for (b = buck_pos) buck(b);
    wago(wA, -1); wago(wB, -1); wago(gA, 1); wago(gB, 1);
    fuse_holder(); rocker_body(); jack_body(); panel_led();
    wiring();
}
