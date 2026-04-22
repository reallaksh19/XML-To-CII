# Work Instruction — XML to CII Zero-Diff Program
**Project:** Generate `BM_CII.CII` from old CAESAR II XML
**Primary input:** `BM_CII_INPUT.XML`
**Golden output:** `BM_CII.CII`

## Mandatory baseline files
This WI is **not standalone**. It must be executed **in direct linkage with** these two baseline files:

1. `BM_CII_improved_oldXML_to_CII_mapping.md`
   Purpose: semantic contract for old XML -> CII mapping, fallback logic, section ownership, and known unresolved gaps.

2. `BM_CII_INPUT_improved_profile.xsd`
   Purpose: logical validation profile for the old input XML structure, sentinel-aware parsing expectations, and child-record structure.

## Rule 0 — Do not restart from scratch
The implementation must **begin from these two files** as the current contract.
Do **not** redesign the XML model or remap sections from zero unless a mismatch proves the baseline wrong.

---

# 1. Objective

Build a deterministic converter that reads the old XML and emits a CII file that reaches:

- **Stage A — Structural zero error**
  - converter parses XML successfully
  - canonical model is consistent
  - owned CII sections are internally valid and diff-clean where resolvable

- **Stage B — Golden zero error**
  - generated `BM_CII.CII` matches the golden `BM_CII.CII` **byte by byte**

The final target is **Golden zero error**.

---

# 2. Clear-cut scope

## 2.1 In scope
The implementation must cover:

- XML parsing
- sentinel-aware normalization
- inheritance/effective-value resolution
- active/inactive child filtering
- section-wise CII generation
- section-wise diffing
- whole-file byte diffing
- CRLF / spacing / format stabilization

The converter must explicitly support these CII sections:

- `#$ VERSION`
- `#$ CONTROL`
- `#$ ELEMENTS`
- `#$ BEND`
- `#$ RIGID`
- `#$ RESTRANT`
- `#$ SIF&TEES`
- `#$ ALLOWBLS`
- `#$ UNITS`

And must investigate / resolve these derived or harder sections:

- `#$ NODENAME`
- `#$ MISCEL_1`
- `#$ COORDS`
- line-name derivation such as `LINENO1`, `LINENO2`

## 2.2 Out of scope unless proven necessary
- redesigning the XML input model
- inventing new section semantics not grounded in the baseline mapping file
- changing golden file expectations
- assuming CAESAR internal defaults without evidence

## 2.3 Forbidden actions
- writing final CII directly from raw XML
- using list-directed Fortran output for golden sections
- inventing names, coordinates, nodenames, or hanger values
- silently converting invalid numeric values without logging
- allowing each block owner to define its own sentinel rules

---

# 3. Implementation architecture

Use this pipeline only:

```text
BM_CII_INPUT.XML
-> schema-aware parse
-> normalization
-> canonical model
-> inheritance/effective values
-> section extraction
-> fixed-format CII writers
-> assembled BM_CII_out.CII
-> section diff
-> raw byte diff
```

## 3.1 Mandatory contract usage
`BM_CII_improved_oldXML_to_CII_mapping.md` must be treated as the **semantic mapping contract**.

`BM_CII_INPUT_improved_profile.xsd` must be treated as the **input structure contract**.

If either contract appears insufficient during implementation:
1. log the exact mismatch
2. prove it against golden output
3. revise contract intentionally
4. rerun all pass tests

---

# 4. Team structure

Use **3 agents + 1 orchestrator**.

## Orchestrator
Owns:
- contract freeze
- mismatch routing
- fallback approval
- section merge order
- release gates
- final zero-diff declaration

## Agent 1 — Input Contract + Canonical Model
Owns:
- XML reader
- schema/profile alignment
- sentinel cleanup
- NaN cleanup
- inheritance
- active-slot classification
- canonical model snapshot

## Agent 2 — Core CII Writer
Owns:
- VERSION
- CONTROL
- ELEMENTS
- BEND
- RIGID
- RESTRANT
- SIF&TEES
- ALLOWBLS
- UNITS

## Agent 3 — Derived / Unresolved / Byte-Match
Owns:
- NODENAME
- MISCEL_1
- COORDS
- line-name derivation
- final CRLF/spacing/numeric-format polish

---

# 5. Input rules linked to baseline profile

The implementation must follow the improved XML profile rules.

## 5.1 Sentinel handling
Treat as missing unless proven otherwise:

- `-1.010100` -> missing real
- `-1` -> missing integer
- `-nan`, `nan`, `NaN` -> missing real
- empty string -> empty / missing text

## 5.2 Child records
The profile allows child blocks under `PIPINGELEMENT`, including:

- `RIGID`
- `RESTRAINT`
- `BEND`
- `SIF`
- `HANGER`
- `ALLOWABLESTRESS`

These are **owner-linked children**.
They must not be flattened blindly.

## 5.3 Effective-value inheritance
For each element, compute effective values for:

- diameter
- wall thickness
- insulation thickness
- corrosion allowance
- temperatures 1..9
- pressures 1..9
- hydro pressure
- pipe density
- insulation density
- fluid density
- material number / name

If current XML field is sentinel/missing, inherit the previous valid effective value where the baseline mapping says inheritance applies.

---

# 6. Output rules linked to baseline mapping

The implementation must follow the improved mapping file.

## 6.1 One XML element may feed multiple CII sections
A `PIPINGELEMENT` may feed:

- `#$ ELEMENTS`
- `#$ RIGID`
- `#$ BEND`
- `#$ RESTRANT`
- `#$ SIF&TEES`
- `#$ ALLOWBLS`
- `#$ MISCEL_1`

So every child record must carry:
- `owner_seq`
- owner `from_node`
- owner `to_node`

## 6.2 Active-slot filtering
The mapping file already establishes that many child slots are placeholders.

Required behavior:
- do not emit placeholder `RESTRAINT`
- do not emit placeholder `SIF`
- do not emit inactive `BEND`
- do not emit meaningless `RIGID`

## 6.3 Lookup tables
Use only approved lookup maps from the mapping contract.

### RIGID type map
- `Valve` -> `1`
- `Flange` -> `2`
- `Flange Pair` -> `3`
- `Flanged Valve` -> `4`

### RESTRAINT type remap
- `0 -> 1`
- `1 -> 2`
- `2 -> 3`
- `3 -> 4`
- `7 -> 8`
- `10 -> 9`
- `17 -> 14`
- `18 -> 15`

No new mapping may be introduced without orchestrator approval and regression proof.

---

# 7. Block-by-block scope and fallback

## 7.1 VERSION
Scope:
- reproduce fixed header and static metadata layout

Allowed fallback:
- blank metadata lines exactly as golden style

Pass test:
- raw section diff empty

## 7.2 CONTROL
Scope:
- emit counts based on **derived active records**, not blind XML header copy

Allowed fallback:
- none beyond recomputation

Pass test:
- counts match golden exactly

## 7.3 ELEMENTS
Scope:
- full multiline element block
- flags
- local name lines
- inherited engineering values

Allowed fallback:
- inherited effective values
- blank approved line when true name not yet solved during structural phase only

Forbidden fallback:
- inventing line names

Pass test:
- first 5 and last 5 element blocks exact
- whole element section raw diff empty before final release

## 7.4 BEND
Scope:
- flatten active bend records
- use owner wall thickness where required

Allowed fallback:
- zero/default approved pattern only where the mapping file already permits it

Pass test:
- bend count exact
- raw section diff empty

## 7.5 RIGID
Scope:
- flatten active rigids
- use approved type map

Allowed fallback:
- unknown type may be logged during development, but not in final release

Pass test:
- rigid count exact
- all rigid type codes exact
- raw section diff empty

## 7.6 RESTRANT
Scope:
- flatten active supports/restraints
- use approved restraint type remap
- apply approved default stiffness rules only if proven

Allowed fallback:
- placeholder restraints suppressed

Forbidden fallback:
- inventing support behavior

Pass test:
- active restraint count exact
- raw section diff empty

## 7.7 SIF&TEES
Scope:
- flatten active SIF/tee records
- suppress placeholder second slots

Allowed fallback:
- none beyond active-slot suppression

Pass test:
- active SIF count exact
- raw section diff empty

## 7.8 ALLOWBLS
Scope:
- extract nested allowable block globally
- preserve 9 cases in order
- normalize dirty numerics

Allowed fallback:
- sanitize invalid numeric text to missing only through approved normalization logic

Pass test:
- one allowable block
- 9 cases
- no NaN in writer
- raw section diff empty

## 7.9 UNITS
Scope:
- exact factors and labels
- exact output order

Allowed fallback:
- none

Pass test:
- raw section diff empty

## 7.10 NODENAME
Scope:
- derive exact nodename section only when backed by evidence

Allowed fallback:
- unresolved during structural phase, but must be logged

Forbidden fallback:
- inventing nodenames

Pass test:
- exact section, or formal unresolved note

## 7.11 MISCEL_1
Scope:
- especially hanger-linked records

Allowed fallback:
- unresolved during structural phase if exact mapping not yet proven

Forbidden fallback:
- inventing hanger table semantics

Pass test:
- exact section, or formal unresolved note

## 7.12 COORDS
Scope:
- derive only if true coordinate source is proven

Allowed fallback:
- unresolved during structural phase

Forbidden fallback:
- fabricated coordinates

Pass test:
- exact section, or formal external-source gap report

---

# 8. Method of achieving zero diff

This is the mandatory method.

## 8.1 Contract freeze
1. pin:
   - `BM_CII_improved_oldXML_to_CII_mapping.md`
   - `BM_CII_INPUT_improved_profile.xsd`
2. freeze mismatch vocabulary
3. freeze ownership map

## 8.2 Canonical snapshot
Agent 1 produces:
- normalized XML snapshot
- effective-value trace
- active child-register
- canonical model vN

Orchestrator approves or rejects canonical model vN.

No writer may proceed on unapproved canonical state.

## 8.3 Section-first implementation
Implement and converge sections in this order:

1. VERSION
2. CONTROL
3. ELEMENTS
4. BEND
5. RIGID
6. RESTRANT
7. SIF&TEES
8. ALLOWBLS
9. UNITS
10. NODENAME
11. MISCEL_1
12. COORDS

## 8.4 Two-layer diffing
For every cycle:
- **Layer 1:** section diff
- **Layer 2:** full raw byte diff

Do not debug the whole file first.

## 8.5 Mismatch classification
Every mismatch must be classified as exactly one of:

- `SCHEMA_MISMATCH`
- `NORMALIZATION_MISMATCH`
- `INHERITANCE_MISMATCH`
- `ACTIVE_SLOT_MISMATCH`
- `TYPEMAP_MISMATCH`
- `FORMAT_MISMATCH`
- `EXTERNAL_SOURCE_GAP`

This is mandatory.

## 8.6 Fix loop
For each mismatch:
1. QA reports exact mismatch
2. Orchestrator assigns owner
3. Owner proposes fix
4. Orchestrator approves contract impact
5. Owner updates code
6. section diff rerun
7. if clean, merge section
8. rerun whole-file raw diff

## 8.7 Byte-by-byte closure
Final pass requires:
- exact line order
- exact text spacing
- exact numeric formatting
- exact CRLF behavior
- exact section order
- exact section content

No “close enough” tolerance is allowed for final release.

---

# 9. Pass tests

## 9.1 Contract pass tests
- baseline mapping file linked and referenced
- baseline improved profile linked and referenced
- ownership map fixed
- mismatch vocabulary fixed

## 9.2 Agent 1 pass tests
- XML conforms to profile expectations
- no NaN leaks
- effective inheritance proven
- counts derived correctly:
  - `40` elements
  - `7` bends
  - `15` rigids
  - `8` active restraints
  - `1` allowable block
  - `9` active SIF/ISect entries

## 9.3 Agent 2 pass tests
- VERSION raw diff empty
- CONTROL raw diff empty
- ELEMENTS raw diff empty
- BEND raw diff empty
- RIGID raw diff empty
- RESTRANT raw diff empty
- SIF&TEES raw diff empty
- ALLOWBLS raw diff empty
- UNITS raw diff empty

## 9.4 Agent 3 pass tests
- NODENAME exact or formal unresolved proof
- MISCEL_1 exact or formal unresolved proof
- COORDS exact or formal unresolved proof
- final full-file line endings exact
- full-file spacing exact
- full-file numeric formatting exact

## 9.5 Orchestrator pass tests
- every mismatch assigned to one owner
- no unresolved gap hidden
- no fallback introduced without approval
- release state reflects actual diff state

## 9.6 Final release pass test
The release may be marked **Golden zero error** only when:
1. all required section pass tests are green
2. unresolved-gap registry is empty
3. raw whole-file byte diff is empty
4. line endings match exactly
5. orchestrator writes:
   `GOLDEN_ZERO_ERROR = TRUE`

---

# 10. Required coding practices

- use Fortran modules with one concern each
- use `implicit none`
- use `iostat` on all numeric reads
- centralize normalization helpers
- centralize type maps
- centralize formatter families
- do not use list-directed output for final sections
- keep section writers isolated
- keep canonical model immutable per approved snapshot version

---

# 11. Deliverables

Minimum deliverables:

- converter source
- canonical model module
- normalization module
- inheritance module
- section writers
- lookup-map module
- diff tool
- section diff reports
- whole-file raw diff report
- unresolved-gap report
- release status report

---

# 12. Final instruction to the implementation team

Use the two baseline files as the **linked contract**.

Do not restart schema design.
Do not shortcut byte-diff with approximations.
Do not guess unresolved sections.
Converge one section at a time until the entire file reaches zero diff.
