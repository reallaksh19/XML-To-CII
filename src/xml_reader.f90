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

    ! Safely find the end of an XML tag, accounting for attributes containing ">"
    ! and distinguishing between self-closing <TAG ... /> and paired <TAG>...</TAG>
    subroutine get_element_bounds(xml_str, tag_name, start_pos, end_pos)
        character(len=*), intent(in) :: xml_str
        character(len=*), intent(in) :: tag_name
        integer, intent(out) :: start_pos, end_pos
        integer :: close_bracket, end_tag
        character(len=64) :: open_tag, close_str

        start_pos = 0
        end_pos = 0

        open_tag = '<' // trim(tag_name)
        start_pos = index(xml_str, trim(open_tag))
        if (start_pos == 0) return

        ! Find the closing bracket of the opening tag
        close_bracket = index(xml_str(start_pos:), '>')
        if (close_bracket == 0) then
            start_pos = 0
            return
        end if

        ! Check if it was self-closing />
        if (xml_str(start_pos + close_bracket - 2 : start_pos + close_bracket - 1) == '/>') then
            end_pos = start_pos + close_bracket - 1
            return
        end if

        ! Not self closing, find the matching </tag_name>
        close_str = '</' // trim(tag_name) // '>'
        end_tag = index(xml_str(start_pos:), trim(close_str))
        if (end_tag > 0) then
            end_pos = start_pos + end_tag + len_trim(close_str) - 2
        else
            ! Malformed or not found
            end_pos = start_pos + close_bracket - 1
        end if
    end subroutine get_element_bounds

    subroutine read_xml_and_build_model(filename, model)
        character(len=*), intent(in) :: filename
        type(CanonicalModel), intent(out) :: model
        integer :: unit, iostat, file_size
        character(len=1), allocatable :: xml_data_arr(:)
        character(len=3000000) :: xml_data
        character(len=1024) :: val_str
        integer :: current_pos, num_elements
        integer :: elem_start, elem_end
        integer :: child_start, seq, idx
        character(len=30000) :: elem_str
        character(len=4000) :: child_str
        character(len=500) :: case_str
        integer :: len_elem, c_end, c_start

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
            call get_element_bounds(xml_data(current_pos:file_size), 'PIPINGELEMENT', elem_start, elem_end)
            if (elem_start == 0) exit
            num_elements = num_elements + 1
            current_pos = current_pos + elem_end
        end do

        model%num_elements = num_elements
        allocate(model%elements(num_elements))

        current_pos = 1
        seq = 1
        do while (.true.)
            call get_element_bounds(xml_data(current_pos:file_size), 'PIPINGELEMENT', elem_start, elem_end)
            if (elem_start == 0) exit

            elem_str = ' '
            len_elem = elem_end - elem_start + 1
            if (len_elem > 30000) len_elem = 30000
            elem_str(1:len_elem) = xml_data(current_pos + elem_start - 1 : current_pos + elem_end - 1)

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
            call get_attr(child_str, "INSUL_THICK", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_insul = clean_double(val_str)
            call get_attr(child_str, "CORR_ALLOW", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_corr = clean_double(val_str)
            call get_attr(child_str, "HYDRO_PRESSURE", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_hydro = clean_double(val_str)
            call get_attr(child_str, "MATERIAL_NUM", val_str)
            if (.not. is_missing(clean_double(val_str))) eff_mat_num = clean_double(val_str)
            call get_attr(child_str, "MATERIAL_NAME", val_str)
            if (len_trim(clean_str(val_str)) > 0) eff_mat_name = clean_str(val_str)
            call get_attr(child_str, "NAME", val_str)
            model%elements(seq)%name = clean_str(val_str)

            model%elements(seq)%effective_diameter = eff_dia
            model%elements(seq)%effective_wall_thk = eff_wall
            model%elements(seq)%effective_insul_thk = eff_insul
            model%elements(seq)%effective_corr_allow = eff_corr
            model%elements(seq)%effective_hydro_pressure = eff_hydro
            model%elements(seq)%material_num = eff_mat_num
            model%elements(seq)%material_name = eff_mat_name

            ! RIGID pass 1
            rigid_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'RIGID', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

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
                child_start = child_start + c_end
            end do
            model%elements(seq)%num_rigids = rigid_count
            if (rigid_count > 0) allocate(model%elements(seq)%rigids(rigid_count))

            ! RIGID pass 2
            rigid_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'RIGID', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

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
                child_start = child_start + c_end
            end do

            ! RESTRAINT pass 1
            rest_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'RESTRAINT', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    rest_count = rest_count + 1
                end if
                child_start = child_start + c_end
            end do
            model%elements(seq)%num_restraints = rest_count
            if (rest_count > 0) allocate(model%elements(seq)%restraints(rest_count))

            ! RESTRAINT pass 2
            rest_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'RESTRAINT', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                call get_attr(child_str, "TYPE", val_str)
                t_type_int = clean_int(val_str)

                if (.not. is_missing(t_node) .and. t_type_int /= MISSING_INT) then
                    rest_count = rest_count + 1
                    model%elements(seq)%restraints(rest_count)%owner_seq = seq
                    model%elements(seq)%restraints(rest_count)%node = t_node
                    model%elements(seq)%restraints(rest_count)%type_code = t_type_int
                    call get_attr(child_str, "STIFFNESS", val_str)
                    model%elements(seq)%restraints(rest_count)%stiffness = clean_double(val_str)
                    call get_attr(child_str, "GAP", val_str)
                    model%elements(seq)%restraints(rest_count)%gap = clean_double(val_str)
                    call get_attr(child_str, "FRIC_COEF", val_str)
                    model%elements(seq)%restraints(rest_count)%fric_coef = clean_double(val_str)
                    call get_attr(child_str, "CNODE", val_str)
                    model%elements(seq)%restraints(rest_count)%cnode = clean_double(val_str)
                    call get_attr(child_str, "XCOSINE", val_str)
                    model%elements(seq)%restraints(rest_count)%xcos = clean_double(val_str)
                    call get_attr(child_str, "YCOSINE", val_str)
                    model%elements(seq)%restraints(rest_count)%ycos = clean_double(val_str)
                    call get_attr(child_str, "ZCOSINE", val_str)
                    model%elements(seq)%restraints(rest_count)%zcos = clean_double(val_str)
                    call get_attr(child_str, "TAG", val_str)
                    model%elements(seq)%restraints(rest_count)%tag = clean_str(val_str)
                end if
                child_start = child_start + c_end
            end do

            ! BEND
            model%elements(seq)%has_bend = .false.
            call get_element_bounds(elem_str, 'BEND', c_start, c_end)
            if (c_start > 0) then
                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(c_start : c_end)
                call get_attr(child_str, "RADIUS", val_str)
                t_rad = clean_double(val_str)
                call get_attr(child_str, "ANGLE1", val_str)
                t_a1 = clean_double(val_str)
                call get_attr(child_str, "NODE1", val_str)
                t_n1 = clean_double(val_str)
                if (.not. is_missing(t_rad) .and. .not. is_missing(t_a1) .and. .not. is_missing(t_n1)) then
                    model%elements(seq)%has_bend = .true.
                    model%elements(seq)%bend%owner_seq = seq
                    model%elements(seq)%bend%radius = t_rad
                    model%elements(seq)%bend%angle1 = t_a1
                    model%elements(seq)%bend%node1 = t_n1
                    call get_attr(child_str, "TYPE", val_str)
                    model%elements(seq)%bend%type_code = clean_int(val_str)
                    call get_attr(child_str, "ANGLE2", val_str)
                    model%elements(seq)%bend%angle2 = clean_double(val_str)
                    call get_attr(child_str, "NODE2", val_str)
                    model%elements(seq)%bend%node2 = clean_double(val_str)
                    call get_attr(child_str, "ANGLE3", val_str)
                    model%elements(seq)%bend%angle3 = clean_double(val_str)
                    call get_attr(child_str, "NODE3", val_str)
                    model%elements(seq)%bend%node3 = clean_double(val_str)
                    call get_attr(child_str, "NUM_MITER", val_str)
                    model%elements(seq)%bend%num_miter = clean_double(val_str)
                    call get_attr(child_str, "FITTINGTHICKNESS", val_str)
                    model%elements(seq)%bend%fitting_thickness = clean_double(val_str)
                    call get_attr(child_str, "KFACTOR", val_str)
                    model%elements(seq)%bend%kfactor = clean_double(val_str)
                end if
            end if

            ! SIF pass 1
            sif_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'SIF', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

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
                child_start = child_start + c_end
            end do
            model%elements(seq)%num_sifs = sif_count
            if (sif_count > 0) allocate(model%elements(seq)%sifs(sif_count))

            ! SIF pass 2
            sif_count = 0
            child_start = 1
            do while (.true.)
                call get_element_bounds(elem_str(child_start:len_elem), 'SIF', c_start, c_end)
                if (c_start == 0) exit

                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(child_start + c_start - 1 : child_start + c_end - 1)

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
                        call get_attr(child_str, "SIF_IN", val_str)
                        model%elements(seq)%sifs(sif_count)%sif_in = clean_double(val_str)
                        call get_attr(child_str, "SIF_OUT", val_str)
                        model%elements(seq)%sifs(sif_count)%sif_out = clean_double(val_str)
                        call get_attr(child_str, "SIF_TORSION", val_str)
                        model%elements(seq)%sifs(sif_count)%sif_torsion = clean_double(val_str)
                        call get_attr(child_str, "SIF_AXIAL", val_str)
                        model%elements(seq)%sifs(sif_count)%sif_axial = clean_double(val_str)
                        call get_attr(child_str, "SIF_PRESSURE", val_str)
                        model%elements(seq)%sifs(sif_count)%sif_pressure = clean_double(val_str)
                    end if
                end if
                child_start = child_start + c_end
            end do

            ! HANGER
            model%elements(seq)%has_hanger = .false.
            call get_element_bounds(elem_str, 'HANGER', c_start, c_end)
            if (c_start > 0) then
                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(c_start : c_end)
                call get_attr(child_str, "NODE", val_str)
                t_node = clean_double(val_str)
                if (.not. is_missing(t_node)) then
                    model%elements(seq)%has_hanger = .true.
                    model%elements(seq)%hanger%owner_seq = seq
                    model%elements(seq)%hanger%node = t_node
                    call get_attr(child_str, "CNODE", val_str)
                    model%elements(seq)%hanger%cnode = clean_double(val_str)
                    call get_attr(child_str, "LOAD_VAR", val_str)
                    model%elements(seq)%hanger%load_var = clean_double(val_str)
                    call get_attr(child_str, "HGR_TABLE", val_str)
                    model%elements(seq)%hanger%hgr_table = clean_int(val_str)
                    call get_attr(child_str, "SHORT_RANGE", val_str)
                    model%elements(seq)%hanger%short_range = clean_int(val_str)
                    call get_attr(child_str, "TAG", val_str)
                    model%elements(seq)%hanger%tag = clean_str(val_str)
                end if
            end if

            ! ALLOWABLE
            model%elements(seq)%has_allowable = .false.
            call get_element_bounds(elem_str, 'ALLOWABLESTRESS', c_start, c_end)
            if (c_start > 0) then
                model%elements(seq)%has_allowable = .true.
                child_str = ' '
                child_str(1:c_end - c_start + 1) = elem_str(c_start : c_end)

                model%elements(seq)%allowable%owner_seq = seq
                call get_attr(child_str, "HOOP_STRESS_FACTOR", val_str)
                model%elements(seq)%allowable%hoop_stress_factor = clean_double(val_str)
                call get_attr(child_str, "COLD_ALLOW", val_str)
                model%elements(seq)%allowable%cold_allow = clean_double(val_str)
                call get_attr(child_str, "EFF", val_str)
                model%elements(seq)%allowable%eff = clean_double(val_str)
                call get_attr(child_str, "SY", val_str)
                model%elements(seq)%allowable%sy = clean_double(val_str)
                call get_attr(child_str, "SU", val_str)
                model%elements(seq)%allowable%su = clean_double(val_str)
                call get_attr(child_str, "PIPING_CODE", val_str)
                model%elements(seq)%allowable%piping_code = clean_int(val_str)

                ! CASES pass 1
                case_count = 0
                child_start = 1
                do while (.true.)
                    call get_element_bounds(child_str(child_start:), 'CASE', idx, c_end)
                    if (idx == 0) exit
                    case_count = case_count + 1
                    child_start = child_start + c_end
                end do

                model%elements(seq)%allowable%num_cases = case_count
                if (case_count > 0) allocate(model%elements(seq)%allowable%cases(case_count))

                ! CASES pass 2
                case_count = 0
                child_start = 1
                do while (.true.)
                    call get_element_bounds(child_str(child_start:), 'CASE', idx, c_end)
                    if (idx == 0) exit

                    case_str = ' '
                    case_str(1:c_end - idx + 1) = child_str(child_start + idx - 1 : child_start + c_end - 1)

                    case_count = case_count + 1
                    call get_attr(case_str, "NUM", val_str)
                    model%elements(seq)%allowable%cases(case_count)%num = clean_int(val_str)
                    call get_attr(case_str, "HOT_ALLOW", val_str)
                    model%elements(seq)%allowable%cases(case_count)%hot_allow = clean_double(val_str)
                    call get_attr(case_str, "HOT_SY", val_str)
                    model%elements(seq)%allowable%cases(case_count)%hot_sy = clean_double(val_str)
                    call get_attr(case_str, "HOT_SU", val_str)
                    model%elements(seq)%allowable%cases(case_count)%hot_su = clean_double(val_str)
                    call get_attr(case_str, "CYC_RED_FACTOR", val_str)
                    model%elements(seq)%allowable%cases(case_count)%cyc_red_factor = clean_double(val_str)
                    call get_attr(case_str, "BUTTWELDCYCLES", val_str)
                    model%elements(seq)%allowable%cases(case_count)%buttweldcycles = clean_double(val_str)
                    call get_attr(case_str, "BUTTWELDSTRESS", val_str)
                    model%elements(seq)%allowable%cases(case_count)%buttweldstress = clean_double(val_str)

                    child_start = child_start + c_end
                end do
            end if

            current_pos = current_pos + elem_end
            seq = seq + 1
        end do

    end subroutine read_xml_and_build_model

    function is_missing(val) result(res)
        real(8), intent(in) :: val
        logical :: res
        res = (val == MISSING_REAL)
    end function is_missing

end module xml_reader
