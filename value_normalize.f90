module value_normalize
  implicit none

  real(8), parameter :: MISSING_REAL = -1.010100d0
  integer, parameter :: MISSING_INT = -1

  contains

  function is_missing_real(val) result(res)
    real(8), intent(in) :: val
    logical :: res
    ! Treat exact match or very close match to sentinel as missing
    res = (abs(val - MISSING_REAL) < 1.0d-6) .or. (val /= val) ! val /= val is a check for NaN
  end function is_missing_real

  function is_missing_int(val) result(res)
    integer, intent(in) :: val
    logical :: res
    res = (val == MISSING_INT)
  end function is_missing_int

  function parse_real(str) result(val)
    character(len=*), intent(in) :: str
    real(8) :: val
    character(len=64) :: trimmed_str
    integer :: iostat

    trimmed_str = adjustl(str)

    if (len_trim(trimmed_str) == 0) then
      val = MISSING_REAL
      return
    end if

    if (index(trimmed_str, "-nan") > 0 .or. &
        index(trimmed_str, "nan") > 0 .or. &
        index(trimmed_str, "NaN") > 0) then
      val = MISSING_REAL
      return
    end if

    read(trimmed_str, *, iostat=iostat) val
    if (iostat /= 0) then
      val = MISSING_REAL
    end if
  end function parse_real

end module value_normalize
