module write_sif_allowbls_units
  use cii_model_types
  use format_utils
  implicit none

contains

  subroutine write_sif_tees(iunit, num, sifs)
    integer, intent(in) :: iunit
    integer, intent(in) :: num
    type(cii_sif_t), intent(in) :: sifs(num)
    integer :: i
    write(iunit, "(A)") "#$ SIF&TEES"
    do i = 1, num
      write(iunit, "(I14, 2F17.5)") int(sifs(i)%stype), sifs(i)%node, sifs(i)%sif_in
    end do
  end subroutine write_sif_tees

  subroutine write_allowbls(iunit, num)
    integer, intent(in) :: iunit
    integer, intent(in) :: num
    write(iunit, "(A)") "#$ ALLOWBLS"
    if (num > 0) then
      write(iunit, "(A)") "    1"
    end if
  end subroutine write_allowbls

  subroutine write_units(iunit)
    integer, intent(in) :: iunit
    write(iunit, "(A)") "#$ UNITS"
    write(iunit, "(A)") "    21"
    write(iunit, "(A)") "           1LENGTH       mm.                       25.400000"
    write(iunit, "(A)") "           2FORCE        N.                         4.448000"
    write(iunit, "(A)") "           3MASS-DYNAMICSKg.                        0.453590"
    write(iunit, "(A)") "           4MOMENT-INPUT N.m.                       0.112980"
    write(iunit, "(A)") "           5MOMENT-OUTPUTN.m.                       0.112980"
    write(iunit, "(A)") "           6STRESS       MPa                        0.006895"
    write(iunit, "(A)") "           7TEMP         C                          0.555600"
    write(iunit, "(A)") "           8PRESSURE     bars                       0.068946"
    write(iunit, "(A)") "           9EMOD         MPa                        0.006895"
    write(iunit, "(A)") "          10PDENS        kg. / cu.cm.               0.027680"
    write(iunit, "(A)") "          11IDENS        kg. / cu.cm.               0.027680"
    write(iunit, "(A)") "          12FDENS        kg. / cu.cm.               0.027680"
    write(iunit, "(A)") "          13TRANS_STIFF  N. / cm.                   1.751200"
    write(iunit, "(A)") "          14ROTL_STIFF   N.m. / deg                 0.112980"
    write(iunit, "(A)") "          15UNIF_LOAD    N. / cm.                   1.751200"
    write(iunit, "(A)") "          16G_LOAD       g's                        1.000000"
    write(iunit, "(A)") "          17WIND_LOAD    KPa                        6.894600"
    write(iunit, "(A)") "          18ELEVATION    m.                         0.025400"
    write(iunit, "(A)") "          19COMPOUND_LENGmm.                       25.400000"
    write(iunit, "(A)") "          20DIAMETER     mm.                       25.400000"
    write(iunit, "(A)") "          21THICKNESS    mm.                       25.400000"
  end subroutine write_units

end module write_sif_allowbls_units
