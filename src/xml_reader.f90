module xml_reader
    use canonical_types
    use normalization
    implicit none
    save

contains

    subroutine get_attr(xml_str, attr_name, val_str)
        character(len=*), intent(in) :: xml_str
        character(len=*), intent(in) :: attr_name
        character(len=*), intent(out) :: val_str
        integer :: start_pos, end_pos
        character(len=64) :: search_str

        val_str = ""
        search_str = trim(attr_name) // '="'
        start_pos = index(xml_str, trim(search_str))
        if (start_pos > 0) then
            start_pos = start_pos + len_trim(search_str)
            end_pos = index(xml_str(start_pos:), '"')
            if (end_pos > 0) then
                val_str = xml_str(start_pos : start_pos + end_pos - 2)
            end if
        end if
    end subroutine get_attr

    subroutine read_xml_and_build_model(filename, model)
        character(len=*), intent(in) :: filename
        type(CanonicalModel), intent(out) :: model
        integer :: unit, iostat, file_size
        character(len=1), allocatable :: xml_data_arr(:)
        character(len=3000000) :: xml_data
        character(len=1024) :: val_str
        integer :: current_pos, num_elements
        integer :: elem_start, elem_end
        integer :: child_start, child_end, seq, idx
        character(len=30000) :: elem_str
        character(len=4000) :: child_str
        integer :: len_elem

        real(8) :: eff_dia = MISSING_REAL
        real(8) :: eff_wall = MISSING_REAL
        real(8) :: eff_insul = MISSING_REAL
        real(8) :: eff_corr = MISSING_REAL
        real(8) :: eff_temps(9) = MISSING_REAL
        real(8) :: eff_press(9) = MISSING_REAL
        real(8) :: eff_hydro = MISSING_REAL
        real(8) :: eff_mat_num = MISSING_REAL
        character(len=64) :: eff_mat_name = ""

        integer :: rigid_count, rest_count, sif_count, case_count
        real(8) :: t_node, t_weight, t_rad, t_a1, t_n1
        integer :: t_type_int
        character(len=64) :: t_type_str
        logical :: active

        open(newunit=unit, file=filename, status='old', access='stream', iostat=iostat)
        if (iostat /= 0) then
            print *, "Error opening file"
            return
        end if
        inquire(unit, size=file_size)
        allocate(xml_data_arr(file_size))
        read(unit) xml_data_arr
        close(unit)

        xml_data = ' '
        do current_pos = 1, file_size
            xml_data(current_pos:current_pos) = xml_data_arr(current_pos)
        end do
        deallocate(xml_data_arr)

        num_elements = 0
        current_pos = 1
        do while (.true.)
            idx = index(xml_data(current_pos:file_size), '<PIPINGELEMENT')
            if (idx == 0) goto 999
            num_elements = num_elements + 1
            current_pos = current_pos + idx + 14
        end do
999     continue

        model%num_elements = num_elements
        allocate(model%elements(num_elements))

        current_pos = 1
        seq = 1
        do while (.true.)
            idx = index(xml_data(current_pos:file_size), '<PIPINGELEMENT')
            if (idx == 0) goto 998
            elem_start = current_pos + idx - 1

            idx = index(xml_data(elem_start+15:file_size), '<PIPINGELEMENT')
            if (idx == 0) then
                elem_end = file_size
            else
                elem_end = elem_start + 15 + idx - 2
            end if

            idx = index(xml_data(elem_start:elem_end), '<UNITS>')
            if (idx > 0) elem_end = elem_start + idx - 2

            elem_str = ' '
            len_elem = elem_end - elem_start + 1
            if (len_elem > 30000) len_elem = 30000
            elem_str(1:len_elem) = xml_data(elem_start:elem_end)

            ! Extract PIPINGELEMENT attributes ONLY (from start to first '>')
            idx = index(elem_str, '>')
            child_str = ' '
            if (idx > 0) then
                child_str(1:idx) = elem_str(1:idx)
            else
                child_str = elem_str
            end if

            model%elements(seq)%seq = seq
            call get_attr(child_str, "FROM_NODE", val_str)
            model%elements(seq)%from_node = clean_double(val_str)
            call get_attr(child_str, "TO_NODE", val_str)
            model%elements(seq)%to_node = clean_double(val_str)

            call get_attr(child_str, "DIAMETER", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_dia = clean_double(val_str)
            call get_attr(child_str, "WALL_THICK", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_wall = clean_double(val_str)

            model%elements(seq)%effective_diameter = eff_dia
            model%elements(seq)%effective_wall_thk = eff_wall

            ! RIGID pass 1
            rigid_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<RIGID')
                if (idx == 0) goto 101
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</RIGID>')
                    if (idx > 0) then
                        child_end = child_start + idx + 7
                    else
                        goto 101
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "WEIGHT", val_str)
                t_weight = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_str = clean_str(val_str)

                active = .false.
                if (trim(t_type_str) == "Valve" .or. trim(t_type_str) == "Flange" .or. &
                    trim(t_type_str) == "Flange Pair" .or. trim(t_type_str) == "Flanged Valve" .or. &
                    trim(t_type_str) == "Unspecified") then
                    active = .true.
                else if (.not. is_missing(t_weight) .and. t_weight /= 0.0d0) then
                    active = .true.
                end if

                if (active) rigid_count = rigid_count + 1
                child_start = child_end + 1
            end do
101         continue
            model%elements(seq)%num_rigids = rigid_count
            if (rigid_count > 0) allocate(model%elements(seq)%rigids(rigid_count))

            ! RIGID pass 2
            rigid_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<RIGID')
                if (idx == 0) goto 102
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</RIGID>')
                    if (idx > 0) then
                        child_end = child_start + idx + 7
                    else
                        goto 102
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "WEIGHT", val_str)
                t_weight = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_str = clean_str(val_str)

                active = .false.
                if (trim(t_type_str) == "Valve" .or. trim(t_type_str) == "Flange" .or. &
                    trim(t_type_str) == "Flange Pair" .or. trim(t_type_str) == "Flanged Valve" .or. &
                    trim(t_type_str) == "Unspecified") then
                    active = .true.
                else if (.not. is_missing(t_weight) .and. t_weight /= 0.0d0) then
                    active = .true.
                end if

                if (active) then
                    rigid_count = rigid_count + 1
                    model%elements(seq)%rigids(rigid_count)%owner_seq = seq
                    model%elements(seq)%rigids(rigid_count)%weight = t_weight
                    model%elements(seq)%rigids(rigid_count)%type_str = t_type_str
                end if
                child_start = child_end + 1
            end do
102         continue

            ! RESTRAINT pass 1
            rest_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<RESTRAINT')
                if (idx == 0) goto 103
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</RESTRAINT>')
                    if (idx > 0) then
                        child_end = child_start + idx + 11
                    else
                        goto 103
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    rest_count = rest_count + 1
                end if
                child_start = child_end + 1
            end do
103         continue
            model%elements(seq)%num_restraints = rest_count
            if (rest_count > 0) allocate(model%elements(seq)%restraints(rest_count))

            ! RESTRAINT pass 2
            rest_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<RESTRAINT')
                if (idx == 0) goto 104
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</RESTRAINT>')
                    if (idx > 0) then
                        child_end = child_start + idx + 11
                    else
                        goto 104
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    rest_count = rest_count + 1
                    model%elements(seq)%restraints(rest_count)%owner_seq = seq
                    model%elements(seq)%restraints(rest_count)%node = t_node
                    model%elements(seq)%restraints(rest_count)%type_code = t_type_int
                end if
                child_start = child_end + 1
            end do
104         continue

            ! BEND
            model%elements(seq)%has_bend = .false.
            child_start = 1
            idx = index(elem_str(child_start:len_elem), '<BEND')
            if (idx > 0) then
                child_start = child_start + idx - 1
                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</BEND>')
                    if (idx > 0) child_end = child_start + idx + 6
                end if

                if (child_end > child_start) then
                    child_str = ' '
                    child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                    call get_attr(child_str, "RADIUS", val_str)
                    t_rad = clean_double(val_str)
                    call get_attr(child_str, "ANGLE1", val_str)
                    t_a1 = clean_double(val_str)
                    call get_attr(child_str, "NODE1", val_str)
                    t_n1 = clean_double(val_str)
                    if (.not. is_missing(t_rad) .and. .not. is_missing(t_a1) .and. .not. is_missing(t_n1)) then
                        model%elements(seq)%has_bend = .true.
                        model%elements(seq)%bend%radius = t_rad
                        model%elements(seq)%bend%angle1 = t_a1
                        model%elements(seq)%bend%node1 = t_n1
                    end if
                end if
            end if

            ! SIF pass 1
            sif_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<SIF')
                if (idx == 0) goto 105
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</SIF>')
                    if (idx > 0) then
                        child_end = child_start + idx + 5
                    else
                        goto 105
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    call get_attr(child_str, "TYPE", val_str)
                    if (trim(clean_str(val_str)) /= 'Input') then
                        sif_count = sif_count + 1
                    end if
                end if
                child_start = child_end + 1
            end do
105         continue
            model%elements(seq)%num_sifs = sif_count
            if (sif_count > 0) allocate(model%elements(seq)%sifs(sif_count))

            ! SIF pass 2
            sif_count = 0
            child_start = 1
            do while (.true.)
                idx = index(elem_str(child_start:len_elem), '<SIF')
                if (idx == 0) goto 106
                child_start = child_start + idx - 1

                idx = index(elem_str(child_start:len_elem), '/>')
                if (idx > 0) then
                    child_end = child_start + idx + 1
                else
                    idx = index(elem_str(child_start:len_elem), '</SIF>')
                    if (idx > 0) then
                        child_end = child_start + idx + 5
                    else
                        goto 106
                    end if
                end if

                child_str = ' '
                child_str(1:child_end - child_start + 1) = elem_str(child_start:child_end)
                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    call get_attr(child_str, "TYPE", val_str)
                    if (trim(clean_str(val_str)) /= 'Input') then
                        sif_count = sif_count + 1
                        model%elements(seq)%sifs(sif_count)%owner_seq = seq
                        model%elements(seq)%sifs(sif_count)%node = t_node
                        model%elements(seq)%sifs(sif_count)%type_code = t_type_int
                    end if
                end if
                child_start = child_end + 1
            end do
106         continue

            ! ALLOWABLE
            model%elements(seq)%has_allowable = .false.
            idx = index(elem_str, '<ALLOWABLESTRESS')
            if (idx > 0) model%elements(seq)%has_allowable = .true.

            current_pos = elem_end + 1
            seq = seq + 1
        end do
998     continue

    end subroutine read_xml_and_build_model

    function is_missing(val) result(res)
        real(8), intent(in) :: val
        logical :: res
        res = (val == MISSING_REAL)
    end function is_missing

end module xml_reader
