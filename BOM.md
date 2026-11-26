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

## Carrier PCB (replaces Wago, fuse holder and loose wiring)

References match `pcb/carrier.kicad_sch`. **M** = fit on a main board, **E** = fit on an expansion board.

| Ref | Qty | Part | Footprint | M | E |
|---|---|---|---|---|---|
| — | 1 | PCB 160 × 70 mm, 2-layer, 2 oz copper (Gerbers from `pcb/build.sh`) | — | ✓ | ✓ |
| J1 | 1 | CUI PJ-063AH 5.5×2.1 barrel jack | THT | ✓ | |
| Q1 | 1 | AOD4185 P-channel MOSFET, 40 V | TO-252 (DPAK) | ✓ | |
| R1 | 1 | 10 kΩ | 0805 | ✓ | |
| D2 | 1 | MMSZ5245B 15 V zener | SOD-123 | ✓ | |
| F1 | 1 | Keystone 3568 mini blade fuse holder + 5 A mini blade fuse | THT | ✓ | |
| D1 | 1 | SMBJ15CA TVS diode | SMB | ✓ | ✓ |
| C1 | 1 | 470 µF 25 V electrolytic, 10 mm | THT | ✓ | ✓ |
| J2 | 1 | JST-VH B2P-VH header (rocker lead); bridge it if there's no rocker | THT | ✓ | opt |
| J3 | 1 | AMASS XT30PW-F (right-angle female) | THT | ✓ | ✓ (input) |
| J4 | 1 | Phoenix MKDS 1,5/2-5,08 screw terminal (GS308) | THT | ✓ | |
| J5–J7 | 3 | Phoenix MKDS 1,5/2-5,08 screw terminal (Pi 5 V) | THT | ✓ | ✓ |
| J10–J15 | — | Wire pads for buck IN/OUT (no part) | — | | |
| R2–R4 | 3 | 1 kΩ | 0805 | ✓ | ✓ |
| D3–D5 | 3 | Green LED | 0805 | ✓ | ✓ |
| — | 3 | Buck modules (same as above) | — | ✓ | ✓ |
| — | 4 | M3 × 6 screws + M3 heat-set inserts (tray standoffs) | — | ✓ | ✓ |

The PCB build drops the Wago connectors, the inline fuse holder and the panel-mount DC jack from the hand-wired list. **Rough cost:** about $15–25 in parts per board plus ~$10–20 for 5 PCBs (+ shipping).
