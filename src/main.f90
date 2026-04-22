program main
  use cii_types
  use xml_parser
  implicit none

  type(cii_model_t) :: model

  print *, "Running XML to Canonical Model Parser (Agent A1)..."

  call parse_xml("BM_CII_INPUT.XML", model)

  print *, "=== Parsed Canonical Model Summary ==="
  print *, "Elements: ", model%count_elements
  print *, "Bends: ", model%count_bends
  print *, "Rigids: ", model%count_rigids
  print *, "Active Restraints: ", model%count_restraints
  print *, "Allowable Blocks: ", model%count_allowable
  print *, "Active SIF/ISect: ", model%count_sifs
  print *, "======================================"

end program main
