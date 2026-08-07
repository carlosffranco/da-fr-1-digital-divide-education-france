# DA-FR-1 — Phase 2: Descriptive Statistics & EDA Report

**Analyst:** Carlos F. Franco
**Purpose:** De-risk the regression before running it — diagnose distributions, coding decisions, collinearity, and bivariate relationships. All analysis is **per track (GT / Pro), never pooled.**

## P2-T1 — Summary Statistics (per track)

Continuous model variables, 2023 cross-section (`df_reg`, n = 4,340: GT 2,331 / Pro 2,009).

| Track | Variable | n | Mean | Median | SD | Min | Max | NA |
|---|---|---|---|---|---|---|---|---|
| GT | DV1_va | 2,319 | -0.25 | 0 | 2.99 | -19 | 19 | 12 |
| GT | DV2_taux | 2,331 | 95.4 | 97 | 4.74 | 56 | 100 | 0 |
| GT | IPS_mean | 2,322 | 113.0 | 112 | 15.5 | 64.1 | 163 | 9 |
| GT | IPS_std | 2,322 | 31.1 | 31.8 | 4.38 | 6.3 | 41.8 | 9 |
| GT | fibre_coverage | 2,330 | 91.4 | 93.8 | 11.4 | 0 | 100 | 1 |
| GT | median_income | 2,285 | 22,667 | 21,420 | 4,851 | 13,530 | 48,010 | 46 |
| GT | poverty_rate | 2,244 | 19.6 | 19 | 7.44 | 5 | 52 | 87 |
| Pro | DV1_va | 1,995 | -0.70 | 0 | 7.45 | -55 | 29 | 14 |
| Pro | DV2_taux | 2,009 | 83.8 | 84 | 9.77 | 31 | 100 | 0 |
| Pro | IPS_mean | 2,002 | 96.3 | 95.2 | 13.5 | 64.1 | 143 | 7 |
| Pro | IPS_std | 922 | 31.3 | 31.8 | 3.68 | 11.4 | 44.5 | 1,087 |
| Pro | fibre_coverage | 2,008 | 90.8 | 93.8 | 12.8 | 0 | 100 | 1 |
| Pro | median_income | 1,969 | 21,789 | 21,150 | 3,843 | 13,530 | 48,010 | 40 |
| Pro | poverty_rate | 1,912 | 20.4 | 21 | 7.48 | 5 | 52 | 97 |

### Key findings

1. **DV2 (raw Bac rate) — ceiling effect in GT.** GT median 97, SD 4.74: half of GT lycées are at ≥97% pass rate, compressed against the 100 ceiling with little usable variance. Pro is far more dispersed (median 84, SD 9.77). Confirms the Brief's rationale for using value-added (DV1), not raw rate, as Model A's dependent variable.

2. **DV1 (value-added) — correctly centered at 0.** Both tracks have median exactly 0 (value-added is a residual, so centering at zero is by construction). Unlike the raw rate, DV1 retains usable dispersion (GT SD 3.0, Pro SD 7.5), making it the appropriate DV for Model A. Pro shows much wider spread (range -55 to 29).

3. **fibre_coverage — compressed at the median but not variance-dead (Catch 1).** Median 93.8 in both tracks (saturated near the top), but SD is moderate (GT 11.4, Pro 12.8) because the lower tail — rural communes down to 0% — injects variance. Verdict: usable predictor for Model A, identified mainly off low-coverage communes; frame as a persistent-infrastructure proxy with the ARCEP-2024 vs COVID-era temporal caveat.

4. **IPS_mean — the ~17-point GT/Pro social gap (key inequality finding).** GT mean IPS 113 vs Pro 96.3. Pro students come from systematically more disadvantaged backgrounds, quantifying the social segregation between tracks that motivates the study. Reinforces the never-pool rule.

5. **IPS_std in Pro — >50% missing.** Pro IPS_std has 1,087 NA of ~2,009 (n=922 valid) vs near-complete in GT. Descriptive-only per Brief (not in regression), but unusable for Pro. Documented; likely tied to the cross-year IPS_std definition difference noted in Step 2.

**Temporal note for Model B:** IPS covers sessions 2023–2026 only; the 2023 headline uses the 2022 IPS definition (single-definition, clean).

## P2-T2 — Distribution Diagnostics (histograms, per track)

Histograms of the three key model variables, split by track. Figures saved to `output/figures/`.

**Note on missing values:** histograms are computed on non-missing rows (NAs filtered explicitly before plotting). Per-variable NA counts are in the P2-T1 table. Exclusions are minor and non-systematic — the largest are IPS_std in Pro (1,087 NA, descriptive-only, not used in regression), poverty_rate (GT 87 / Pro 97, from INSEE "s"/"nd" suppression codes), median_income (GT 46 / Pro 40), and DV1_va (GT 12 / Pro 14). DV2_taux has 0 NA.

### Findings

**1. DV2_taux (raw Bac rate) — ceiling effect confirmed visually.**
GT: mass compressed against the 100% ceiling, median 97, with a short left tail. Pro: more dispersed, peak around 80–84, longer spread. Visual confirmation of the ceiling effect — justifies using value-added (DV1), not the raw rate, as Model A's DV.
`p2t2_dv2_hist.png`

**2. DV1_va (value-added) — symmetric, centered on 0.**
GT: tight, near-normal bell centered on 0 (SD ≈ 3), i.e. a modest school effect; ~68% of GT lycées fall within ±1 SD (roughly 0 ± 3 points). Pro: much wider (SD ≈ 7.5), fatter tails (down to −55), with a slight negative skew (mean −0.70 < median 0). Being centered on 0 confirms DV1 is a residual by construction and the appropriate DV for Model A. Pro's heavy left tail flags outlier sensitivity for Phase 3 diagnostics.
`p2t2_dv1_hist.png`

**3. fibre_coverage — left-skewed; compressed at ceiling but with usable variance (Catch 1).**
Both tracks: mass saturated near 90–100% with a long left tail toward 0 (rural low-coverage communes). Mean < median (GT 91.4 < 93.8; Pro 90.8 < 93.8) confirms the left skew. SD is moderate (GT 11.4, Pro 12.8) — the left tail injects usable variance despite the high median. **Verdict:** fibre is a viable Model A predictor, identified primarily off low-coverage communes; frame as a persistent-infrastructure proxy with the ARCEP-2024 vs COVID-era temporal caveat.
`p2t2_fibre_hist.png`

**Cross-cutting:** all three diagnostics reinforce the never-pool rule — GT and Pro differ in shape (GT tighter and more ceiling-bound; Pro wider with heavier tails) on every variable.

### P2-T3 — Urban/rural coding decision

**Issue (Lead Catch 2).** The Brief provisionally adopted a binary coding
(`urban_rural`: Rural if CATEAAV2020 == 30, Urban otherwise). At lycée level this
produces a near-empty Rural cell and collapses all urban gradations into one group.
Phase 2 was tasked with tabulating the full CATEAAV2020 distribution and
recommending a coding before Phase 3.

**Full CATEAAV2020 distribution (2023 cross-section, per track).**

| CATEAAV2020 | Category | GT | Pro |
|---|---|---:|---:|
| 11 | Large urban centre | 1,420 | 1,147 |
| 12 | Mid-sized urban centre | 473 | 422 |
| 13 | Small urban centre | 38 | 33 |
| 20 | Suburban belt (couronne) | 376 | 371 |
| 30 | Rural / outside AAV | 22 | 34 |
| NA | Unmatched commune | 2 | 2 |

**Findings.**
1. The binary coding hides a substantial group: 747 lycées (17.2% of the sample)
   sit in the suburban belt (code 20) and were classified as "Urban", despite
   being structurally distinct from urban centres.
2. The Rural cell is genuinely small (56 lycées, 1.3%). This is a feature of the
   French school map — lycées are concentrated in urban areas — not a data defect.
3. Codes 13 (71 lycées) and 30 (56 lycées) are too small to support standalone
   regression coefficients; codes 11 and 12 are large and substantively similar
   (urban centres of different size).

**Decision.** Adopt a 3-level coding, `urban_rural3`, with Urban core as the
reference level:

| Level | Groups CATEAAV2020 | GT | Pro |
|---|---|---:|---:|
| Urban core (reference) | 11, 12, 13 | 1,931 | 1,602 |
| Suburban | 20 | 376 | 371 |
| Rural | 30 | 22 | 34 |

**Rationale.** The 3-level coding recovers the urban-core / suburban distinction
erased by the binary (17.2% of the sample) while avoiding the near-empty cells
that a raw 5-level coding would produce. Rural is retained as a separate level
rather than merged into a combined peripheral category: the study's research
question concerns territorial inequality, and dissolving the rural category would
make the rural penalty unmeasurable by construction. Urban core is set as the
reference level because it is the largest and substantively natural baseline;
using a small group as reference would inflate standard errors on all contrasts.

**Caveat for Phase 3.** The Rural coefficient will be estimated on 22 (GT) and 34
(Pro) schools. It must be reported with wide confidence intervals and interpreted
with caution; it is indicative, not conclusive. The binary `urban_rural` is
retained in the dataset and will be used as a robustness check to verify that
results are not driven by the coding choice.

### P2-T4 — Correlation matrix & collinearity pre-check

**Method.** Pearson correlations among the two DVs and the four continuous
predictors, computed separately per track on the 2023 cross-section
(`use = "pairwise.complete.obs"`). This is a bivariate pre-check; VIF on the
estimation sample (Phase 3) is the authoritative multicollinearity diagnostic.

**Findings.**

1. **Only one predictor pair exceeds the |r| > 0.6 threshold:**
   `median_income` ↔ `poverty_rate` (GT −0.74, Pro −0.77). This is expected by
   construction — the poverty rate is defined on the lower tail of the same income
   distribution. Implied bivariate VIF is approximately 2.2 (GT) and 2.5 (Pro),
   well below the VIF > 5 threshold. Both variables are retained: they capture
   distinct constructs (territorial resource level vs. concentration of
   deprivation). Flagged for VIF confirmation in Phase 3.

2. **Second pair to monitor:** `IPS_mean` ↔ `median_income` (GT 0.58, Pro 0.36).
   Below threshold, but it means the multivariate VIF for `median_income` in
   Model B will exceed the bivariate estimate above.

3. **The IVAL circularity argument is empirically confirmed.** `DV1_va` ↔
   `IPS_mean` is 0.05 (GT) and 0.00 (Pro). The value-added score carries
   essentially no linear association with school-level parental SES, consistent
   with DEPP's model already netting out intake composition. This validates the
   Model A / Model B architecture: IPS is correctly excluded from Model A.

4. **`fibre_coverage` shows very weak bivariate association with both DVs**
   (DV2: GT 0.15, Pro 0.01; DV1: GT −0.11, Pro −0.05). Combined with its
   compressed distribution (P2-T2) and its temporal misalignment with the COVID
   exposure window, a non-significant coefficient in Phase 3 is plausible. This
   would itself be a substantive result — supply-side infrastructure availability
   would not predict post-COVID attainment net of socioeconomic context — and is
   stated here in advance of estimation.

5. **The socioeconomic gradient is markedly stronger in GT than in Pro.**
   `DV2_taux` ↔ `IPS_mean` is 0.63 in GT versus 0.40 in Pro; `IPS_mean` ↔
   `median_income` is 0.58 versus 0.36. Track-stratified estimation is therefore
   warranted not only by differing means (P2-T1) but by a differing association
   structure.

**No transformation flags raised at this stage.** Skew-related transformation
decisions (e.g. log income) are addressed in the Phase 3 readiness section.

### P2-T5 — Bivariate scatter plots (linear vs loess fit)

**Method.** Scatter plots of each dependent variable against the continuous
predictors, faceted by track, on the 2023 cross-section. Each panel overlays a
linear fit (the functional form Phase 3 will estimate) and a loess fit
(unconstrained shape). Divergence between the two indicates non-linearity that a
correlation coefficient cannot detect. NAs in either plotted variable are filtered
explicitly. Six figures produced (three per DV), stored in `output/figures/`.

Note on reading the loess: in regions with few observations — notably
`fibre_coverage` below 75% and `poverty_rate` above 35% — the loess curve is
unstable and is not interpreted as evidence.

---

#### A. Dependent variable validation — DV1_va vs IPS_mean

This plot is not a predictor screen. `IPS_mean` is excluded from Model A by
design; the plot tests whether that exclusion is empirically justified, i.e.
whether the IVAL value-added score has in fact netted out school intake
composition as DEPP's methodology states.

**Result: the test is passed.** The linear fit is flat at zero in both tracks
(r = 0.05 GT, 0.00 Pro). Value-added carries essentially no linear association
with school-level parental SES. The circularity argument underlying the Model A /
Model B split is therefore confirmed on this dataset, not merely assumed from
source documentation.

---

#### B. Predictor screening — DV2_taux (raw pass rate)

1. **`IPS_mean` — strong but non-linear in GT.** The relationship is the
   strongest in the study (r = 0.63 GT), but the loess is concave: steep at low
   IPS, flattening above roughly IPS 120 as schools approach the 100% ceiling.
   The linear fit extrapolates above 100% at the top of the IPS range — an
   arithmetically impossible prediction. In Pro the two fits nearly coincide and
   the linear assumption holds; Pro's median pass rate (84%) sits well below the
   ceiling. This is direct visual support for the Brief's decision to treat DV1_va
   as the primary dependent variable.

2. **`fibre_coverage` — flat where the data are.** Observations are concentrated
   between 85% and 100% coverage (restricted range, consistent with P2-T2). Within
   that region both fits are flat; the apparent rise below 50% coverage rests on a
   handful of observations. In Pro the linear fit is essentially horizontal
   (r = 0.01). Schools in communes with 0% FTTH coverage span pass rates from 56%
   to 100%, indicating that other factors dominate entirely. Non-linearity does not
   rescue this predictor.

3. **`poverty_rate` — linear and well behaved.** Observations span 5–52% with
   density throughout, and the two fits nearly coincide in both tracks. Negative
   slope as expected. The mild downward deviation of the loess above 35% poverty in
   GT is not supported by sufficient data to justify a quadratic term.

---

#### C. Predictor screening — DV1_va (value-added, primary DV)

All three predictors produce flat fits close to zero in both tracks, consistent
with the correlation matrix (fibre −0.11 / −0.05; poverty 0.08 / 0.02; income
−0.06 / −0.03). Point clouds are symmetric around zero, with no ceiling
truncation — the structural advantage of value-added over the raw rate.

Two clarifications on interpretation:

- The zero-centring of DV1_va is mechanical (it is a residual). The **flatness
  against territorial predictors is not.** DEPP's value-added model adjusts for
  student composition (PCS variables); it does not adjust for commune broadband
  coverage, income, or poverty. Those predictors were free to show association
  with DV1_va and do not.
- Apparent widening of the vertical spread at high `fibre_coverage` reflects
  observation density, not heteroskedasticity: 90% of schools sit in that range.

**Expected consequence for Phase 3, stated in advance of estimation.** Model A
is likely to return a very low R² (order of 1–2% in GT, below 1% in Pro) with
territorial coefficients close to zero. This would constitute a substantive
finding rather than a null result: net of student intake composition, territorial
conditions — digital infrastructure availability, commune income, commune poverty
— would explain almost none of the variation in lycée value-added. Such a result
is consistent with the Coleman tradition cited in the analytical framework and
would locate post-COVID educational inequality in the social composition of
school intakes rather than in municipal territorial conditions. Model B, where
`IPS_mean` correlates 0.63 with the raw pass rate in GT, is expected to carry the
explanatory weight.

---

#### D. Observations carried to Phase 3

| # | Observation | Implication |
|---|---|---|
| 1 | Ceiling effect in DV2_taux (GT): linear fit predicts >100% at high IPS | Model B on GT is misspecified at the upper bound; reinforces DV1_va as primary DV |
| 2 | Variance compression near the GT ceiling | Possible heteroskedasticity — Breusch-Pagan test decides |
| 3 | Vertical striping in all commune-level predictor plots: schools in the same commune share identical x values | Observations are clustered within commune; conventional standard errors are downward-biased. Cluster-robust SE (by commune) required |
| 4 | Isolated extreme values in Pro DV1_va (−55 to +29) | Likely small entry cohorts; check `presents` and run influence diagnostics (Cook's distance) |
| 5 | Restricted range in `fibre_coverage` | Limited power to identify an effect regardless of specification; state alongside the temporal-misalignment caveat |

**No transformation flags raised.** No predictor shows non-linearity against
DV1_va that a transformation would correct. The one clear non-linearity —
`IPS_mean` vs DV2_taux in GT — is a bounded-outcome artefact, not a functional
form issue, and is addressed by the choice of primary DV rather than by
transforming a predictor.

### P2-T6 — Group comparisons and pre/post-COVID outcome trend

**Method.** Boxplots of both dependent variables across the two categorical
variables (`urban_rural3`, `secteur`) on the 2023 cross-section, faceted by track.
Group medians reported alongside cell sizes, since a boxplot conveys no
information about the number of observations behind it. A pre/post-COVID trend of
mean pass rate (2019–2024, 2020 excluded) is computed on the full panel
(`df_full`). Four figures produced, stored in `output/figures/`.

**Note on the trend plot.** `annee` is stored as character (it serves as a join
and filter key throughout the pipeline) and is converted to integer for this
figure only, so that the x axis is continuous. Panels use free y scales because
the two tracks operate at different levels (≈95% vs ≈84%); the shape of each
trend is comparable across panels, the levels are not.

---

#### A. Urban/rural category

Cell sizes (2023): GT — Urban core 1,931 / Suburban 376 / Rural 22.
Pro — Urban core 1,602 / Suburban 371 / Rural 34. The Rural boxes are drawn on
very few schools and are indicative only.

1. **Value-added shows no systematic urban/rural gradient.** All three category
   boxes sit at or near zero in both tracks. This is not mechanical: DEPP's
   value-added model adjusts for student composition, not for the territorial
   classification of the commune, so a gradient was possible and does not appear.
   Consistent with the flat bivariate fits reported in P2-T5.

2. **Raw pass rates differ by category, but modestly in GT.** Urban core and
   Suburban are close; Rural sits slightly higher, on 22 schools.

---

#### B. School sector

Cell sizes (2023): GT — private under contract 780 / public 1,551.
Pro — private under contract 508 / public 1,501.

| Track | Sector | Median DV2 (raw rate) | Median DV1 (value-added) |
|---|---|---:|---:|
| GT | Private under contract | 99 | 1 |
| GT | Public | 95 | −1 |
| Pro | Private under contract | 94 | 2 |
| Pro | Public | 81 | −1 |

**Most of the private-sector advantage is intake composition, not school
effectiveness.** In the vocational track the raw gap of 13 percentage points
narrows to roughly 3 points once intake is netted out — approximately three
quarters of the apparent advantage is attributable to student composition. In the
general track the raw gap of 4 points narrows to roughly 2.

A residual private advantage remains in value-added terms in both tracks. It is
real but small relative to the raw differential. Because value-added is reported
as an integer in the source data, these median differences are indicative;
Model B will quantify the sector effect with standard errors.

**Implication.** `secteur` is not a specified predictor in either model as
written, but the size of the raw differential means it cannot be ignored. The
Brief already schedules a public-sector-only sensitivity analysis in Phase 3;
this finding gives that check a concrete motivation.

---

#### C. Pre/post-COVID trend, 2019–2024

Mean pass rate by track and urban/rural category, 2020 excluded. Cell sizes are
stable across years (e.g. Pro Rural n = 34 in every year), so the trend is not
contaminated by changes in panel composition within these categories.

1. **2021 is an outlier year across all categories.** GT rises from roughly 92%
   (2019) to 97% (2021); Pro from roughly 83% to 87%. Rates then decline towards
   pre-pandemic levels. This reflects the relaxed assessment arrangements of the
   2021 session. **2021 should be treated as methodologically atypical alongside
   2020**, which the original design did not anticipate. It does not affect the
   regression models (2023 cross-section) but constrains any descriptive
   before/after framing.

2. **A persistent rural advantage in the vocational track.** In Pro, Rural
   schools exceed Urban core by 5–7 percentage points in every year observed
   (2019: 89.7 vs 82.9; 2024: 89.2 vs 84.2). The pattern is stable, not a
   single-year artefact, and runs **contrary to the rural-penalty hypothesis
   stated in the Brief**. It rests on 34 schools and plausibly reflects
   composition or school-size effects rather than a territorial advantage; it is
   reported as an observation requiring confirmation, not as a finding.

3. **The urban/rural gap does not widen after COVID.** The Pro gap is
   approximately 6 points before and after the pandemic. There is no descriptive
   evidence that the disruption amplified territorial inequality in Bac outcomes.
   Stated because the study's framing anticipated the opposite.
   
   ---

## Phase 3 readiness

This section consolidates the decisions and diagnostic flags produced by Phase 2
and states what Phase 3 must carry forward. It is the basis on which sign-off is
requested.

### 1. Specification decisions taken

| Decision | Resolution | Evidence |
|---|---|---|
| Urban/rural coding | `urban_rural3` — 3 levels (Urban core / Suburban / Rural), reference = Urban core. Binary `urban_rural` retained for robustness check | P2-T3 |
| Track handling | Estimate separately for GT and Pro. Never pool | P2-T1, P2-T4, P2-T5 |
| Primary dependent variable | `DV1_va` (value-added) confirmed as primary; `DV2_taux` is bounded above and misspecified by a linear fit in GT | P2-T5 |
| IPS exclusion from Model A | Confirmed empirically, not merely assumed | P2-T4, P2-T5 §A |
| Income / poverty collinear pair | Both retained. Implied bivariate VIF ≈ 2.2–2.5, below threshold | P2-T4 |
| Variable transformations | **None required.** No predictor shows non-linearity against `DV1_va` that a transformation would correct | P2-T5 |

### 2. Diagnostic flags carried to Phase 3

| # | Flag | Required action |
|---|---|---|
| 1 | **Clustering by commune.** Commune-level predictors are shared across schools in the same commune; observations are not independent | Apply cluster-robust standard errors clustered on commune (`sandwich` / `lmtest`). Coefficients are unaffected; conventional SEs are downward-biased |
| 2 | **Ceiling effect in DV2_taux (GT).** Linear fit extrapolates above 100% at high IPS | Report Model B on GT with this limitation stated. Do not present fitted values in the upper range without qualification |
| 3 | **Possible heteroskedasticity (GT).** Variance is compressed near the ceiling | Run Breusch-Pagan. Apply robust SEs if significant — this is subsumed by the cluster-robust treatment in flag 1 |
| 4 | **Extreme values in Pro `DV1_va`** (range −55 to +29), plausibly small entry cohorts | Run Cook's distance. Cross-check against `presents`. Report whether conclusions are sensitive to their exclusion; do not delete them silently |
| 5 | **Restricted range in `fibre_coverage`** (most observations between 85% and 100%) | State alongside the temporal-misalignment caveat. Limited power to identify an effect regardless of specification |

### 3. Specification issue requiring reframing

The Brief schedules a panel fixed-effects robustness check on UAI. **As written
this is not viable.** All territorial predictors (`fibre_coverage`,
`median_income`, `poverty_rate`, `urban_rural3`) are single-vintage and therefore
time-invariant within school. School fixed effects would absorb them entirely,
leaving nothing to estimate.

Options for Phase 3, to be decided with the Lead:
- Drop the panel check and rely on cross-sectional estimation with cluster-robust SEs.
- Replace it with a different robustness strategy (e.g. estimating on an adjacent year and comparing coefficients).
- Retain a panel specification only for the outcome trend, without territorial predictors — descriptive, not identifying.

### 4. Expectations declared in advance of estimation

Recorded before any model is fitted, so that results cannot be rationalised
retrospectively.

- **Model A is expected to return a very low R²** (order of 1–2% in GT, below 1%
  in Pro), with territorial coefficients close to zero. If this occurs it is a
  substantive finding, not a null result: net of student intake composition,
  territorial conditions explain almost none of the variation in lycée
  value-added.
- **`fibre_coverage` is expected to be non-significant** in both models. Its
  bivariate association with both DVs is near zero and its distribution is
  compressed.
- **`IPS_mean` is expected to be the dominant predictor in Model B**, particularly
  in GT (r = 0.63 with the raw pass rate).

### 5. Additional analysis warranted by Phase 2 findings

Not in the original plan; raised by the exploratory results.

- **Sector effect.** The private/public raw gap is 13 points in Pro but roughly 3
  points in value-added terms — approximately three quarters of the apparent
  advantage is intake composition. `secteur` is not a specified predictor in
  either model, but the magnitude warrants including it, or at minimum executing
  the public-only sensitivity analysis already scheduled in the Brief.
- **2021 as an atypical session.** The Brief excludes 2020 only. Phase 2 shows
  2021 pass rates spike across all categories and both tracks under relaxed
  assessment arrangements. This does not affect the 2023 cross-section but
  constrains any descriptive pre/post-COVID framing and should be noted in the
  limitations section.
- **Rural advantage in Pro.** Rural vocational schools exceed urban core by 5–7
  points in every year observed, contrary to the rural-penalty hypothesis. Based
  on 34 schools; plausibly composition or school-size driven. Worth examining
  against `presents` before any interpretation is offered.

### 6. Sign-off requested

Phase 3 is gated on Lead approval of:

1. The `urban_rural3` coding decision and its reference level (§1).
2. The confirmation that no variable transformations are required (§1).
3. The five diagnostic flags and their required actions (§2).
4. A decision on the panel fixed-effects reframing (§3).
5. Whether `secteur` enters the models as a predictor or remains a sensitivity check (§5).

---

*End of Phase 2 — Descriptive Statistics & Exploratory Analysis.*