# Bill of materials

Prices are rough USD estimates (late 2026) and vary by vendor.

## Power

| Qty | Part | Example | Notes | ~Cost |
|---|---|---|---|---|
| 1 | 12 V 5 A (60 W) power brick, 5.5×2.1 mm plug | Mean Well GST60A12-P1J | About 2–3× the real load, so it runs cool. Avoid no-name bricks. | $20–25 |
| 3 | 12 V→5 V buck converter, ≥3 A continuous | Mini560 (5 V 5 A) or Pololu D24V30F5 (5 V 3 A) | One per Pi. Avoid LM2596 boards. If you use an adjustable buck, set it to 5.15–5.2 V before connecting a Pi. | $3–15 total |

## Connectors and wiring

| Qty | Part | Notes | ~Cost |
|---|---|---|---|
| 1 | Panel-mount female 5.5×2.1 mm DC jack, M12 body | Goes in the rear wall. Use `jack_d = 8.2` in the model for the M8 type. | $2 |
| 1 | Male 5.5×2.1 mm barrel pigtail | Powers the GS308. Check that your adapter is 5.5×2.1 and center-positive. | $2 |
| 3 | Micro-USB male power pigtails, 20 AWG preferred | Keep them 10–15 cm long. | $5 |
| 1 | Inline blade fuse holder + 5 A fuse | Goes right after the DC jack. | $3 |
| 1 | KCD1-style snap-in rocker switch, rated ≥5 A at 12 V DC | Front panel cutout is 19.4 × 13.1 mm. | $1 |
| 1 | 5 mm LED + ~1 kΩ resistor (optional) | Power indicator, run off 12 V. | $1 |
| 1 | Wago 221-415 (5-port) lever connector | 12 V distribution. A matching GND connector is also needed (a second 221-415 or a 221-413). | $3 |
| — | 18 AWG red/black wire | For the 12 V bus. | $5 |
| — | Heat-shrink, small zip ties (≤4 mm wide), optional ferrules | | $5 |

## Mounting

| Qty | Part | Notes |
|---|---|---|
| 1 | Printed panel + tray (`cad/rack-power-panel.scad`) | PETG preferred, PLA is OK. About 60–80 g of filament. |
| 4 | Rack screws + cage nuts (M6 or M5) | Whatever your 10" rack uses. |

## Tools

- A multimeter (required, for checking polarity and buck output voltage)
- A soldering iron
- Wire strippers, and crimpers if you use ferrules

**Estimated total (main module):** about $40–55 plus filament.

## Main module additions for the link-out

| Qty | Part | Notes | ~Cost |
|---|---|---|---|
| 1 | Wago 221-413 (3-port) | +12 V tap for the link-out. A matching GND connector is also needed. | $2 |
| 1 | XT30 female pigtail, 18 AWG | Link out, through the rear notch with zip-tie strain relief | $2 |

## Expansion module (Pi 4–6, same brick)

| Qty | Part | Notes | ~Cost |
|---|---|---|---|
| 3 | 12 V→5 V buck converter, ≥3 A | Same as the main module | $3–15 total |
| 3 | Micro-USB male power pigtails | 10–15 cm | $5 |
| 1 | XT30 male pigtail, 18 AWG | Link in | $2 |
| 1 | 18 AWG jumper, under 30 cm, XT30 on both ends | Panel 1 to panel 2. Or join the two pigtails directly. | $2 |
| 2 | Wago 221-415 | One each for +12 V and GND | $5 |
| 1 | KCD1 rocker switch (optional) | Local on/off for Pi 4–6 | $1 |
| 1 | Printed panel + tray (`cad/expansion-panel.scad`) | | — |
| 4 | Rack screws + cage nuts | | — |

No brick and no fuse: the expansion panel runs from the main module's brick and 5 A fuse. **One 60 W brick handles 6 Pi 3B+ total.**

**Estimated total (expansion):** about $20–30 plus filament.

## Six-buck panel (Pi 1–6 in one panel, instead of main + expansion)

Start from the main module list above, then change these:

| Change | Part | Notes | ~Cost |
|---|---|---|---|
| 3 → 6 | 12 V→5 V buck converter, ≥3 A | One per Pi | +$3–15 |
| 3 → 6 | Micro-USB male power pigtails | 10–15 cm, 20 AWG preferred | +$5 |
| 2 → 4 | Wago 221-415 | Two per rail (+12 V and GND), each pair joined by a short 18 AWG jumper | +$5 |
| drop | Wago 221-413 and XT30 pigtail | No link-out | −$4 |
| — | Printed panel + tray (`cad/six-panel.scad`) | PETG recommended (six bucks in one tray) | — |

**Estimated total (six-buck panel):** about $55–75 plus filament. That's less than main + expansion, which need a second print, an XT30 link and more Wagos.

## Six-output carrier PCB (fully assembled; replaces the bucks, Wagos and internal wiring)

References match `pcb/six-carrier.kicad_sch`. `pcb/build.sh` also writes this list as `pcb/out/six-carrier-bom.csv` for the assembly quote.

| Ref | Qty | Part | Footprint |
|---|---|---|---|
| — | 1 | PCB 160 × 84 mm, 2-layer, 2 oz copper | — |
| U1–U6 | 6 | RECOM R-78B5.0-2.0 (5 V 2 A switching regulator) | SIP-3 THT |
| C1–C6 | 6 | 10 µF 25 V X7R (e.g. Murata GRM31CR71E106KA12L) | 1206 |
| C7–C12 | 6 | 22 µF 10 V X5R (e.g. Murata GRM31CR61A226KE19L) | 1206 |
| R1 | 1 | 2.2 kΩ (panel LED) | 0805 |
| R2–R7 | 6 | 1 kΩ (status LEDs) | 0805 |
| D1–D6 | 6 | Green LED | 0805 |
| F1 | 1 | Keystone 3568 mini blade fuse holder + 5 A mini blade fuse | THT |
| J1–J10 | 10 | Phoenix Contact 1715721 (MKDS 1,5/2-5,08) screw terminal | THT |

**Off-board:** a pre-wired 5.5×2.1 panel-mount jack (front panel), the rocker with 2 leads, a 5 mm LED with 2 leads, the GS308 barrel pigtail, six micro-USB pigtails, 4 × M3 × 6 screws and 4 × M3 heat-set inserts for the standoffs, and the printed panel + tray (`cad/six-pcb-panel.scad`).

**Rough cost:** about $60–90 in parts per board (the six R-78Bs are most of it) plus PCBWay's board and assembly charges. Get their quote for a run of 5.
