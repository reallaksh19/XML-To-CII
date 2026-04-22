module xml_parser
  use cii_types
  use normalization
  use inheritance
  use xml_parser_base
  use xml_parser_elements
  implicit none

contains

  subroutine parse_xml(filename, model)
    character(len=*), intent(in) :: filename
    type(cii_model_t), intent(inout) :: model

    integer :: iu, ios, i, j
    character(len=100000) :: line
    character(len=100000), allocatable :: tags(:)
    integer :: num_tags, max_tags
    character(len=100000) :: tag

    ! Max limits for simplicity
    type(cii_element_t), allocatable :: elems(:)
    integer :: n_elems, max_elems

    type(inheritance_state_t) :: state

    ! Temporaries
    type(cii_rigid_t) :: rig
    type(cii_restrain_t) :: rest
    type(cii_bend_t) :: bnd
    type(cii_sif_t) :: sf
    type(cii_allowable_case_t) :: acase

    integer :: n_rigids, n_rests, n_bends, n_sifs, n_allow
    logical :: in_element, in_allowable

    max_elems = 1000
    max_tags = 5000
    allocate(elems(max_elems))
    allocate(tags(max_tags))
    n_elems = 0
    in_element = .false.
    in_allowable = .false.

    model%count_elements = 0
    model%count_bends = 0
    model%count_rigids = 0
    model%count_restraints = 0
    model%count_allowable = 0
    model%count_sifs = 0

    n_allow = 0

    open(newunit=iu, file=filename, status='old', action='read', iostat=ios)
    if (ios /= 0) then
      print *, "Error opening file: ", trim(filename)
      return
    end if

    do
      read(iu, '(A)', iostat=ios) line
      if (ios /= 0) exit

      call split_xml_tags(line, tags, num_tags, max_tags)

      do j = 1, num_tags
        tag = tags(j)

        if (index(tag, "<PIPINGELEMENT") > 0) then
          n_elems = n_elems + 1
          in_element = .true.
          elems(n_elems)%seq = n_elems

          ! Reset allowables state for the new element
          n_allow = 0
          in_allowable = .false.

          ! Initialize allocations
          allocate(elems(n_elems)%rigids(10))
          allocate(elems(n_elems)%restraints(10))
          allocate(elems(n_elems)%bends(1))
          allocate(elems(n_elems)%sifs(10))

          n_rigids = 0
          n_rests = 0
          n_bends = 0
          n_sifs = 0

          call parse_element_attributes(tag, elems(n_elems))
        end if

        if (in_element) then
          if (index(tag, "<RIGID") > 0) then
            n_rigids = n_rigids + 1
            rig = cii_rigid_t(MISSING_REAL, "")
            call parse_rigid(tag, rig)

            ! Active-slot filter for RIGID
            if (rig%weight /= MISSING_REAL .or. (len_trim(rig%rtype) > 0 .and. rig%rtype /= "Unspecified")) then
               elems(n_elems)%rigids(n_rigids) = rig
               model%count_rigids = model%count_rigids + 1
            else
               n_rigids = n_rigids - 1
            end if
          end if

          if (index(tag, "<RESTRAINT") > 0) then
            n_rests = n_rests + 1
            rest = cii_restrain_t(MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL, 0.0d0, 0.0d0, 0.0d0, "")
            call parse_restraint(tag, rest)

            ! Active-slot filter for RESTRAINT: Node AND Type must be valid
            if (rest%node /= MISSING_REAL .and. rest%rtype /= MISSING_REAL) then
               elems(n_elems)%restraints(n_rests) = rest
               model%count_restraints = model%count_restraints + 1
            else
               n_rests = n_rests - 1
            end if
          end if

          if (index(tag, "<BEND") > 0) then
            n_bends = n_bends + 1
            bnd = cii_bend_t(MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL)
            call parse_bend(tag, bnd)

            ! Active-slot filter for BEND: Radius and Node1 must be valid
            if (bnd%radius /= MISSING_REAL .and. bnd%node1 /= MISSING_REAL) then
               elems(n_elems)%bends(n_bends) = bnd
               model%count_bends = model%count_bends + 1
            else
               n_bends = n_bends - 1
            end if
          end if

          if (index(tag, "<SIF") > 0 .and. index(tag, "<SIF_") == 0) then
            n_sifs = n_sifs + 1
            sf = cii_sif_t(MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL)
            call parse_sif(tag, sf)

            ! Active-slot filter for SIF: Node and Stype must be valid
            if (sf%node /= MISSING_REAL .and. sf%stype /= MISSING_REAL) then
               elems(n_elems)%sifs(n_sifs) = sf
               model%count_sifs = model%count_sifs + 1
            else
               n_sifs = n_sifs - 1
            end if
          end if

          if (index(tag, "<ALLOWABLESTRESS") > 0) then
            if (n_allow == 0) then
               model%count_allowable = model%count_allowable + 1
               n_allow = 1
               allocate(elems(n_elems)%allowable(1))
               allocate(elems(n_elems)%allowable(1)%cases(9))
            end if
            in_allowable = .true.
          end if

          if (in_allowable .and. index(tag, "<CASE") > 0) then
            acase = cii_allowable_case_t(MISSING_INT, MISSING_REAL, MISSING_REAL, MISSING_REAL, &
              MISSING_REAL, MISSING_REAL, MISSING_REAL)
            call parse_allowable_case(tag, acase)
            if (acase%num /= MISSING_INT .and. acase%num <= 9 .and. acase%num >= 1) then
               elems(n_elems)%allowable(1)%cases(acase%num) = acase
            end if
          end if

          if (in_allowable .and. index(tag, "</ALLOWABLESTRESS>") > 0) then
             in_allowable = .false.
          end if
        end if

        if (index(tag, "</PIPINGELEMENT>") > 0 .or. &
           (index(tag, "/>") > 0 .and. in_element .and. index(tag, "<PIPINGELEMENT") > 0)) then
           ! If it's a self-closing piping element, we handle it here
           if (index(tag, "</PIPINGELEMENT>") > 0 .or. &
              (index(tag, "<PIPINGELEMENT") > 0 .and. index(tag, "/>") > 0)) then
               call apply_inheritance(elems(n_elems), state)
               in_element = .false.
           end if
        end if
      end do
    end do

    close(iu)

    model%count_elements = n_elems

    ! Assign elements to the model correctly
    allocate(model%elements(n_elems))
    do i = 1, n_elems
       model%elements(i) = elems(i)
    end do

  end subroutine parse_xml

end module xml_parser
