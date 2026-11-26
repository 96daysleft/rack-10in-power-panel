# rack-10in-power-panel

A 3D-printable 1U power panel for a 10" rack. It powers **3× Raspberry Pi 3B+** and a **Netgear GS308** switch from a single 12 V brick. The only mains wiring is the brick's own cord, outside the rack.

![Panel layout](docs/layout.svg)

## How it works

```
Brick 12V ──► rear DC jack ──► 5A fuse ──► front rocker ──► Wago (+12V / GND)
                                                             ├──► GS308 barrel pigtail (12 V)
                                                             ├──► Buck #1 ──► micro-USB ──► Pi 1
                                                             ├──► Buck #2 ──► micro-USB ──► Pi 2
                                                             └──► Buck #3 ──► micro-USB ──► Pi 3
```

There is one buck converter per Pi, so a fault on one Pi doesn't take down the others.

### Expansion module (Pi 4–6)

A second 1U panel can run off the same brick. Panel 1 taps 12 V after its fuse and rocker and sends it out through an **XT30** pigtail to the expansion panel:

```
Panel 1 Wago ──► 221-413 ──► XT30 link out ──► 18 AWG jumper (<30 cm) ──► XT30 in
                                                                          │
Panel 2: (optional rocker) ──► Wago 221-415 ──► Buck 4–6 ──► Pi 4–6 ◄─────┘
```

- **One 60 W brick handles 6 Pi 3B+ total.** A third panel needs its own brick, or upgrade to a 12 V 7.5 A brick with a 7.5 A fuse.
- The link uses XT30, **not** a 5.5×2.1 barrel. If the brick got plugged into a barrel output by mistake, power would feed in behind the fuse and switch.
- The expansion panel has no fuse of its own: panel 1's 5 A fuse protects the whole chain.
- The GS308 has 7 usable ports, so going past 7 Pis also means adding a second switch.

| Device | Input | Typical draw | Worst case |
|---|---|---|---|
| Pi 3B+ ×3 | 5.1 V micro-USB | ~2–3 W each | ~5–6 W each |
| GS308 | 12 V barrel | ~2–3 W | ~4 W |

### Six-buck panel (Pi 1–6 in one 1U)

All six Pis and the GS308 can also run from **one** panel instead of main + expansion. It has the main module's input (rear jack, 5 A fuse, rocker), no link-out, and the bucks in two rows of three:

```
Brick 12V ──► rear DC jack ──► 5A fuse ──► rocker ──► Wago 221-415 ══ jumper ══ Wago 221-415   (+12V; GND the same)
                                                        ├──► GS308         ├──► Buck 3–6 ──► Pi 3–6
                                                        └──► Buck 1–2 ──► Pi 1–2
```

- **Wagos:** each rail needs 8 connections (input, GS308, 6 bucks), and a 221-415 has only 5 ports. Use two 221-415s per rail joined by a short jumper, which leaves exactly 8 usable ports. The front pair of pockets is for +12 V, the rear pair for GND.
- **Load:** about 44 W worst case on the 60 W brick (about 3.7 A through the 5 A fuse). That's the same load as main + expansion.
- **Heat:** six bucks lose about 4–5 W in a closed 1U tray. Print in PETG rather than PLA.
- **Trade-off:** it's one print and no XT30 link, but there's no room to grow past 6 Pis without a second brick.

![Six-buck panel](docs/six-panel-preview.png)

Wired up, with stand-in parts (`cad/six-assembly.scad`, a preview only, not for printing). Red is +12 V, black is GND, grey cables are the micro-USB and GS308 pigtails:

![Six-buck panel, wired, from the rear](docs/six-assembly.png)

![Six-buck panel, wired, top view (front panel at the bottom)](docs/six-assembly-top.png)

- **Panel LED:** both 221-415 pairs are full, so the LED's + wire piggybacks on the rocker's output tab (1 kΩ resistor in the lead), and its − wire shares GND Wago A's jumper port in a twin ferrule. An illuminated 3-pin rocker avoids the extra wires entirely.

## Repo layout

| Path | What |
|---|---|
| [`cad/rack-power-panel.scad`](cad/rack-power-panel.scad) | Parametric OpenSCAD model (panel + tray). Main module by default. |
| [`cad/expansion-panel.scad`](cad/expansion-panel.scad) | Expansion module: includes the main model with `role = "expansion"` |
| [`cad/six-panel.scad`](cad/six-panel.scad) | Six-buck panel: all six Pis in one 1U (`role = "six"`) |
| [`cad/six-assembly.scad`](cad/six-assembly.scad) | Six-buck panel with stand-in parts and wiring (preview only) |
| [`cad/render.sh`](cad/render.sh) | Renders every variant to STL + PNG and fails on warnings or a non-manifold mesh |
| [`docs/layout.svg`](docs/layout.svg) | Front and top view with dimensions, drawn to scale |
| [`BOM.md`](BOM.md) | Bill of materials |

## Before printing

The model is parametric. Measure your parts and change the values at the top of the `.scad` file:

1. `ear_pitch` (236.5): your rack's hole spacing, center to center.
2. `buck_in` ([22, 20]): the pocket size for your buck module.
3. `jack_d` (12.2): use 8.2 for an M8-body DC jack.
4. `rocker` ([19.4, 13.1]): the cutout for your rocker switch.
5. `tray_w` (210): this must fit between your rack rails.

To export an STL:

```bash
openscad -o rack-power-panel.stl cad/rack-power-panel.scad
```

```bash
openscad -o expansion-panel.stl cad/expansion-panel.scad
```

```bash
openscad -o six-panel.stl cad/six-panel.scad
```

Or render all variants (STL + PNG preview) to `cad/out/` and check them:

```bash
cad/render.sh
```

It finds `openscad` on your PATH or an OpenSCAD AppImage in `~/AppImages` (or set `OPENSCAD=/path/to/openscad`). It fails if OpenSCAD reports a warning, an error or a non-manifold mesh.

All the files share every dimension, so a change in `rack-power-panel.scad` carries over to the other variants. To change just one variant, override the parameter in its wrapper file below the `include`. The six-buck layout has its own parameters (`buck6_x`, `buck6_y`, `wago6_pos`, `pi6_notch_x`).

The drawing in `docs/layout.svg` shows the main module before the link-out was added.

| | Main | Expansion | Six-buck |
|---|---|---|---|
| Input | 5.5×2.1 DC jack (rear wall) | XT30 pigtail through a rear notch | 5.5×2.1 DC jack (rear wall) |
| Fuse | 5 A inline, with tie-down | none | 5 A inline, with tie-down |
| Rocker | yes | optional (`expansion_rocker`) | yes |
| Bucks | 3, one row | 3, one row | 6, two rows of three |
| Wago | 221-415 + 221-413 | 221-415 | 4× 221-415 |
| Rear notches | link out, GS308, Pi ×3 | link in, Pi ×3 | GS308, Pi ×6 |
| Strain relief | zip slots at the link-out | zip slots at the link-in | none (no link) |

**Printing:** print with the tray floor on the bed and the front panel standing up, so nothing needs supports. PETG is preferred. If your parts differ from the defaults, print a thin test strip of the front panel first to check the rack holes and the switch cutout.

## Bring-up checklist

1. Power the 12 V bus with nothing connected and check polarity at each Wago output.
2. Measure each buck's output. It should read **5.1–5.2 V**.
3. Check that the GS308 pigtail is **center-positive**.
4. Connect the devices, boot, and run `vcgencmd get_throttled` on each Pi. `0x0` means no under-voltage.

## Status

All three variants render cleanly in OpenSCAD 2021.01 (no warnings, manifold meshes). Nothing has been test-printed yet, so expect to adjust the model after a test print.
