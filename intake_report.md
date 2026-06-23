# DA-FR-1 — Phase 1, Step 1: Data Intake & Reconnaissance Report

**Analyst:** Carlos F. Franco
**Date:** June 2026
**Environment:** RStudio Desktop, R 4.5.1 (aarch64)

## 1. File Inventory

| File | Rows | Cols | Join key | Delim | Encoding | Notes / flags |
|---|---|---|---|---|---|---|
| `arcep_mci_commune_2024T4.csv` | 34,937 | 16 | `code_insee` | `;` | UTF-8 | Flag #1 confirmed: actual column is `elig_ftth`, not `elig_fith` (guide typo). `nbr` present (denominator for fibre_coverage). `type` appears constant (`"all"`) — verify duplicates in Obj. 3. Leading zeros preserved (read as character). |
| `ival_gt_lycees_2023.csv` | 32,485 | 88 | `UAI` | `;` | UTF-8 | **Multi-year panel 2012–2025** (~2,300 rows/year) despite `_2023` filename. Flag #5: year column is `Année` (not `année`). DV-1 & DV-2 present (cols 14, 13). `Code commune` present (col 5). |
| `ival_pro_lycees_2023.csv` | 28,258 | 88 | `UAI` | `;` | UTF-8 | **Multi-year panel 2012–2025** (~2,000 rows/year). Same 88-column structure as GT. Confirms panel architecture. Row counts sum to dim. |
| `ips_Lycees_2023.csv` | 10,905 | 48 | `UAI` | `;` | UTF-8 | Flag #4: 3 stacked cohorts (`Rentrée scolaire` = 2023-24, 2024-25, 2025-26; sum = 10,905). **New flag:** ~3,600 rows/cohort > ~2,500 target lycées → likely extra establishment types; verify distinct/duplicate UAI in Obj. 3. IPS_mean = `IPS de l'établissement` (col 18) ✅; IPS_std = `Ecart-type établissement` (col 21) ✅. Year format `YYYY-YYYY` differs from IVAL `YYYY`. |

## 2. Discrepancy Resolution (8 flags)

| Flag | Description | Status | Evidence |
|---|---|---|---|
| #1 | ARCEP fibre column misspelled (`elig_fith`) | Confirmed | Real column is `elig_ftth` (position 8 in `names(arcep)`). |
| #3 | IVAL multi-year vs single 2023 | Confirmed (panel) | Both GT & Pro return 14 years (2012–2025) via `count(Année)`; row counts sum to dim in both. |
| #5 | Year column casing (`année` vs real) | Confirmed | Real column is `Année` (capital A + accent), position 1 in both IVAL files. |
| #4 | IPS 2023 suspicious row count (10,905) | Confirmed | 3 stacked cohorts via `count(Rentrée scolaire)`; rows sum to dim. Extra granularity (>target lycées) flagged for Obj. 3. |

## 3. Architecture Verdict

**PANEL (multi-year, 2012–2025).** Both IVAL files (GT and Pro) contain 14 years of data, ~one row per school per year, despite the `_2023` filename. This preserves the full study scope: the main regression runs on the `Année == 2023` cross-section, while the panel fixed-effects robustness check (2022–2024) and the pre/post-COVID descriptive trend (2019–2024, excluding 2020) remain feasible. No re-scoping required.
