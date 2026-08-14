# Digital Divide & Post-COVID Educational Inequality in France

**Project code:** DA-FR-1 · **Analyst:** Carlos F. Franco
**Status:** Stage 3 of 5 — Regression analysis, assigned and not yet started (last updated: August 2026)

> This repository is an active research project, not a finished study. Regression
> results, dashboards and policy conclusions do not exist yet and are not claimed
> below. What is documented here is complete, reviewed and reproducible.

---

## Research question

**What socioeconomic and territorial factors predict Baccalauréat outcomes across French lycées in the post-COVID period?**

The analysis tests whether municipal-level conditions — broadband infrastructure,
household income, poverty, urban/rural location — explain variation in school
performance once student intake composition is accounted for.

| Field | Value |
|---|---|
| Unit of analysis | Lycée (upper secondary school) |
| Regression frame | 2023 cross-section, 4,340 schools (GT 2,331 / Pro 2,009) |
| Descriptive panel | 2019–2024, 60,743 school-year observations |
| Geography | France (metropolitan + overseas départements) |
| Data sources | 9 public administrative datasets |
| Language of analysis | R 4.5.1 |

---

## How this project is run

The project is executed under a **multi-role structure modelled on institutional
analytical practice**: a *project lead* role responsible for scope, quality control and
phase gating, and an *analyst* role responsible for execution. Both roles are performed
by the author.

The separation is deliberate. Each stage closes with a written report that must be
reviewed and signed off before the next stage may begin. The purpose is to force the work
through critical scrutiny at every gate rather than let it advance unquestioned —
reviewing one's own analysis from an explicitly different vantage point is not the same as
reviewing it from the position that produced it.

This is why the reports in this repository carry sign-off and gating language. The
convention is the object of the exercise, not decoration.

**It has already caught a real error.** At the close of Stage 2, the review identified that
an effective-N figure certified in Stage 1 was arithmetically impossible: the
listwise-deletion set had been built on median income but omitted the poverty rate, which
carries additional missing values from small-commune suppression. The magnitude is small
(~2%); the principle is not. Recertification and a written erratum are the first task of
Stage 3 and gate everything below it. **Effective-N figures are therefore not quoted in
this repository until that correction is issued.**

---

## Analytical design

Four models, none of which have yet been estimated:

| Model | Dependent variable | Predictors | Status |
|---|---|---|---|
| **A** (primary) | IVAL value-added score | fibre coverage, median income, poverty rate, urban/rural | Assigned, not estimated |
| **B** (secondary) | Raw Bac pass rate | school social index (IPS) + Model A predictors | Assigned, not estimated |
| **B+** | Raw Bac pass rate | Model B + school sector | Assigned, not estimated |
| **C** (descriptive) | Pass rate by département | mapping only | Not started — Stage 4 |

### Three design choices that define the project

**Track stratification.** All analysis is run separately for the *general/technological*
(GT) and *vocational* (Pro) tracks. The two are never pooled. They differ in outcome
distribution (median pass rate 97% vs 84%), in social composition (IPS 113 vs 96) and in
association structure (IPS↔pass rate r = 0.63 vs 0.40) — pooling would average two
distinct regimes into one uninterpretable coefficient.

**Value-added as primary outcome.** The raw pass rate hits a hard ceiling in the GT track:
a linear fit extrapolates above 100% at high social index values, which is an impossible
prediction. The IVAL value-added measure, which nets out intake composition, is used
instead. The school social index is deliberately excluded from Model A to avoid
circularity — a theoretical claim that was **empirically verified** on this dataset before
being relied upon (correlation of 0.05 GT / 0.00 Pro).

**Commune-clustered standard errors.** Schools in the same commune share identical
territorial predictor values, so residuals are correlated within commune and conventional
standard errors are downward-biased on precisely the headline predictors. Inference will
use CR2 cluster-robust standard errors by commune (~1,393 clusters), reported alongside
classical ones.

---

## Current state

| Stage | Status |
|---|---|
| 0 — Framing and design | ✅ Complete |
| 1 — Data preparation and merge pipeline | ✅ Certified (one figure under erratum) |
| 2 — Descriptive statistics and EDA | ✅ Complete and signed off |
| 3 — Regression analysis | ▶ Assigned, not started |
| 4 — Visualisation and dashboard | ⬜ Not started |
| 5 — Reporting and communication | ⬜ Not started |

**Not yet available:** regression coefficients, model diagnostics, recertified effective N,
Tableau dashboard, OECD benchmarking, policy recommendations.

---

## Findings established so far

Descriptive results from the exploratory phase. They are not causal.

1. **The circularity argument holds empirically.** The value-added score carries
   essentially no linear association with parental socioeconomic status
   (r = 0.05 GT / 0.00 Pro), validating its exclusion from Model A.

2. **A ~17-point social index gap separates the two tracks** (GT 113, Pro 96) — a direct
   measure of social segregation between the general and vocational pathways.

3. **The socioeconomic gradient is far stronger in GT than in Pro**
   (pass rate vs IPS: r = 0.63 vs 0.40). The tracks differ not only in level but in the
   structure of association.

4. **Most of the private-sector advantage is intake composition, not school
   effectiveness.** In the vocational track a raw gap of 13 percentage points narrows to
   roughly 3 in value-added terms. In the general track, 4 points narrows to roughly 2.
   Indicative, pending Model B+ estimation.

5. **2021 is methodologically atypical, not only 2020.** Pass rates spike across every
   category and both tracks under that session's relaxed assessment arrangements. The
   original design excluded 2020 only. Harmless for the 2023 cross-section; constraining
   for any descriptive before/after framing.

6. **A persistent rural advantage in the vocational track**, contrary to the rural-penalty
   hypothesis in the original brief — Rural exceeds Urban core by 5–7 points in every year
   observed. Based on 34 schools; reported but not interpreted.

7. **The urban/rural gap does not widen after COVID.** The vocational gap is approximately
   6 points before and after. No descriptive evidence that the disruption amplified
   territorial inequality in Bac outcomes.

8. **Fibre coverage shows almost no bivariate association with either outcome**
   (r = 0.15 / 0.01 with pass rate; −0.11 / −0.05 with value-added), with a compressed
   distribution (median 93.8%).

### Pre-registered expectation

**Model A is expected to return a very low R² — of the order of 1–2% in the general track
and below 1% in the vocational track — and this is declared in writing before
estimation.** If confirmed, it will be reported as a substantive finding rather than a
failure: net of intake composition, territorial conditions would explain almost none of
the variation in school value-added, consistent with the Coleman tradition and locating
post-COVID educational inequality in the social composition of school intakes rather than
in municipal conditions.

---

## Repository structure

```
DA-FR-1/
├── DA-FR-1.Rproj              # open the project via this file
├── .gitignore
│
├── 01_reconnaissance.R        # loads and inspects the 9 raw datasets
├── 02_build_join_inputs.R     # builds 6 validated input frames
├── 03_execute_joins.R         # merges, derives variables, certifies the regression frame
├── 04_eda.R                   # Stage 2 exploratory analysis — complete
│
├── intake_report.md           # Stage 1 Step 1 — signed off
├── join_readiness_report.md   # Stage 1 Step 2 — signed off
├── integrity_report.md        # Stage 1 Step 3 — certified, one figure under erratum
├── eda_report.md              # Stage 2 — complete and signed off
│
├── data/
│   ├── raw/                   # 9 source files, never modified — versioned
│   └── processed/             # generated artefacts — not versioned
│
└── output/
    └── figures/               # 13 figures, 300 dpi — versioned
```

## Reproducibility

Run the scripts in order from a clean R session:

```
01_reconnaissance.R  →  02_build_join_inputs.R  →  03_execute_joins.R  →  04_eda.R
```

Scripts `02` and `03` regenerate all processed artefacts from the raw sources. No manual
step is required at any point.

**Versioning policy.** Raw source data is versioned to guarantee reproducibility and to
preserve the exact snapshot the analysis was run on — several publishers overwrite their
files periodically. Processed artefacts are not versioned, as they are deterministically
regenerated by the pipeline. Code and figures are versioned.

**Verification standard.** No script is committed until it has been verified to run from a
clean session (`Session → Restart R`, then `source()`). Commits follow Conventional Commits
and are atomic — one logical change each. Commit and push happen together: a commit that
has not been pushed is not backed up.

---

## Data sources

| Source | Publisher | Content |
|---|---|---|
| IVAL (GT and Pro) | DEPP — Ministry of Education | School value-added indicators, 2023 |
| IPS Lycées 2022, 2023 | DEPP | Social position index by school |
| Annuaire de l'éducation | Ministry of Education | School directory and commune crosswalk |
| Bac results by département | DEPP | Pass rates, 2023–2025 |
| Filosofi 2021 (COM) | INSEE | Median income and poverty rate by commune |
| ARCEP MCI 2024T4 | ARCEP | FTTH broadband coverage by commune |
| AAV 2020 | INSEE | Urban/rural classification |

Licence terms per source: `[TO CONFIRM before public release]`

---

## Documented methodological decisions

Six substantive choices departing from the original brief are logged with their rationale,
including track stratification, a dual commune-key strategy resolving a granularity
mismatch between datasets, a three-level urban/rural recoding, and the correction of a
silent numeric conversion failure caused by French decimal commas combined with INSEE
statistical-secrecy codes.

One claim in the original brief has been **formally withdrawn**: a panel fixed-effects
robustness check on territorial predictors is not identified, since single-vintage
territorial variables demean to zero under school fixed effects. Adjacent-year coefficient
stability replaces it.

Full decision log: `docs/decision_log.md` *(in preparation)*

---

## Known limitations

- The broadband snapshot is 2024, measured against a 2020–21 exposure window; it is framed
  as a proxy for persistent territorial infrastructure, not contemporaneous exposure.
- Income data carries a two-year lag relative to the outcome year.
- Fibre coverage is a supply-side availability measure, not actual household usage.
- The social index definition breaks between the 2022 and 2023 files; it has been
  harmonised to a common schema and the break is caveated wherever adjacent years are
  compared.
- The rural category is thin (22 GT / 34 Pro schools). It is retained because dissolving it
  would make a rural effect unmeasurable by construction, but its coefficient will be
  reported and not interpreted.
- A small share of schools is dropped by listwise deletion, driven mainly by INSEE income
  and poverty suppression codes. The exact figure is under recertification.

---

## Author

**Carlos F. Franco** — Economist working in data analysis for social impact
MBA in Technology for Business (AI, Data Science, Big Data), PUCRS
