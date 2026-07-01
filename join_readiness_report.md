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