module write_bend_rigid_restrant
  use cii_model_types
  use format_utils
  implicit none

contains

  subroutine write_bend(iunit, num, bends)
    integer, intent(in) :: iunit
    integer, intent(in) :: num
    type(cii_bend_t), intent(in) :: bends(num)
    integer :: i

    write(iunit, "(A)") "#$ BEND"
    do i = 1, num
      write(iunit, "(I14, 2F17.5, 2F13.5)") int(bends(i)%btype), bends(i)%node1, bends(i)%radius, bends(i)%angle1, bends(i)%angle2
    end do
  end subroutine write_bend

  subroutine write_rigid(iunit, num, rigids)
    integer, intent(in) :: iunit
    integer, intent(in) :: num
    type(cii_rigid_t), intent(in) :: rigids(num)
    integer :: i
    write(iunit, "(A)") "#$ RIGID"
    do i = 1, num
      write(iunit, "(F13.5, A)") rigids(i)%weight, trim(rigids(i)%rtype)
    end do
  end subroutine write_rigid

  subroutine write_restrant(iunit, num, restrants)
    integer, intent(in) :: iunit
    integer, intent(in) :: num
    type(cii_restrain_t), intent(in) :: restrants(num)
    integer :: i
    write(iunit, "(A)") "#$ RESTRANT"
    do i = 1, num
      write(iunit, "(2F13.5, A)") restrants(i)%node, restrants(i)%rtype, trim(restrants(i)%tag)
    end do
  end subroutine write_restrant

end module write_bend_rigid_restrant
