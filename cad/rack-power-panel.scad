// 10-inch rack, 1U power panel: 3x Raspberry Pi 3B+ + Netgear GS308
//
// Power path:
//   12 V brick -> rear DC jack -> inline 5 A fuse -> front rocker -> Wago 221
//     -> GS308 barrel pigtail (12 V)
//     -> 3x 12->5 V buck (one per Pi) -> micro-USB pigtails
//
// Print with the tray floor on the bed (front panel stands up), PETG preferred.
// All dimensions in mm. Measure your actual parts and adjust the parameters.

$fn = 48;

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

/* [Rear wall cutouts] (x from the tray's left edge) */
jack_d      = 12.2;   // panel-mount 5.5x2.1 jack, M12 body (8.2 for M8 type)
jack_x      = 20;
jack_z      = 13;     // centre height; leaves room for the nut above the floor
notch_x     = [58, 95, 135, 175]; // GS308 lead, Pi 1, Pi 2, Pi 3
notch_w     = 7;
notch_depth = 12;     // open-top slots so pigtails drop in

/* [Pockets] (centres, tray coordinates) */
buck_in     = [22, 20];   // inner size: MEASURE your buck module
buck_x      = [95, 135, 175];
buck_y      = 35;
wago_in     = [20.6, 19]; // Wago 221-415 footprint
wago_pos    = [48, 35];
pocket_h    = 5;
pocket_wall = 1.6;
zip_slot    = [4, 2];     // zip-tie slot through the floor
fuse_pos    = [20, 62];   // inline fuse holder tie-down

tray_x0 = (panel_w - tray_w) / 2;

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
        // vents
        for (x = [vent_x0 : vent_pitch : vent_x1 - vent_w])
            translate([x, (panel_h - vent_h) / 2]) square([vent_w, vent_h]);
    }
}

module front_panel() rotate([90, 0, 0]) linear_extrude(panel_t) panel_2d();

// ---------- tray parts ----------
module pocket(inner) {
    o = inner + [2, 2] * pocket_wall;
    difference() {
        translate([-o[0] / 2, -o[1] / 2, 0]) cube([o[0], o[1], floor_t + pocket_h]);
        translate([-inner[0] / 2, -inner[1] / 2, floor_t]) cube([inner[0], inner[1], pocket_h + 1]);
        // wire openings on all four sides (leaves corner posts)
        translate([-(inner[0] - 6) / 2, -o[1] / 2 - 1, floor_t]) cube([inner[0] - 6, o[1] + 2, pocket_h + 1]);
        translate([-o[0] / 2 - 1, -(inner[1] - 6) / 2, floor_t]) cube([o[0] + 2, inner[1] - 6, pocket_h + 1]);
    }
}

module zip_slot_cut()
    translate([-zip_slot[0] / 2, -zip_slot[1] / 2, -1]) cube([zip_slot[0], zip_slot[1], floor_t + 2]);

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
            for (x = buck_x) translate([x, buck_y, 0]) pocket(buck_in);
            translate([wago_pos[0], wago_pos[1], 0]) pocket(wago_in);
        }
        // rear DC input jack
        translate([jack_x, tray_d + 1, jack_z]) rotate([90, 0, 0]) cylinder(d = jack_d, h = wall_t + 2);
        // cable exit notches
        for (x = notch_x)
            translate([x - notch_w / 2, tray_d - wall_t - 1, wall_h - notch_depth])
                cube([notch_w, wall_t + 2, notch_depth + 1]);
        // zip-tie slots
        for (x = buck_x) zip_pair([x, buck_y], buck_in);
        zip_pair(wago_pos, wago_in);
        for (dy = [-6, 6]) translate([fuse_pos[0], fuse_pos[1] + dy, 0]) zip_slot_cut();
    }
}

front_panel();
tray();
