import xml.etree.ElementTree as ET
import sys

def parse_xml_and_write_driver(xml_path, out_f90):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    model = root.find('.//PIPINGMODEL')

    numelt = model.get('NUMELT', '0')
    numbend = model.get('NUMBEND', '0')
    numrigid = model.get('NUMRIGID', '0')
    numrest = model.get('NUMREST', '0')
    numallow = model.get('NUMALLOW', '0')
    numisect = model.get('NUMISECT', '0')

    with open(out_f90, 'w') as f:
        f.write("program generated_driver\n")
        f.write("  use cii_model_types\n")
        f.write("  use write_version_control\n")
        f.write("  use write_elements\n")
        f.write("  use write_bend_rigid_restrant\n")
        f.write("  use write_sif_allowbls_units\n")
        f.write("  implicit none\n")
        f.write("  integer :: iunit\n")
        f.write("  type(cii_element_t) :: el\n")
        f.write("  integer :: rig_flags(6), res_flags(6), ben_flags(3), sif_flags(6)\n")

        f.write("  type(cii_bend_t), allocatable :: bends(:)\n")
        f.write("  type(cii_rigid_t), allocatable :: rigids(:)\n")
        f.write("  type(cii_restrain_t), allocatable :: restrants(:)\n")
        f.write("  type(cii_sif_t), allocatable :: sifs(:)\n")

        f.write("  open(newunit=iunit, file='BM_CII_out.CII', status='replace')\n")
        f.write("  call write_version(iunit)\n")
        f.write(f"  call write_control(iunit, {numelt}, {numbend}, {numrigid}, {numrest}, {numallow}, {numisect})\n")
        f.write("  write(iunit, \"(A)\") \"#$ ELEMENTS\"\n")

        for i, el in enumerate(model.findall('PIPINGELEMENT')):
            # Read attributes
            fn = el.get('FROM_NODE', '-1.010100')
            tn = el.get('TO_NODE', '-1.010100')
            dx = el.get('DELTA_X', '-1.010100')
            dy = el.get('DELTA_Y', '-1.010100')
            dz = el.get('DELTA_Z', '-1.010100')
            dia = el.get('DIAMETER', '-1.010100')
            wt = el.get('WALL_THICK', '-1.010100')
            ins = el.get('INSUL_THICK', '-1.010100')
            ca = el.get('CORR_ALLOW', '-1.010100')
            t1 = el.get('TEMP_EXP_C1', '-1.010100')
            p1 = el.get('PRESSURE1', '-1.010100')
            hp = el.get('HYDRO_PRESSURE', '-1.010100')
            mod = el.get('MODULUS', '-1.010100')
            pois = el.get('POISSONS', '-1.010100')
            pden = el.get('PIPE_DENSITY', '-1.010100')
            iden = el.get('INSUL_DENSITY', '-1.010100')
            fden = el.get('FLUID_DENSITY', '-1.010100')
            name = el.get('NAME', '')

            f.write(f"  el%from_node = {fn}d0\n")
            f.write(f"  el%to_node = {tn}d0\n")
            f.write(f"  el%dx = {dx}d0\n")
            f.write(f"  el%dy = {dy}d0\n")
            f.write(f"  el%dz = {dz}d0\n")
            f.write(f"  el%diameter = {dia}d0\n")
            f.write(f"  el%wall_thk = {wt}d0\n")
            f.write(f"  el%insul_thk = {ins}d0\n")
            f.write(f"  el%corr_allow = {ca}d0\n")
            f.write(f"  el%temp_exp(1) = {t1}d0\n")
            f.write("  el%temp_exp(2:9) = 0.0d0\n")
            f.write("  el%pressure(1:9) = 0.0d0\n")
            f.write(f"  el%pressure(1) = {p1}d0\n")
            f.write(f"  el%hydro_pressure = {hp}d0\n")
            f.write(f"  el%modulus = {mod}d0\n")
            f.write(f"  el%poissons = {pois}d0\n")
            f.write("  el%hot_mod(1:9) = 0.0d0\n")
            f.write(f"  el%pipe_density = {pden}d0\n")
            f.write(f"  el%insul_density = {iden}d0\n")
            f.write(f"  el%fluid_density = {fden}d0\n")

            f.write("  el%refractory_density = 0.0d0\n")
            f.write("  el%refractory_thk = 0.0d0\n")
            f.write("  el%cladding_den = 0.0d0\n")
            f.write("  el%cladding_thk = 0.0d0\n")
            f.write("  el%insul_clad_unit_weight = 0.0d0\n")
            f.write("  el%material_num = 0.0d0\n")
            f.write("  el%mill_tol_plus = 0.0d0\n")
            f.write("  el%mill_tol_minus = 0.0d0\n")
            f.write("  el%seam_weld = 0.0d0\n")
            f.write(f"  el%name = '{name}'\n")

            # Write rig_flags, etc. based on children presence. For now all 0.
            f.write("  rig_flags = 0\n")
            f.write("  res_flags = 0\n")
            f.write("  ben_flags = 0\n")
            f.write("  sif_flags = 0\n")

            f.write("  call write_element(iunit, el, rig_flags, res_flags, ben_flags, sif_flags)\n")

        f.write(f"  allocate(bends({numbend}))\n")
        f.write(f"  allocate(rigids({numrigid}))\n")
        f.write(f"  allocate(restrants({numrest}))\n")
        f.write(f"  allocate(sifs({numisect}))\n")

        # Populate bends
        bend_idx = 1
        for el in model.findall('PIPINGELEMENT'):
            bend = el.find('BEND')
            if bend is not None:
                f.write(f"  bends({bend_idx})%btype = 1\n") # simplified
                f.write(f"  bends({bend_idx})%node1 = {bend.get('NODE1', '0.0')}d0\n")
                f.write(f"  bends({bend_idx})%radius = {bend.get('RADIUS', '0.0')}d0\n")
                f.write(f"  bends({bend_idx})%angle1 = {bend.get('ANGLE1', '0.0')}d0\n")
                f.write(f"  bends({bend_idx})%angle2 = {bend.get('ANGLE2', '0.0')}d0\n")
                bend_idx += 1
        f.write(f"  call write_bend(iunit, {numbend}, bends)\n")

        # Populate rigids
        rig_idx = 1
        for el in model.findall('PIPINGELEMENT'):
            for rig in el.findall('RIGID'):
                wt = rig.get('WEIGHT', '-1.010100')
                if wt == '-1.010100': wt = '0.0'
                f.write(f"  rigids({rig_idx})%weight = {wt}d0\n")
                f.write(f"  rigids({rig_idx})%rtype = '{rig.get('TYPE', '')}'\n")
                rig_idx += 1
        f.write(f"  call write_rigid(iunit, {numrigid}, rigids)\n")

        # Populate restrants
        res_idx = 1
        for el in model.findall('PIPINGELEMENT'):
            for res in el.findall('RESTRAINT'):
                node = res.get('NODE', '-1.010100')
                if node != '-1.010100':
                    f.write(f"  restrants({res_idx})%node = {node}d0\n")
                    f.write(f"  restrants({res_idx})%rtype = {res.get('TYPE', '0.0')}d0\n")
                    f.write(f"  restrants({res_idx})%tag = '{res.get('TAG', '')}'\n")
                    res_idx += 1
        # The XML file has inactive restraints.
        # We write based on numrest which should be recomputed.
        # But we'll trust the python parser to filter them.
        f.write(f"  call write_restrant(iunit, {res_idx-1}, restrants)\n")

        # Populate SIFs
        sif_idx = 1
        for el in model.findall('PIPINGELEMENT'):
            for sif in el.findall('SIF'):
                node = sif.get('NODE', '-1.010100')
                if node != '-1.010100':
                    f.write(f"  sifs({sif_idx})%stype = {sif.get('TYPE', '0.0')}d0\n")
                    f.write(f"  sifs({sif_idx})%node = {node}d0\n")
                    f.write(f"  sifs({sif_idx})%sif_in = 0.0d0\n")
                    sif_idx += 1
        f.write(f"  call write_sif_tees(iunit, {sif_idx-1}, sifs)\n")

        f.write(f"  call write_allowbls(iunit, {numallow})\n")
        f.write("  call write_units(iunit)\n")

        f.write("  close(iunit)\n")
        f.write("end program generated_driver\n")

if __name__ == '__main__':
    parse_xml_and_write_driver('BM_CII_INPUT.XML', 'generated_driver.f90')
