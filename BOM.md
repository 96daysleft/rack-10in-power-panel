# Bill of materials

Prices are rough USD estimates (late 2026) and vary by vendor.

## Power

| Qty | Part | Example | Notes | ~Cost |
|---|---|---|---|---|
| 1 | 12 V 5 A (60 W) power brick, 5.5×2.1 mm plug | Mean Well GST60A12-P1J | About 2–3× the real load, so it runs cool. Avoid no-name bricks. | $20–25 |
| 3 (buy 4–5) | 12 V→5 V buck converter | **Mini560, fixed 5 V output, "5 A"** | One per Pi. Get the fixed 5 V version, not adjustable, and check that the listing's input range covers 12 V. Buy from a well-reviewed seller and get spares. Expect about 3 A continuous in the closed tray, against a Pi 3B+'s ~1–1.2 A at full CPU and ~2.5 A peak with USB devices. Fits the 22 × 20 mm pocket; measure yours. | $5–10 total |

**Buck converter notes**

- **Check every module before it touches a Pi.** On 12 V with no load, the output should read 5.0–5.2 V. After bring-up, `vcgencmd get_throttled` on each Pi should return `0x0`.
- **Premium alternative:** Pololu D36V28F5 (5 V, about 3.2 A) or D24V30F5 (5 V, 3 A). Genuine parts with real ratings and built-in protection, about $10–15 each. Check the board size against `buck_in` before ordering.
- **Not recommended:**
  - **MP1584 boards:** small and efficient, but only about 1.5–2 A of real headroom, and usually an adjustable trim pot that can drift.
  - **LM2596 boards:** about 75–80 % efficient, so they run hot in 1U. They're too big for the pocket, often carry clone chips, and use a trim pot.
- **If you use any adjustable buck,** set it to 5.15–5.2 V before connecting a Pi, then lock the pot with a dab of nail polish.

## Connectors and wiring

| Qty | Part | Notes | ~Cost |
|---|---|---|---|
| 1 | Panel-mount female 5.5×2.1 mm DC jack, M12 body | Rear wall on the main panel, front panel on the six-buck panel. Use `jack_d = 8.2` in the model for the M8 type. | $2 |
| 1 | Male 5.5×2.1 mm barrel pigtail | Powers the GS308. Check that your adapter is 5.5×2.1 and center-positive. | $2 |
| 3 | Micro-USB male power pigtails, 20 AWG preferred | Keep them 10–15 cm long. | $5 |
| 1 | Inline blade fuse holder + 5 A fuse | Goes right after the DC jack. | $3 |
| 1 | KCD1-style snap-in rocker switch, rated ≥5 A at 12 V DC | Front panel cutout is 19.4 × 13.1 mm. | $1 |
| 1 | 5 mm LED + ~1 kΩ resistor (optional) | Power indicator, run off 12 V. | $1 |
| 2 | Wago 221-415 (5-port) lever connector | One for +12 V and one for GND. Each uses all 5 ports: input, GS308 and 3 bucks. | $6 |
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

**Estimated total (main module):** about $45–60 plus filament.

## Six-buck panel (Pi 1–6 in one panel)

Start from the main module list above, then change these:

| Change | Part | Notes | ~Cost |
|---|---|---|---|
| 3 → 6 (buy 8–10) | Mini560, fixed 5 V | One per Pi, same as the main module. Buy spares. | +$5–10 |
| 3 → 6 | Micro-USB male power pigtails | 10–15 cm, 20 AWG preferred | +$5 |
| 8 (+ spares) | 16–14 AWG nylon closed-end crimp caps | Daisy-chain splices: 3× 18 AWG each, 4 per row. Check that the pack's combination chart covers 3×18, and test-crimp one first. Or solder + adhesive-lined heat-shrink. Needs a crimper with a closed-end die. | +$5 |
| — | Printed panel + tray (`cad/six-panel.scad`) | PETG recommended (six bucks in one tray) | — |

**Estimated total (six-buck panel):** about $60–85 plus filament.
