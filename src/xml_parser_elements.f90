module xml_parser_elements
  use cii_types
  use normalization
  use xml_parser_base
  implicit none

contains

  subroutine parse_element_attributes(line, elem)
    character(len=*), intent(in) :: line
    type(cii_element_t), intent(inout) :: elem

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "FROM_NODE", val, found)
    if (found) elem%from_node = normalize_real_str(val)

    call extract_attribute(line, "TO_NODE", val, found)
    if (found) elem%to_node = normalize_real_str(val)

    call extract_attribute(line, "DELTA_X", val, found)
    if (found) elem%dx = normalize_real_str(val)

    call extract_attribute(line, "DELTA_Y", val, found)
    if (found) elem%dy = normalize_real_str(val)

    call extract_attribute(line, "DELTA_Z", val, found)
    if (found) elem%dz = normalize_real_str(val)

    call extract_attribute(line, "DIAMETER", val, found)
    if (found) elem%diameter = normalize_real_str(val)

    call extract_attribute(line, "WALL_THICK", val, found)
    if (found) elem%wall_thk = normalize_real_str(val)

    call extract_attribute(line, "INSUL_THICK", val, found)
    if (found) elem%insul_thk = normalize_real_str(val)

    call extract_attribute(line, "CORR_ALLOW", val, found)
    if (found) elem%corr_allow = normalize_real_str(val)

    call extract_attribute(line, "TEMP_EXP_C1", val, found)
    if (found) elem%temp_exp(1) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C2", val, found)
    if (found) elem%temp_exp(2) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C3", val, found)
    if (found) elem%temp_exp(3) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C4", val, found)
    if (found) elem%temp_exp(4) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C5", val, found)
    if (found) elem%temp_exp(5) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C6", val, found)
    if (found) elem%temp_exp(6) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C7", val, found)
    if (found) elem%temp_exp(7) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C8", val, found)
    if (found) elem%temp_exp(8) = normalize_real_str(val)
    call extract_attribute(line, "TEMP_EXP_C9", val, found)
    if (found) elem%temp_exp(9) = normalize_real_str(val)

    call extract_attribute(line, "PRESSURE1", val, found)
    if (found) elem%pressure(1) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE2", val, found)
    if (found) elem%pressure(2) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE3", val, found)
    if (found) elem%pressure(3) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE4", val, found)
    if (found) elem%pressure(4) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE5", val, found)
    if (found) elem%pressure(5) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE6", val, found)
    if (found) elem%pressure(6) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE7", val, found)
    if (found) elem%pressure(7) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE8", val, found)
    if (found) elem%pressure(8) = normalize_real_str(val)
    call extract_attribute(line, "PRESSURE9", val, found)
    if (found) elem%pressure(9) = normalize_real_str(val)

    call extract_attribute(line, "HYDRO_PRESSURE", val, found)
    if (found) elem%hydro_pressure = normalize_real_str(val)

    call extract_attribute(line, "MODULUS", val, found)
    if (found) elem%modulus = normalize_real_str(val)

    call extract_attribute(line, "HOT_MOD1", val, found)
    if (found) elem%hot_mod(1) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD2", val, found)
    if (found) elem%hot_mod(2) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD3", val, found)
    if (found) elem%hot_mod(3) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD4", val, found)
    if (found) elem%hot_mod(4) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD5", val, found)
    if (found) elem%hot_mod(5) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD6", val, found)
    if (found) elem%hot_mod(6) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD7", val, found)
    if (found) elem%hot_mod(7) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD8", val, found)
    if (found) elem%hot_mod(8) = normalize_real_str(val)
    call extract_attribute(line, "HOT_MOD9", val, found)
    if (found) elem%hot_mod(9) = normalize_real_str(val)

    call extract_attribute(line, "POISSONS", val, found)
    if (found) elem%poissons = normalize_real_str(val)

    call extract_attribute(line, "PIPE_DENSITY", val, found)
    if (found) elem%pipe_density = normalize_real_str(val)

    call extract_attribute(line, "INSUL_DENSITY", val, found)
    if (found) elem%insul_density = normalize_real_str(val)

    call extract_attribute(line, "FLUID_DENSITY", val, found)
    if (found) elem%fluid_density = normalize_real_str(val)

    call extract_attribute(line, "MATERIAL_NUM", val, found)
    if (found) elem%material_num = normalize_real_str(val)

    call extract_attribute(line, "MATERIAL_NAME", val, found)
    if (found) elem%material_name = normalize_string(val)

    call extract_attribute(line, "NAME", val, found)
    if (found) elem%name = normalize_string(val)
  end subroutine parse_element_attributes

  subroutine parse_rigid(line, rig)
    character(len=*), intent(in) :: line
    type(cii_rigid_t), intent(inout) :: rig

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "WEIGHT", val, found)
    if (found) rig%weight = normalize_real_str(val)

    call extract_attribute(line, "TYPE", val, found)
    if (found) rig%rtype = normalize_string(val)
  end subroutine parse_rigid

  subroutine parse_restraint(line, rest)
    character(len=*), intent(in) :: line
    type(cii_restrain_t), intent(inout) :: rest

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "NUM", val, found)
    if (found) rest%num = normalize_real_str(val)

    call extract_attribute(line, "NODE", val, found)
    if (found) rest%node = normalize_real_str(val)

    call extract_attribute(line, "TYPE", val, found)
    if (found) rest%rtype = normalize_real_str(val)

    call extract_attribute(line, "TAG", val, found)
    if (found) rest%tag = normalize_string(val)
  end subroutine parse_restraint

  subroutine parse_bend(line, bnd)
    character(len=*), intent(in) :: line
    type(cii_bend_t), intent(inout) :: bnd

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "RADIUS", val, found)
    if (found) bnd%radius = normalize_real_str(val)

    call extract_attribute(line, "ANGLE1", val, found)
    if (found) bnd%angle1 = normalize_real_str(val)

    call extract_attribute(line, "NODE1", val, found)
    if (found) bnd%node1 = normalize_real_str(val)
  end subroutine parse_bend

  subroutine parse_sif(line, sf)
    character(len=*), intent(in) :: line
    type(cii_sif_t), intent(inout) :: sf

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "SIF_NUM", val, found)
    if (found) sf%sif_num = normalize_real_str(val)

    call extract_attribute(line, "NODE", val, found)
    if (found) sf%node = normalize_real_str(val)

    call extract_attribute(line, "TYPE", val, found)
    if (found) sf%stype = normalize_real_str(val)
  end subroutine parse_sif

  subroutine parse_allowable_case(line, case)
    character(len=*), intent(in) :: line
    type(cii_allowable_case_t), intent(inout) :: case

    character(len=256) :: val
    logical :: found

    call extract_attribute(line, "NUM", val, found)
    if (found) case%num = normalize_int_str(val)
    call extract_attribute(line, "TEMP", val, found)
    if (found) case%temp = normalize_real_str(val)
    call extract_attribute(line, "PRESS", val, found)
    if (found) case%press = normalize_real_str(val)
    call extract_attribute(line, "SH", val, found)
    if (found) case%sh = normalize_real_str(val)
    call extract_attribute(line, "SA", val, found)
    if (found) case%sa = normalize_real_str(val)
    call extract_attribute(line, "SY", val, found)
    if (found) case%sy = normalize_real_str(val)
    call extract_attribute(line, "SU", val, found)
    if (found) case%su = normalize_real_str(val)
  end subroutine parse_allowable_case

end module xml_parser_elements
