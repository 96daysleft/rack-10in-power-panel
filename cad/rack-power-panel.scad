// 10-inch rack, 1U power panel for Raspberry Pi 3B+ nodes + Netgear GS308
//
// Four roles share this file (set `role`):
//
//   main      12 V brick -> rear DC jack -> 5 A fuse -> front rocker -> Wago 221-415 + 221-413
//               -> GS308 barrel pigtail (12 V)
//               -> 3x 12->5 V buck -> micro-USB pigtails -> Pi 1-3
//               -> 12 V link out (XT30 pigtail) -> expansion module
//
//   expansion XT30 link in -> (optional rocker) -> Wago 221-415
//               -> 3x 12->5 V buck -> micro-USB pigtails -> Pi 4-6
//             No fuse: the main module's 5 A fuse protects the whole chain.
//             One 60 W brick is good for 6 Pi 3B+ total (main + one expansion).
//
//   six       All six Pis in one panel: main's input (jack, fuse, rocker), no link,
//               bucks in two rows of three, and 4x Wago 221-415 (two per rail,
//               joined by a short jumper) -> GS308 + 6x buck -> Pi 1-6
//
//   six-pcb   Six outputs on the assembled carrier board in pcb/ (six-carrier):
//               front-panel jack, rocker and LED wire into the board's screw
//               terminals; the tray has 4 standoffs instead of pockets
//
// expansion-panel.scad, six-panel.scad and six-pcb-panel.scad are wrappers that
// include this file with role = "expansion" / "six" / "six-pcb".
//
// Print with the tray floor on the bed (front panel stands up), PETG preferred.
// All dimensions in mm. Measure your actual parts and adjust the parameters.

$fn = 48;

/* [Module] */
role             = "main"; // [main, expansion, six, six-pcb]
expansion_rocker = true;   // expansion only: local on/off switch for its Pis

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

/* [DC input jack] (main and six) */
jack_side    = "rear"; // [rear, front] rear wall, or front panel between the LED and the vents
jack_front_x = 90;     // front: centre, x from the panel's left edge

/* [Rear wall cutouts] (x from the tray's left edge) */
jack_d      = 12.2;   // panel-mount 5.5x2.1 jack, M12 body (8.2 for M8 type)
jack_x      = 20;
jack_z      = 13;     // centre height; leaves room for the nut above the floor
link_x      = 40;     // main: 12 V link-out pigtail notch
gs308_x     = 58;     // main: GS308 barrel pigtail notch
in_x        = 20;     // expansion: 12 V link-in pigtail notch
notch_w     = 7;
notch_depth = 12;     // open-top slots so pigtails drop in

/* [Pockets] (centres, tray coordinates) */
buck_in     = [22, 20];   // inner size: MEASURE your buck module
buck_x      = [95, 135, 175];
buck_y      = 35;
wago_in     = [20.6, 19]; // Wago 221-415 footprint
wago_pos    = [48, 35];
wago2_in    = [14.2, 19]; // main: Wago 221-413 for the link-out tap
wago2_pos   = [48, 62];
pocket_h    = 5;
pocket_wall = 1.6;
zip_slot    = [4, 2];     // zip-tie slot through the floor
fuse_pos    = [20, 62];   // main: inline fuse holder tie-down
relief_y    = 80;         // strain-relief zip ties in front of link notches

/* [Six-buck panel] (role = "six") */
buck6_x     = [105, 145, 185];   // columns, shifted right to make room for 4 Wagos
buck6_y     = [32, 68];          // two rows; zip slots between the rows stay clear
wago6_pos   = [[46, 32], [72, 32], [46, 64], [72, 64]]; // front pair +12V, rear pair GND
pi6_notch_x = [97, 113, 137, 153, 177, 193]; // one rear notch per Pi cable (six and six-pcb)

/* [Six-output carrier board] (role = "six-pcb"; must match pcb/generate.py) */
pcb6_holes    = [[47, 5], [201, 5], [47, 83], [201, 83]]; // M3 holes, tray coordinates
standoff_h    = 6;    // clearance under the board for THT leads
standoff_d    = 7;
standoff_hole = 4.0;  // M3 heat-set insert (use 2.5 to self-tap an M3 screw)
vent_jack_gap = 4;    // keep vents this far from a front jack

is_main    = role == "main";
is_six     = role == "six";
is_six_pcb = role == "six-pcb";
has_input  = is_main || is_six || is_six_pcb;  // DC jack, rocker (and a fuse: loose or on the board)
buck_pos   = is_six ? [for (y = buck6_y, x = buck6_x) [x, y]]
           : is_six_pcb ? [] : [for (x = buck_x) [x, buck_y]];
wagos      = is_six ? wago6_pos : is_six_pcb ? [] : [wago_pos];  // all 221-415
tray_x0 = (panel_w - tray_w) / 2;
notch_x = is_main ? concat([link_x, gs308_x], buck_x)
        : is_six || is_six_pcb ? concat([gs308_x], pi6_notch_x)
        :           concat([in_x], buck_x);

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
        if (has_input || expansion_rocker)
            translate([rocker_x - rocker[0] / 2, panel_h / 2 - rocker[1] / 2]) square(rocker);
        // power LED
        if (led_d > 0) translate([led_x, panel_h / 2]) circle(d = led_d);
        // DC input jack (front option)
        if (has_input && jack_side == "front") translate([jack_front_x, panel_h / 2]) circle(d = jack_d);
        // vents
        front_jack = has_input && jack_side == "front";
        for (x = [vent_x0 : vent_pitch : vent_x1 - vent_w])
            if (!(front_jack && abs(x + vent_w / 2 - jack_front_x) < jack_d / 2 + vent_w / 2 + vent_jack_gap))
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

module zip_slot_cut(s = zip_slot)
    translate([-s[0] / 2, -s[1] / 2, -1]) cube([s[0], s[1], floor_t + 2]);

// pair of slots either side of a pocket (tie runs across the module)
module zip_pair(c, inner) {
    off = inner[1] / 2 + pocket_wall + 2.5;
    for (dy = [-off, off]) translate([c[0], c[1] + dy, 0]) zip_slot_cut();
}

// pair of slots either side of a cable running front-to-back (strain relief)
module relief_pair(x)
    for (dx = [-5, 5]) translate([x + dx, relief_y, 0]) zip_slot_cut([zip_slot[1], zip_slot[0]]);

module tray() {
    translate([tray_x0, -0.5, 0]) difference() {
        union() {
            cube([tray_w, tray_d, floor_t]);
            cube([wall_t, tray_d, wall_h]);                                     // left wall
            translate([tray_w - wall_t, 0, 0]) cube([wall_t, tray_d, wall_h]);  // right wall
            translate([0, tray_d - wall_t, 0]) cube([tray_w, wall_t, wall_h]);  // rear wall
            for (b = buck_pos) translate([b[0], b[1], 0]) pocket(buck_in);
            for (w = wagos) translate([w[0], w[1], 0]) pocket(wago_in);
            if (is_main) translate([wago2_pos[0], wago2_pos[1], 0]) pocket(wago2_in);
            if (is_six_pcb) for (h = pcb6_holes) translate([h[0], h[1], 0]) cylinder(d = standoff_d, h = floor_t + standoff_h);
        }
        if (is_six_pcb)  // heat-set insert holes (blind, from the top)
            for (h = pcb6_holes) translate([h[0], h[1], 1]) cylinder(d = standoff_hole, h = floor_t + standoff_h);
        // cable exit notches (open from the top)
        for (x = notch_x)
            translate([x - notch_w / 2, tray_d - wall_t - 1, wall_h - notch_depth])
                cube([notch_w, wall_t + 2, notch_depth + 1]);
        // zip-tie slots
        for (b = buck_pos) zip_pair(b, buck_in);
        for (w = wagos) zip_pair(w, wago_in);
        if (has_input) {
            // DC input jack in the rear wall (rear option)
            if (jack_side == "rear")
                translate([jack_x, tray_d + 1, jack_z]) rotate([90, 0, 0]) cylinder(d = jack_d, h = wall_t + 2);
            if (!is_six_pcb)  // inline fuse tie-down (the carrier board has its own fuse)
                for (dy = [-6, 6]) translate([fuse_pos[0], fuse_pos[1] + dy, 0]) zip_slot_cut();
        }
        if (is_main) {
            zip_pair(wago2_pos, wago2_in);
            relief_pair(link_x);
        } else if (!is_six && !is_six_pcb) {
            relief_pair(in_x);
        }
    }
}

front_panel();
tray();
