module write_hanger_miscel
  implicit none
  private
  public :: emit_miscel_1
contains
  subroutine emit_miscel_1(lun, config_file)
    integer, intent(in) :: lun
    character(len=*), intent(in) :: config_file
    integer :: clun, ierr, len_line
    character(len=256) :: line
    character(len=256) :: full_line
    logical :: in_section = .false.

    if ("MISCEL_1" == "NODENAME") then
        write(lun, "(A)") "#$ NODENAME"
    else if ("MISCEL_1" == "MISCEL_1") then
        write(lun, "(A)") "#$ MISCEL_1"
    else if ("MISCEL_1" == "COORDS") then
        write(lun, "(A)") "#$ COORDS  "
    end if

    open(newunit=clun, file=config_file, status='old', action='read')
    do
      read(clun, '(A)', iostat=ierr) full_line
      if (ierr /= 0) then
          close(clun)
          return
      end if

      if (trim(full_line) == "[MISCEL_1]") then
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
  end subroutine emit_miscel_1
end module write_hanger_miscel
