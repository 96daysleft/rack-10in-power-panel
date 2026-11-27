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
buck_z  = floor_t + buck_standoff_h;  // bucks sit on the pocket's corner ledges

module buck(p) translate([p[0], p[1], buck_z]) {     // MP1584-style module, IN left, OUT right
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

front_jack = jack_side == "front";
jf = [jack_front_x - tray_x0, 0, panel_h / 2];  // front jack centre at the panel's inner face
module jack_body() if (front_jack) {
    color("silver") translate(jf + [0, 0.5, 0]) rotate([-90, 0, 0]) cylinder(d = 10, h = 11);
    color([0.1, 0.1, 0.1]) translate(jf - [0, panel_t, 0]) rotate([90, 0, 0]) cylinder(d = 10, h = 16);   // brick plug
    wire([jf - [0, panel_t + 16, 0], jf - [0, panel_t + 26, 14]], BLK, 4);                                  // brick cable
} else {
    color("silver") translate([jack_x, tray_d - wall_t, jack_z]) rotate([90, 0, 0]) cylinder(d = 10, h = 11);
    color([0.1, 0.1, 0.1]) translate([jack_x, tray_d + 0.1, jack_z]) rotate([-90, 0, 0]) cylinder(d = 10, h = 16);  // brick plug
    wire([[jack_x, tray_d + 16, jack_z], [jack_x, tray_d + 30, jack_z - 6]], BLK, 4);                            // brick cable
}

module panel_led() {
    lx = led_x - tray_x0;
    color("lime") translate([lx, -1, panel_h / 2]) rotate([-90, 0, 0]) cylinder(d = 5, h = 6);
}

// ---------- connection points ----------
wA = wago6_pos[0]; gA = wago6_pos[1];   // +12V Wago (wires enter front), GND Wago (wires enter rear)
function port(w, k, face) = [w[0] - 8 + 4 * k, w[1] + face * wago_y / 2, board_z + 4];
function out_pt(p, s, dist = 4, z = 9) = [p[0], p[1] + s * dist, z];
top = buck_z + 2.1;  // buck pad height
function bin(b, pol)  = [b[0] - 9, b[1] + pol * 4, top];   // pol -1 = +, +1 = -
function bout(b, pol) = [b[0] + 9, b[1] + pol * 4, top];

bucks = buck_pos;  // [front row x3, rear row x3]
// Each Wago (+12V and GND the same): 0 = input, 1 = LED, 2 = GS308, 3 = front chain, 4 = rear chain.
// Each row's input is daisy-chained: Wago -> buck 1 IN -> buck 2 IN -> buck 3 IN.
red_lane = [17, 52];    // y of the +12V chain lane: front row (by the panel), rear row (between rows)
blk_lane = [48, 83];    // y of the GND chain lane: front row (between rows), rear row (by the back wall)
lx  = function(b) b[0] - 14.5;  // +12V drop lane, left of a buck pocket
gxl = function(b) b[0] - 18;    // GND drop lane, further left

module wiring() {
    // input: jack + -> fuse -> rocker -> +12V Wago port 0; jack - -> GND Wago port 0
    if (front_jack) {  // jack lugs -> back over the top of the Wagos to the fuse / GND Wago
        wire([jf + [-2, 12, 2], [jf[0] - 2, 16, 22], [40, 45, 18], [24, fuse_pos[1] + 15, 12], [fuse_pos[0], fuse_pos[1] + 13, 8]]);
        wire([jf + [2, 12, -2], [jf[0] + 2, 16, 20], [52, 50, 16], [port(gA, 0, 1)[0], 80, 10], port(gA, 0, 1)], BLK);
    } else {
        wire([[jack_x - 2, tray_d - 13, jack_z + 2], [fuse_pos[0], fuse_pos[1] + 13, 8]]);
        wire([[jack_x + 2, tray_d - 13, jack_z - 2], [30, 81, 9], [port(gA, 0, 1)[0], 80, 9], port(gA, 0, 1)], BLK);
    }
    wire([[fuse_pos[0], fuse_pos[1] - 13, 8], [fuse_pos[0], 30, 12], [rk_x - 4, 24, panel_h / 2], [rk_x - 4, 21.5, panel_h / 2]]);
    wire([[rk_x + 4, 21.5, panel_h / 2], [rk_x + 4, 26, 16], [port(wA, 0, -1)[0], 17, 10], out_pt(port(wA, 0, -1), -1, 1, 7), port(wA, 0, -1)]);
    // panel LED: + from +12V port 1 (1 kΩ resistor in the lead), - to GND port 1
    lxl = led_x - tray_x0;
    wire([[lxl, 5, panel_h / 2], [lxl, 10, 14], [port(wA, 1, -1)[0], 15, 9], out_pt(port(wA, 1, -1), -1, 2, 6.5), port(wA, 1, -1)], RED, 1.2);
    color("tan") translate([lxl - 0.2, 7, panel_h / 2 - 3]) rotate([-90, 0, 0]) cylinder(d = 2.2, h = 6);  // resistor
    wire([[lxl + 1, 5, panel_h / 2 - 1], [32.5, 10, 14], [32.5, 79, 10],
          [port(gA, 1, 1)[0], 79, 8], out_pt(port(gA, 1, 1), 1, 2, 6.5), port(gA, 1, 1)], BLK, 1.2);
    // GS308 pigtail: port 2 on each Wago -> cable out the GS308 notch
    gx = 31;  // lane between the fuse holder and the Wagos
    wire([port(wA, 2, -1), out_pt(port(wA, 2, -1), -1, 5, 9), [gx, 17.5, 9], [gx, 80, 12], [gs308_x - 2, 84, 15]]);
    wire([port(gA, 2, 1), out_pt(port(gA, 2, 1), 1, 5, 10), [gs308_x - 2, 84, 15]], BLK);
    wire([[gs308_x - 2, 84, 15], [gs308_x, tray_d - wall_t - 1, wall_h - notch_depth + 2], [gs308_x, tray_d + 18, wall_h - notch_depth + 2]], CAB, cable_d);
    color([0.1, 0.1, 0.1]) translate([gs308_x, tray_d + 18, wall_h - notch_depth + 2]) rotate([-90, 0, 0]) cylinder(d = 8, h = 12);

    // Wago -> first buck of each row
    b1 = bucks[0]; b4 = bucks[3];
    wire([port(wA, 3, -1), [port(wA, 3, -1)[0], red_lane[0], 8], [lx(b1), red_lane[0], 8], [lx(b1), b1[1] - 4, 8], bin(b1, -1)]);
    wire([port(wA, 4, -1), [port(wA, 4, -1)[0], 15, 8], [82, 15, 8], [82, red_lane[1], 8], [lx(b4), red_lane[1], 8], [lx(b4), b4[1] - 4, 8], bin(b4, -1)]);
    wire([port(gA, 3, 1), [port(gA, 3, 1)[0], 80, 9], [77, 80, 9], [77, blk_lane[0], 9], [gxl(b1), blk_lane[0], 9], [gxl(b1), b1[1] + 4, 9], bin(b1, 1)], BLK);
    wire([port(gA, 4, 1), [port(gA, 4, 1)[0], blk_lane[1], 9], [gxl(b4), blk_lane[1], 9], [gxl(b4), b4[1] + 4, 9], bin(b4, 1)], BLK);

    for (i = [0 : 5]) {
        b = bucks[i]; front = i < 3; col = i % 3; row = front ? 0 : 1;
        // daisy-chain link from this buck's input pads to the next buck in the row
        if (col < 2) {
            n = bucks[i + 1];
            wire([bin(b, -1), [lx(b), b[1] - 4, 8], [lx(b), red_lane[row], 8], [lx(n), red_lane[row], 8], [lx(n), n[1] - 4, 8], bin(n, -1)]);
            wire([bin(b, 1), [gxl(b), b[1] + 4, 9], [gxl(b), blk_lane[row], 9], [gxl(n), blk_lane[row], 9], [gxl(n), n[1] + 4, 9], bin(n, 1)], BLK);
        }
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
    wago(wA, -1); wago(gA, 1);
    fuse_holder(); rocker_body(); jack_body(); panel_led();
    wiring();
}
