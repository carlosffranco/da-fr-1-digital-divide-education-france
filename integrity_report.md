# DA-FR-1 — Phase 1, Step 3: Post-Merge Integrity Report

**Analyst:** Carlos F. Franco
**Purpose:** Reconcile commune sources, execute joins with row-count assertions, derive variables, audit NAs, and certify df_reg.

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