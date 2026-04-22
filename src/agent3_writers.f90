module agent3_writers
    implicit none

contains

    subroutine write_nodename(unit, tag)
        integer, intent(in) :: unit
        character(len=*), intent(in) :: tag

        write(unit, '(A)') '#$ NODENAME'
        if (trim(tag) /= '') then
            ! Print with 28 spaces indent to the tag
            write(unit, '(A28,A)') '                            ', trim(tag)
            ! Print with 2 spaces indent
            write(unit, '(A2,A)') '  ', trim(tag)
        else
            write(unit, '(A)') 'UNRESOLVED_GAP'
        end if
    end subroutine write_nodename

    subroutine write_miscel_1(unit)
        integer, intent(in) :: unit
        write(unit, '(A)') '#$ MISCEL_1'
        write(unit, '(A)') 'UNRESOLVED_GAP'
    end subroutine write_miscel_1

    subroutine write_coords(unit)
        integer, intent(in) :: unit
        write(unit, '(A)') '#$ COORDS  '
        write(unit, '(A)') 'UNRESOLVED_GAP'
    end subroutine write_coords

end module agent3_writers
