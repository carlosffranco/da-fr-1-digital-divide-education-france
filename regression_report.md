# DA-FR-1 — Phase 3: Regression Analysis

Models A, B and B+ estimated per track (GT / Pro) on the certified 2023
cross-section. Headline inference uses CR2 commune-clustered standard errors.
Expectations were pre-registered in the Phase 2 report before any model was
fitted and are adjudicated in the closing section.

---

## T0 — Effective N recertification

**Erratum against Phase 1 Step 3.** Step 3 certified Model A effective N at
GT 2,284 / Pro 1,966. Those figures are incorrect and are superseded here. The
Step 3 listwise-deletion set was constructed on `median_income` (86 NA) but
omitted `poverty_rate` (184 NA); the two variables do not share the same missing
rows, as `poverty_rate` carries additional NAs arising from INSEE's small-commune
suppression codes ("s" / "nd"). Because both models include `poverty_rate`, the
certified figures exceeded the maximum attainable N — an arithmetic impossibility.

Effective N is recomputed below on the complete predictor set for each model,
including the dependent variable, replicating the listwise deletion `lm()`
performs internally.

| Track | Rows in `df_reg` | Model A | Model B | Model B+ |
|---|---:|---:|---:|---:|
| GT | 2,331 | 2,243 | 2,237 | 2,237 |
| Pro | 2,009 | 1,909 | 1,907 | 1,907 |

**Reconciliation.** Model A loses 41 rows (GT) and 57 rows (Pro) relative to the
superseded Step 3 figures. Listwise deletion removes 3.8% of GT rows and 5.0% of
Pro rows; the dropped subset was audited in Phase 1 and found near-random.

**Two structural notes.** Adding `IPS_mean` (Model B) costs only 6 rows in GT and
2 in Pro, fewer than its total NA count, because part of its missingness falls on
rows already excluded by another variable — the same overlap effect that produced
the original error. Adding `secteur` (Model B+) costs nothing: the variable is
complete in both tracks.

Phase 1 is not reopened. The figure is recertified here and all Phase 3 tables
report these values.