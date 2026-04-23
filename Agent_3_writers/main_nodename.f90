program test_nodename
  use cii_model_types
  use write_nodename_mod
  implicit none

  type(cii_element_t), allocatable :: elements(:)
  integer :: file_unit

  allocate(elements(1))
  allocate(elements(1)%restrains(1))
  elements(1)%restrains(1)%tag = 'PS-123'

  open(newunit=file_unit, file='test_output_nodename.CII', status='replace')
  call write_nodename(elements, file_unit)
  close(file_unit)
end program test_nodename
