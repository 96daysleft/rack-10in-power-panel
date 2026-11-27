// 10-inch rack, 1U power panel for Raspberry Pi 3B+ nodes + Netgear GS308
//
// Two roles share this file (set `role`):
//
//   main      12 V brick -> rear DC jack -> 5 A fuse -> front rocker -> Wago 221-415 (+12 V / GND)
//               -> GS308 barrel pigtail (12 V)
//               -> 3x 12->5 V buck -> micro-USB pigtails -> Pi 1-3
//
//   six       All six Pis in one panel: same input (jack, fuse, rocker),
//               bucks in two rows of three, and 2x Wago 221-415 (+12 V / GND).
//               Each row's 12 V input is daisy-chained buck to buck from one
//               Wago port -> GS308 + 6x buck -> Pi 1-6
//
// six-panel.scad is a wrapper that includes this file with role = "six".
//
// Print with the tray floor on the bed (front panel stands up), PETG preferred.
// All dimensions in mm. Measure your actual parts and adjust the parameters.

$fn = 48;

/* [Module] */
role = "main"; // [main, six]

/* [Rack] */
panel_w   = 254;    // 10" front panel width
panel_h   = 44.0;   // 1U is 44.45; leave a little clearance
panel_t   = 4;
ear_pitch = 236.5;  // rack hole centre-to-centre (check your rack)
hole_z    = [6.1, 37.9];
slot_w    = 6.5;    // fits M6 / M5 rack screws
slot_l    = 10;

/* [Tray] */
tray_w  = 210;      // must fit between the rack rails (~222 mm on most 10" racks)
tray_d  = 90;
floor_t = 2.5;
wall_t  = 2.5;
wall_h  = 26;

/* [Front panel cutouts] (x from the panel's left edge) */
rocker     = [19.4, 13.1]; // KCD1-style snap-in rocker
rocker_x   = 45;
led_d      = 5.2;          // 5 mm LED (needs ~1k resistor at 12 V); 0 = omit
led_x      = 70;
vent_x0    = 110;
vent_x1    = 225;
vent_w     = 3;
vent_pitch = 7;
vent_h     = 26;

/* [DC input jack] */
jack_side    = "rear"; // [rear, front] rear wall, or front panel between the LED and the vents
jack_front_x = 90;     // front: centre, x from the panel's left edge

/* [Rear wall cutouts] (x from the tray's left edge) */
jack_d      = 12.2;   // panel-mount 5.5x2.1 jack, M12 body (8.2 for M8 type)
jack_x      = 20;
jack_z      = 13;     // centre height; leaves room for the nut above the floor
gs308_x     = 58;     // GS308 barrel pigtail notch
notch_w     = 7;
notch_depth = 12;     // open-top slots so pigtails drop in

/* [Pockets] (centres, tray coordinates) */
buck_in     = [22, 20];   // inner size: MEASURE your buck module
buck_x      = [95, 135, 175];
buck_y      = 35;
wago_in     = [20.6, 19]; // Wago 221-415 footprint
wago_pos    = [[48, 35], [48, 64]]; // main: front +12V, rear GND
pocket_h    = 5;
buck_standoff_h = 3;      // corner ledges lift each buck this far off the floor (pin + air clearance); 0 = off
buck_ledge  = 3;          // ledge size in each inner corner of a buck pocket
pocket_wall = 1.6;
zip_slot    = [4, 2];     // zip-tie slot through the floor
fuse_pos    = [20, 62];   // inline fuse holder tie-down

/* [Six-buck panel] (role = "six") */
buck6_x     = [105, 145, 185];   // columns, shifted right to make room for 4 Wagos
buck6_y     = [32, 68];          // two rows; zip slots between the rows stay clear
wago6_pos   = [[60, 32], [60, 64]]; // front +12V, rear GND
pi6_notch_x = [97, 113, 137, 153, 177, 193]; // one rear notch per Pi cable

is_six   = role == "six";
buck_pos = is_six ? [for (y = buck6_y, x = buck6_x) [x, y]] : [for (x = buck_x) [x, buck_y]];
wagos    = is_six ? wago6_pos : wago_pos;  // all 221-415
tray_x0  = (panel_w - tray_w) / 2;
notch_x  = concat([gs308_x], is_six ? pi6_notch_x : buck_x);

// ---------- front panel ----------
module panel_2d() {
    difference() {
        square([panel_w, panel_h]);
        // rack ear slots
        for (x = [(panel_w - ear_pitch) / 2, (panel_w + ear_pitch) / 2], z = hole_z)
            translate([x, z])
                hull() for (dx = [-(slot_l - slot_w) / 2, (slot_l - slot_w) / 2])
                    translate([dx, 0]) circle(d = slot_w);
        // rocker switch
        translate([rocker_x - rocker[0] / 2, panel_h / 2 - rocker[1] / 2]) square(rocker);
        // power LED
        if (led_d > 0) translate([led_x, panel_h / 2]) circle(d = led_d);
        // DC input jack (front option)
        if (jack_side == "front") translate([jack_front_x, panel_h / 2]) circle(d = jack_d);
        // vents
        for (x = [vent_x0 : vent_pitch : vent_x1 - vent_w])
            translate([x, (panel_h - vent_h) / 2]) square([vent_w, vent_h]);
    }
}

module front_panel() rotate([90, 0, 0]) linear_extrude(panel_t) panel_2d();

// ---------- tray parts ----------
// lift > 0 raises the walls by that much and adds a corner ledge the module sits on
module pocket(inner, lift = 0) {
    o = inner + [2, 2] * pocket_wall;
    h = pocket_h + lift;
    difference() {
        translate([-o[0] / 2, -o[1] / 2, 0]) cube([o[0], o[1], floor_t + h]);
        translate([-inner[0] / 2, -inner[1] / 2, floor_t]) cube([inner[0], inner[1], h + 1]);
        // wire openings on all four sides (leaves corner posts)
        translate([-(inner[0] - 6) / 2, -o[1] / 2 - 1, floor_t]) cube([inner[0] - 6, o[1] + 2, h + 1]);
        translate([-o[0] / 2 - 1, -(inner[1] - 6) / 2, floor_t]) cube([o[0] + 2, inner[1] - 6, h + 1]);
    }
    if (lift > 0)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (inner[0] / 2 - buck_ledge / 2) - buck_ledge / 2,
                       sy * (inner[1] / 2 - buck_ledge / 2) - buck_ledge / 2, floor_t - 0.01])
                cube([buck_ledge, buck_ledge, lift + 0.01]);
}

module zip_slot_cut(s = zip_slot)
    translate([-s[0] / 2, -s[1] / 2, -1]) cube([s[0], s[1], floor_t + 2]);

// pair of slots either side of a pocket (tie runs across the module)
module zip_pair(c, inner) {
    off = inner[1] / 2 + pocket_wall + 2.5;
    for (dy = [-off, off]) translate([c[0], c[1] + dy, 0]) zip_slot_cut();
}

module tray() {
    translate([tray_x0, -0.5, 0]) difference() {
        union() {
            cube([tray_w, tray_d, floor_t]);
            cube([wall_t, tray_d, wall_h]);                                     // left wall
            translate([tray_w - wall_t, 0, 0]) cube([wall_t, tray_d, wall_h]);  // right wall
            translate([0, tray_d - wall_t, 0]) cube([tray_w, wall_t, wall_h]);  // rear wall
            for (b = buck_pos) translate([b[0], b[1], 0]) pocket(buck_in, buck_standoff_h);
            for (w = wagos) translate([w[0], w[1], 0]) pocket(wago_in);
        }
        // cable exit notches (open from the top)
        for (x = notch_x)
            translate([x - notch_w / 2, tray_d - wall_t - 1, wall_h - notch_depth])
                cube([notch_w, wall_t + 2, notch_depth + 1]);
        // zip-tie slots
        for (b = buck_pos) zip_pair(b, buck_in);
        for (w = wagos) zip_pair(w, wago_in);
        // DC input jack in the rear wall (rear option)
        if (jack_side == "rear")
            translate([jack_x, tray_d + 1, jack_z]) rotate([90, 0, 0]) cylinder(d = jack_d, h = wall_t + 2);
        for (dy = [-6, 6]) translate([fuse_pos[0], fuse_pos[1] + dy, 0]) zip_slot_cut();
    }
}

front_panel();
tray();
