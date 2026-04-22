# XML → CII Schema Profile for `BM_CII_INPUT.XML` → `BM_CII.CII`

This profile was derived from the repository sample pair:

- **Input XML:** `BM_CII_INPUT.XML`
- **Target CII:** `BM_CII.CII`

It is written as a **Fortran-oriented serialization profile** rather than a purely academic XML schema.  
The goal is to preserve the information needed to write a CAESAR II style `.CII` file that matches the sample structure.

## 1) High-level mapping

The XML is already a CAESAR II input model:

- Root: `CAESARII`
- Main model node: `PIPINGMODEL`
- Repeating geometry/body records: `PIPINGELEMENT`
- Nested specialized records:
  - `RIGID`
  - `RESTRAINT`
  - `ALLOWABLESTRESS`
    - `CASE`
  - `BEND`
  - `SIF`
  - `HANGER`
  - `UNITS`

The target `BM_CII.CII` is a fixed-section text file with major sections:

- `#$ VERSION`
- `#$ CONTROL`
- `#$ ELEMENTS`
- `#$ AUX_DATA`
- `#$ NODENAME`
- `#$ BEND`
- `#$ RIGID`
- `#$ EXPJT`
- `#$ RESTRANT`
- `#$ DISPLMNT`
- `#$ FORCMNT`
- `#$ UNIFORM`
- `#$ WIND`
- `#$ OFFSETS`
- `#$ ALLOWBLS`
- `#$ SIF&TEES`
- `#$ REDUCERS`
- `#$ FLANGES`
- `#$ EQUIPMNT`
- `#$ MISCEL_1`
- `#$ UNITS`
- `#$ COORDS`

## 2) Core serialization rule

For **zero-error round-trip intent**, the XML schema alone is not enough. The writer must also obey these record rules:

1. **Preserve element order exactly** as in XML.
2. **Preserve section order exactly** as in the sample `.CII`.
3. Treat XML sentinel value **`-1.010100`** as **unset / inherited / omitted**.
4. Convert unset XML fields into the correct CII representation:
   - sometimes `0`
   - sometimes blank string
   - sometimes `9999.99`
   - sometimes omitted child record
5. Emit fixed-format numeric text consistently.
6. Counts on `PIPINGMODEL` must match the actual occurrences:
   - `NUMELT`
   - `NUMBEND`
   - `NUMRIGID`
   - `NUMREST`
   - `NUMALLOW`
   - `NUMISECT`
   - etc.

## 3) Required XML objects

## 3.1 Root

```xml
<CAESARII xmlns="COADE" VERSION="11.00" XML_TYPE="Input">
  <PIPINGMODEL xmlns="" ...>
    ...
  </PIPINGMODEL>
</CAESARII>
```

### Required root attributes

- `VERSION`
- `XML_TYPE`

## 3.2 `PIPINGMODEL`

This is the top-level model header. It drives the `#$ CONTROL` section and global counts.

### Important `PIPINGMODEL` attributes

- `JOBNAME`
- `TIME`
- `NUMELT`
- `NUMNOZ`
- `NOHGRS`
- `NUMBEND`
- `NUMRIGID`
- `NUMEXPJNT`
- `NUMREST`
- `NUMFORCMNT`
- `NUMUNFLOAD`
- `NUMWIND`
- `NUMELEOFF`
- `NUMALLOW`
- `NUMISECT`
- `NORTH_Z`
- `NORTH_Y`
- `NORTH_X`

### Round-trip note

These counts must be **recomputed from actual XML contents** before writing CII.  
Do **not** trust stale count attributes if elements are edited.

---

## 3.3 `PIPINGELEMENT`

Each `PIPINGELEMENT` maps to one main record block under `#$ ELEMENTS`.

### Minimum fields required to serialize one element correctly

- `FROM_NODE`
- `TO_NODE`
- `DELTA_X`
- `DELTA_Y`
- `DELTA_Z`
- `DIAMETER`
- `WALL_THICK`
- `INSUL_THICK`
- `CORR_ALLOW`
- `TEMP_EXP_C1`
- `PRESSURE1`
- `HYDRO_PRESSURE`
- `MODULUS`
- `HOT_MOD1..HOT_MOD9`
- `POISSONS`
- `PIPE_DENSITY`
- `INSUL_DENSITY`
- `FLUID_DENSITY`
- `MATERIAL_NUM`
- `MATERIAL_NAME`
- `NAME`

### Important behavior seen in sample

- First element contains full physical property definition.
- Later elements often use `-1.010100` for values that are effectively inherited or treated as blank/default in output.
- `NAME=""` produces no element name line content.
- Non-empty names like `GATE_FLG_300`, `LINENO1`, `LINENO2` must propagate.

## 4) Nested object mapping

## 4.1 `RIGID`

### XML form
```xml
<RIGID WEIGHT="186.808350" TYPE="Flange Pair"/>
```

### CII relation
Maps to:
- embedded element subrecord behavior
- `#$ RIGID` section summary entries

### Practical rule
If an element has one or more `RIGID` children, write the local element rigid data and include the corresponding `#$ RIGID` records.

---

## 4.2 `RESTRAINT`

### XML form
```xml
<RESTRAINT
  NUM="1"
  NODE="35.000000"
  TYPE="17.000000"
  STIFFNESS="-1.010100"
  GAP="-1.010100"
  FRIC_COEF="-1.010100"
  CNODE="-1.010100"
  XCOSINE="0.000000"
  YCOSINE="1.000000"
  ZCOSINE="0.000000"
  TAG=""
  GUID=""
/>
```

### CII relation
Maps to:
- local restraint lines in the element block
- `#$ RESTRANT`

### Required semantics
- `TYPE` drives support/restraint behavior
- direction cosines must be preserved exactly
- restraint tag such as `PS-456` must propagate

---

## 4.3 `ALLOWABLESTRESS`

### XML form
```xml
<ALLOWABLESTRESS ...>
  <CASE NUM="1" .../>
  ...
  <CASE NUM="9" .../>
</ALLOWABLESTRESS>
```

### CII relation
Maps to `#$ ALLOWBLS`

### Critical refinement rule
There are many sentinel/unset values. The writer must normalize them consistently:
- unset numeric -> zero or `9999.99` depending on CII field meaning
- unset integer/flag -> `0` or blank
- NaN-like values in XML should be sanitized before CII serialization

**Important sample issue:** one XML field contains `BUTTWELDCYCLES="-nan"`.  
This should be normalized before output, otherwise a strict writer/diff will fail.

Recommended normalization:
- if value is NaN-like, replace with unset sentinel in memory
- then serialize with the target CII default for that field

---

## 4.4 `BEND`

### XML form
```xml
<BEND
  RADIUS="152.399994"
  TYPE="-1.010100"
  ANGLE1="45.000000"
  NODE1="129.000000"
  ANGLE2="0.000000"
  NODE2="158.000000"
  ...
/>
```

### CII relation
Maps to `#$ BEND`

### Required semantics
- bend radius
- bend angle(s)
- associated node linkage
- fitting thickness / K-factor when present

---

## 4.5 `SIF`

### XML form
```xml
<SIF
  SIF_NUM="1"
  NODE="100.000000"
  TYPE="5.000000"
  ...
/>
```

### CII relation
Maps to `#$ SIF&TEES`

### Important observation
The sample uses multiple SIF types:
- branch / tee-like
- intersection / reducer-like local behavior markers

These must be emitted in the same order as encountered.

---

## 4.6 `HANGER`

### XML form
```xml
<HANGER
  NODE="205.000000"
  LOAD_VAR="25.000000"
  HGR_TABLE="1"
  SHORT_RANGE="1"
  ...
/>
```

### CII relation
Maps primarily into `#$ MISCEL_1`

### Important behavior
This is not just a decorative child; it contributes to downstream special records.

---

## 4.7 `UNITS`

### XML form
```xml
<UNITS>
  <LENGTH LABEL="mm." FACTOR="25.400000"/>
  ...
</UNITS>
```

### CII relation
Maps to `#$ UNITS`

### Required semantics
Units must preserve:
- label
- factor
- ordering

## 5) Zero-error refinement checklist

To get as close as possible to `BM_CII.CII`, the XML profile should obey:

### 5.1 Structural checks
- `PIPINGMODEL/@NUMELT == count(PIPINGELEMENT)`
- `PIPINGMODEL/@NUMBEND == count(//BEND)`
- `PIPINGMODEL/@NUMRIGID == count(//RIGID)`
- `PIPINGMODEL/@NUMREST == count(//RESTRAINT that are materially present)`
- `PIPINGMODEL/@NUMALLOW == count(//ALLOWABLESTRESS)`
- `PIPINGMODEL/@NUMISECT == count(//SIF with active type)`

### 5.2 Data sanitation
- replace XML `-nan`, `nan`, `NaN` with internal null/unset
- trim whitespace-only names to empty
- preserve numeric sign and scale where meaningful
- keep node numbers consistent as numeric identifiers, not strings with accidental formatting drift

### 5.3 Writer defaults
Recommended internal rules:

- if a value is `-1.010100`, mark it as `missing`
- if missing and field is:
  - optional text -> blank
  - optional real lower bound/open range -> `0.000000`
  - unused upper/default cap -> `9999.99`
  - unused ID/enum -> `0`

### 5.4 Ordering
- keep all `PIPINGELEMENT`s in input order
- for each element, keep child order:
  1. `RIGID*`
  2. `RESTRAINT*`
  3. `ALLOWABLESTRESS?`
  4. `BEND?`
  5. `SIF*`
  6. `HANGER?`

This ordering matches the practical sample usage and reduces writer ambiguity.

## 6) Fortran-oriented data model

Recommended derived-type layout:

```fortran
type :: cii_restrain_t
  real(8) :: num, node, rtype, stiffness, gap, fric_coef, cnode
  real(8) :: xcos, ycos, zcos
  character(len=64) :: tag
end type

type :: cii_rigid_t
  real(8) :: weight
  character(len=64) :: rtype
end type

type :: cii_bend_t
  real(8) :: radius, btype
  real(8) :: angle1, node1, angle2, node2, angle3, node3
  real(8) :: num_miter, fitting_thk, kfactor
end type

type :: cii_sif_t
  real(8) :: sif_num, node, stype
  real(8) :: sif_in, sif_out, sif_torsion, sif_axial, sif_pressure
  real(8) :: iin, iout, it, ia, ipr
  real(8) :: weld_d, fillet, pad_thk, ftg_ro, crotch, weld_id, b1, b2
end type

type :: cii_hanger_t
  real(8) :: node, cnode, const_eff_load, load_var
  real(8) :: rigid_sup, avail_space, cold_load, hot_load, max_travel
  integer :: multi_lc, freeanchor1, freeanchor2, doftype1, hgr_table, short_range
  character(len=64) :: tag
end type

type :: cii_element_t
  real(8) :: from_node, to_node
  real(8) :: dx, dy, dz
  real(8) :: diameter, wall_thk, insul_thk, corr_allow
  real(8) :: temp_exp(9), pressure(9), hydro_pressure
  real(8) :: modulus, hot_mod(9), poissons
  real(8) :: pipe_density, insul_density, fluid_density
  real(8) :: refractory_density, refractory_thk, cladding_den, cladding_thk
  real(8) :: insul_clad_unit_weight
  real(8) :: material_num, mill_tol_plus, mill_tol_minus, seam_weld
  character(len=64) :: material_name, name
  type(cii_rigid_t), allocatable :: rigids(:)
  type(cii_restrain_t), allocatable :: restrains(:)
  type(cii_bend_t), allocatable :: bends(:)
  type(cii_sif_t), allocatable :: sifs(:)
  type(cii_hanger_t), allocatable :: hangers(:)
end type
```

## 7) Recommended schema refinement decisions

These refinements are recommended specifically for the sample pair:

1. Make most numeric XML attributes **required in schema presence**, even if sentinel-valued.
2. Permit sentinel `-1.010100` as a legal lexical value.
3. Allow empty strings for `NAME`, `TAG`, `GUID`, `ISSUE_NO`.
4. Allow repeated `RESTRAINT`, `RIGID`, and `SIF`.
5. Allow optional `ALLOWABLESTRESS`, `BEND`, `HANGER`.
6. Treat `UNITS` as required at model level.
7. Sanitize `NaN` before writing CII.

## 8) What still controls exact byte match

Even with the correct XML schema, exact identity with `BM_CII.CII` still depends on the writer:

- field width
- decimal precision
- exponent style
- blank vs zero handling
- section padding
- whether missing fields become `0.000000` or `9999.99`
- name line emission rules

So the schema below is **necessary**, but not by itself **sufficient**, for byte-for-byte equivalence.

## 9) Deliverables in this package

- `BM_CII_INPUT_refined_schema.xsd`
- `XML_to_CII_schema_profile.md`

## 10) Recommended next refinement loop

To reach true zero-error against `BM_CII.CII`:

1. Parse XML into internal Fortran structures.
2. Serialize to trial `.CII`.
3. Diff section by section against `BM_CII.CII`.
4. Refine:
   - missing/default handling
   - fixed widths
   - section counters
   - optional record suppression
5. Repeat until diff is zero.

