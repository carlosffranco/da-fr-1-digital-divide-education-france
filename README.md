# Digital Divide & Post-COVID Educational Inequality in France

**Project code:** DA-FR-1 · **Analyst:** Carlos F. Franco
**Status:** Phase 2 of 5 — Exploratory Data Analysis, in progress (last updated: August 2026)

> This repository is an active research project, not a finished study. Regression
> results, dashboards and policy conclusions do not exist yet and are not claimed
> below. What is documented here is complete, certified and reproducible.

---

## Research question

**What socioeconomic and territorial factors predict Baccalauréat outcomes across French lycées in the post-COVID period?**

The analysis tests whether municipal-level conditions — broadband infrastructure,
household income, poverty, urban/rural location — explain variation in school
performance once student intake composition is accounted for.

| Field | Value |
|---|---|
| Unit of analysis | Lycée (upper secondary school) |
| Regression sample | 2023 cross-section, n = 4,340 schools |
| Descriptive panel | 2019–2024, 60,743 school-year observations |
| Geography | France (metropolitan + overseas départements) |
| Data sources | 9 public administrative datasets |
| Language of analysis | R 4.5.1 |

---

## Analytical design

Three models, of which none have yet been estimated:

| Model | Dependent variable | Predictors | Status |
|---|---|---|---|
| **A** (primary) | IVAL value-added score | fibre coverage, median income, poverty rate, urban/rural | Not yet estimated — Phase 3 |
| **B** (secondary) | Raw Bac pass rate | school social index (IPS) + Model A predictors | Not yet estimated — Phase 3 |
| **C** (descriptive) | Pass rate by département | mapping only | Not yet built — Phase 4 |

### Two design choices that define the project

**Track stratification.** All analysis is run separately for the *general/technological*
(GT) and *vocational* (Pro) tracks. The two are never pooled. They differ in outcome
distribution (median pass rate 97% vs 84%), in social composition (IPS 113 vs 96) and
in association structure — pooling would average two distinct regimes into one
uninterpretable coefficient.

**Value-added as primary outcome.** The raw pass rate hits a hard ceiling in the GT
track: a linear fit extrapolates above 100% at high social index values, which is an
impossible prediction. The IVAL value-added measure, which nets out intake
composition, is used instead. The school social index is deliberately excluded from
Model A to avoid circularity — a theoretical claim that was **empirically verified**
on this dataset before being relied upon (correlation of 0.05 GT / 0.00 Pro).

---

## Current state

| Stage | Status |
|---|---|
| 0 — Framing and design | ✅ Complete |
| 1 — Data preparation and merge pipeline | ✅ Complete and certified |
| 2 — Descriptive statistics and EDA | ▶ In progress (5 of 6 tasks) |
| 3 — Regression analysis | ⬜ Not started |
| 4 — Visualisation and dashboard | ⬜ Not started |
| 5 — Reporting and communication | ⬜ Not started |

**Not yet available:** regression coefficients, model diagnostics, Tableau dashboard,
OECD benchmarking, policy recommendations.

---

## Findings established so far

These are results from the exploratory phase. They are descriptive, not causal.

1. **The circularity argument holds empirically.** The value-added score carries
   essentially no linear association with parental socioeconomic status
   (r = 0.05 GT / 0.00 Pro), validating its exclusion from Model A.

2. **A ~17-point social index gap separates the two tracks** (GT 113, Pro 96) — a
   direct measure of social segregation between the general and vocational pathways.

3. **The socioeconomic gradient is far stronger in GT than in Pro**
   (pass rate vs IPS: r = 0.63 vs 0.40). The tracks differ not only in level but in
   the structure of association.

4. **The raw pass rate has a hard ceiling in GT** (median 97%), providing direct
   visual evidence for the value-added specification.

5. **Fibre coverage shows almost no bivariate association with either outcome**
   (r = 0.15 / 0.01 with pass rate; −0.11 / −0.05 with value-added) and its
   distribution is compressed (median 93.8%).

### Pre-registered expectation

**Model A is expected to return a very low R² (order of 1–2%), and this is declared
in writing before estimation.** If confirmed, it will be reported as a substantive
finding rather than a failure: net of intake composition, territorial conditions
would explain almost none of the variation in school value-added — consistent with
the Coleman tradition, and locating post-COVID educational inequality in the social
composition of school intakes rather than in municipal conditions.

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
├── 04_eda.R                   # Phase 2 exploratory analysis (in progress)
│
├── intake_report.md           # Phase 1 Step 1 — signed off
├── join_readiness_report.md   # Phase 1 Step 2 — signed off
├── integrity_report.md        # Phase 1 Step 3 — certified
├── eda_report.md              # Phase 2 — in progress
│
├── data/
│   ├── raw/                   # 9 source files, never modified — versioned
│   └── processed/             # generated artefacts — not versioned
│
└── output/
    └── figures/               # 9 figures, 300 dpi — versioned
```

## Reproducibility

Run the scripts in order from a clean R session:

```
01_reconnaissance.R  →  02_build_join_inputs.R  →  03_execute_joins.R  →  04_eda.R
```

Scripts `02` and `03` regenerate all processed artefacts from the raw sources. No
manual step is required at any point.

**Versioning policy.** Raw source data is versioned to guarantee reproducibility and
to preserve the exact snapshot the analysis was run on — several publishers overwrite
their files periodically. Processed artefacts are not versioned, as they are
deterministically regenerated by the pipeline. Code and figures are versioned.

**Verification standard.** No script is committed until it has been verified to run
from a clean session (`Session → Restart R`, then `source()`). Commits follow
Conventional Commits and are atomic — one logical change each.

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

Six substantive choices departing from the original brief are logged with their
rationale, including track stratification, a dual commune-key strategy resolving a
granularity mismatch between datasets, a three-level urban/rural recoding, and the
correction of a silent numeric conversion failure caused by French decimal commas
combined with INSEE statistical-secrecy codes.

Full decision log: `docs/decision_log.md` *(in preparation)*

---

## Known limitations

- The broadband snapshot is 2024, measured against a 2020–21 exposure window; it is
  framed as a proxy for persistent territorial infrastructure, not contemporaneous exposure.
- Income data carries a two-year lag relative to the outcome year.
- Fibre coverage is a supply-side availability measure, not actual household usage.
- The social index definition breaks between the 2022 and 2023 files; it has been
  harmonised to a common schema and the break is documented.
- Approximately 2.1% of schools are dropped by listwise deletion, driven mainly by
  INSEE income suppression codes. The dropped subset was audited and found near-random.

---

## Author

**Carlos F. Franco** — Data Analyst
MBA in Technology for Business (AI, Data Science, Big Data), PUCRS
