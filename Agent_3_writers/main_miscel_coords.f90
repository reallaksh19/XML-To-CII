program test_miscel_coords
  use cii_model_types
  use write_hanger_miscel_mod
  use write_coords_mod
  implicit none
  type(cii_element_t), allocatable :: elements(:)
  integer :: file_unit
  allocate(elements(1))
  open(newunit=file_unit, file='test_output_miscel.CII', status='replace')
  call write_hanger_miscel(elements, file_unit)
  call write_coords(file_unit)
  close(file_unit)
end program test_miscel_coords
