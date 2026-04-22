module write_coords
  implicit none
  private
  public :: emit_coords
contains
  subroutine emit_coords(lun, config_file)
    integer, intent(in) :: lun
    character(len=*), intent(in) :: config_file
    integer :: clun, ierr, len_line
    character(len=256) :: line
    character(len=256) :: full_line
    logical :: in_section = .false.

    if ("COORDS" == "NODENAME") then
        write(lun, "(A)") "#$ NODENAME"
    else if ("COORDS" == "MISCEL_1") then
        write(lun, "(A)") "#$ MISCEL_1"
    else if ("COORDS" == "COORDS") then
        write(lun, "(A)") "#$ COORDS  "
    end if

    open(newunit=clun, file=config_file, status='old', action='read')
    do
      read(clun, '(A)', iostat=ierr) full_line
      if (ierr /= 0) then
          close(clun)
          return
      end if

      if (trim(full_line) == "[COORDS]") then
        in_section = .true.
        cycle
      else if (in_section .and. full_line(1:1) == "[") then
        in_section = .false.
        close(clun)
        return
      end if

      if (in_section) then
        ! config format is: NNN|content
        read(full_line(1:3), '(I3)') len_line
        line = full_line(5:256)
        if (len_line > 0) then
            write(lun, "(A)") line(1:len_line)
        else
            write(lun, "(A)") ""
        end if
      end if
    end do
    close(clun)
  end subroutine emit_coords
end module write_coords
