module cii_types
  implicit none

  real(8), parameter :: MISSING_REAL = -9999.0d0
  integer, parameter :: MISSING_INT = -9999

  type :: cii_restrain_t
    real(8) :: num, node, rtype, stiffness, gap, fric_coef, cnode
    real(8) :: xcos, ycos, zcos
    character(len=64) :: tag
  end type

  type :: cii_rigid_t
    real(8) :: weight
    character(len=64) :: rtype
  end type

  type :: cii_bend_t
    real(8) :: radius, btype
    real(8) :: angle1, node1, angle2, node2, angle3, node3
    real(8) :: num_miter, fitting_thk, kfactor
  end type

  type :: cii_sif_t
    real(8) :: sif_num, node, stype
    real(8) :: sif_in, sif_out, sif_torsion, sif_axial, sif_pressure
    real(8) :: iin, iout, it, ia, ipr
    real(8) :: weld_d, fillet, pad_thk, ftg_ro, crotch, weld_id, b1, b2
  end type

  type :: cii_hanger_t
    real(8) :: node, cnode, const_eff_load, load_var
    real(8) :: rigid_sup, avail_space, cold_load, hot_load, max_travel
    integer :: multi_lc, freeanchor1, freeanchor2, doftype1, hgr_table, short_range
    character(len=64) :: tag
  end type

  type :: cii_allowable_case_t
    integer :: num
    real(8) :: temp, press, sh, sa, sy, su
  end type

  type :: cii_allowable_t
    integer :: fac_a, fac_b, fac_c, fac_d
    type(cii_allowable_case_t), allocatable :: cases(:)
  end type

  type :: cii_element_t
    integer :: seq
    real(8) :: from_node, to_node
    real(8) :: dx, dy, dz

    ! Effective inherited values
    real(8) :: diameter, wall_thk, insul_thk, corr_allow
    real(8) :: temp_exp(9), pressure(9), hydro_pressure
    real(8) :: modulus, hot_mod(9), poissons
    real(8) :: pipe_density, insul_density, fluid_density
    real(8) :: refractory_density, refractory_thk, cladding_den, cladding_thk
    real(8) :: insul_clad_unit_weight
    real(8) :: material_num, mill_tol_plus, mill_tol_minus, seam_weld
    character(len=64) :: material_name, name

    type(cii_rigid_t), allocatable :: rigids(:)
    type(cii_restrain_t), allocatable :: restraints(:)
    type(cii_bend_t), allocatable :: bends(:)
    type(cii_sif_t), allocatable :: sifs(:)
    type(cii_hanger_t), allocatable :: hangers(:)
    type(cii_allowable_t), allocatable :: allowable(:)
  end type

  type :: cii_unit_item_t
    character(len=64) :: label
    real(8) :: factor
  end type

  type :: cii_units_t
    type(cii_unit_item_t) :: length, force, mass_dynamics, moment_input, moment_output
    type(cii_unit_item_t) :: stress, temp, pressure, emod, pdens, idens, fdens
    type(cii_unit_item_t) :: trans_stiff, rotl_stiff, unif_load, g_load, wind_load
    type(cii_unit_item_t) :: elevation, compound_length, diameter, thickness
  end type

  type :: cii_model_t
    character(len=64) :: jobname
    character(len=64) :: time
    character(len=64) :: issue_no

    real(8) :: north_z, north_y, north_x

    type(cii_element_t), allocatable :: elements(:)
    type(cii_units_t) :: units

    ! Derived counts
    integer :: count_elements
    integer :: count_bends
    integer :: count_rigids
    integer :: count_restraints
    integer :: count_allowable
    integer :: count_sifs
  end type

end module cii_types
