module inheritance
  use cii_types
  implicit none

  type :: inheritance_state_t
    real(8) :: diameter = MISSING_REAL
    real(8) :: wall_thk = MISSING_REAL
    real(8) :: insul_thk = MISSING_REAL
    real(8) :: corr_allow = MISSING_REAL
    real(8) :: temp_exp(9) = MISSING_REAL
    real(8) :: pressure(9) = MISSING_REAL
    real(8) :: hydro_pressure = MISSING_REAL
    real(8) :: modulus = MISSING_REAL
    real(8) :: hot_mod(9) = MISSING_REAL
    real(8) :: poissons = MISSING_REAL
    real(8) :: pipe_density = MISSING_REAL
    real(8) :: insul_density = MISSING_REAL
    real(8) :: fluid_density = MISSING_REAL
    real(8) :: refractory_density = MISSING_REAL
    real(8) :: refractory_thk = MISSING_REAL
    real(8) :: cladding_den = MISSING_REAL
    real(8) :: cladding_thk = MISSING_REAL
    real(8) :: insul_clad_unit_weight = MISSING_REAL
    real(8) :: material_num = MISSING_REAL
    real(8) :: mill_tol_plus = MISSING_REAL
    real(8) :: mill_tol_minus = MISSING_REAL
    real(8) :: seam_weld = MISSING_REAL
    character(len=64) :: material_name = ""
  end type

contains

  subroutine apply_inheritance(elem, state)
    type(cii_element_t), intent(inout) :: elem
    type(inheritance_state_t), intent(inout) :: state
    integer :: i

    ! Diameter
    if (elem%diameter /= MISSING_REAL) then
      state%diameter = elem%diameter
    else
      elem%diameter = state%diameter
    end if

    ! Wall thickness
    if (elem%wall_thk /= MISSING_REAL) then
      state%wall_thk = elem%wall_thk
    else
      elem%wall_thk = state%wall_thk
    end if

    ! Insulation thickness
    if (elem%insul_thk /= MISSING_REAL) then
      state%insul_thk = elem%insul_thk
    else
      elem%insul_thk = state%insul_thk
    end if

    ! Corrosion allowance
    if (elem%corr_allow /= MISSING_REAL) then
      state%corr_allow = elem%corr_allow
    else
      elem%corr_allow = state%corr_allow
    end if

    ! Temperatures
    do i = 1, 9
      if (elem%temp_exp(i) /= MISSING_REAL) then
        state%temp_exp(i) = elem%temp_exp(i)
      else
        elem%temp_exp(i) = state%temp_exp(i)
      end if
    end do

    ! Pressures
    do i = 1, 9
      if (elem%pressure(i) /= MISSING_REAL) then
        state%pressure(i) = elem%pressure(i)
      else
        elem%pressure(i) = state%pressure(i)
      end if
    end do

    ! Hydro pressure
    if (elem%hydro_pressure /= MISSING_REAL) then
      state%hydro_pressure = elem%hydro_pressure
    else
      elem%hydro_pressure = state%hydro_pressure
    end if

    ! Modulus
    if (elem%modulus /= MISSING_REAL) then
      state%modulus = elem%modulus
    else
      elem%modulus = state%modulus
    end if

    ! Hot modulus
    do i = 1, 9
      if (elem%hot_mod(i) /= MISSING_REAL) then
        state%hot_mod(i) = elem%hot_mod(i)
      else
        elem%hot_mod(i) = state%hot_mod(i)
      end if
    end do

    ! Poissons
    if (elem%poissons /= MISSING_REAL) then
      state%poissons = elem%poissons
    else
      elem%poissons = state%poissons
    end if

    ! Densities
    if (elem%pipe_density /= MISSING_REAL) then
      state%pipe_density = elem%pipe_density
    else
      elem%pipe_density = state%pipe_density
    end if

    if (elem%insul_density /= MISSING_REAL) then
      state%insul_density = elem%insul_density
    else
      elem%insul_density = state%insul_density
    end if

    if (elem%fluid_density /= MISSING_REAL) then
      state%fluid_density = elem%fluid_density
    else
      elem%fluid_density = state%fluid_density
    end if

    if (elem%refractory_density /= MISSING_REAL) then
      state%refractory_density = elem%refractory_density
    else
      elem%refractory_density = state%refractory_density
    end if

    if (elem%refractory_thk /= MISSING_REAL) then
      state%refractory_thk = elem%refractory_thk
    else
      elem%refractory_thk = state%refractory_thk
    end if

    if (elem%cladding_den /= MISSING_REAL) then
      state%cladding_den = elem%cladding_den
    else
      elem%cladding_den = state%cladding_den
    end if

    if (elem%cladding_thk /= MISSING_REAL) then
      state%cladding_thk = elem%cladding_thk
    else
      elem%cladding_thk = state%cladding_thk
    end if

    if (elem%insul_clad_unit_weight /= MISSING_REAL) then
      state%insul_clad_unit_weight = elem%insul_clad_unit_weight
    else
      elem%insul_clad_unit_weight = state%insul_clad_unit_weight
    end if

    ! Material num and name
    if (elem%material_num /= MISSING_REAL) then
      state%material_num = elem%material_num
    else
      elem%material_num = state%material_num
    end if

    if (elem%mill_tol_plus /= MISSING_REAL) then
      state%mill_tol_plus = elem%mill_tol_plus
    else
      elem%mill_tol_plus = state%mill_tol_plus
    end if

    if (elem%mill_tol_minus /= MISSING_REAL) then
      state%mill_tol_minus = elem%mill_tol_minus
    else
      elem%mill_tol_minus = state%mill_tol_minus
    end if

    if (elem%seam_weld /= MISSING_REAL) then
      state%seam_weld = elem%seam_weld
    else
      elem%seam_weld = state%seam_weld
    end if

    if (len_trim(elem%material_name) > 0) then
      state%material_name = elem%material_name
    else
      elem%material_name = state%material_name
    end if

  end subroutine apply_inheritance

end module inheritance
