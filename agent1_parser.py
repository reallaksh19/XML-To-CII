import xml.etree.ElementTree as ET
import json
import math

MISSING_REAL = -1.010100
MISSING_INT = -1

def is_missing_real(val):
    if val is None:
        return True
    try:
        fval = float(val)
        if math.isnan(fval):
            return True
        return abs(fval - MISSING_REAL) < 1e-6
    except ValueError:
        if isinstance(val, str) and val.lower().strip() in ["-nan", "nan"]:
            return True
        return True

def parse_real(val):
    if is_missing_real(val):
        return MISSING_REAL
    try:
        return float(val)
    except ValueError:
        return MISSING_REAL

def parse_int(val):
    if val is None:
        return MISSING_INT
    try:
        return int(float(val))
    except ValueError:
        return MISSING_INT

def parse_str(val):
    if val is None:
        return ""
    return str(val).strip()

def is_active_restraint(node, rtype):
    return not is_missing_real(node) and not is_missing_real(rtype)

def is_active_sif(node, stype):
    return not is_missing_real(node) and not is_missing_real(stype)

def is_active_bend(radius, angle1, node1):
    return not is_missing_real(radius) and not is_missing_real(angle1) and not is_missing_real(node1)

def is_active_rigid(rtype, weight):
    rtype_str = parse_str(rtype)
    return (rtype_str) or not is_missing_real(weight)

def apply_inheritance(prev_elem, curr_elem):
    if prev_elem is None:
        for k in ['diameter', 'wall_thk', 'insul_thk', 'corr_allow', 'hydro_pressure', 'pipe_density', 'insul_density', 'fluid_density', 'material_num']:
            curr_elem[f'effective_{k}'] = curr_elem[k]
        curr_elem['effective_temps'] = curr_elem['temps'][:]
        curr_elem['effective_pressures'] = curr_elem['pressures'][:]
        curr_elem['effective_material_name'] = curr_elem['material_name']
        return

    # Diameter
    curr_elem['effective_diameter'] = prev_elem['effective_diameter'] if is_missing_real(curr_elem['diameter']) else curr_elem['diameter']
    # Wall thickness
    curr_elem['effective_wall_thk'] = prev_elem['effective_wall_thk'] if is_missing_real(curr_elem['wall_thk']) else curr_elem['wall_thk']
    # Insul thickness
    curr_elem['effective_insul_thk'] = prev_elem['effective_insul_thk'] if is_missing_real(curr_elem['insul_thk']) else curr_elem['insul_thk']
    # Corr allow
    curr_elem['effective_corr_allow'] = prev_elem['effective_corr_allow'] if is_missing_real(curr_elem['corr_allow']) else curr_elem['corr_allow']

    # Temps & Pressures
    curr_elem['effective_temps'] = []
    for i in range(9):
        curr_elem['effective_temps'].append(prev_elem['effective_temps'][i] if is_missing_real(curr_elem['temps'][i]) else curr_elem['temps'][i])

    curr_elem['effective_pressures'] = []
    for i in range(9):
        curr_elem['effective_pressures'].append(prev_elem['effective_pressures'][i] if is_missing_real(curr_elem['pressures'][i]) else curr_elem['pressures'][i])

    # Hydro pressure
    curr_elem['effective_hydro_pressure'] = prev_elem['effective_hydro_pressure'] if is_missing_real(curr_elem['hydro_pressure']) else curr_elem['hydro_pressure']

    # Densities
    curr_elem['effective_pipe_density'] = prev_elem['effective_pipe_density'] if is_missing_real(curr_elem['pipe_density']) else curr_elem['pipe_density']
    curr_elem['effective_insul_density'] = prev_elem['effective_insul_density'] if is_missing_real(curr_elem['insul_density']) else curr_elem['insul_density']
    curr_elem['effective_fluid_density'] = prev_elem['effective_fluid_density'] if is_missing_real(curr_elem['fluid_density']) else curr_elem['fluid_density']

    # Material
    if is_missing_real(curr_elem['material_num']):
        curr_elem['effective_material_num'] = prev_elem['effective_material_num']
        curr_elem['effective_material_name'] = prev_elem['effective_material_name']
    else:
        curr_elem['effective_material_num'] = curr_elem['material_num']
        curr_elem['effective_material_name'] = curr_elem['material_name']

def parse_xml(filename):
    tree = ET.parse(filename)
    root = tree.getroot()

    model = {
        'version': parse_str(root.get('VERSION')),
        'xml_type': parse_str(root.get('XML_TYPE')),
        'jobname': "",
        'time': "",
        'elements': [],
        'units': []
    }

    piping_model = root.find('.//PIPINGMODEL')
    if piping_model is not None:
        model['jobname'] = parse_str(piping_model.get('JOBNAME'))
        model['time'] = parse_str(piping_model.get('TIME'))

        # Units
        units_node = piping_model.find('./UNITS')
        if units_node is not None:
            for child in units_node:
                model['units'].append({
                    'name': child.tag,
                    'label': parse_str(child.get('LABEL')),
                    'factor': parse_real(child.get('FACTOR'))
                })

        # Elements
        prev_elem = None
        seq = 1
        for pe in piping_model.findall('./PIPINGELEMENT'):
            elem = {
                'seq': seq,
                'from_node': parse_real(pe.get('FROM_NODE')),
                'to_node': parse_real(pe.get('TO_NODE')),
                'dx': parse_real(pe.get('DELTA_X')),
                'dy': parse_real(pe.get('DELTA_Y')),
                'dz': parse_real(pe.get('DELTA_Z')),
                'diameter': parse_real(pe.get('DIAMETER')),
                'wall_thk': parse_real(pe.get('WALL_THICK')),
                'insul_thk': parse_real(pe.get('INSUL_THICK')),
                'corr_allow': parse_real(pe.get('CORR_ALLOW')),
                'temps': [parse_real(pe.get(f'TEMP_EXP_C{i}')) for i in range(1, 10)],
                'pressures': [parse_real(pe.get(f'PRESSURE{i}')) for i in range(1, 10)],
                'hydro_pressure': parse_real(pe.get('HYDRO_PRESSURE')),
                'pipe_density': parse_real(pe.get('PIPE_DENSITY')),
                'insul_density': parse_real(pe.get('INSUL_DENSITY')),
                'fluid_density': parse_real(pe.get('FLUID_DENSITY')),
                'material_num': parse_real(pe.get('MATERIAL_NUM')),
                'material_name': parse_str(pe.get('MATERIAL_NAME')),
                'name': parse_str(pe.get('NAME')),

                'rigids': [],
                'restraints': [],
                'bend': None,
                'sifs': [],
                'hanger': None,
                'allowable': None
            }

            # Apply inheritance
            apply_inheritance(prev_elem, elem)

            # Rigids
            for r in pe.findall('./RIGID'):
                rtype = parse_str(r.get('TYPE'))
                weight = parse_real(r.get('WEIGHT'))
                if is_active_rigid(rtype, weight):
                    elem['rigids'].append({
                        'rtype': rtype,
                        'weight': weight,
                        'owner_seq': seq
                    })

            # Restraints
            for r in pe.findall('./RESTRAINT'):
                node = parse_real(r.get('NODE'))
                rtype = parse_real(r.get('TYPE'))
                if is_active_restraint(node, rtype):
                    elem['restraints'].append({
                        'num': parse_real(r.get('NUM')),
                        'node': node,
                        'rtype': rtype,
                        'stiffness': parse_real(r.get('STIFFNESS')),
                        'gap': parse_real(r.get('GAP')),
                        'fric_coef': parse_real(r.get('FRIC_COEF')),
                        'cnode': parse_real(r.get('CNODE')),
                        'xcos': parse_real(r.get('XCOSINE')),
                        'ycos': parse_real(r.get('YCOSINE')),
                        'zcos': parse_real(r.get('ZCOSINE')),
                        'tag': parse_str(r.get('TAG')),
                        'owner_seq': seq
                    })

            # Bend
            bend_node = pe.find('./BEND')
            if bend_node is not None:
                radius = parse_real(bend_node.get('RADIUS'))
                angle1 = parse_real(bend_node.get('ANGLE1'))
                node1 = parse_real(bend_node.get('NODE1'))
                if is_active_bend(radius, angle1, node1):
                    elem['bend'] = {
                        'radius': radius,
                        'btype': parse_real(bend_node.get('TYPE')),
                        'angle1': angle1, 'node1': node1,
                        'angle2': parse_real(bend_node.get('ANGLE2')), 'node2': parse_real(bend_node.get('NODE2')),
                        'angle3': parse_real(bend_node.get('ANGLE3')), 'node3': parse_real(bend_node.get('NODE3')),
                        'num_miter': parse_real(bend_node.get('NUM_MITER')),
                        'fitting_thk': parse_real(bend_node.get('FITTINGTHICKNESS')),
                        'kfactor': parse_real(bend_node.get('KFACTOR')),
                        'owner_seq': seq
                    }

            # SIFs
            for s in pe.findall('./SIF'):
                node = parse_real(s.get('NODE'))
                stype = parse_real(s.get('TYPE'))
                if is_active_sif(node, stype):
                    elem['sifs'].append({
                        'sif_num': parse_real(s.get('SIF_NUM')),
                        'node': node,
                        'stype': stype,
                        'sif_in': parse_real(s.get('SIF_IN')),
                        'sif_out': parse_real(s.get('SIF_OUT')),
                        'sif_torsion': parse_real(s.get('SIF_TORSION')),
                        'sif_axial': parse_real(s.get('SIF_AXIAL')),
                        'sif_pressure': parse_real(s.get('SIF_PRESSURE')),
                        'iin': parse_real(s.get('STRESSINDEX_Iin')),
                        'iout': parse_real(s.get('STRESSINDEX_Iout')),
                        'it': parse_real(s.get('STRESSINDEX_It')),
                        'ia': parse_real(s.get('STRESSINDEX_Ia')),
                        'ipr': parse_real(s.get('STRESSINDEX_Ipr')),
                        'weld_d': parse_real(s.get('WELD_D')),
                        'fillet': parse_real(s.get('FILLET')),
                        'pad_thk': parse_real(s.get('PAD_THK')),
                        'ftg_ro': parse_real(s.get('FTG_RO')),
                        'crotch': parse_real(s.get('CROTCH')),
                        'weld_id': parse_real(s.get('WELD_ID')),
                        'b1': parse_real(s.get('B1')),
                        'b2': parse_real(s.get('B2')),
                        'owner_seq': seq
                    })

            # Hanger
            h_node = pe.find('./HANGER')
            if h_node is not None:
                node = parse_real(h_node.get('NODE'))
                if not is_missing_real(node):
                    elem['hanger'] = {
                        'node': node,
                        'cnode': parse_real(h_node.get('CNODE')),
                        'const_eff_load': parse_real(h_node.get('CONST_EFF_LOAD')),
                        'load_var': parse_real(h_node.get('LOAD_VAR')),
                        'rigid_sup': parse_real(h_node.get('RIGID_SUP')),
                        'avail_space': parse_real(h_node.get('AVAIL_SPACE')),
                        'cold_load': parse_real(h_node.get('COLD_LOAD')),
                        'hot_load': parse_real(h_node.get('HOT_LOAD')),
                        'max_travel': parse_real(h_node.get('MAX_TRAVEL')),
                        'multi_lc': parse_int(h_node.get('MULTI_LC')),
                        'freeanchor1': parse_real(h_node.get('FREEANCHOR1')),
                        'freeanchor2': parse_real(h_node.get('FREEANCHOR2')),
                        'doftype1': parse_str(h_node.get('DOFTYPE1')),
                        'hgr_table': parse_int(h_node.get('HGR_TABLE')),
                        'short_range': parse_int(h_node.get('SHORT_RANGE')),
                        'tag': parse_str(h_node.get('TAG')),
                        'owner_seq': seq
                    }

            # Allowable
            a_node = pe.find('./ALLOWABLESTRESS')
            if a_node is not None:
                allowable = {
                    'hoop_stress_factor': parse_real(a_node.get('HOOP_STRESS_FACTOR')),
                    'cold_allow': parse_real(a_node.get('COLD_ALLOW')),
                    'eff': parse_real(a_node.get('EFF')),
                    'sy': parse_real(a_node.get('SY')),
                    'su': parse_real(a_node.get('SU')),
                    'piping_code': parse_real(a_node.get('PIPING_CODE')),
                    'cases': [],
                    'owner_seq': seq
                }
                for c in a_node.findall('./CASE'):
                    allowable['cases'].append({
                        'num': parse_int(c.get('NUM')),
                        'hot_allow': parse_real(c.get('HOT_ALLOW')),
                        'hot_sy': parse_real(c.get('HOT_SY')),
                        'hot_su': parse_real(c.get('HOT_SU')),
                        'cyc_red_factor': parse_real(c.get('CYC_RED_FACTOR')),
                        'buttweldcycles': parse_real(c.get('BUTTWELDCYCLES')),
                        'buttweldstress': parse_real(c.get('BUTTWELDSTRESS'))
                    })
                elem['allowable'] = allowable

            model['elements'].append(elem)
            prev_elem = elem
            seq += 1

    # Counts based on active derived records
    model['numelt'] = len(model['elements'])
    model['numbend'] = sum(1 for e in model['elements'] if e['bend'] is not None)
    model['numrigid'] = sum(len(e['rigids']) for e in model['elements'])
    model['numrest'] = sum(1 for e in model['elements'] if len(e['restraints']) > 0)
    model['numisect'] = sum(1 for e in model['elements'] if len(e['sifs']) > 0)
    model['numallow'] = sum(1 for e in model['elements'] if e['allowable'] is not None)

    return model

if __name__ == "__main__":
    canonical_model = parse_xml('BM_CII_INPUT.XML')
    with open('canonical_model.json', 'w') as f:
        json.dump(canonical_model, f, indent=2)
    print("Agent 1 Parser execution completed.")
