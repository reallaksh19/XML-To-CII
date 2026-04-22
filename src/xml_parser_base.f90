module xml_parser_base
  implicit none

contains

  subroutine extract_attribute(line, attr_name, attr_val, found)
    character(len=*), intent(in) :: line
    character(len=*), intent(in) :: attr_name
    character(len=*), intent(out) :: attr_val
    logical, intent(out) :: found

    integer :: start_idx, end_idx
    character(len=256) :: search_str

    search_str = trim(attr_name) // '="'
    start_idx = index(line, trim(search_str))

    if (start_idx > 0) then
      start_idx = start_idx + len_trim(search_str)
      end_idx = index(line(start_idx:), '"')
      if (end_idx > 0) then
        attr_val = line(start_idx : start_idx + end_idx - 2)
        found = .true.
        return
      end if
    end if

    found = .false.
    attr_val = ""
  end subroutine extract_attribute

  subroutine split_xml_tags(line, tags, num_tags, max_tags)
    character(len=*), intent(in) :: line
    integer, intent(in) :: max_tags
    character(len=100000), intent(out) :: tags(max_tags)
    integer, intent(out) :: num_tags

    integer :: i, start_idx
    logical :: in_tag

    num_tags = 0
    in_tag = .false.
    start_idx = 1

    do i = 1, len_trim(line)
       if (line(i:i) == '<') then
          start_idx = i
          in_tag = .true.
       else if (line(i:i) == '>') then
          if (in_tag .and. num_tags < max_tags) then
             num_tags = num_tags + 1
             tags(num_tags) = line(start_idx:i)
          end if
          in_tag = .false.
       end if
    end do
  end subroutine split_xml_tags

end module xml_parser_base
