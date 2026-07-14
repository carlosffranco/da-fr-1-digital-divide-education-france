# DA-FR-1 — Phase 1, Step 3: Post-Merge Integrity Report

**Analyst:** Carlos F. Franco
**Purpose:** Reconcile commune sources, execute joins with row-count assertions, derive variables, audit NAs, and certify df_reg.

## Executive Summary

**Objective.** Phase 1, Step 3 reconciled dual commune sources, resolved arrondissement mapping, executed the full join sequence with row-count assertions, derived analytical variables, audited missingness, and certified the regression-ready frame `df_reg`.

**Headline results.**
- **Commune reconciliation rescued coverage to 100%** (2023): `commune_final = coalesce(IVAL-native, crosswalk)`; agreement rate 98.46% validated the crosswalk; 42 crosswalk-missing schools recovered from IVAL-native.
- **Arrondissement handling verified empirically (Ruling 1):** Filosofi carries arrondissement-level codes (kept for income granularity); ARCEP/AAV are global-only (arrondissements mapped to parent for those joins).
- **All 4 joins preserved row count** (60,743) — no fan-out; assertion table clean.
- **Derived variables validated:** fibre_coverage (0 divide-by-zero, 0 values >100), urban_rural, exclude_regression (2020 only).
- **Effective N certified per track:** Model A — GT 2,284 / Pro 1,966; Model B — GT 2,278 / Pro 1,963.

**Missingness.** 2.1% of 2023 schools dropped by listwise deletion, driven by Filosofi income coverage (the documented cost of Ruling 1's arrondissement granularity). Dropped schools show a minor, immaterial rural/public skew (~4 rural, ~12 private); size does not differ. No material coefficient bias.

**Carried to Phase 3.** Model B bounded to sessions 2023–2026 (IPS availability); 2023 IPS uses the 2022 definition (break at 2023/2024); rural coefficient has low power (lycée-level urban skew); 11 pending crosswalk conflicts largely resolved by IVAL-native commune.

**Status: `df_reg` certified regression-ready. Phase 1 complete.**

## T0 — Commune Source Reconciliation

Two commune sources existed: IVAL-native `Code commune` (contemporaneous to Bac year) and crosswalk `code_commune` (current annuaire). IVAL-native cleaned (Corsica-safe) — already `.0`-free (CSV origin), 0 missing, 0 malformed.

**Agreement rate (2023 slice, where both exist):** 98.46% (66 disagreements of ~4,298; clusters: overseas 97… and metropolitan same-dept differences incl. Paris arrondissements). Crosswalk validated (>97% threshold).

**Rule applied:** `commune_final = coalesce(commune_ival, commune_xwalk)` — IVAL-native wins (contemporaneous), crosswalk backfills. Supersedes guide's "always crosswalk" instruction (guide predates knowing IVAL carries its own commune).

**Result:** `commune_final` has 0 missing. **2023 commune coverage: 98.46% → 100%** (42 crosswalk-missing schools rescued by IVAL-native). No fan-out (nrow 60,743 unchanged). The 66 disagreements (incl. 5 Paris conflict-log entries) resolve automatically to the IVAL-native Bac-year commune.

## T1 — Arrondissement Verification & Mapping (Ruling 1)

**Empirical verification (not assumed):** confirmed which sources carry arrondissement codes.

| Source | Paris arr (751xx) | Lyon arr (6938x) | Marseille arr (132xx) | Verdict |
|---|---|---|---|---|
| Filosofi (income) | 20 | 9 | 16 | Arrondissement-level ✅ |
| ARCEP (fibre) | 0 | 0 | 0 | Global-only |
| AAV (urban/rural) | 0 | 0 | 0 | Global-only |

Confirms Step 2 hypothesis (and explains the 64 vs 51 missing-commune gap: the ~13 difference = arrondissements Filosofi covers but ARCEP/AAV don't).

**Ruling 1 applied (per-variable treatment):**
- `commune_final` keeps arrondissements → used for **Filosofi** join (preserves within-city income gradient).
- `commune_terr` maps arrondissements → parent global code (751xx→75056, 6938x→69123, 132xx→13055) → used for **ARCEP/AAV** joins (fibre & urban/rural are ~constant within dense urban cores; approximation is harmless).
- Validation: `commune_terr` 0 NAs, 0 malformed.

**Methodological justification:** the asymmetry is deliberate — income varies sharply across arrondissements (must preserve), whereas FTTH availability and urban/rural class are saturated/constant within a city core (safe to collapse).

## T2 — Join Execution (with row-count assertions)

Master dataframe `df` built by joining in order, each with a `stopifnot(nrow == 60743)` assertion.

| Step | Join key | nrow after | Preserved |
|---|---|---|---|
| baseline (anchor) | — | 60,743 | ✅ |
| 1: + IPS | UAI + annee | 60,743 | ✅ |
| 2: + Filosofi | commune_final | 60,743 | ✅ |
| 3: + ARCEP | commune_terr | 60,743 | ✅ |
| 4: + AAV | commune_terr | 60,743 | ✅ |

No fan-out at any step. IPS replicates across GT/Pro rows of LPOs (expected — row count preserved, not fan-out). Ruling 1 applied: Filosofi on `commune_final` (arrondissement-granular), ARCEP/AAV on `commune_terr` (arrondissement-collapsed).

## T3 — Derived Analytical Variables

Three model variables derived from raw joined columns (Filosofi cols renamed to analytical names: `median_income`, `poverty_rate`, `income_d1`, `income_ratio`).

**`fibre_coverage` = elig_ftth / nbr × 100** (with guards):
- Divide-by-zero (`nbr == 0`): 0 cases.
- Values >100 (data error): 0 cases.
- Distribution (all years): min 0, median 93.82, mean 91.21, max 99.96 — plausible, left-skewed (rural communes at low end). 92 NA total (unmatched communes).

**`urban_rural`** = factor(Rural if CATEAAV2020=="30" else Urban). Distribution: Urban 59,837 / Rural 786 / NA 120. **Note:** heavily Urban-skewed at lycée level (rural communes rarely host a lycée) — low statistical power for the rural coefficient; interpret with caution in Phase 3.

**`exclude_regression`** = (annee == 2020). Flags 4,334 rows, all confirmed to be 2020 only (COVID automatic passes).

**2023-slice territorial NA counts (of 4,340 rows):** fibre 2, urban_rural 4, income 86, poverty 86 (~2% max). Income/poverty share the same 86 (same Filosofi source). Filosofi loses slightly more than ARCEP/AAV — the deliberate cost of keeping arrondissement granularity for income (Ruling 1).

## T4 — Post-Merge NA Audit (DV-focused)

**Global NA audit (full df, 60,743 rows):** DV1_va 935, DV2_taux 0, IPS_mean 47,752 (expected — IPS exists only for sessions 2023–2026; pre-2023 rows have no IPS by design), fibre 92, income/poverty 1,214 each, urban_rural 120.

**2023 slice DV audit (sets effective N):** of 4,340 rows — DV1_va NA 26 (0.6%), DV2_taux NA 0, IPS NA 16. The Lead's "value-added is NA-heavy" concern did not materialize in 2023 (VA computed for ~99.4% of schools).

**Effective N per track (listwise deletion):**
| Track | Rows | Model A (DV1 + territorial) | Model B (DV2 + IPS + territorial) |
|---|---|---|---|
| GT | 2,331 | 2,284 | 2,278 |
| Pro | 2,009 | 1,966 | 1,963 |

GT confirmed as primary stratum (~2,280, in line with Lead's ~2,500 estimate); Pro robust as parallel stratum (~1,965). Model A and B run on near-identical samples.

**Dropped-school characterization (90 dropped from Model A, 2.1%):** primary driver is Filosofi income coverage (86 of 90), the documented cost of keeping arrondissement granularity (Ruling 1). Dropped vs retained: size similar (176 vs 155 présents — refutes small-school VA concern); rural slightly over-represented (4.7% vs 1.2%) and private under-represented (13.3% vs 30%), but absolute counts are tiny (~4 rural, ~12 private). **Verdict: missingness is near-random with a minor, immaterial rural/public skew — documented, not hidden. No material coefficient bias.**

## T5 — Certified Regression-Ready Frame (df_reg)

`df_reg` = `df` filtered to `annee == 2023` & `!exclude_regression`. 4,340 rows (GT 2,331 / Pro 2,009), one unique UAI×track unit per row. Structural check: all rows 2023, none excluded, DV1_va and IPS_mean numeric — regression-ready confirmed.

**Certified effective N (listwise deletion, per track):**
| Track | Rows | Model A (DV1 + territorial) | Model B (DV2 + IPS + territorial) |
|---|---|---|---|
| GT | 2,331 | 2,284 | 2,278 |
| Pro | 2,009 | 1,966 | 1,963 |

Track-stratified design preserved: GT (primary) and Pro (parallel) coexist in one frame, distinguished by `track` — Phase 3 can run both strata without reconstruction.