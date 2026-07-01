# DA-FR-1 — Phase 1, Step 2: Join-Readiness Report

**Analyst:** Carlos F. Franco
**Date:** June 2026
**Purpose:** Validate that all join inputs are cleaned and uniquely keyed before any merge (Step 3).

## T1 — Clean Crosswalk (Annuaire)

**Input:** `rep_annuaire_edu_V2.xlsx` — 4,907 rows (100% Lycée, defensive filter applied).
**Cleaning:** `code_commune` stripped of `.0` xlsx artifact + zero-padded to 5 chars. All codes validated against `^(\d{5}|2[AB]\d{3})$` — 0 malformed.
**Duplicates:** 33 duplicated UAI found. Split into benign (same commune) vs genuine (different communes).
**Genuine conflicts:** 19 UAI mapping to >1 commune (Lead expected ~5). Resolved via documented conflict log (8 resolved on textual basis, 11 pending external verification).
**Output:** `crosswalk_final` — 4,873 rows, 1 per UAI. Columns: `UAI, code_commune, sector`.
**Uniqueness proof:** `nrow == n_distinct(UAI) == 4,873`; `count(UAI) |> filter(n>1)` = 0 rows. ✅

## T2 — Standardized Commune-Level Keys

All commune keys standardized via `str_pad(str_remove(key, "\\.0$"), 5, pad="0")` and validated against `^(\d{5}|2[AB]\d{3})$`. No derivations performed (raw columns kept — transforms deferred to Step 3).

| Input frame | Source | Key | Cols kept | Distinct = Rows | Malformed keys |
|---|---|---|---|---|---|
| `filosofi_input` | `cc_filosofi_2021_COM.csv` | `CODGEO` | CODGEO, MED21, TP6021, D121, RD21 | 34,919 | 0 |
| `arcep_input` | `arcep_mci_commune_2024T4.csv` | `code_insee` | code_insee, elig_ftth, nbr | 34,937 | 0 |
| `aav_input` | `aav2020_urban_rural.xlsx` | `CODGEO` | CODGEO, CATEAAV2020 | 34,875 | 0 |

**Note:** `fibre_coverage` (`elig_ftth`/`nbr`) and urban/rural recoding (`CATEAAV2020`) intentionally deferred to Step 3 per Lead ruling.

## T3 — IVAL Anchor (track-stratified, Ruling 1)

**C1 confirmed:** GT and Pro share only 15 of 88 column names; 73 diverge per side (track-specific series). Some near-shared columns differ by accent (`Présents - Toutes séries` GT vs `series` Pro) — handled by selecting per-file exact names and renaming to a common schema.

**Assembly:** selected common core by exact name (C4-compliant): `UAI, annee, etablissement, code_commune, secteur, presents, DV2_taux (Taux de réussite - Toutes séries), DV1_va (Valeur ajoutée … Toutes séries)`. Added `track` ("GT"/"Pro") before binding.

**Output:** `ival_anchor` — 60,743 rows (32,485 GT + 28,258 Pro).

**Uniqueness proof:** `count(UAI, annee, track) |> filter(n>1)` = 0 rows. Panel key `UAI + annee + track` is unique. ✅

**LPO verification:** the 983 shared UAI appear as paired rows across both tracks (GT: 12,176; Pro: 12,111), confirming polyvalents are now legitimate separate observations, not duplicates. Guide's `anti_join == 0` assumption formally superseded.

### T3.1 — C1 confirmed (GT/Pro column divergence)

Both files have 88 columns but share only 15 (`intersect`); 73 differ per side (track-specific series: GT has L/ES/S/STMG…, Pro has Transformations/Services/Production…). **Additional catch:** some seemingly-shared columns differ by accents across files — `Présents - Toutes séries` (GT) vs `Présents - Toutes series` (Pro), `Taux d'accès 1ere-bac` (GT) vs `Taux d'acces 1ere-bac` (Pro). Both DVs (`Taux de réussite - Toutes séries`, `Valeur ajoutée du taux de réussite - Toutes séries`) ARE identical across files. Common core selected by exact per-file name.

## T4 — Harmonized IPS (rename + rentrée→session mapping, C3)

**Schema harmonization:** IPS 2022 and 2023 use different column names for the same concepts. Renamed both to common schema `UAI, rentree, IPS_mean, IPS_std`. (IPS_mean: `IPS Ensemble GT-PRO` in 2022 vs `IPS de l'établissement` in 2023 — definition break documented; IPS_std is descriptive-only per Brief.)

**Mapping rule (C3):** rentrée `AAAA-BBBB` → Bac session `BBBB` (exit year). Applied via `str_sub(rentree, 6, 9)`.

| rentree | → session (annee) | source | rows |
|---|---|---|---|
| 2022-2023 | 2023 | IPS 2022 | 3,598 |
| 2023-2024 | 2024 | IPS 2023 | 3,612 |
| 2024-2025 | 2025 | IPS 2023 | 3,631 |
| 2025-2026 | 2026 | IPS 2023 | 3,662 |

**Consequence for Model B:** IPS covers sessions 2023–2026 only. Model B (uses IPS) is bounded to these years — cannot use IVAL's long panel. Session 2023 IPS_mean uses the 2022 definition; 2024+ use the 2023 definition (methodological break at 2023/2024 boundary).

**Output:** `ips_input` — 14,503 rows. Columns: `UAI, annee, IPS_mean, IPS_std`.
**Uniqueness proof:** `count(UAI, annee) |> filter(n>1)` = 0 rows. ✅

### Conflict Resolution Log (19 UAI)

| UAI | Chosen commune | Status | Rationale |
|---|---|---|---|
| 0440980B | 44079 | resolved | Ancenis is 'site d'' secondary; Le Landreau is main seat |
| 0570279U | 57177 | resolved | Freyming is 'Annexe'; Dieuze is main seat |
| 0690543R | 69149 | resolved | Mornant is 'Annexe'; Oullins is main seat |
| 0690521S | 69385 | resolved | La Verpilliere is 'site de'; Lyon 5e is main seat |
| 0570225K | 57097 | resolved | Kept 'Lycee professionnel' (Boulay), not 'Centre d'accueil' |
| 0573734Z | 57463 | resolved | 3 sites; Metz is main seat |
| 0690539L | 69387 | resolved | Lyon 7e is main urban seat of Assomption Bellevue |
| 0770920G | 77079 | resolved | 'Lycee polyvalent La Fayette' fuller name = main seat |
| 0382371W | 38138 | pending | No annexe marker; Cremieu provisional |
| 0740283F | 74213 | pending | Two rural communes; Poisy provisional |
| 0750770E | 75103 | pending | Paris arrondissement; needs official check |
| 0752845K | 75112 | pending | Paris arrondissement; needs official check |
| 0754025T | 75106 | pending | Paris arrondissement; needs official check |
| 0754874R | 75105 | pending | Paris arrondissement; needs official check |
| 0754875S | 75105 | pending | Paris arrondissement; needs official check |
| 0350778F | 35238 | pending | Different school names; needs verification |
| 0783288A | 78586 | pending | Different school names; needs verification |
| 0820725T | 82037 | pending | Different school names (depts 82 vs 46); needs verification |
| 9840160B | 98738 | pending | French Polynesia; likely no territorial coverage |