module normalization
    use canonical_types
    implicit none
    save

contains

    function clean_double(val_str) result(val)
        character(len=*), intent(in) :: val_str
        real(8) :: val
        character(len=64) :: c
        integer :: iostat

        c = adjustl(trim(val_str))
        if (len_trim(c) == 0 .or. c == "-1.010100" .or. c == "-1" .or. &
            c == "-nan" .or. c == "nan" .or. c == "NaN") then
            val = MISSING_REAL
            return
        end if

        read(c, *, iostat=iostat) val
        if (iostat /= 0) then
            val = MISSING_REAL
        end if
    end function clean_double

    function clean_int(val_str) result(val)
        character(len=*), intent(in) :: val_str
        integer :: val
        real(8) :: temp_real
        character(len=64) :: c
        integer :: iostat

        c = adjustl(trim(val_str))
        if (len_trim(c) == 0 .or. c == "-1.010100" .or. c == "-1" .or. &
            c == "-nan" .or. c == "nan" .or. c == "NaN") then
            val = MISSING_INT
            return
        end if

        read(c, *, iostat=iostat) temp_real
        if (iostat /= 0) then
            val = MISSING_INT
        else
            val = int(temp_real)
        end if
    end function clean_int

    function clean_str(val_str) result(val)
        character(len=*), intent(in) :: val_str
        character(len=64) :: val
        character(len=64) :: c

        c = adjustl(trim(val_str))
        if (len_trim(c) == 0 .or. c == "-1.010100" .or. c == "-1" .or. &
            c == "-nan" .or. c == "nan" .or. c == "NaN") then
            val = ""
        else
            val = c
        end if
    end function clean_str

end module normalization
