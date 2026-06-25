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
| `ips_Lycees_2022.csv` | 3,598 | 18 | `UAI` | `;` | UTF-8 | Single cohort (`Rentrée scolaire` = 2022-2023). Column names **differ from IPS 2023**: IPS_mean = `IPS Ensemble GT-PRO` (col 16), IPS_std = `Ecart-type de l'IPS voie GT` (col 17). Must `rename()` to common names before `bind_rows()` with 2023. IPS_std definition not comparable across years → descriptive only. |
| `cc_filosofi_2021_COM.csv` | 34,919 | 28 | `CODGEO` | `;` | UTF-8 | Flag #8 resolved: `CODGEO` (col 1), `MED21` (col 4), `TP6021` (col 6) all present. Encoding clean in UTF-8 (headers are accent-free codes). Bonus robustness cols: `D121`, `D921`, `RD21`. Initial inventory header-parse failure was a delimiter issue (needs `;`). |
| `bac_par_departement_2023_2025.csv` | 1,818 | 10 | `Code département` | `;` | UTF-8 | Model C only. Flag #6 confirmed: rows split by `Voie` (Générale/Professionnelle/Technologique) × `Genre` (Féminin/Masculin) × `Session` (2023/24/25) = 18 combos × ~101 depts. **No pre-computed total row.** Must aggregate as Σ`admis`/Σ`présents` per dept — never average the rate column. Balanced table (all combos present). |
| `rep_annuaire_edu_V2.xlsx` (Sheet1) | 4,907 | 63 | `Identifiant_de_l_etablissement` → `Code_commune` | xlsx | — | Crosswalk file. All 4 key cols present: `Identifiant_de_l_etablissement` (UAI, col 1), `Code_commune` (col 10), `Type_etablissement` (col 2, filter to lycée), `Statut_public_prive` (col 3). `Appartenance_Education_Prioritaire` (col 46) present → explains `rep_` name, but REP not valid at lycée level → not used (per Brief). 4,907 rows > target → includes non-lycée types; filter needed. `multi_uai` col present → watch for duplicates in Obj. 3. |
| `aav2020_urban_rural.xlsx` (Composition_communale) | 34,875 | 7 | `CODGEO` | xlsx | — | **Real header on row 6 → `skip = 5`** (rows 1–5 are title/metadata; row 5 is descriptive labels, row 6 is short codes). `CODGEO` + `CATEAAV2020` present. CATEAAV2020 distribution: 20=24,236 (69%), 30=8,897 (26%), 11/12/13=1,742 (5%). Distribution supports binary Urban/Rural coding (cat 13 has only 33 communes). |

## 2. Discrepancy Resolution (8 flags)

| Flag | Description | Status | Evidence |
|---|---|---|---|
| #1 | ARCEP fibre column misspelled (`elig_fith`) | Confirmed | Real column is `elig_ftth` (position 8 in `names(arcep)`). |
| #3 | IVAL multi-year vs single 2023 | Confirmed (panel) | Both GT & Pro return 14 years (2012–2025) via `count(Année)`; row counts sum to dim in both. |
| #5 | Year column casing (`année` vs real) | Confirmed | Real column is `Année` (capital A + accent), position 1 in both IVAL files. |
| #4 | IPS 2023 suspicious row count (10,905) | Confirmed | 3 stacked cohorts via `count(Rentrée scolaire)`; rows sum to dim. Extra granularity (>target lycées) flagged for Obj. 3. |
| (IPS schema) | IPS 2022 vs 2023 column names differ | Confirmed | 2022 uses `IPS Ensemble GT-PRO` / `Ecart-type de l'IPS voie GT`; 2023 uses `IPS de l'établissement` / `Ecart-type établissement`. Rename required pre-bind. |
| #8 | Filosofi unverified (cols / encoding / delimiter) | Confirmed OK | `;`-delimited, UTF-8 clean. `CODGEO`, `MED21`, `TP6021` all present. 34,919 communes. |
| #6 | bac_par_departement not one rate per dept | Confirmed | `count()` shows no "ensemble" in Voie or Genre; only disaggregated rows. Weighted aggregation (Σadmis/Σprésents) required for dept totals. |
| #2 (annuaire) | Annuaire is xlsx (not csv) & name hints REP | Confirmed | Single sheet `Sheet1`, 63 cols. Crosswalk keys present. `Appartenance_Education_Prioritaire` exists but excluded (REP not valid for lycées, per Brief). |
| #2 (aav) | AAV is xlsx; correct sheet & header position | Confirmed | 4 sheets; data in `Composition_communale`. Header on row 6 (`skip = 5`). Binary urban/rural empirically supported (cats 20+30 = 95%). |

## 3. Architecture Verdict

**PANEL (multi-year, 2012–2025).** Both IVAL files (GT and Pro) contain 14 years of data, ~one row per school per year, despite the `_2023` filename. This preserves the full study scope: the main regression runs on the `Année == 2023` cross-section, while the panel fixed-effects robustness check (2022–2024) and the pre/post-COVID descriptive trend (2019–2024, excluding 2020) remain feasible. No re-scoping required.
