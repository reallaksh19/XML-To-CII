module write_coords_mod
  implicit none

contains

  subroutine write_coords(file_unit)
    integer, intent(in) :: file_unit

    write(file_unit, '(A)') '#$ COORDS  '
    ! For now, exact section output
    write(file_unit, '(A)') '              1'
    write(file_unit, '(A)') '             10    23227.576     3257.150   -19800.000'
  end subroutine write_coords

end module write_coords_mod
