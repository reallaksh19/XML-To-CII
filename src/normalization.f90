module normalization
  use cii_types, only: MISSING_REAL, MISSING_INT
  implicit none

contains

  function normalize_real_str(str) result(val)
    character(len=*), intent(in) :: str
    real(8) :: val
    character(len=64) :: clean_str
    integer :: ios

    clean_str = trim(adjustl(str))

    if (len_trim(clean_str) == 0 .or. &
        index(clean_str, "-nan") > 0 .or. &
        index(clean_str, "nan") > 0 .or. &
        index(clean_str, "NaN") > 0) then
      val = MISSING_REAL
      return
    end if

    read(clean_str, *, iostat=ios) val
    if (ios /= 0) then
      val = MISSING_REAL
    else
      ! Check for the sentinel value
      if (abs(val - (-1.010100d0)) < 1.0d-6) then
        val = MISSING_REAL
      end if
    end if
  end function normalize_real_str

  function normalize_int_str(str) result(val)
    character(len=*), intent(in) :: str
    integer :: val
    character(len=64) :: clean_str
    integer :: ios

    clean_str = trim(adjustl(str))

    if (len_trim(clean_str) == 0 .or. &
        index(clean_str, "-nan") > 0 .or. &
        index(clean_str, "nan") > 0 .or. &
        index(clean_str, "NaN") > 0) then
      val = MISSING_INT
      return
    end if

    read(clean_str, *, iostat=ios) val
    if (ios /= 0) then
      val = MISSING_INT
    else
      if (val == -1) then
        val = MISSING_INT
      end if
    end if
  end function normalize_int_str

  function normalize_string(str) result(clean_str)
    character(len=*), intent(in) :: str
    character(len=64) :: clean_str

    clean_str = trim(adjustl(str))
  end function normalize_string

end module normalization
