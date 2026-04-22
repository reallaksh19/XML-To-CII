# XML-to-CII Program — Merge / Integration Control Addendum
**Applies to:** `XML_to_CII_Zero_Diff_WI.md`
**Baseline-linked files:**
- `BM_CII_improved_oldXML_to_CII_mapping.md`
- `BM_CII_INPUT_improved_profile.xsd`

This addendum incorporates the integration checklist as **mandatory controls** for the 3-agent + 1-orchestrator plan.

---

## 1. Freeze contracts first, then parallelize
Before any agent starts coding, the orchestrator must freeze:

- canonical model contract
- missing-value semantics
- inheritance semantics
- active-slot suppression rules
- rigid type map
- restraint type map
- formatting family ownership
- unresolved-gap registry format

No parallel work may begin before these are written and versioned.

### XML-to-CII translation of this rule
Lock these interfaces first:
- `model_t`
- `element_t`
- `rigid_t`
- `restraint_t`
- `bend_t`
- `sif_t`
- `hanger_t`
- section writer inputs/outputs
- diff report schema

---

## 2. Enforce file ownership for high-conflict files
Certain files/modules must have **single-owner windows**.

### High-conflict ownership map
- `cii_model_types.f90` -> Orchestrator approval required for any change
- `value_normalize.f90` -> Agent 1 exclusive
- `inheritance_engine.f90` -> Agent 1 exclusive
- `write_elements.f90` -> Agent 2 exclusive
- `write_restrant.f90` -> Agent 2 exclusive or Agent 3 if ownership reassigned, but never both
- `write_nodename.f90` -> Agent 3 exclusive
- `write_hanger_miscel.f90` -> Agent 3 exclusive
- `compare_cii.py` / diff tool -> QA ownership only

If a file affects multiple sections, it must be merged only through orchestrator-approved semantic review.

---

## 3. Never resolve critical conflicts with blanket overwrite
For critical modules, blanket overwrite behavior is forbidden.

### Forbidden merge behavior
- git `--ours`
- git `--theirs`
- blind copy-paste replacement

### Requires semantic/manual merge
- canonical types
- normalization helpers
- inheritance logic
- section formatters
- merge assembler
- diff tool
- any lookup-map module

### XML-to-CII reason
A blanket overwrite can silently break:
- inheritance
- active child filtering
- rigid/restraint mapping
- byte formatting
- unresolved gap tracking

---

## 4. Merge in strict waves with integration branch
All work must merge through a dedicated integration branch, not directly to main.

## Required wave order
### Wave 1 — Foundation
- Orchestrator contract files
- Agent 1 canonical model
- normalization
- inheritance
- active-slot classification

### Wave 2 — Core section generation
- Agent 2:
  - VERSION
  - CONTROL
  - ELEMENTS
  - BEND
  - RIGID
  - RESTRANT
  - SIF&TEES
  - ALLOWBLS
  - UNITS

### Wave 3 — Derived / unresolved surfaces
- Agent 3:
  - NODENAME
  - MISCEL_1
  - COORDS
  - line-name derivation
  - final formatting polish

### Wave 4 — Hardening
- QA raw byte diff
- behavior parity audit
- release gating

No agent may jump waves without orchestrator approval.

---

## 5. Add behavior gates, not only compile gates
Compile success is not enough.

The CI must run **behavior gates** that reflect conversion correctness.

## Required behavior gates
1. sentinel normalization gate
2. inheritance gate
3. active-slot suppression gate
4. rigid type-map gate
5. restraint type-map gate
6. section-count gate
7. section-order gate
8. numeric-format gate
9. CRLF/line-ending gate
10. full byte-diff gate

### Equivalent of UI scenario checks in this project
Instead of “view mode switch” and “anchor drag”, the scenario checks are:
- element with inherited values still emits real engineering data
- placeholder restraint slot is suppressed
- placeholder SIF slot is suppressed
- one element emits to multiple sections correctly
- nested allowable block becomes global ALLOWBLS section
- hanger remains isolated unless exact mapping proven
- unresolved COORDS cannot slip into final claim silently

---

## 6. Add “contract violation” static checks
CI must fail if code bypasses the approved architecture.

### Examples of contract violation in this project
Fail build if:
- a writer reads raw XML directly instead of canonical model
- a section writer performs its own sentinel normalization
- a section writer defines its own inheritance rule
- a section writer defines a private rigid/restraint map
- unresolved-source sections are emitted without gap-resolution approval

### Static / grep-style checks
Block merge if patterns indicate architecture bypass, such as:
- raw XML attribute access outside Agent 1 modules
- duplicate `map_rigid_type`
- duplicate `map_restraint_type`
- duplicate sentinel check logic
- duplicate format family definitions

---

## 7. Protect against silent feature regressions
Use a pre-merge critical marker checklist.

## Required pre-merge markers
- sentinel cleanup logic still present
- `-nan` cleanup still present
- inheritance engine still used by section writers
- active child suppression still present
- rigid type lookup still present
- restraint type remap still present
- ALLOWABLESTRESS extraction still global
- unresolved-gap registry still updated
- raw byte diff still run in CI

If any marker disappears, merge must be blocked.

---

## 8. Keep stubs out of routed surfaces
No placeholder logic may remain in active conversion paths.

### Forbidden in active path
- placeholder nodename emitter
- dummy coords generator
- hardcoded fake line-name generator
- temporary hanger formatter
- “return zero section for now” in final release path

### Allowed only if
- behind explicit `UNRESOLVED_GAP`
- excluded from Golden zero-error claim
- documented in gap registry

---

## 9. Require per-branch evidence artifacts
Every agent branch must publish evidence before approval.

## Required evidence by branch
### Agent 1
- normalization log
- inheritance trace
- active-slot report
- canonical snapshot summary

### Agent 2
- section-wise pass logs
- raw diffs for owned sections
- formatter proof for owned sections

### Agent 3
- derivation evidence for NODENAME / MISCEL_1 / COORDS
- unresolved-gap report if not solved
- final formatting evidence

### Orchestrator
- routing log
- approved contract version
- release gate status

### QA
- raw byte diff
- normalized diff
- section parity matrix

No merge approval without artifacts.

---

## 10. Do one final behavior parity audit before main
Before merging to main, perform a feature/behavior matrix audit.

## Required parity audit matrix
| Capability | Expected | Actual | Status |
|---|---:|---:|---|
| XML parses under improved profile | Yes | ? | |
| Sentinels normalized | Yes | ? | |
| `-nan` cleaned | Yes | ? | |
| Effective inheritance applied | Yes | ? | |
| Active restraints only emitted | Yes | ? | |
| Active SIF only emitted | Yes | ? | |
| RIGID map exact | Yes | ? | |
| RESTRAINT map exact | Yes | ? | |
| ALLOWBLS extracted globally | Yes | ? | |
| UNITS exact | Yes | ? | |
| NODENAME resolved or proven external | Yes | ? | |
| MISCEL_1 resolved or proven external | Yes | ? | |
| COORDS resolved or proven external | Yes | ? | |
| Section diff clean | Yes | ? | |
| Raw byte diff clean | Yes | ? | |

The orchestrator must sign off this matrix.

---

## 11. Revised release control
Main branch merge is allowed only if:

1. contract frozen and versioned
2. all changes merged through integration branch
3. no critical file had concurrent unsupervised edits
4. no critical conflict was resolved by blanket overwrite
5. all required evidence artifacts are present
6. parity audit completed
7. orchestrator signs release state

### Release states
- `PARTIAL`
- `STRUCTURAL_ZERO_ERROR`
- `GOLDEN_ZERO_ERROR`

Only the orchestrator may set the final state.

---

## 12. Practical mapping of your checklist to this project
Your original checklist translates directly as:

1. **Freeze contracts first**
   -> freeze canonical XML-to-CII contract before agent coding

2. **Single-owner for high-conflict files**
   -> one owner for normalization, inheritance, section writers, diff tools

3. **No blanket ours/theirs merges**
   -> semantic merge only for canonical/formatter/writer files

4. **Strict merge waves**
   -> Foundation -> Core sections -> Derived sections -> Hardening

5. **Behavior gates beyond compile**
   -> inheritance / suppression / mapping / byte-diff gates

6. **Contract violation checks**
   -> fail if any section bypasses canonical model

7. **Protect against silent regressions**
   -> marker checklist for normalization, inheritance, maps, diff

8. **Keep stubs out of routed surfaces**
   -> block placeholder nodename/coords/hanger emitters in final path

9. **Per-branch evidence artifacts**
   -> logs, traces, diffs, parity artifacts required

10. **Final behavior parity audit**
   -> full expected vs actual matrix before main
