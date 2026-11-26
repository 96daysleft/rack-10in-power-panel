#!/usr/bin/env python3
"""Generate the rack power carrier board (schematic + PCB) from one netlist.

Single source of truth: PARTS (symbol, footprint, placement) and NETS below.
Writes carrier.kicad_sch, carrier.kicad_pcb and carrier.kicad_pro next to this file.

Run via build.sh (it clears the desktop app's library paths and runs ERC/DRC).
Requires KiCad 8+ (uses the pcbnew Python module and the stock KiCad libraries).
"""
import json
import math
import os
import uuid

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
NAME = "carrier"
SYM_DIR = os.environ.get("KICAD_SYMBOL_DIR", "/usr/share/kicad/symbols")
FP_DIR = os.environ.get("KICAD_FOOTPRINT_DIR", "/usr/share/kicad/footprints")

# Board outline (KiCad page coords, mm). Front edge (toward panel) is y = 100.
BX0, BY0, BW, BH = 100.0, 100.0, 160.0, 70.0
BUCK_X = [185.0, 210.0, 235.0]  # left pad x of each buck slot column

# --------------------------------------------------------------------------
# Parts: ref -> (symbol, value, footprint, (x, y, rot_deg), schematic (x, y))
# --------------------------------------------------------------------------
PARTS = {
    "J1": ("Connector:Barrel_Jack", "12V IN 5.5x2.1", "Connector_BarrelJack:BarrelJack_CUI_PJ-063AH_Horizontal", (115, 158, 0), (40, 60)),
    "Q1": ("Device:Q_PMOS_GDS", "AOD4185 (P-ch 40V, rev. polarity)", "Package_TO_SOT_SMD:TO-252-2", (125, 146, 0), (80, 55)),
    "R1": ("Device:R", "10k", "Resistor_SMD:R_0805_2012Metric", (122, 140, 0), (70, 80)),
    "D2": ("Device:D_Zener", "MMSZ5245B 15V", "Diode_SMD:D_SOD-123", (116, 144, 0), (95, 80)),
    "F1": ("Device:Fuse", "5A mini blade", "Fuse:Fuseholder_Blade_Mini_Keystone_3568", (106, 128, 0), (125, 55)),
    "D1": ("Device:D_TVS", "SMBJ15CA", "Diode_SMD:D_SMB", (124, 124, 0), (150, 70)),
    "C1": ("Device:C_Polarized", "470uF 25V", "Capacitor_THT:CP_Radial_D10.0mm_P5.00mm", (130, 132, 0), (170, 70)),
    "J2": ("Connector_Generic:Conn_01x02", "ROCKER (bridge if none)", "Connector_JST:JST_VH_B2P-VH_1x02_P3.96mm_Vertical", (140, 108, 0), (200, 55)),
    "J3": ("Connector_Generic:Conn_01x02", "XT30 LINK", "Connector_AMASS:AMASS_XT30PW-F_1x02_P2.50mm_Horizontal", (150, 155, 180), (240, 40)),
    "J4": ("Connector_Generic:Conn_01x02", "GS308 12V", "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal", (160, 162, 0), (240, 70)),
    "H1": ("Mechanical:MountingHole", "M3", "MountingHole:MountingHole_3.2mm_M3", (104, 104, 0), (40, 160)),
    "H2": ("Mechanical:MountingHole", "M3", "MountingHole:MountingHole_3.2mm_M3", (256, 104, 0), (55, 160)),
    "H3": ("Mechanical:MountingHole", "M3", "MountingHole:MountingHole_3.2mm_M3", (104, 166, 0), (70, 160)),
    "H4": ("Mechanical:MountingHole", "M3", "MountingHole:MountingHole_3.2mm_M3", (256, 166, 0), (85, 160)),
    # Front-panel power LED (follows the rocker: fed from the switched +12V)
    "R5": ("Device:R", "2k2", "Resistor_SMD:R_0805_2012Metric", (152, 108, 0), (180, 80)),
    "J8": ("Connector_Generic:Conn_01x02", "PANEL LED (1=A 2=K)", "Connector_JST:JST_PH_B2B-PH-K_1x02_P2.00mm_Vertical", (158.5, 108, 0), (200, 80)),
    # Optional 3-channel current monitor; the 10 mOhm shunts are always fitted
    "U1": ("Power_Management:INA3221", "INA3221 (optional)", "Package_DFN_QFN:Texas_RGV0016A_VQFN-16-1EP_4x4mm_P0.65mm_EP2.1x2.1mm", (210, 107, 180), (235, 150)),
    "C2": ("Device:C", "100nF (optional)", "Capacitor_SMD:C_0805_2012Metric", (216, 104, 0), (210, 165)),
    "J9": ("Connector_Generic:Conn_01x04", "I2C GND/3V3/SDA/SCL (optional)", "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical", (232, 104, 270), (270, 150)),
    "#FLG01": ("power:PWR_FLAG", "PWR_FLAG", None, None, (110, 175)),
    "#FLG02": ("power:PWR_FLAG", "PWR_FLAG", None, None, (125, 175)),
}
OPTIONAL = {"U1", "C2", "J9"}  # marked DNP in the BOM/schematic; fit for current monitoring
NETS = {
    "VIN": [("J1", "1"), ("Q1", "2")],
    "VREV": [("Q1", "3"), ("F1", "1"), ("D2", "1")],
    "GATE": [("Q1", "1"), ("R1", "1"), ("D2", "2")],
    "+12V_F": [("F1", "2"), ("D1", "1"), ("C1", "1"), ("J2", "1")],
    "+12V": [("J2", "2"), ("J3", "2"), ("J4", "1"), ("R5", "1")],
    "PANEL_LED": [("R5", "2"), ("J8", "1")],
    "+3V3_I2C": [("U1", "4"), ("U1", "16"), ("C2", "1"), ("J9", "2"), ("#FLG02", "1")],
    "SDA": [("U1", "7"), ("J9", "3")],
    "SCL": [("U1", "6"), ("J9", "4")],
    "GND": [("J1", "2"), ("R1", "2"), ("D1", "2"), ("C1", "2"), ("J3", "1"), ("J4", "2"), ("J8", "2"),
            ("U1", "3"), ("U1", "5"), ("U1", "17"), ("C2", "2"), ("J9", "1"), ("#FLG01", "1")],
}
NO_CONNECT = [("U1", "8"), ("U1", "9"), ("U1", "10"), ("U1", "13")]  # WARNING, CRITICAL, PV, TC
INA_IN = {1: ("12", "11"), 2: ("15", "14"), 3: ("2", "1")}  # channel -> (IN+, IN-) pin numbers
# Three identical buck slots: IN pads, OUT pads, shunt, output terminal, LED + resistor.
for i, x in enumerate(BUCK_X):
    n = i + 1
    jin, jout, jterm = f"J{10 + 2 * i}", f"J{11 + 2 * i}", f"J{5 + i}"
    r, d, rs = f"R{2 + i}", f"D{3 + i}", f"R{6 + i}"
    sx = 40 + 60 * i
    PARTS[jin] = ("Connector_Generic:Conn_01x02", f"BUCK{n} IN", "Connector_Wire:SolderWire-0.5sqmm_1x02_P4.6mm_D0.9mm_OD2.1mm", (x, 120, 0), (sx, 110))
    PARTS[jout] = ("Connector_Generic:Conn_01x02", f"BUCK{n} OUT", "Connector_Wire:SolderWire-0.5sqmm_1x02_P4.6mm_D0.9mm_OD2.1mm", (x, 144, 0), (sx + 15, 110))
    PARTS[jterm] = ("Connector_Generic:Conn_01x02", f"PI{n} 5V", "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal", (x, 162, 0), (sx + 30, 110))
    PARTS[rs] = ("Device:R", "10mR 1W shunt", "Resistor_SMD:R_2512_6332Metric", (x, 150, 90), (sx + 45, 110))
    PARTS[r] = ("Device:R", "1k", "Resistor_SMD:R_0805_2012Metric", (x + 8, 155, 0), (sx + 10, 135))
    PARTS[d] = ("Device:LED", "green", "LED_SMD:LED_0805_2012Metric", (x + 12, 155, 180), (sx + 25, 135))
    ip, im = INA_IN[n]
    NETS["+12V"].append((jin, "1"))
    NETS[f"BUCK{n}_OUT"] = [(jout, "1"), (rs, "2"), ("U1", ip)]
    NETS[f"+5V_PI{n}"] = [(rs, "1"), (jterm, "1"), (r, "1"), ("U1", im)]
    NETS[f"LED{n}"] = [(r, "2"), (d, "2")]
    NETS["GND"] += [(jin, "2"), (jout, "2"), (jterm, "2"), (d, "1")]

# --------------------------------------------------------------------------
# Routing (F.Cu). Each route: (net, width_mm, [points]); a point is (x, y),
# ("pad", ref, number) or ("via", x, y). Pads resolve to the nearest pad with
# that number. GND is a B.Cu pour; SMD GND pads drop to it through vias.
# --------------------------------------------------------------------------
W12, W5, WS, WSN = 2.5, 1.5, 0.5, 0.25
ROUTES = [
    ("VIN", W12, [("pad", "J1", "1"), (128, 158), ("pad", "Q1", "2")]),
    ("VREV", W12, [("pad", "Q1", "3"), (106, 148.28), ("pad", "F1", "1")]),
    ("VREV", WS, [("pad", "D2", "1"), (114.35, 148.28)]),
    ("VREV", W12, [(106, 128), (106, 131.4)]),          # fuse clip: join its two pads
    ("+12V_F", W12, [(115.92, 128), (115.92, 131.4)]),  # fuse clip: join its two pads
    ("GATE", WS, [("pad", "Q1", "1"), (117.65, 143.72), ("pad", "D2", "2")]),
    ("GATE", WS, [("pad", "Q1", "1"), (119.96, 140), ("pad", "R1", "1")]),
    ("GND", WS, [("pad", "R1", "2"), ("via", 124.6, 140)]),
    ("+12V_F", W12, [("pad", "F1", "2"), (115.92, 120), (121.85, 120), (130, 120), (140, 120), ("pad", "J2", "1")]),
    ("+12V_F", W12, [("pad", "D1", "1"), (121.85, 120)]),
    ("+12V_F", W12, [("pad", "C1", "1"), (130, 120)]),
    ("GND", 1.0, [("pad", "D1", "2"), ("via", 126.15, 127)]),
    ("+12V", W12, [("pad", "J2", "2"), (143.96, 114), (145, 114), (151.05, 114), (160, 114)] + [(x, 114) for x in BUCK_X]),
    ("+12V", WS, [(151.05, 114), ("pad", "R5", "1")]),
    ("PANEL_LED", WS, [("pad", "R5", "2"), ("pad", "J8", "1")]),
    ("+12V", W12, [(145, 114), ("pad", "J3", "2")]),  # XT30 pad 2 is + per the AMASS silk
    ("+12V", W12, [(160, 114), ("pad", "J4", "1")]),
]
# INA3221 (U1 at 210,107 rotated 180): pins 11/12 face channel 1 (left),
# 14/15 face channel 2 (down, across the 12 V bus via B.Cu), 1/2 face channel 3 (right).
ROUTES += [
    # channel 1 sense pair: B.Cu from the shunt vias, F.Cu into pins 12 (IN+1) / 11 (IN-1)
    ("BUCK1_OUT", WSN, [(181.5, 147.037), (181.5, 107.975), ("via", 202.5, 107.975)], "B"),
    ("BUCK1_OUT", WSN, [(202.5, 107.975), ("pad", "U1", "12")]),
    ("+5V_PI1", WSN, [(179.5, 152.963), (179.5, 107.325), ("via", 204.5, 107.325)], "B"),
    ("+5V_PI1", WSN, [(204.5, 107.325), ("pad", "U1", "11")]),
    # channel 2: pins 15 (IN+2) / 14 (IN-2) drop to vias just below the chip
    ("BUCK2_OUT", WSN, [("pad", "U1", "15"), (210.325, 109.7), ("via", 211.0, 110.4)]),
    ("BUCK2_OUT", WSN, [(211.0, 110.4), (211.0, 111.4), (206.5, 111.4), (206.5, 147.037)], "B"),
    ("+5V_PI2", WSN, [("pad", "U1", "14"), (209.675, 109.7), ("via", 209.0, 110.4)]),
    ("+5V_PI2", WSN, [(209.0, 110.4), (204.5, 110.4), (204.5, 152.963)], "B"),
    # channel 3: pins 2 (IN+3) / 1 (IN-3) run right on F.Cu, then B.Cu down to the shunt
    ("BUCK3_OUT", WSN, [("pad", "U1", "2"), ("via", 217.5, 107.325)]),
    ("BUCK3_OUT", WSN, [(217.5, 107.325), (231.5, 107.325), (231.5, 147.037)], "B"),
    ("+5V_PI3", WSN, [("pad", "U1", "1"), ("via", 219.5, 107.975)]),
    ("+5V_PI3", WSN, [(219.5, 107.975), (229.5, 107.975), (229.5, 152.963)], "B"),
    # supply, address and ground
    ("GND", WSN, [("pad", "U1", "3"), (210.6, 106.675)]),                    # GND pin -> exposed pad
    # exposed pad -> B.Cu ground pour (0.3 mm holes: standard 2-layer fab minimum)
    ("GND", WSN, [("via", 209.5, 106.5)]), ("GND", WSN, [("via", 210.5, 106.5)]),
    ("GND", WSN, [("via", 209.5, 107.5)]), ("GND", WSN, [("via", 210.5, 107.5)]),
    ("GND", WSN, [("pad", "U1", "5"), (210.975, 106.2)]),                    # A0 -> GND: address 0x40
    ("+3V3_I2C", 0.4, [("pad", "J9", "2"), (229.46, 106.4), (215.05, 106.4), ("pad", "C2", "1")]),
    ("+3V3_I2C", WSN, [("pad", "C2", "1"), (213.6, 104), ("via", 213.6, 105.2), (212.8, 106.025), ("pad", "U1", "4")]),
    ("+3V3_I2C", WSN, [("pad", "U1", "16"), (210.975, 109.5), ("via", 211.9, 110.2)]),   # VPU
    ("+3V3_I2C", WSN, [(211.9, 110.2), (213.6, 110.2), (213.6, 105.2)], "B"),
    ("GND", WSN, [("pad", "C2", "2"), ("via", 217.2, 105.4)]),
    # I2C to the header (J9 pin 3 = SDA, pin 4 = SCL)
    ("SDA", WSN, [("pad", "U1", "7"), (209.675, 101.6), (226.92, 101.6), ("pad", "J9", "3")]),
    ("SCL", WSN, [("pad", "U1", "6"), (210.325, 102.5), (224.38, 102.5), ("pad", "J9", "4")]),
]
for i, x in enumerate(BUCK_X):
    n = i + 1
    jin, jout, jterm, r, d = f"J{10 + 2 * i}", f"J{11 + 2 * i}", f"J{5 + i}", f"R{2 + i}", f"D{3 + i}"
    ROUTES += [
        ("+12V", W12, [(x, 114), ("pad", jin, "1")]),
        (f"BUCK{n}_OUT", W5, [("pad", jout, "1"), ("pad", f"R{6 + i}", "2")]),
        (f"+5V_PI{n}", W5, [("pad", f"R{6 + i}", "1"), (x, 155), ("pad", jterm, "1")]),
        # Kelvin taps from the shunt pads to vias; the sense pair then runs on B.Cu
        (f"BUCK{n}_OUT", WSN, [("pad", f"R{6 + i}", "2"), ("via", x - 3.5, 147.037)]),
        (f"+5V_PI{n}", WSN, [("pad", f"R{6 + i}", "1"), ("via", x - 5.5, 152.963)]),
        (f"+5V_PI{n}", WS, [(x, 155), ("pad", r, "1")]),
        (f"LED{n}", WS, [("pad", r, "2"), ("pad", d, "2")]),
        ("GND", WS, [("pad", d, "1"), ("via", x + 14.8, 155)]),
    ]

SILK = [  # (text, x, y, size_mm)
    ("rack-10in-power-panel carrier v0.2", 180, 103.5, 1.2),
    ("PANEL LED", 159.5, 104.8, 0.8),
    ("INA3221 (opt)", 210, 112.0, 0.8),
    ("SCL", 224.38, 106.6, 0.8), ("SDA", 226.92, 106.6, 0.8), ("3V3", 229.46, 106.6, 0.8), ("GND", 232.0, 106.6, 0.8),
    ("12V IN", 115, 154, 1.0),
    ("5A", 111, 135, 1.0),
    ("ROCKER", 142, 102.5, 1.0),
    ("XT30 LINK", 148, 151, 1.0),
    ("GS308", 162.5, 155.6, 1.0),
    ("+12V", 156, 117, 0.9),
]
for i, x in enumerate(BUCK_X):
    SILK += [
        (f"BUCK {i + 1}", x + 2.3, 132, 1.2),
        ("IN+   IN-", x + 2.3, 117, 0.8),
        ("OUT+  OUT-", x + 2.3, 139.6, 0.8),
        (f"PI{i + 1} 5V", x + 2.5, 155.6, 1.0),
    ]


# --------------------------------------------------------------------------
# Minimal s-expression reader/writer for KiCad symbol libraries
# --------------------------------------------------------------------------
class Q(str):
    """A quoted string atom."""


def sexp_parse(text):
    tokens, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c in "()":
            tokens.append(c); i += 1
        elif c.isspace():
            i += 1
        elif c == '"':
            j, buf = i + 1, []
            while text[j] != '"':
                if text[j] == "\\":
                    buf.append(text[j:j + 2]); j += 2
                else:
                    buf.append(text[j]); j += 1
            tokens.append(Q("".join(buf))); i = j + 1
        else:
            j = i
            while j < n and not text[j].isspace() and text[j] not in '()"':
                j += 1
            tokens.append(text[i:j]); i = j
    stack = [[]]
    for t in tokens:
        if t == "(" and not isinstance(t, Q):
            stack.append([])
        elif t == ")" and not isinstance(t, Q):
            done = stack.pop(); stack[-1].append(done)
        else:
            stack[-1].append(t)
    return stack[0][0]


def sexp_dump(x, ind=0):
    if isinstance(x, list):
        if all(not isinstance(e, list) for e in x):
            return "(" + " ".join(sexp_dump(e) for e in x) + ")"
        pad = "  " * (ind + 1)
        head = " ".join(sexp_dump(e) for e in x if not isinstance(e, list))
        body = "\n".join(pad + sexp_dump(e, ind + 1) for e in x if isinstance(e, list))
        return "(" + head + "\n" + body + ")"
    if isinstance(x, Q):
        return '"' + x + '"'
    return str(x)


_lib_cache = {}


def lib_symbol(lib_id):
    lib, name = lib_id.split(":")
    if lib not in _lib_cache:
        with open(os.path.join(SYM_DIR, lib + ".kicad_sym")) as f:
            tree = sexp_parse(f.read())
        _lib_cache[lib] = {e[1]: e for e in tree if isinstance(e, list) and e[0] == "symbol"}
    sym = _lib_cache[lib][name]
    if any(isinstance(e, list) and e[0] == "extends" for e in sym):
        raise SystemExit(f"{lib_id} extends another symbol; pick a base symbol")
    out = list(sym)
    out[1] = Q(lib_id)
    return out


def symbol_pins(sym):
    """pin number -> (x, y, angle) in symbol coordinates (y up)."""
    pins = {}

    def walk(node):
        for e in node:
            if isinstance(e, list):
                if e[0] == "pin":
                    at = next(a for a in e if isinstance(a, list) and a[0] == "at")
                    num = next(a for a in e if isinstance(a, list) and a[0] == "number")[1]
                    pins[str(num)] = (float(at[1]), float(at[2]), float(at[3]) if len(at) > 3 else 0.0)
                else:
                    walk(e)
    walk(sym)
    return pins


# --------------------------------------------------------------------------
# Schematic: every pin gets a short wire stub and a net label
# --------------------------------------------------------------------------
def uid():
    return str(uuid.uuid4())


def snap(v, g=1.27):
    return round(round(v / g) * g, 4)


def write_schematic(root_uuid, sym_uuids):
    pin_net = {(ref, pin): net for net, members in NETS.items() for ref, pin in members}
    used_libs, lib_syms, items = set(), [], []
    font = ["effects", ["font", ["size", "1.27", "1.27"]]]
    for ref, (lib_id, value, fp, _pcb, (sx, sy)) in PARTS.items():
        sym = lib_symbol(lib_id)
        if lib_id not in used_libs:
            used_libs.add(lib_id); lib_syms.append(sym)
        sx, sy = snap(sx * 1.6, 2.54), snap(sy * 1.6, 2.54)  # spread over the A3 sheet, keep on grid
        pins = symbol_pins(sym)

        def prop(k, v, dx, dy, hide=False):
            eff = ["effects", ["font", ["size", "1.27", "1.27"]]] + (["hide"] if hide else [])
            return ["property", Q(k), Q(v), ["at", str(sx + dx), str(sy + dy), "0"], eff]

        virtual = fp is None  # power flags: schematic only
        yn = lambda b: "yes" if b else "no"
        node = ["symbol", ["lib_id", Q(lib_id)], ["at", str(sx), str(sy), "0"], ["unit", "1"],
                ["in_bom", yn(not virtual)], ["on_board", yn(not virtual)], ["dnp", yn(ref in OPTIONAL)],
                ["uuid", Q(sym_uuids[ref])],
                prop("Reference", ref, 3.81, -2.54, hide=virtual), prop("Value", value, 3.81, 2.54),
                prop("Footprint", fp or "", 0, 5.08, hide=True), prop("Datasheet", "~", 0, 7.62, hide=True)]
        for num in pins:
            node.append(["pin", Q(num), ["uuid", Q(uid())]])
        node.append(["instances", ["project", Q(NAME), ["path", Q("/" + root_uuid), ["reference", Q(ref)], ["unit", "1"]]]])
        items.append(node)

        for num, (px, py, ang) in pins.items():
            net = pin_net.get((ref, num))
            ax, ay = sx + px, sy - py  # symbol y is up, schematic y is down
            if (ref, num) in NO_CONNECT:
                items.append(["no_connect", ["at", str(round(ax, 4)), str(round(ay, 4))], ["uuid", Q(uid())]])
                continue
            if net is None:
                raise SystemExit(f"{ref} pin {num} is not on any net")
            ox, oy = -math.cos(math.radians(ang)), math.sin(math.radians(ang))
            ex, ey = round(ax + 2.54 * ox, 4), round(ay + 2.54 * oy, 4)
            items.append(["wire", ["pts", ["xy", str(round(ax, 4)), str(round(ay, 4))], ["xy", str(ex), str(ey)]],
                          ["stroke", ["width", "0"], ["type", "default"]], ["uuid", Q(uid())]])
            rot = {(-1, 0): 180, (1, 0): 0, (0, -1): 90, (0, 1): 270}[(round(ox), round(oy))]
            just = "left" if rot in (0, 90) else "right"
            items.append(["label", Q(net), ["at", str(ex), str(ey), str(rot)], ["fields_autoplaced"],
                          ["effects", ["font", ["size", "1.27", "1.27"]], ["justify", just, "bottom"]], ["uuid", Q(uid())]])

    sch = ["kicad_sch", ["version", "20230121"], ["generator", "eeschema"], ["uuid", Q(root_uuid)],
           ["paper", "A3"],
           ["title_block", ["title", Q("Rack power carrier")], ["rev", Q("0.2")],
            ["comment", "1", Q("Generated by pcb/generate.py - edit the script, not this file")]],
           ["lib_symbols"] + lib_syms] + items + [["sheet_instances", ["path", Q("/"), ["page", Q("1")]]]]
    with open(os.path.join(HERE, NAME + ".kicad_sch"), "w") as f:
        f.write(sexp_dump(sch) + "\n")


# --------------------------------------------------------------------------
# PCB
# --------------------------------------------------------------------------
def mm(x, y):
    return pcbnew.VECTOR2I_MM(x, y)


def write_pcb(root_uuid, sym_uuids):
    board = pcbnew.BOARD()
    nets = {}
    for name in NETS:
        ni = pcbnew.NETINFO_ITEM(board, name)
        board.Add(ni); nets[name] = ni
    pin_net = {(ref, pin): net for net, members in NETS.items() for ref, pin in members}

    fps = {}
    for ref, (lib_id, value, fpid, place, _s) in PARTS.items():
        if fpid is None:
            continue
        x, y, rot = place
        lib, name = fpid.split(":")
        fp = pcbnew.FootprintLoad(os.path.join(FP_DIR, lib + ".pretty"), name)
        if fp is None:
            raise SystemExit(f"footprint not found: {fpid}")
        fp.SetFPID(pcbnew.LIB_ID(lib, name))
        fp.SetReference(ref); fp.SetValue(value)
        fp.Value().SetVisible(False)
        if ref.startswith(("H", "J")):  # holes, and connectors that carry their own silk labels
            fp.Reference().SetVisible(False)  # avoid clutter on holes and buck pads
        fp.SetPosition(mm(x, y)); fp.SetOrientationDegrees(rot)
        fp.SetPath(pcbnew.KIID_PATH("/" + sym_uuids[ref]))
        fp.SetDNP(ref in OPTIONAL)
        board.Add(fp); fps[ref] = fp
        for pad in fp.Pads():
            net = pin_net.get((ref, pad.GetNumber()))
            if net:
                pad.SetNet(nets[net])

    def resolve(pt, near):
        if pt[0] == "pad":
            _, ref, num = pt
            cands = [p for p in fps[ref].Pads() if p.GetNumber() == num]
            if near is None:
                p = cands[0]
            else:
                p = min(cands, key=lambda c: (c.GetPosition().x / 1e6 - near[0]) ** 2 + (c.GetPosition().y / 1e6 - near[1]) ** 2)
            return (p.GetPosition().x / 1e6, p.GetPosition().y / 1e6)
        if pt[0] == "via":
            return (pt[1], pt[2])
        return pt

    if os.environ.get("PRINT_PADS"):
        for ref in os.environ["PRINT_PADS"].split(","):
            for p in fps[ref].Pads():
                b = p.GetBoundingBox()
                print(ref, p.GetNumber(), "%.3f %.3f" % (p.GetPosition().x / 1e6, p.GetPosition().y / 1e6),
                      "box x %.2f..%.2f y %.2f..%.2f" % (b.GetLeft() / 1e6, b.GetRight() / 1e6, b.GetTop() / 1e6, b.GetBottom() / 1e6))

    for route in ROUTES:
        net, width, pts = route[:3]
        layer = pcbnew.B_Cu if len(route) > 3 and route[3] == "B" else pcbnew.F_Cu
        small = width < 0.4  # fine-pitch signals get small vias
        coords = []
        for i, pt in enumerate(pts):
            near = None
            if pt[0] == "pad":
                nb = pts[i + 1] if i + 1 < len(pts) else pts[i - 1]
                near = nb[1:] if nb[0] == "via" else (nb if nb[0] != "pad" else None)
            coords.append(resolve(pt, near))
            if pt[0] == "via":
                v = pcbnew.PCB_VIA(board)
                v.SetPosition(mm(*coords[-1])); v.SetDrill(pcbnew.FromMM(0.3 if small else 0.4))
                v.SetWidth(pcbnew.FromMM(0.6 if small else 0.8)); v.SetNet(nets[net])
                board.Add(v)
        for a, b in zip(coords, coords[1:]):
            t = pcbnew.PCB_TRACK(board)
            t.SetStart(mm(*a)); t.SetEnd(mm(*b)); t.SetWidth(pcbnew.FromMM(width))
            t.SetLayer(layer); t.SetNet(nets[net])
            board.Add(t)

    edge = pcbnew.PCB_SHAPE(board, pcbnew.SHAPE_T_RECT)
    edge.SetStart(mm(BX0, BY0)); edge.SetEnd(mm(BX0 + BW, BY0 + BH))
    edge.SetLayer(pcbnew.Edge_Cuts); edge.SetWidth(pcbnew.FromMM(0.1))
    board.Add(edge)

    for x in BUCK_X:  # module keep-out outline on silk
        box = pcbnew.PCB_SHAPE(board, pcbnew.SHAPE_T_RECT)
        box.SetStart(mm(x - 5.5, 122.5)); box.SetEnd(mm(x + 10.1, 141.5))
        box.SetLayer(pcbnew.F_SilkS); box.SetWidth(pcbnew.FromMM(0.15))
        board.Add(box)

    for text, x, y, size in SILK:
        t = pcbnew.PCB_TEXT(board)
        t.SetText(text); t.SetPosition(mm(x, y)); t.SetLayer(pcbnew.F_SilkS)
        t.SetTextSize(mm(size, size)); t.SetTextThickness(pcbnew.FromMM(size * 0.15))
        board.Add(t)

    zone = pcbnew.ZONE(board)
    zone.SetLayer(pcbnew.B_Cu); zone.SetNet(nets["GND"])
    zone.SetLocalClearance(pcbnew.FromMM(0.5))
    zone.SetMinThickness(pcbnew.FromMM(0.25))
    ol = zone.Outline(); ol.NewOutline()
    for x, y in [(BX0 + .5, BY0 + .5), (BX0 + BW - .5, BY0 + .5), (BX0 + BW - .5, BY0 + BH - .5), (BX0 + .5, BY0 + BH - .5)]:
        ol.Append(pcbnew.FromMM(x), pcbnew.FromMM(y))
    board.Add(zone)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())

    board.Save(os.path.join(HERE, NAME + ".kicad_pcb"))


def write_lib_tables():
    """Project-local library tables so the project opens/checks without global KiCad setup."""
    sym_libs = sorted({p[0].split(":")[0] for p in PARTS.values()})
    fp_libs = sorted({p[2].split(":")[0] for p in PARTS.values() if p[2]})
    with open(os.path.join(HERE, "sym-lib-table"), "w") as f:
        f.write("(sym_lib_table\n  (version 7)\n")
        for lib in sym_libs:
            f.write(f'  (lib (name "{lib}")(type "KiCad")(uri "{SYM_DIR}/{lib}.kicad_sym")(options "")(descr ""))\n')
        f.write(")\n")
    with open(os.path.join(HERE, "fp-lib-table"), "w") as f:
        f.write("(fp_lib_table\n  (version 7)\n")
        for lib in fp_libs:
            f.write(f'  (lib (name "{lib}")(type "KiCad")(uri "{FP_DIR}/{lib}.pretty")(options "")(descr ""))\n')
        f.write(")\n")


def write_project():
    write_lib_tables()
    path = os.path.join(HERE, NAME + ".kicad_pro")
    pro = {"meta": {"filename": NAME + ".kicad_pro", "version": 1},
           "board": {"design_settings": {"rules": {"min_clearance": 0.2, "min_track_width": 0.25}}},
           "sheets": [], "text_variables": {}}
    with open(path, "w") as f:
        json.dump(pro, f, indent=2)


if __name__ == "__main__":
    # Stable UUIDs so regenerating doesn't churn every line of the outputs.
    ns = uuid.UUID("6f0c1c2e-6c0e-4d3e-9a51-6b1c7e0a9a10")
    root = str(uuid.uuid5(ns, "root"))
    syms = {ref: str(uuid.uuid5(ns, "sym/" + ref)) for ref in PARTS}
    uuid.uuid4 = lambda _c=[0]: (_c.__setitem__(0, _c[0] + 1), uuid.uuid5(ns, f"item/{_c[0]}"))[1]
    write_project()
    write_schematic(root, syms)
    write_pcb(root, syms)
    print("wrote", NAME + ".kicad_sch", NAME + ".kicad_pcb", NAME + ".kicad_pro")
