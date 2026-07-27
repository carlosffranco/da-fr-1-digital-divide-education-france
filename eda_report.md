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