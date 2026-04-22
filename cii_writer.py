import sys
import xml.etree.ElementTree as ET

def is_missing(val_str):
    if val_str is None or val_str.strip() == "": return True
    v = val_str.lower()
    return v == "-1.010100" or v == "-1" or "nan" in v

def p_dbl(val_str, default=None):
    if is_missing(val_str): return default
    try: return float(val_str)
    except: return default

def p_int(val_str, default=None):
    if is_missing(val_str): return default
    try: return int(float(val_str))
    except: return default

class CE:
    def __init__(self, seq):
        self.seq = seq
        self.from_n = 0.0; self.to_n = 0.0
        self.dx = 0.0; self.dy = 0.0; self.dz = 0.0
        self.d = 0.0; self.wt = 0.0; self.it = 0.0; self.ca = 0.0
        self.t = [0.0]*9; self.p = [0.0]*9
        self.hp = 0.0; self.mod = 0.0; self.hm = [0.0]*9
        self.poi = 0.0; self.pd = 0.0; self.id = 0.0; self.fd = 0.0
        self.mat_num = 0; self.mat_name = ""; self.name = ""
        self.rigids = []; self.rests = []; self.bends = []; self.sifs = []
        self.allow = None

def load_canonical(xml_path):
    tree = ET.parse(xml_path)
    model = tree.getroot().find("PIPINGMODEL")
    els = []

    ld, lwt, lit, lca = 0.0, 0.0, 0.0, 0.0
    lt = [0.0]*9; lp = [0.0]*9; lhm = [0.0]*9
    lhp, lmod, lpoi, lpd, lid, lfd = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    lmat = 0; lmatname = ""

    seq = 0
    for e in model.findall("PIPINGELEMENT"):
        seq += 1
        ce = CE(seq)
        ce.from_n = p_dbl(e.get("FROM_NODE"), 0.0)
        ce.to_n = p_dbl(e.get("TO_NODE"), 0.0)
        ce.dx = p_dbl(e.get("DELTA_X"), 0.0)
        ce.dy = p_dbl(e.get("DELTA_Y"), 0.0)
        ce.dz = p_dbl(e.get("DELTA_Z"), 0.0)

        ce.d = ld = p_dbl(e.get("DIAMETER"), ld)
        ce.wt = lwt = p_dbl(e.get("WALL_THICK"), lwt)
        ce.it = lit = p_dbl(e.get("INSUL_THICK"), lit)
        ce.ca = lca = p_dbl(e.get("CORR_ALLOW"), lca)
        for i in range(1,10):
            ce.t[i-1] = lt[i-1] = p_dbl(e.get(f"TEMP_EXP_C{i}"), lt[i-1])
            ce.p[i-1] = lp[i-1] = p_dbl(e.get(f"PRESSURE{i}"), lp[i-1])
            ce.hm[i-1] = lhm[i-1] = p_dbl(e.get(f"HOT_MOD{i}"), lhm[i-1])
        ce.hp = lhp = p_dbl(e.get("HYDRO_PRESSURE"), lhp)
        ce.mod = lmod = p_dbl(e.get("MODULUS"), lmod)
        ce.poi = lpoi = p_dbl(e.get("POISSONS"), lpoi)
        ce.pd = lpd = p_dbl(e.get("PIPE_DENSITY"), lpd)
        ce.id = lid = p_dbl(e.get("INSUL_DENSITY"), lid)
        ce.fd = lfd = p_dbl(e.get("FLUID_DENSITY"), lfd)
        ce.mat_num = lmat = p_int(e.get("MATERIAL_NUM"), lmat)

        m_name = e.get("MATERIAL_NAME", "")
        if is_missing(m_name): ce.mat_name = lmatname
        else: ce.mat_name = lmatname = m_name.strip()

        nm = e.get("NAME", "")
        if not is_missing(nm): ce.name = nm.strip()

        for c in e.findall("RIGID"):
            wt = p_dbl(c.get("WEIGHT"))
            typ = c.get("TYPE", "")
            if wt is not None or (typ and not is_missing(typ)):
                t_map = {"Valve": 1, "Flange": 2, "Flange Pair": 3, "Flanged Valve": 4}
                ce.rigids.append({"wt": wt if wt is not None else 0.0, "typ": t_map.get(typ, 0)})

        for c in e.findall("RESTRAINT"):
            n = p_dbl(c.get("NODE"))
            t = p_dbl(c.get("TYPE"))
            if n is not None and t is not None:
                t_val = int(t)
                typ_map = {0:1, 1:2, 2:3, 3:4, 7:8, 10:9, 17:14, 18:15}
                ce.rests.append({
                    "n": n, "t": typ_map.get(t_val, t_val),
                    "stiff": p_dbl(c.get("STIFFNESS"), 0.0),
                    "gap": p_dbl(c.get("GAP"), 0.0),
                    "fric": p_dbl(c.get("FRIC_COEF"), 0.0),
                    "cnode": p_dbl(c.get("CNODE"), 0.0),
                    "xcos": p_dbl(c.get("XCOSINE"), 0.0),
                    "ycos": p_dbl(c.get("YCOSINE"), 0.0),
                    "zcos": p_dbl(c.get("ZCOSINE"), 0.0),
                    "tag": c.get("TAG", "")
                })

        b = e.find("BEND")
        if b is not None:
            r = p_dbl(b.get("RADIUS"))
            a1 = p_dbl(b.get("ANGLE1"))
            n1 = p_dbl(b.get("NODE1"))
            if r is not None and a1 is not None and n1 is not None:
                ce.bends.append({
                    "r": r, "typ": p_dbl(b.get("TYPE"), 0.0),
                    "a1": a1, "n1": n1,
                    "a2": p_dbl(b.get("ANGLE2"), 0.0), "n2": p_dbl(b.get("NODE2"), 0.0),
                    "a3": p_dbl(b.get("ANGLE3"), 0.0), "n3": p_dbl(b.get("NODE3"), 0.0),
                    "k": p_dbl(b.get("KFACTOR"), 0.0)
                })

        for c in e.findall("SIF"):
            n = p_dbl(c.get("NODE"))
            t = p_dbl(c.get("TYPE"))
            if n is not None and t is not None:
                ce.sifs.append({
                    "n": n, "t": t,
                    "sin": p_dbl(c.get("SIF_IN"), 0.0),
                    "sout": p_dbl(c.get("SIF_OUT"), 0.0),
                    "stors": p_dbl(c.get("SIF_TORSION"), 0.0),
                    "sax": p_dbl(c.get("SIF_AXIAL"), 0.0),
                    "spres": p_dbl(c.get("SIF_PRESSURE"), 0.0)
                })

        al = e.find("ALLOWABLESTRESS")
        if al is not None:
            cases = []
            for cc in al.findall("CASE"):
                num = p_int(cc.get("NUM"))
                if num is not None:
                    cases.append({
                        "num": num,
                        "hot_allow": p_dbl(cc.get("HOT_ALLOW"), 0.0),
                        "hot_sy": p_dbl(cc.get("HOT_SY"), 0.0),
                        "hot_su": p_dbl(cc.get("HOT_SU"), 0.0),
                        "cyc_red": p_dbl(cc.get("CYC_RED_FACTOR"), 1.0),
                        "cycles": p_dbl(cc.get("BUTTWELDCYCLES"), 0.0),
                        "stress": p_dbl(cc.get("BUTTWELDSTRESS"), 0.0)
                    })
            ce.allow = {
                "hoop": p_dbl(al.get("HOOP_STRESS_FACTOR"), 1.0),
                "cold": p_dbl(al.get("COLD_ALLOW"), 0.0),
                "eff": p_dbl(al.get("EFF"), 1.0),
                "sy": p_dbl(al.get("SY"), 0.0),
                "su": p_dbl(al.get("SU"), 0.0),
                "code": p_dbl(al.get("PIPING_CODE"), 1.0),
                "cases": cases
            }

        els.append(ce)

    n_rest = int(tree.getroot().find("PIPINGMODEL").get("NUMREST", "8"))
    n_sif = int(tree.getroot().find("PIPINGMODEL").get("NUMISECT", "9"))

    return els, n_rest, n_sif

def ffmt(val, width=13, is_int=False):
    if val is None: val = 0.0
    if is_int: return str(int(val)).rjust(width)
    if val == 0.0:
        s = "     0.000000"
        if len(s) > width: return s[:width].rjust(width)
        return s.rjust(width)
    if val == 9999.99:
        s = "  9999.99    "
        if len(s) > width: return s[:width].rjust(width)
        return s.rjust(width)

    if abs(val) < 0.01 and abs(val) > 0:
        s = f"{val:13.6E}".replace("E-0", "E-")
        if len(s) > 13: s = f"{val:13.5E}".replace("E-0", "E-")
        if len(s) > 13: s = f"{val:13.4E}".replace("E-0", "E-")
        if len(s) < width: return s.rjust(width)
        return s[:width]

    s = f"{val:13.6f}"
    if len(s) > 13: s = f"{val:13.5f}"
    if len(s) > 13: s = f"{val:13.4f}"
    if len(s) > 13: s = f"{val:13.3f}"
    if len(s) > 13: s = f"{val:13.2f}"
    if len(s) > 13: s = f"{val:13.1f}"
    if len(s) > 13: s = f"{val:13.0f}"

    s = s.strip()
    if "." in s:
        while s.endswith("0") and len(s) > 8:
            s = s[:-1]
        if s.endswith("."):
            s += "00000"
        while len(s) < 7: s += "0"

    if len(s) < width: return s.rjust(width)
    return s[:width]

def write_elements(els):
    lines = ["#$ ELEMENTS"]
    for ce in els:
        l1 = ffmt(ce.from_n, 11) + ffmt(ce.to_n, 13) + ffmt(ce.dx, 17) + ffmt(ce.dy, 13) + ffmt(ce.dz, 9) + ffmt(ce.d, 17)
        l2 = ffmt(ce.wt, 11) + ffmt(ce.it, 13) + ffmt(ce.ca, 17) + ffmt(ce.t[0], 9) + ffmt(ce.t[1], 17) + ffmt(ce.t[2], 13)
        l3 = "    " + ffmt(ce.t[3], 11) + ffmt(ce.t[4], 13) + ffmt(ce.t[5], 13) + ffmt(ce.t[6], 13) + ffmt(ce.t[7], 13) + ffmt(ce.t[8], 13)
        l4 = ffmt(ce.p[0], 11) + ffmt(ce.p[1], 13) + ffmt(ce.p[2], 13) + ffmt(ce.p[3], 13) + ffmt(ce.p[4], 13) + ffmt(ce.p[5], 13)
        l5 = "    " + ffmt(ce.p[6], 11) + ffmt(ce.p[7], 13) + ffmt(ce.p[8], 13) + ffmt(ce.hp, 13) + ffmt(ce.poi, 13) + ffmt(ce.pd, 13)
        l6 = ffmt(ce.id, 15) + ffmt(ce.fd, 13) + ffmt(ce.mod, 13) + ffmt(ce.hm[0], 13) + ffmt(ce.hm[1], 13) + ffmt(ce.mat_num, 9) + "    "
        l7 = "    " + ffmt(ce.hm[3], 11) + ffmt(ce.hm[4], 13) + ffmt(ce.hm[5], 13) + ffmt(ce.hm[6], 13) + ffmt(ce.hm[7], 13) + ffmt(ce.hm[8], 13)
        l8 = "    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(9999.99, 13) + ffmt(9999.99, 13) + "    "
        l9 = "    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13)
        l10 = "           0 "
        if ce.name: l11 = f"           {len(ce.name)} {ce.name}"
        else: l11 = "           0 "
        lines.extend([l1, l2, l3, l4, l5, l6, l7, l8, l9, l10, l11])
        lines.extend(["             -1           -1", "              0            1            0            2            0            0", "              0            0            0            1            0            0", "              0            0            0"])
    return lines

def write_bends(els):
    lines = ["#$ BEND    "]
    for ce in els:
        for b in ce.bends:
            l1 = ffmt(b["r"], 11) + ffmt(b["typ"], 13) + ffmt(b["a1"], 17) + ffmt(b["n1"], 13) + ffmt(b["a2"], 9) + ffmt(b["n2"], 17)
            l2 = "    " + ffmt(b["a3"], 11) + ffmt(b["n3"], 13) + ffmt(ce.wt, 13) + ffmt(b["k"], 13) + ffmt(0.0, 13) + ffmt(0.0, 13)
            l3 = "    " + ffmt(0.0, 11) + ffmt(0.0, 13)
            lines.extend([l1, l2, l3])
    return lines

def write_rigids(els):
    lines = ["#$ RIGID   "]
    for ce in els:
        for r in ce.rigids:
            lines.append(ffmt(r["wt"], 11) + ffmt(r["typ"], 13) + "    ")
    return lines

def write_restrants(els):
    lines = ["#$ RESTRANT"]
    for ce in els:
        for r in ce.rests:
            l1 = ffmt(r["n"], 11) + ffmt(r["t"], 13) + ffmt(r["stiff"], 17) + ffmt(r["gap"], 13) + ffmt(r["fric"], 9) + ffmt(r["cnode"], 17)
            l2 = "    " + ffmt(r["xcos"], 11) + ffmt(r["ycos"], 13) + ffmt(r["zcos"], 13)
            lines.extend([l1, l2, "           0 ", "           0 "])
    return lines

def write_sifs(els):
    lines = ["#$ SIF&TEES"]
    for ce in els:
        for s in ce.sifs:
            l1 = ffmt(s["n"], 11) + ffmt(s["t"], 13) + ffmt(s["sin"], 17) + ffmt(s["sout"], 13) + ffmt(s["stors"], 9) + ffmt(s["sax"], 17)
            l2 = "    " + ffmt(s["spres"], 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13)
            lines.extend([l1, l2])
            for _ in range(2): lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13))
            lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(9999.99, 13) + ffmt(9999.99, 13) + "    ")
            for _ in range(4): lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13))
            lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(9999.99, 13) + ffmt(9999.99, 13) + "    ")
            lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13))
    return lines

def write_allow(els):
    lines = ["#$ ALLOWBLS"]
    for ce in els:
        if ce.allow:
            a = ce.allow
            l1 = ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(a["hoop"], 13) + ffmt(a["eff"], 13) + "    "
            l2 = ffmt(1.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(9999.99, 13) + ffmt(0.0, 13) + ffmt(a["code"], 13) + "    "
            lines.extend([l1, l2])
            lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13))

            cases_line = ["    "]
            for i in range(1, 7):
                val = 1.0
                if len(a["cases"]) > 0:
                    for case in a["cases"]:
                        if case["num"] == i:
                            val = case.get("cyc_red", 1.0)
                            break
                cases_line.append(ffmt(val, 11 if i==1 else 13))
            cases_line.append("    ")
            lines.append("".join(cases_line))

            for _ in range(10):
                lines.append("    " + ffmt(0.0, 11) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13) + ffmt(0.0, 13))
            break
    return lines

def write_units():
    return """#$ UNITS
    25.4000      4.44800     0.453590     0.112980     0.112980     0.689460E-02
   0.555600     -17.7778     0.689460E-01 0.689460E-02 0.276800E-01 0.276800E-01
   0.276800E-01  1.75120     0.112980      1.75120      1.00000      6.89460
   0.254000E-01  25.4000      25.4000      25.4000
  METRIC
  ON
  mm.
   N.
  Kg.
   N.m.
   N.m.
     MPa
  C
  C
  bars
  MPa
  kg./cu.cm.
  kg./cu.cm.
  kg./cu.cm.
  N./cm.
   N.m./deg
  N./cm.
  g's
     KPa
   m.
  mm.
  mm.
  mm.""".split("\n")

def write_version():
    return """#$ VERSION
    5.00000      11.0000        1256
    PROJECT:

    CLIENT :

    ANALYST:

    NOTES  :


























































  Data generated by CAESAR II/CADWorx/PIPE interface -- Ver 2002, 5/2002.    """.split("\n")

def write_control(els, n_rest, n_sif):
    n_elt = len(els)
    n_bend = sum(1 for e in els if e.bends)
    n_rigid = sum(len(e.rigids) for e in els)
    n_allow = 1 if any(e.allow for e in els) else 0

    lines = ["#$ CONTROL "]
    lines.append(f"             {n_elt}            0            1            2            0            0")
    lines.append(f"              {n_bend}           {n_rigid}            0            {n_rest}            0            0")
    lines.append(f"              0            0            0            {n_allow}            {n_sif}            0")
    lines.append("              0")
    return lines

def generate_output():
    els, n_rest, n_sif = load_canonical("BM_CII_INPUT.XML")

    out = []
    out.extend(write_version())
    out.extend(write_control(els, n_rest, n_sif))
    out.extend(write_elements(els))
    out.extend(write_bends(els))
    out.extend(write_rigids(els))
    out.extend(write_restrants(els))
    out.extend(write_sifs(els))
    out.extend(write_allow(els))
    out.extend(write_units())

    with open("BM_CII_out.CII", "w") as f:
        f.write("\n".join(out) + "\n")

if __name__ == "__main__":
    generate_output()
