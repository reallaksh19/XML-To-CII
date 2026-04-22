module write_hanger_miscel_mod
  use cii_model_types, only: cii_element_t, cii_hanger_t
  implicit none

contains

  subroutine write_hanger_miscel(elements, file_unit)
    type(cii_element_t), intent(in) :: elements(:)
    integer, intent(in) :: file_unit

    write(file_unit, '(A)') '#$ MISCEL_1'

    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '    106.000      106.000      106.000      106.000    '
    write(file_unit, '(A)') '              1  25.0000         0.000000  9999.99      1.00000      1.00000    '
    write(file_unit, '(A)') '              1            0            1            1            1'
    write(file_unit, '(A)') '            205'
    write(file_unit, '(A)') '       0.000000  25.0000         0.000000     0.000000     0.000000     0.000000'
    write(file_unit, '(A)') '       0.000000  9999.99      1.00000         0.000000     0.000000'
    write(file_unit, '(A)') '           0 '
    write(file_unit, '(A)') '           0 '
    write(file_unit, '(A)') '              0            0            0            0'
    write(file_unit, '(A)') '              0'
    write(file_unit, '(A)') '              0'
    write(file_unit, '(A)') '              1'
    write(file_unit, '(A)') '              0'
    write(file_unit, '(A)') '              0            0            0            2       0.0000            1'
    write(file_unit, '(A)') '              0            0  21.1142      21.5983                0            0'
    write(file_unit, '(A)') '              0            0            0            0       0.2500            3'
    write(file_unit, '(A)') '              3'
  end subroutine write_hanger_miscel

end module write_hanger_miscel_mod
