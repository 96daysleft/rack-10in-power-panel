#!/usr/bin/env python3
"""Generate the single-Pi power board (schematic + PCB) from one netlist.

One board powers one Raspberry Pi from the panel's 12 V bus:
  12 V IN screw terminal -> RECOM R-78B5.0-2.0 (5 V 2 A) -> 5 V OUT screw terminal
with input/output capacitors and a green status LED. Every part is a catalogue
part, so the fab can assemble it; you only screw in the 12 V leads and a
micro-USB pigtail. Order 5, fit one per Pi.

Writes pi-power.kicad_sch, .kicad_pcb and .kicad_pro next to this file.
Run via build.sh (it clears the desktop app's library paths and runs ERC/DRC).
Requires KiCad 8+ (uses the pcbnew Python module and the stock KiCad libraries).
"""
import json
import math
import os
import uuid

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
NAME = "pi-power"
TITLE, REV = "Single-Pi 12 V to 5 V power board", "1.0"
SYM_DIR = os.environ.get("KICAD_SYMBOL_DIR", "/usr/share/kicad/symbols")
FP_DIR = os.environ.get("KICAD_FOOTPRINT_DIR", "/usr/share/kicad/footprints")

# Board outline (KiCad page coords, mm). Both terminals sit on the bottom edge
# (y = 123) with their wire entries facing it.
BX0, BY0, BW, BH = 100.0, 100.0, 40.0, 23.0
TERM_Y = 117.0

TERM = "TerminalBlock_Phoenix:TerminalBlock_Phoenix_MKDS-1,5-2-5.08_1x02_P5.08mm_Horizontal"
R0805, C1206, LED0805 = "Resistor_SMD:R_0805_2012Metric", "Capacitor_SMD:C_1206_3216Metric", "LED_SMD:LED_0805_2012Metric"
HOLE = "MountingHole:MountingHole_3.2mm_M3"
T2 = "Connector_Generic:Conn_01x02"

# --------------------------------------------------------------------------
# Parts: ref -> (symbol, value, footprint, (x, y, rot_deg), schematic (x, y))
# --------------------------------------------------------------------------
PARTS = {
    "J1": (T2, "12V IN (1=+ 2=-)", TERM, (106, TERM_Y, 0), (40, 60)),
    "C1": ("Device:C", "10uF 25V X7R", C1206, (110, 104.5, 90), (70, 80)),
    "U1": ("Regulator_Switching:R-78B1.2-2.0", "R-78B5.0-2.0", "Converter_DCDC:Converter_DCDC_RECOM_R-78B-2.0_THT", (116.46, 104, 0), (100, 60)),
    "C2": ("Device:C", "22uF 10V X5R", C1206, (128, 104.5, 90), (130, 80)),
    "R1": ("Device:R", "1k", R0805, (128.5, 108.3, 0), (150, 60)),
    "D1": ("Device:LED", "green", LED0805, (132.5, 108.3, 180), (170, 60)),
    "J2": (T2, "5V OUT to Pi (1=+ 2=-)", TERM, (126, TERM_Y, 0), (200, 60)),
    "H1": ("Mechanical:MountingHole", "M3", HOLE, (103.5, 103.5, 0), (40, 120)),
    "H2": ("Mechanical:MountingHole", "M3", HOLE, (136.5, 103.5, 0), (55, 120)),
    "#FLG01": ("power:PWR_FLAG", "PWR_FLAG", None, None, (110, 120)),
    "#FLG02": ("power:PWR_FLAG", "PWR_FLAG", None, None, (125, 120)),
}
MPN = {
    "U1": "RECOM R-78B5.0-2.0",
    "J1": "Phoenix Contact 1715721 (MKDS 1,5/2-5,08)",
    "J2": "Phoenix Contact 1715721 (MKDS 1,5/2-5,08)",
    "C1": "Murata GRM31CR71E106KA12L or equiv. (10uF 25V X7R 1206)",
    "C2": "Murata GRM31CR61A226KE19L or equiv. (22uF 10V X5R 1206)",
    "R1": "any 1k 1% 0805 thick film",
    "D1": "any green 0805 LED, Vf ~2 V",
}
OPTIONAL = set()
NO_CONNECT = []
NO_BOM = {"H1", "H2"}  # footprints flagged "exclude from BOM"
NETS = {
    "+12V": [("J1", "1"), ("C1", "1"), ("U1", "1"), ("#FLG02", "1")],
    "+5V": [("U1", "3"), ("C2", "1"), ("J2", "1"), ("R1", "1")],
    "LED": [("R1", "2"), ("D1", "2")],
    "GND": [("J1", "2"), ("C1", "2"), ("U1", "2"), ("C2", "2"), ("J2", "2"), ("D1", "1"), ("#FLG01", "1")],
}

# --------------------------------------------------------------------------
# Routing (F.Cu). Each route: (net, width_mm, [points][, "B"]); a point is (x, y),
# ("pad", ref, number) or ("via", x, y). GND is a B.Cu pour; SMD GND pads drop
# to it through vias.
# --------------------------------------------------------------------------
W12, W5, WS, WSN = 1.0, 1.5, 0.5, 0.25
ROUTES = [
    # 12 V in -> input cap -> regulator IN
    ("+12V", W12, [("pad", "J1", "1"), (106, 108.5), (110, 108.5), (116.46, 108.5), ("pad", "U1", "1")]),
    ("+12V", W12, [(110, 108.5), ("pad", "C1", "1")]),
    ("GND", WS, [("pad", "C1", "2"), ("via", 108.0, 103.025)]),
    # regulator OUT -> output cap -> 5 V terminal, status LED
    ("+5V", W5, [("pad", "U1", "3"), (121.54, 107.3), (126, 107.3), ("pad", "J2", "1")]),
    ("+5V", W12, [(126, 107.3), (128, 107.3), ("pad", "C2", "1")]),
    ("GND", WS, [("pad", "C2", "2"), ("via", 130.0, 103.025)]),
    ("+5V", WS, [(126, 108.3), ("pad", "R1", "1")]),
    ("LED", WS, [("pad", "R1", "2"), ("pad", "D1", "2")]),
    ("GND", WS, [("pad", "D1", "1"), ("via", 135.3, 108.3)]),
]

SILK = [  # (text, x, y, size_mm)
    ("pi-power v1.0", 120, 112.0, 1.2, "B"),
    ("rack-10in-power-panel", 120, 114.0, 0.9, "B"),
    ("+  12V IN  -", 108.54, 110.6, 0.8),
    ("+  5V OUT  -", 129.6, 110.6, 0.8),
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
                ["in_bom", yn(not virtual and ref not in NO_BOM)], ["on_board", yn(not virtual)], ["dnp", yn(ref in OPTIONAL)],
                ["uuid", Q(sym_uuids[ref])],
                prop("Reference", ref, 3.81, -2.54, hide=virtual), prop("Value", value, 3.81, 2.54),
                prop("Footprint", fp or "", 0, 5.08, hide=True), prop("Datasheet", "~", 0, 7.62, hide=True),
                prop("MPN", MPN.get(ref, ""), 0, 10.16, hide=True)]
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
           ["title_block", ["title", Q(TITLE)], ["rev", Q(REV)],
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
        ni = pcbnew.NETINFO_ITEM(board, "/" + name)  # match the schematic's local-label net names
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
        if ref.startswith(("H", "J", "C", "R", "D")):  # small board: refs live in the placement file  # holes, and connectors that carry their own silk labels
            fp.Reference().SetVisible(False)  # avoid clutter on holes and buck pads
        fp.SetPosition(mm(x, y)); fp.SetOrientationDegrees(rot)
        fp.SetPath(pcbnew.KIID_PATH("/" + sym_uuids[ref]))
        fp.SetDNP(ref in OPTIONAL)
        fp.SetField("MPN", MPN.get(ref, ""))  # match the schematic field (parity check)
        fp.GetField("MPN").SetVisible(False)
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

    # Fab/assembly origin at the board's bottom-left corner (placement CSV, Gerbers, drill)
    board.GetDesignSettings().SetAuxOrigin(mm(BX0, BY0 + BH))

    edge = pcbnew.PCB_SHAPE(board, pcbnew.SHAPE_T_RECT)
    edge.SetStart(mm(BX0, BY0)); edge.SetEnd(mm(BX0 + BW, BY0 + BH))
    edge.SetLayer(pcbnew.Edge_Cuts); edge.SetWidth(pcbnew.FromMM(0.1))
    board.Add(edge)

    for item in SILK:  # (text, x, y, size[, "B"]) - "B" puts it on the back, mirrored
        text, x, y, size = item[:4]
        back = len(item) > 4 and item[4] == "B"
        t = pcbnew.PCB_TEXT(board)
        t.SetText(text); t.SetPosition(mm(x, y)); t.SetLayer(pcbnew.B_SilkS if back else pcbnew.F_SilkS)
        t.SetMirrored(back)
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
