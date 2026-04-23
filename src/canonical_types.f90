module canonical_types
    implicit none
    save

    ! Sentinel constants
    real(8), parameter :: MISSING_REAL = -999999.0d0
    integer, parameter :: MISSING_INT = -999999

    type :: RigidRecord
        integer :: owner_seq
        real(8) :: weight
        character(len=32) :: type_str
    end type RigidRecord

    type :: RestraintRecord
        integer :: owner_seq
        real(8) :: node
        integer :: type_code
        real(8) :: stiffness
        real(8) :: gap
        real(8) :: fric_coef
        real(8) :: cnode
        real(8) :: xcos, ycos, zcos
        character(len=32) :: tag
    end type RestraintRecord

    type :: BendRecord
        integer :: owner_seq
        real(8) :: radius
        integer :: type_code
        real(8) :: angle1, node1
        real(8) :: angle2, node2
        real(8) :: angle3, node3
        real(8) :: num_miter
        real(8) :: fitting_thickness
        real(8) :: kfactor
    end type BendRecord

    type :: SifRecord
        integer :: owner_seq
        real(8) :: node
        integer :: type_code
        real(8) :: sif_in, sif_out, sif_torsion, sif_axial, sif_pressure
    end type SifRecord

    type :: HangerRecord
        integer :: owner_seq
        real(8) :: node
        real(8) :: cnode
        real(8) :: load_var
        integer :: hgr_table
        integer :: short_range
        character(len=32) :: tag
    end type HangerRecord

    type :: AllowCaseRecord
        integer :: num
        real(8) :: hot_allow
        real(8) :: hot_sy
        real(8) :: hot_su
        real(8) :: cyc_red_factor
        real(8) :: buttweldcycles
        real(8) :: buttweldstress
    end type AllowCaseRecord

    type :: AllowableRecord
        integer :: owner_seq
        real(8) :: hoop_stress_factor
        real(8) :: cold_allow
        real(8) :: eff
        real(8) :: sy
        real(8) :: su
        integer :: piping_code
        integer :: num_cases
        type(AllowCaseRecord), allocatable :: cases(:)
    end type AllowableRecord

    type :: CanonicalElement
        integer :: seq
        real(8) :: from_node, to_node
        real(8) :: dx, dy, dz

        ! Effective values
        real(8) :: effective_diameter
        real(8) :: effective_wall_thk
        real(8) :: effective_insul_thk
        real(8) :: effective_corr_allow
        real(8) :: effective_temps(9)
        real(8) :: effective_pressures(9)
        real(8) :: effective_hydro_pressure
        real(8) :: material_num
        character(len=64) :: material_name
        character(len=64) :: name

        ! Child records sizes
        integer :: num_rigids
        integer :: num_restraints
        integer :: num_sifs

        type(RigidRecord), allocatable :: rigids(:)
        type(RestraintRecord), allocatable :: restraints(:)

        logical :: has_bend
        type(BendRecord) :: bend

        type(SifRecord), allocatable :: sifs(:)

        logical :: has_hanger
        type(HangerRecord) :: hanger

        logical :: has_allowable
        type(AllowableRecord) :: allowable
    end type CanonicalElement

    type :: CanonicalModel
        character(len=256) :: jobname
        character(len=64) :: time
        integer :: num_elements
        type(CanonicalElement), allocatable :: elements(:)
    end type CanonicalModel

end module canonical_types
