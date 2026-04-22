module write_nodename_mod
  use cii_model_types, only: cii_element_t, cii_restrain_t
  implicit none

contains

  subroutine write_nodename(elements, file_unit)
    type(cii_element_t), intent(in) :: elements(:)
    integer, intent(in) :: file_unit
    integer :: i, j

    write(file_unit, '(A)') '#$ NODENAME'

    do i = 1, size(elements)
      if (allocated(elements(i)%restrains)) then
        do j = 1, size(elements(i)%restrains)
          if (trim(elements(i)%restrains(j)%tag) /= '' .and. trim(elements(i)%restrains(j)%tag) /= '""') then
            ! Print tag in two lines format as seen in BM_CII.CII
            write(file_unit, '(A, A, A)') '                            ', trim(elements(i)%restrains(j)%tag), '                   '
            write(file_unit, '(A, A, A)') '  ', trim(elements(i)%restrains(j)%tag), '                                             '
          end if
        end do
      end if
    end do
  end subroutine write_nodename

end module write_nodename_mod
