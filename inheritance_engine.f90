module inheritance_engine
  use cii_model_types
  use value_normalize
  implicit none

  contains

  subroutine apply_element_inheritance(prev_elem, curr_elem)
    type(element_t), intent(in) :: prev_elem
    type(element_t), intent(inout) :: curr_elem
    integer :: i

    ! Diameter
    if (is_missing_real(curr_elem%diameter)) then
      curr_elem%effective_diameter = prev_elem%effective_diameter
    else
      curr_elem%effective_diameter = curr_elem%diameter
    end if

    ! Wall thickness
    if (is_missing_real(curr_elem%wall_thk)) then
      curr_elem%effective_wall_thk = prev_elem%effective_wall_thk
    else
      curr_elem%effective_wall_thk = curr_elem%wall_thk
    end if

    ! Insulation thickness
    if (is_missing_real(curr_elem%insul_thk)) then
      curr_elem%effective_insul_thk = prev_elem%effective_insul_thk
    else
      curr_elem%effective_insul_thk = curr_elem%insul_thk
    end if

    ! Corrosion allowance
    if (is_missing_real(curr_elem%corr_allow)) then
      curr_elem%effective_corr_allow = prev_elem%effective_corr_allow
    else
      curr_elem%effective_corr_allow = curr_elem%corr_allow
    end if

    ! Temperatures
    do i = 1, 9
      if (is_missing_real(curr_elem%temps(i))) then
        curr_elem%effective_temps(i) = prev_elem%effective_temps(i)
      else
        curr_elem%effective_temps(i) = curr_elem%temps(i)
      end if
    end do

    ! Pressures
    do i = 1, 9
      if (is_missing_real(curr_elem%pressures(i))) then
        curr_elem%effective_pressures(i) = prev_elem%effective_pressures(i)
      else
        curr_elem%effective_pressures(i) = curr_elem%pressures(i)
      end if
    end do

    ! Hydro pressure
    if (is_missing_real(curr_elem%hydro_pressure)) then
      curr_elem%effective_hydro_pressure = prev_elem%effective_hydro_pressure
    else
      curr_elem%effective_hydro_pressure = curr_elem%hydro_pressure
    end if

    ! Densities
    if (is_missing_real(curr_elem%pipe_density)) then
      curr_elem%effective_pipe_density = prev_elem%effective_pipe_density
    else
      curr_elem%effective_pipe_density = curr_elem%pipe_density
    end if

    if (is_missing_real(curr_elem%insul_density)) then
      curr_elem%effective_insul_density = prev_elem%effective_insul_density
    else
      curr_elem%effective_insul_density = curr_elem%insul_density
    end if

    if (is_missing_real(curr_elem%fluid_density)) then
      curr_elem%effective_fluid_density = prev_elem%effective_fluid_density
    else
      curr_elem%effective_fluid_density = curr_elem%fluid_density
    end if

    ! Material num and name
    if (is_missing_real(curr_elem%material_num)) then
      curr_elem%effective_material_num = prev_elem%effective_material_num
      curr_elem%effective_material_name = prev_elem%effective_material_name
    else
      curr_elem%effective_material_num = curr_elem%material_num
      curr_elem%effective_material_name = curr_elem%material_name
    end if

  end subroutine apply_element_inheritance

  subroutine init_element_effective_values(curr_elem)
    type(element_t), intent(inout) :: curr_elem
    integer :: i

    curr_elem%effective_diameter = curr_elem%diameter
    curr_elem%effective_wall_thk = curr_elem%wall_thk
    curr_elem%effective_insul_thk = curr_elem%insul_thk
    curr_elem%effective_corr_allow = curr_elem%corr_allow

    do i = 1, 9
      curr_elem%effective_temps(i) = curr_elem%temps(i)
      curr_elem%effective_pressures(i) = curr_elem%pressures(i)
    end do

    curr_elem%effective_hydro_pressure = curr_elem%hydro_pressure
    curr_elem%effective_pipe_density = curr_elem%pipe_density
    curr_elem%effective_insul_density = curr_elem%insul_density
    curr_elem%effective_fluid_density = curr_elem%fluid_density

    curr_elem%effective_material_num = curr_elem%material_num
    curr_elem%effective_material_name = curr_elem%material_name
  end subroutine init_element_effective_values

end module inheritance_engine
