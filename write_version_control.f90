module write_version_control
  use cii_model_types
  implicit none

contains

  subroutine write_version(iunit)
    integer, intent(in) :: iunit
    ! The version header exactly matches BM_CII.CII
    write(iunit, "(A)") "#$ VERSION "
    write(iunit, "(A)") "    5.00000      11.0000        1256"
    write(iunit, "(A)") "    PROJECT:                                                                 "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "    CLIENT :                                                                 "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "    ANALYST:                                                                 "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "    NOTES  :                                                                 "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "                                                                             "
    write(iunit, "(A)") "  Data generated by CAESAR II/CADWorx/PIPE interface -- Ver 2002, 5/2002.    "
  end subroutine write_version

  subroutine write_control(iunit, numelt, numbend, numrigid, numrest, numallow, numisect)
    integer, intent(in) :: iunit
    integer, intent(in) :: numelt, numbend, numrigid, numrest, numallow, numisect

    write(iunit, "(A)") "#$ CONTROL "

    ! First line
    write(iunit, "(6I13)") numelt, 0, 1, 2, 0, 0
    ! Second line
    write(iunit, "(6I13)") numbend, numrigid, 0, numrest, 0, 0
    ! Third line
    write(iunit, "(6I13)") 0, 0, 0, numallow, numisect, 0
    ! Fourth line
    write(iunit, "(I13)") 0

  end subroutine write_control

end module write_version_control
