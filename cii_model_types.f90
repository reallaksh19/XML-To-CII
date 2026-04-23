module cii_model_types
  implicit none

  type :: restraint_t
    real(8) :: num, node, rtype, stiffness, gap, fric_coef, cnode
    real(8) :: xcos, ycos, zcos
    character(len=64) :: tag
    integer :: owner_seq
  end type

  type :: rigid_t
    real(8) :: weight
    character(len=64) :: rtype
    integer :: owner_seq
  end type

  type :: bend_t
    real(8) :: radius, btype
    real(8) :: angle1, node1, angle2, node2, angle3, node3
    real(8) :: num_miter, fitting_thk, kfactor
    integer :: owner_seq
  end type

  type :: sif_t
    real(8) :: sif_num, node, stype
    real(8) :: sif_in, sif_out, sif_torsion, sif_axial, sif_pressure
    real(8) :: iin, iout, it, ia, ipr
    real(8) :: weld_d, fillet, pad_thk, ftg_ro, crotch, weld_id, b1, b2
    integer :: owner_seq
  end type

  type :: hanger_t
    real(8) :: node, cnode, const_eff_load, load_var
    real(8) :: rigid_sup, avail_space, cold_load, hot_load, max_travel
    integer :: multi_lc, freeanchor1, freeanchor2, doftype1, hgr_table, short_range
    character(len=64) :: tag
    integer :: owner_seq
  end type

  type :: allow_case_t
    integer :: num
    real(8) :: hot_allow, hot_sy, hot_su, cyc_red_factor
    real(8) :: buttweldcycles, buttweldstress
  end type

  type :: allowable_t
    type(allow_case_t), allocatable :: cases(:)
    real(8) :: hoop_stress_factor, cold_allow, eff, sy, su, piping_code
    integer :: owner_seq
  end type

  type :: element_t
    integer :: seq
    real(8) :: from_node, to_node
    real(8) :: dx, dy, dz

    ! Effective inherited properties
    real(8) :: effective_diameter, effective_wall_thk, effective_insul_thk, effective_corr_allow
    real(8) :: effective_temps(9), effective_pressures(9), effective_hydro_pressure
    real(8) :: effective_pipe_density, effective_insul_density, effective_fluid_density
    real(8) :: effective_material_num
    character(len=64) :: effective_material_name

    ! Original properties for reference
    real(8) :: diameter, wall_thk, insul_thk, corr_allow
    real(8) :: temps(9), pressures(9), hydro_pressure
    real(8) :: modulus, hot_mods(9), poissons
    real(8) :: pipe_density, insul_density, fluid_density
    real(8) :: material_num, mill_tol_plus, mill_tol_minus, seam_weld
    character(len=64) :: material_name, name

    type(rigid_t), allocatable :: rigids(:)
    type(restraint_t), allocatable :: restraints(:)
    type(bend_t), allocatable :: bend
    type(sif_t), allocatable :: sifs(:)
    type(hanger_t), allocatable :: hanger
    type(allowable_t), allocatable :: allowable
  end type

  type :: unit_t
    character(len=64) :: name, label
    real(8) :: factor
  end type

  type :: model_t
    character(len=64) :: jobname, time
    integer :: numelt, numbend, numrigid, numrest, numallow, numisect
    type(element_t), allocatable :: elements(:)
    type(unit_t), allocatable :: units(:)
  end type
end module cii_model_types
