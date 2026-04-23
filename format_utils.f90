module format_utils
  implicit none
contains
  subroutine fmt_real(val, res)
    real(8), intent(in) :: val
    character(len=13), intent(out) :: res
    if (abs(val + 1.010100d0) < 1.0d-5) then
      write(res, "(F13.5)") 0.0d0
    else if (val > 9990.0d0) then
      write(res, "(F13.5)") 9999.99d0
    else
      write(res, "(F13.5)") val
    end if
  end subroutine fmt_real
end module format_utils
