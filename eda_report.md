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