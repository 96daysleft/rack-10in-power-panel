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

## Single-Pi power board (optional; replaces one bare buck module)

One board per Pi. References match `pcb/pi-power.kicad_sch`; `pcb/build.sh` also writes this as `pcb/out/pi-power-bom.csv` for the assembly quote.

| Ref | Qty per board | Part | Footprint |
|---|---|---|---|
| — | 1 | PCB 40 × 23 mm, 2-layer, 1 oz copper is fine | — |
| U1 | 1 | RECOM R-78B5.0-2.0 (5 V 2 A switching regulator) | SIP-3 THT |
| C1 | 1 | 10 µF 25 V X7R (e.g. Murata GRM31CR71E106KA12L) | 1206 |
| C2 | 1 | 22 µF 10 V X5R (e.g. Murata GRM31CR61A226KE19L) | 1206 |
| R1 | 1 | 1 kΩ | 0805 |
| D1 | 1 | Green LED | 0805 |
| J1, J2 | 2 | Phoenix Contact 1715721 (MKDS 1,5/2-5,08) screw terminal | THT |

**Rough cost:** about $10–15 in parts per board (the R-78B is most of it) plus PCBWay's board and assembly charges for a run of 5.
