module write_elements
  use cii_model_types
  use format_utils
  implicit none

contains

  subroutine write_element(iunit, el, rigid_flags, restraint_flags, bend_flags, sif_flags)
    integer, intent(in) :: iunit
    type(cii_element_t), intent(in) :: el
    integer, intent(in) :: rigid_flags(6)
    integer, intent(in) :: restraint_flags(6)
    integer, intent(in) :: bend_flags(3)
    integer, intent(in) :: sif_flags(6)

    character(len=13) :: c_fn, c_tn, c_dx, c_dy, c_dz, c_dia
    character(len=13) :: c_wt, c_it, c_ca, c_t1, c_t2, c_t3
    character(len=13) :: c_t4, c_t5, c_t6, c_t7, c_t8, c_t9
    character(len=13) :: c_p1, c_p2, c_p3, c_p4, c_p5, c_p6
    character(len=13) :: c_p7, c_p8, c_p9, c_hp, c_em, c_pois
    character(len=13) :: c_hm1, c_hm2, c_hm3, c_hm4, c_hm5, c_hm6
    character(len=13) :: c_hm7, c_hm8, c_hm9, c_pd, c_id, c_fd
    character(len=13) :: c_rd, c_rt, c_cd, c_ct, c_icu
    character(len=13) :: c_mtp, c_mtm, c_sw

    call fmt_real(el%from_node, c_fn)
    call fmt_real(el%to_node, c_tn)
    call fmt_real(el%dx, c_dx)
    call fmt_real(el%dy, c_dy)
    call fmt_real(el%dz, c_dz)
    call fmt_real(el%diameter, c_dia)
    write(iunit, "(6A)") c_fn, c_tn, c_dx, c_dy, c_dz, c_dia

    call fmt_real(el%wall_thk, c_wt)
    call fmt_real(el%insul_thk, c_it)
    call fmt_real(el%corr_allow, c_ca)
    call fmt_real(el%temp_exp(1), c_t1)
    call fmt_real(el%temp_exp(2), c_t2)
    call fmt_real(el%temp_exp(3), c_t3)
    write(iunit, "(6A)") c_wt, c_it, c_ca, c_t1, c_t2, c_t3

    call fmt_real(el%temp_exp(4), c_t4)
    call fmt_real(el%temp_exp(5), c_t5)
    call fmt_real(el%temp_exp(6), c_t6)
    call fmt_real(el%temp_exp(7), c_t7)
    call fmt_real(el%temp_exp(8), c_t8)
    call fmt_real(el%temp_exp(9), c_t9)
    write(iunit, "(6A)") c_t4, c_t5, c_t6, c_t7, c_t8, c_t9

    call fmt_real(el%pressure(1), c_p1)
    call fmt_real(el%pressure(2), c_p2)
    call fmt_real(el%pressure(3), c_p3)
    call fmt_real(el%pressure(4), c_p4)
    call fmt_real(el%pressure(5), c_p5)
    call fmt_real(el%pressure(6), c_p6)
    write(iunit, "(6A)") c_p1, c_p2, c_p3, c_p4, c_p5, c_p6

    call fmt_real(el%pressure(7), c_p7)
    call fmt_real(el%pressure(8), c_p8)
    call fmt_real(el%pressure(9), c_p9)
    call fmt_real(el%hydro_pressure, c_hp)
    call fmt_real(el%modulus, c_em)
    call fmt_real(el%poissons, c_pois)
    write(iunit, "(6A)") c_p7, c_p8, c_p9, c_hp, c_em, c_pois

    write(iunit, "(6E13.6)") el%hot_mod(1), el%hot_mod(2), el%hot_mod(3), el%hot_mod(4), el%hot_mod(5), el%hot_mod(6)
    write(iunit, "(6F13.5)") el%hot_mod(7), el%hot_mod(8), el%hot_mod(9), el%pipe_density, el%insul_density, el%fluid_density
    write(iunit, "(6F13.5)") el%refractory_density, el%refractory_thk, el%cladding_den, el%cladding_thk, &
                             el%insul_clad_unit_weight, 9999.99d0
    write(iunit, "(6F13.5)") el%material_num, el%mill_tol_plus, el%mill_tol_minus, el%seam_weld, 0.0d0, 0.0d0

    ! Flags
    write(iunit, "(A)") "           0 "
    if (len_trim(el%name) > 0) then
      write(iunit, "(A, A)") "           7 ", trim(el%name)
    else
      write(iunit, "(A)") "           0 "
    end if
    write(iunit, "(A)") "             -1           -1"
    write(iunit, "(6I13)") rigid_flags(1:6)
    write(iunit, "(6I13)") restraint_flags(1:6)
    write(iunit, "(3I13)") bend_flags(1:3)
    write(iunit, "(6I13)") sif_flags(1:6)
  end subroutine write_element

end module write_elements
