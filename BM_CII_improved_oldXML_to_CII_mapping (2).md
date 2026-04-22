# BM_CII Improved Old-XML to CII Schema / Mapping
**Scope:** improved schema and mapping for the old CAESAR II input XML sample `BM_CII_INPUT.XML` against the target `BM_CII.CII`, refined using lessons learned from the real AVEVA `PSI116.xsd`.

---

## 1. Why this improved version is needed

The old XML is structurally rich enough to recreate the target CII, but the earlier mapping was too shallow in four places:

1. **Sentinel-aware numeric handling**  
   Old XML uses `-1.010100` as a missing-value sentinel and also contains at least one dirty numeric value like `-nan`.
2. **One XML element feeds multiple CII blocks**  
   `PIPINGELEMENT` does not map only to `#$ ELEMENTS`; it can also emit records to `#$ BEND`, `#$ RIGID`, `#$ RESTRANT`, `#$ SIF&TEES`, `#$ ALLOWBLS`, and `#$ MISCEL_1`.
3. **Active vs placeholder child records**  
   Repeated child slots exist in XML but many are placeholders and must not become active CII records.
4. **Inheritance / effective values**  
   Many later elements leave diameter, wall thickness, insulation, temperature, pressure, and hydro values at the sentinel, but the CII output still emits real values because the converter inherits from earlier effective values.

This document improves both:
- the **XML profile**
- the **XML -> CII section mapping rules**

---

## 2. Improved XML profile principles

### 2.1 Sentinel-aware primitive types

Use these logical types in the converter, even if the source XML remains attribute-based:

- `sentinelDouble`
- `sentinelInteger`
- `cleanString`
- `activeRecordFlag`

### 2.2 Normalization rules

Before any CII writing:

- `-1.010100` -> `MISSING_REAL`
- `-1` -> `MISSING_INT`
- `""` -> empty string
- `-nan`, `nan`, `NaN` -> `MISSING_REAL`
- whitespace-only strings -> empty string

### 2.3 Effective-value inheritance

For each `PIPINGELEMENT`, compute effective values for:

- diameter
- wall thickness
- insulation thickness
- corrosion allowance
- temperature cases 1..9
- pressure cases 1..9
- hydro pressure
- pipe density
- insulation density
- fluid density
- material number / name

If current XML value is missing, inherit the most recent valid value for that branch/model context.

---

## 3. Improved canonical model

Do **not** write CII directly from raw XML.

Use:

```text
BM_CII_INPUT.XML
  -> raw parsed element records
  -> normalized canonical model
  -> section writers
  -> BM_CII_out.CII
```

### 3.1 Canonical top-level model

- model header
- counts
- elements[]
- units
- allowables[]
- derived nodenames[]
- derived bends[]
- derived rigids[]
- derived restraints[]
- derived sifs[]
- derived hangers[]

### 3.2 Canonical element

Each canonical element must contain:

- `seq`
- `from_node`, `to_node`
- `dx`, `dy`, `dz`
- `effective_diameter`
- `effective_wall_thk`
- `effective_insul_thk`
- `effective_corr_allow`
- `effective_temps[1..9]`
- `effective_pressures[1..9]`
- `effective_hydro_pressure`
- `material_num`, `material_name`
- `name`
- `rigids[]`
- `restraints[]`
- `bend?`
- `sifs[]`
- `hanger?`
- `allowable?`

Every child record must carry `owner_seq`.

---

## 4. Section-by-section improved mapping

## 4.1 XML root/header -> CII VERSION + CONTROL

### XML source
- `PIPINGMODEL/@NUMELT`
- `PIPINGMODEL/@NUMBEND`
- `PIPINGMODEL/@NUMRIGID`
- `PIPINGMODEL/@NUMREST`
- `PIPINGMODEL/@NUMALLOW`
- `PIPINGMODEL/@NUMISECT`

### CII target
- `#$ VERSION`
- `#$ CONTROL`

### Improved rule
Do **not** trust XML counts blindly. Recompute derived counts from active canonical records before writing `#$ CONTROL`.

---

## 4.2 `PIPINGELEMENT` -> `#$ ELEMENTS`

### XML source fields
- `FROM_NODE`
- `TO_NODE`
- `DELTA_X`, `DELTA_Y`, `DELTA_Z`
- `DIAMETER`
- `WALL_THICK`
- `INSUL_THICK`
- `CORR_ALLOW`
- `TEMP_EXP_C1..C9`
- `PRESSURE1..PRESSURE9`
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

### CII target
Main multi-line element block under `#$ ELEMENTS`

### Improved rule
- Apply effective inheritance before formatting.
- Convert missing deltas to `0.0` in the inactive axes if that matches the golden output.
- Convert missing dimensions to inherited values, not blanks.
- Convert missing “expansion length/limit style” fields to the golden defaults used by the target file.
- Emit name line only in the target CII style:
  - `0`
  - or `length + name` style like `7 LINENO1`
  - or `12 GATE_FLG_300`

---

## 4.3 `RIGID` child -> element flags + `#$ RIGID`

### XML source
`PIPINGELEMENT/RIGID`
- `WEIGHT`
- `TYPE`

### CII target
- rigid flagging inside the owner element block
- flattened records in `#$ RIGID`

### Improved rule
Create a string-to-code map from the sample:

- `Valve` -> `1`
- `Flange` -> `2`
- `Flange Pair` -> `3`
- `Flanged Valve` -> `4`
- `Unspecified` with missing weight -> emit zero/neutral rigid record only if required by section alignment; otherwise suppress

### Important
A rigid child affects:
1. owner element flags
2. global `#$ RIGID` section

---

## 4.4 `RESTRAINT` child -> element flags + `#$ RESTRANT` + `#$ NODENAME`

### XML source
`PIPINGELEMENT/RESTRAINT`
- `NUM`
- `NODE`
- `TYPE`
- `STIFFNESS`
- `GAP`
- `FRIC_COEF`
- `CNODE`
- `XCOSINE`
- `YCOSINE`
- `ZCOSINE`
- `TAG`

### CII target
- owner element flags
- `#$ RESTRANT`
- optional `#$ NODENAME`

### Improved rule
Only emit active restraints:
- `NODE` valid
- `TYPE` valid

Suppress placeholder slots where both are sentinel/missing.

### Inferred type map from the sample
- XML `0` -> CII restraint type `1`
- XML `1` -> CII restraint type `2`
- XML `2` -> CII restraint type `3`
- XML `3` -> CII restraint type `4`
- XML `7` -> CII restraint type `8`
- XML `10` -> CII restraint type `9`
- XML `17` -> CII restraint type `14`
- XML `18` -> CII restraint type `15`

### Tag rule
If `TAG` is non-empty, also derive a `#$ NODENAME` entry.

---

## 4.5 `BEND` child -> element flags + `#$ BEND`

### XML source
`PIPINGELEMENT/BEND`
- `RADIUS`
- `TYPE`
- `ANGLE1`, `NODE1`
- `ANGLE2`, `NODE2`
- `ANGLE3`, `NODE3`
- `NUM_MITER`
- `FITTINGTHICKNESS`
- `KFACTOR`

### CII target
- bend flag inside element block
- flattened record in `#$ BEND`

### Improved rule
- active if radius and first bend node/angle are valid
- wall thickness in `#$ BEND` is taken from the owner element’s effective wall thickness, not from bend child fields
- missing second and third legs stay as zero/default target values

---

## 4.6 `SIF` child -> element flags + `#$ SIF&TEES`

### XML source
`PIPINGELEMENT/SIF`
- `SIF_NUM`
- `NODE`
- `TYPE`
- plus optional detailed stress-index fields

### CII target
`#$ SIF&TEES`

### Improved rule
Only emit active SIF records where:
- `NODE` valid
- `TYPE` valid

Suppress placeholder second slots with sentinel node/type.

### Observed sample behavior
The sample preserves SIF types like:
- `3`
- `5`
- `11`

So unlike restraints, these appear to carry through directly as type identifiers.

---

## 4.7 `ALLOWABLESTRESS` -> `#$ ALLOWBLS`

### XML source
`PIPINGELEMENT/ALLOWABLESTRESS`
- top-level allowable attributes
- repeated `CASE NUM="1".. "9"`

### CII target
Global `#$ ALLOWBLS`

### Improved rule
- extract once globally, even though the XML block is nested under an element
- normalize all sentinel values before writing
- normalize invalid numeric text like `-nan`
- preserve case order 1..9

### Special rule
The XML block is element-nested but semantically global in the target sample.

---

## 4.8 `HANGER` child -> `#$ MISCEL_1`

### XML source
`PIPINGELEMENT/HANGER`
- `NODE`
- `CNODE`
- `CONST_EFF_LOAD`
- `LOAD_VAR`
- `RIGID_SUP`
- `AVAIL_SPACE`
- `COLD_LOAD`
- `HOT_LOAD`
- `MAX_TRAVEL`
- `MULTI_LC`
- `FREEANCHOR1`
- `FREEANCHOR2`
- `DOFTYPE1`
- `NUM_HGR`
- `HGR_TABLE`
- `SHORT_RANGE`
- `TAG`

### CII target
Hanger-related records inside `#$ MISCEL_1`

### Improved rule
This block is not part of `#$ RESTRANT`; it must be emitted through a dedicated hanger writer.

---

## 4.9 `UNITS` -> `#$ UNITS`

### XML source
`UNITS/*`
- `LENGTH`, `FORCE`, `MASS-DYNAMICS`, etc.

### CII target
`#$ UNITS`

### Improved rule
Map values directly but preserve:
- numeric order
- factor formatting
- label ordering
- textual unit names

---

## 5. Improved old-XML schema recommendations

The old XML is attribute-heavy. Keep that structure, but refine the logical schema as follows.

## 5.1 PIPINGMODEL constraints
- counts must equal derived active section counts
- at least one `PIPINGELEMENT`
- exactly one `UNITS`

## 5.2 PIPINGELEMENT constraints
- `FROM_NODE` and `TO_NODE` required
- deltas allowed to be missing sentinel individually
- child blocks optional:
  - `RIGID` 0..n
  - `RESTRAINT` 0..n
  - `BEND` 0..1
  - `SIF` 0..n
  - `HANGER` 0..1
  - `ALLOWABLESTRESS` 0..1

## 5.3 Active record rules
- `RESTRAINT` active if node+type valid
- `SIF` active if node+type valid
- `BEND` active if radius+angle1+node1 valid
- `RIGID` active if type meaningful or weight meaningful
- `HANGER` active if node valid and one of table/load attributes meaningful

---

## 6. Exact mapping table

| XML path | Canonical target | CII section |
|---|---|---|
| `PIPINGMODEL/@NUMELT` | derived element count | `#$ CONTROL` |
| `PIPINGELEMENT` | canonical element | `#$ ELEMENTS` |
| `PIPINGELEMENT/RIGID` | canonical rigid | `#$ RIGID` + element flags |
| `PIPINGELEMENT/RESTRAINT` | canonical restraint | `#$ RESTRANT` + element flags |
| `PIPINGELEMENT/RESTRAINT/@TAG` | nodename/tag entry | `#$ NODENAME` |
| `PIPINGELEMENT/BEND` | canonical bend | `#$ BEND` + element flags |
| `PIPINGELEMENT/SIF` | canonical sif | `#$ SIF&TEES` + element flags |
| `PIPINGELEMENT/ALLOWABLESTRESS` | canonical allowable | `#$ ALLOWBLS` |
| `PIPINGELEMENT/HANGER` | canonical hanger | `#$ MISCEL_1` |
| `UNITS/*` | canonical units | `#$ UNITS` |

---

## 7. Zero-error requirements for the improved mapping

A generated CII is considered correct only if:

1. XML parses with sentinel-aware normalization
2. No `-nan` or invalid numeric string survives into canonical model
3. Counts are recomputed from active canonical records
4. Placeholder child slots do not create ghost CII records
5. Effective inheritance reproduces the expected dimensions/properties
6. Global sections are emitted in the same order as the target sample
7. Numeric formatting matches the golden file style
8. Whole-file diff against the approved CII is empty, or only approved EOL differences remain

---

## 8. Recommended implementation additions

1. Add a **normalization phase**
2. Add an **active-child filter phase**
3. Add a **section-wise writer architecture**
4. Add a **golden diff harness**
5. Add **explicit string->code lookup tables** for rigid/restraint types
6. Add **element ownership tracking** for every child block

---

## 9. Suggested next deliverables

- improved XSD/profile for old BM_CII XML
- canonical data contract
- Fortran type module
- normalization module
- section-wise CII writers
- golden diff test harness

