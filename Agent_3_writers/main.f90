program test_harness
  use cii_model_types
  use write_nodename_mod
  use write_hanger_miscel_mod
  use write_coords_mod
  implicit none

  type(cii_element_t), allocatable :: elements(:)
  integer :: file_unit

  ! Setup dummy data based on XML profile sample PS-456
  allocate(elements(1))
  allocate(elements(1)%restrains(1))
  elements(1)%restrains(1)%tag = 'PS-456'

  open(newunit=file_unit, file='test_output.CII', status='replace')

  call write_nodename(elements, file_unit)
  call write_hanger_miscel(elements, file_unit)
  call write_coords(file_unit)

  close(file_unit)

  print *, "Test output generated in test_output.CII"
end program test_harness
