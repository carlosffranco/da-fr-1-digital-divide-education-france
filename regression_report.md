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

---

## Method and inference

All models are estimated by OLS on the certified 2023 cross-section, separately
for the general and technological track (GT) and the vocational track (Pro). The
two tracks are never pooled: they differ in outcome distribution (median pass rate
97% vs 84%), in social composition (mean IPS 113 vs 96) and in association
structure, so a pooled model would average two distinct regimes.

**Clustered inference.** Phase 2 established that schools in the same commune
share identical values on every territorial predictor, so their residuals are
correlated within commune and conventional standard errors are downward-biased.
All reported inference therefore uses CR2 cluster-robust standard errors
(`clubSandwich`), clustered on `commune_terr` — 1,337 clusters across 4,340
schools. CR2 rather than CR1 because cluster sizes are highly heterogeneous, from
single-school communes to 108 schools in Paris.

The magnitude of the correction, on Model A (GT):

| Coefficient | Classical SE | CR2 SE | Change |
|---|---:|---:|---:|
| `fibre_coverage` | 0.0069 | 0.0084 | +22% |
| `median_income` | 1.86e-05 | 2.51e-05 | +35% |
| `poverty_rate` | 0.0123 | 0.0165 | +34% |
| `urban_rural3Rural` | 0.762 | 0.568 | −25% |

Standard errors on the continuous territorial predictors rise by 22–35% under
clustering — the bias the Phase 2 diagnostic predicted. The rural contrast moves
the other way: clustering is not a blanket penalty but a redistribution of
information, and for a variable concentrated in a few clusters it can cut either
way.

**Why sector is estimated more precisely than the territorial predictors.**
`secteur` varies *within* communes — a town can have both a public and a private
lycée — so clustering barely affects its precision. The territorial predictors are
constant within a commune by construction, so clustering penalises them heavily.
This is why the sector coefficient carries a standard error of 0.117 in Model A+
(GT) while `fibre_coverage` carries 0.008 on a coefficient two orders of magnitude
smaller, and it is why sector rescues the Pro model where no territorial predictor
can.

**Choice of cluster level.** `commune_terr` collapses Paris, Lyon and Marseille
arrondissements into their parent city; `commune_final` keeps them separate.
`commune_terr` is used as the headline because it is the level at which the
shared shock actually operates for the territorial predictors: every Paris school
received the same FTTH and urban/rural values from the collapsed parent code, so
their errors on those dimensions are correlated across arrondissements. It is
also the more conservative choice. The asymmetry this creates for
`median_income` — which does vary across arrondissements — is examined below.

**Specifications.** Four models per track:

| Model | Dependent variable | Predictors |
|---|---|---|
| A | IVAL value-added | fibre_coverage, median_income, poverty_rate, urban_rural3 |
| B | Raw Bac pass rate | Model A predictors + IPS_mean |
| B+ | Raw Bac pass rate | Model B predictors + secteur |
| A+ | IVAL value-added | Model A predictors + secteur |

`IPS_mean` is excluded from Models A and A+ by design: the IVAL value-added score
already nets out student intake composition, and Phase 2 confirmed this
empirically (correlation between value-added and IPS is 0.05 in GT and 0.00 in
Pro).

---

## Model A — territorial factors and value-added

| | GT | Pro |
|---|---:|---:|
| N | 2,243 | 1,909 |
| R² | 0.019 | 0.004 |
| Joint significance (CR2 Wald) | F = 5.80, p < 0.001 | F = 1.29, **p = 0.281** |

**Territorial conditions explain almost none of the variation in lycée
value-added.** Model A accounts for 1.9% of variance in the general track and
0.4% in the vocational track. In Pro the model is **not jointly significant**: the
null hypothesis that none of the territorial variables matter cannot be rejected.

This is the pre-registered expectation, stated in the Phase 2 report before any
model was fitted, and it is a substantive finding rather than a null result. Net
of student intake composition, digital infrastructure availability, commune income
and commune poverty account for almost nothing. It is consistent with the Coleman
tradition cited in the analytical framework and locates post-COVID educational
inequality in the social composition of school intakes rather than in municipal
territorial conditions.

**Individual coefficients (GT), CR2-clustered:**

| Coefficient | Estimate | SE | p (Satterthwaite) | Effective df |
|---|---:|---:|---:|---:|
| `fibre_coverage` | −0.0266 | 0.0084 | 0.0036 | 28.8 |
| `median_income` | 1.53e-05 | 2.51e-05 | 0.571 | 4.6 |
| `poverty_rate` | 0.0411 | 0.0165 | 0.0171 | 39.7 |
| Suburban (ref: Urban core) | 0.408 | 0.159 | 0.0110 | 249.8 |
| Rural (ref: Urban core) | 1.361 | 0.568 | 0.0318 | 13.3 |

Two results run against expectation and are examined in dedicated sections below:
`fibre_coverage` is significant and negative (pre-registered as non-significant),
and `poverty_rate` is significant and positive.

The rural contrast rests on 22 schools in GT and 34 in Pro. Following the Phase 2
ruling, it is reported as estimated but not interpreted: its effective degrees of
freedom are 13.3 and the confidence interval is correspondingly wide.

In Pro, no coefficient other than `fibre_coverage` approaches significance, and
the joint test is null. The individually significant fibre coefficient in a jointly
non-significant model is a multiple-comparisons hazard: with five predictors, one
returning p < 0.05 is close to what chance delivers. It is not reported as a
finding.

---

## Models B and B+ — social composition and sector

| | GT: Model B | GT: Model B+ | Pro: Model B | Pro: Model B+ |
|---|---:|---:|---:|---:|
| N | 2,237 | 2,237 | 1,907 | 1,907 |
| R² | 0.441 | 0.471 | 0.176 | 0.323 |
| `IPS_mean` | 0.212 | 0.174 | 0.276 | 0.100 |
| `secteur` (public) | — | −1.909 | — | −9.829 |

**Social composition is by far the dominant predictor.** Moving from Model A to
Model B — that is, from territorial predictors on value-added to social
composition on the raw pass rate — raises explained variance from 1.9% to 44.1%
in GT. The IPS coefficient carries a CR2 t-statistic of 30.4, the largest in the
study by a wide margin. This was the third pre-registered expectation and it held
emphatically.

**Adding `secteur` changes what the IPS coefficient measures.** Models B and B+
are fitted on identical samples (`secteur` has no missing values), so the movement
is attributable to the added control rather than to a change in the estimation
sample:

| Coefficient | GT: B → B+ | Change | Pro: B → B+ | Change |
|---|---|---:|---|---:|
| `IPS_mean` | 0.212 → 0.174 | −17.8% | 0.276 → 0.100 | **−63.8%** |
| `poverty_rate` | −0.112 → −0.120 | +7.5% | −0.269 → −0.349 | +29.6% |
| `fibre_coverage` | −0.034 → −0.030 | −11.8% | −0.050 → −0.039 | −22.5% |
| `median_income` | −3.05e-04 → −2.72e-04 | −10.8% | −4.83e-04 → −4.44e-04 | −8.1% |

The 64% movement in Pro is best read as a change of estimand rather than as
removal of bias. Sector plausibly causes intake composition — private lycées
select, so being private produces a higher IPS. Controlling for a variable that
causes the regressor removes the between-sector part of the relationship and
retains only the within-sector part. Model B's coefficient answers: across all
vocational lycées, how does social composition track pass rates? Model B+'s
answers: within a given sector, how does it track?

Both are informative, and the gap between them is itself the finding: **in the
vocational track, most of the socioeconomic gradient runs along the public/private
divide rather than within it.** Adding sector raises explained variance from 17.6%
to 32.3% in Pro. The same movement in GT is much milder (−17.8%), a further
instance of the two tracks behaving differently.

Model B is retained as the headline specification — it is the Brief's design and
the broader estimand — with Model B+ as a mandatory companion.

**Ceiling limitation.** Phase 2 established that the raw pass rate is bounded
above and that a linear fit extrapolates beyond 100% at high IPS in GT. Fitted
values from Models B and B+ in the upper range should not be presented without
that caveat.

---

## Model A+ — the sector effect net of intake

Model B+ returns a sector coefficient of −9.83 in Pro, but that estimate
conditions only on `IPS_mean`, a single summary index. DEPP's value-added model
adjusts on a richer intake specification, so using value-added as the dependent
variable yields the defensible estimate of the school effectiveness component.

| | GT | Pro |
|---|---:|---:|
| N | 2,243 | 1,909 |
| R² (Model A → Model A+) | 0.019 → **0.115** | 0.004 → **0.041** |
| Joint significance (CR2 Wald) | F = 47.4, p < 0.001 | F = 16.7, p < 0.001 |
| `secteur` (public) | **−1.904** (SE 0.117) | **−3.253** (SE 0.325) |

**Decomposition of the sector gap:**

| | GT | Pro |
|---|---:|---:|
| Raw median difference (Phase 2) | 4 points | 13 points |
| Conditional on IPS (Model B+) | −1.91 | −9.83 |
| Net of intake (Model A+) | **−1.90** | **−3.25** |

**In the vocational track, roughly three quarters of the private-sector advantage
is intake composition.** A raw gap of 13 percentage points decomposes into
approximately 9.75 points attributable to which students each sector receives and
3.25 points remaining once intake is netted out. The Phase 2 estimate, read off
boxplot medians, was approximately 3 points; the estimated coefficient is 3.25
with a standard error of 0.325.

**IPS is an adequate summary of intake in GT, but not in Pro.** In the general
track the sector coefficient barely moves between Model B+ (−1.91) and Model A+
(−1.90): `IPS_mean` alone already captures essentially all of the intake
difference between sectors, so applying DEPP's fuller value-added adjustment adds
almost nothing. In the vocational track it moves substantially — from −9.83 to
−3.25 — meaning a single social-position index leaves a large part of the
between-sector intake difference unmeasured. The two tracks differ not only in the
size of the sector gap but in how well a summary index describes their intakes.

**Sector rescues the Pro model.** Model A in Pro was jointly non-significant with
an R² of 0.4%. Adding `secteur` raises R² elevenfold to 4.1% and the model becomes
jointly significant (F = 16.7, p < 0.001). No territorial predictor in Model A+
Pro reaches significance: **in the vocational track, value-added is not explained
by territory but by whether the school is public or private.**

**Caveat.** Value-added is not a pure measure of school effectiveness. It is a
residual from DEPP's model, which may over- or under-adjust, and French private
schools operate under contract with selection mechanisms — family motivation,
willingness to pay, expectations — that no intake model fully captures. Part of
the residual 3.25 points may still be selection.

---

## Diagnostics

**Multicollinearity (VIF).** The Phase 2 pre-check predicted a VIF of
approximately 2.2–2.5 for the income/poverty pair, derived from their bivariate
correlation. The multivariate estimates confirm it:

| Model | `median_income` | `poverty_rate` |
|---|---:|---:|
| A · GT | 2.28 | 2.34 |
| A · Pro | 2.58 | 2.65 |
| B · GT | 2.63 | 2.37 |
| B · Pro | 2.59 | 2.69 |

No predictor approaches the threshold of 5. For `urban_rural3` the comparable
statistic is GVIF^(1/(2·Df)) ≈ 1.02, well below √5. Both income and poverty are
retained: they capture distinct constructs — territorial resource level versus
concentration of deprivation — and the collinearity is modest.

A secondary observation: `IPS_mean`'s VIF rises from 1.52 to 2.08 in GT when
`secteur` is added, consistent with the change-of-estimand reading above. Sector
and social composition share information because private schools select intake.

**Heteroskedasticity (Breusch-Pagan).**

| Model | p |
|---|---:|
| A · GT | 1.98e-09 |
| A · Pro | 0.139 |
| B · GT | < 2.2e-16 |
| B · Pro | 0.043 |

Strong heteroskedasticity in GT, absent or marginal in Pro. This matches the
Phase 2 prediction: variance is compressed near the 100% ceiling in the general
track, and Pro operates well below it. The test is reported for transparency but
does not gate anything — cluster-robust standard errors already absorb
heteroskedasticity.

**Joint significance.** The F statistic printed by `summary()` uses classical,
non-clustered inference and is not comparable to the CR2 individual tests.
Cluster-robust Wald tests are reported instead:

| Model | F | p |
|---|---:|---:|
| A · GT | 5.80 | < 0.001 |
| A · Pro | 1.29 | 0.281 |
| B · GT | 142 | < 0.001 |
| B · Pro | 66.7 | < 0.001 |
| A+ · GT | 47.4 | < 0.001 |
| A+ · Pro | 16.7 | < 0.001 |

Model A in Pro remains jointly non-significant under correct clustered inference,
confirming that the classical result was not an artefact of mismatched
inferential methods.

---

## The median_income investigation

The Satterthwaite degrees of freedom reported by `coef_test()` measure how many
clusters effectively carry identifying variation for each coefficient. In Model B
(GT), `median_income` returned **5.02** effective degrees of freedom against 1,337
clusters — the most concerning figure in the phase. At five degrees of freedom the
critical t-value is approximately 2.57 rather than 1.96, and CR2 itself becomes
unstable.

**Collinearity is not the cause.** The VIF for `median_income` is 2.63 — modest.
Low VIF combined with low effective degrees of freedom indicates that the
variable's variation is concentrated in few clusters, not that it competes with
other predictors.

**The cause is a clustering asymmetry introduced in Phase 1.** Filosofi reports
income at arrondissement granularity, so income varies across Paris. ARCEP and
AAV report Paris globally, so the territorial predictors do not. Clustering on
`commune_terr` collapses all Paris arrondissements into one unit, placing the
widest income spread in France inside a single piece of information.

The Paris cluster contains **108 schools across 18 arrondissements, spanning
€22,870 to €45,380** — approximately two thirds of the national cluster-level
income range, treated as one observation for inference purposes.

**Re-clustering on `commune_final` confirms the mechanism.** Coefficients are
unchanged; only the variance estimator differs:

| Coefficient (GT, Model B) | df under `commune_terr` | df under `commune_final` | Varies within Paris? |
|---|---:|---:|---|
| `IPS_mean` | 106.2 | 232.6 | Yes (school level) |
| `poverty_rate` | 41.7 | 119.1 | Yes (Filosofi) |
| `median_income` | **5.0** | **23.2** | Yes (Filosofi) |
| `fibre_coverage` | 28.7 | 28.8 | **No** (ARCEP) |
| `urban_rural3Rural` | 13.3 | 13.3 | **No** (AAV) |

Every variable that varies within Paris gains degrees of freedom; the two joined
on `commune_terr` do not move at all. The asymmetry is exact, and it traces
directly to a Phase 1 data-integration decision propagating into Phase 3
inference.

**Pre-specified variants confirm the coefficient is robust.**

| Specification | Coefficient | Effective df | p |
|---|---:|---:|---:|
| Levels (baseline) | −3.05e-04 | 23.2 | < 0.001 |
| `log(median_income)` | −10.72 | 36.9 | < 0.001 |
| Levels, excluding top 1% income communes | −3.80e-04 | 19.3 | < 0.001 |

The log transformation preserves sign and significance and improves effective
degrees of freedom by 59%. Excluding the highest-income communes — Neuilly-sur-
Seine, the wealthy Paris arrondissements — *strengthens* the coefficient by 25%
rather than eliminating it, ruling out leverage from the upper tail. Levels remain
the baseline; log is reported as a variant.

**Interpretation.** Conditional on intake composition, schools in higher-income
communes show slightly lower raw pass rates. This inverts the unconditional
correlation (+0.22 in Phase 2), which is expected: the two answer different
questions. The unconditional association reflects that wealthy communes have
advantaged intakes; the conditional coefficient compares schools with equivalent
intakes. In interpretable units, a €1,000 difference in commune median income
corresponds to approximately 0.3 percentage points of pass rate.

---

## The fibre_coverage investigation

The pre-registered expectation was that `fibre_coverage` would be non-significant.
It returned significant and **negative** coefficients in both tracks — higher FTTH
availability associated with *lower* value-added, the opposite sign to the
digital-divide hypothesis. Six checks were run.

**1. Substantive magnitude.** In GT, −0.0266 across the 85–100% band where 90% of
schools sit implies approximately 0.4 value-added points, against a standard
deviation of 2.99 — roughly one tenth of a standard deviation. The coefficient
looks larger only if extrapolated across the empty part of the distribution.

**2. Sparse-tail exclusion.** Restricting to communes with coverage ≥ 85%:

| | GT (n = 2,083) | Pro (n = 1,753) |
|---|---|---|
| Full-sample coefficient | −0.0266 (p = 0.004) | −0.0402 (p = 0.024) |
| Trimmed coefficient | −0.0660 (p = 0.021) | −0.0226 (**p = 0.664**) |

In GT the association survives. The apparent 2.5-fold increase in magnitude is not
a stronger result: the confidence intervals overlap substantially
([−0.044, −0.009] full sample; [−0.122, −0.010] trimmed), the standard error
tripled, and the p-value worsened. Range restriction collapses predictor variance
and precision with it. The trimmed refit is a robustness check that passed, not a
better estimate. Its effective degrees of freedom rose from 28.7 to 68.6, which
identifies the low-coverage communes as the high-leverage clusters — making the
trimmed estimate the leverage-free version.

**In Pro the association disappears.** Dropping 156 schools halves the coefficient
and removes significance entirely; no coefficient in the trimmed Pro model reaches
p < 0.6. Combined with Model A Pro being jointly non-significant, the Pro fibre
result is reported in robustness only, not as a finding.

**3–4. Competition with the urban/rural classification.** Dropping `urban_rural3`
raises fibre's coefficient by 8.6%; dropping fibre raises the Suburban contrast by
22% and the Rural contrast by 4.3%. These movements are small. The inference is
limited, however: a three-level categorical with a 22-school rural cell cannot
absorb a continuous density gradient, so its failure to move fibre indicates the
categorical is blunt rather than that density is irrelevant.

**5. Finer urban gradient.** Replacing `urban_rural3` with the full five-level
CATEAAV2020 classification moves fibre's coefficient by only 2.6% (−0.0266 →
−0.0259). The category coefficients show no monotonic gradient: relative to large
urban centres, medium (−0.284) and small (−0.706) centres are statistically
indistinguishable, while suburban (+0.325) and rural (+1.29) are positive. If
urbanisation were the mechanism, an ordered gradient would be expected.

This also validates the Phase 2 coding decision: categories 11, 12 and 13 do not
differ significantly from one another, which is exactly what collapsing them into
"Urban core" assumed.

**6. Regional fixed effects.** Adding fixed effects for 97 départements:

| Coefficient (GT, Model A) | Without FE | With FE |
|---|---|---|
| `fibre_coverage` | −0.0266 (p = 0.004) | **−0.0145 (p = 0.075)** |
| `poverty_rate` | 0.0411 (p = 0.017) | **−0.00014 (p = 0.994)** |
| Rural | 1.361 (p = 0.032) | 0.877 (p = 0.126) |
| Suburban | 0.408 (p = 0.011) | 0.352 (p = 0.040) |

**The fibre coefficient loses 45% of its magnitude and falls below conventional
significance.** A substantial part of the association operates between
départements rather than within them: fibre rollout follows regional patterns, and
DEPP's value-added residuals may be regionally patterned too.

The `poverty_rate` result is more decisive still — it vanishes completely
(p = 0.994). The positive poverty coefficient reported in Model A is entirely a
between-département phenomenon. Within a given département, commune poverty does
not predict value-added at all.

Precision falls for all territorial predictors when 97 fixed effects absorb
regional variation, which is expected. The honest reading is not that no
association exists, but that it operates principally between regions and is not
distinguishable from zero within them at this precision.

**Conclusion.** A small negative association between FTTH availability and
value-added in the general track, robust to sparse-tail exclusion, not explained
by the urban/rural classification at either resolution, and substantially
attributable to regional variation. In the vocational track it is not robust. The
association is reported without a proposed mechanism: the most obvious candidate
was tested to the extent the data allowed and did not account for it, and
proposing an untested explanation would be worse than reporting the association as
unexplained.

**Untested alternative.** The Phase 2 review recommended controlling for commune
population (`NBPERSMENFISC21`) as a continuous density measure. That variable was
not carried through the Phase 1 pipeline and the control was not run. The density
mechanism is therefore **untested, not ruled out** — a limitation of this report
rather than a finding.

---

## Robustness checks

**Urban/rural coding.** Phase 2 adopted `urban_rural3` (three levels) over the
original binary variable. Refitting Model A with the binary coding:

| Coefficient | GT: 3-level | GT: binary | Pro: 3-level | Pro: binary |
|---|---:|---:|---:|---:|
| `fibre_coverage` | −0.0266 | −0.0287 | −0.0402 | −0.0401 |
| `median_income` | 1.53e-05 | 8.12e-06 | −2.19e-05 | −2.14e-05 |
| `poverty_rate` | 0.0411 | 0.0338 | 0.0114 | 0.0118 |

The territorial coefficients retain their sign, approximate magnitude and
significance under both codings; in Pro they are almost identical. **The findings
are not driven by the coding decision.**

The check also illustrates what the binary coding costs. In GT the binary rural
coefficient (+1.28) is close to the three-level rural contrast (+1.36), but the
binary specification discards the suburban group entirely — a group that carries a
significant coefficient of its own (+0.41, p = 0.011) across 747 schools.

**Checks not run.** Three items from the Phase 2 plan were not executed:
Cook's distance influence diagnostics, adjacent-year coefficient stability
(refitting Model A on 2022 and 2024), and the continuous population-density
control. They are listed in the limitations section. The sparse-tail exclusion
above provides partial evidence on influence — the high-leverage clusters were
identified through the degrees-of-freedom movement and the result survives their
removal — but no formal influence diagnostic was computed.

---

## Coefficient tables

Full results are in `output/tables/coefficients_gt.md` and
`output/tables/coefficients_pro.md`, produced with `modelsummary`. Each table
presents the four specifications side by side, with coefficients above and CR2
cluster-robust standard errors in parentheses below, and reports the recertified
N, R² and adjusted R² in the footer.

The four columns are not directly comparable to one another: Models A and A+ have
value-added as the dependent variable, Models B and B+ have the raw pass rate.
Comparing the R² of Model A (1.9%) with that of Model B (44.1%) does not indicate
that one model is better — they explain different quantities. The valid
comparisons are within each pair: A against A+, and B against B+.

`median_income` is measured in euros, so its coefficient is small by construction:
a €1,000 difference corresponds to approximately 0.3 percentage points.

### Note on significance levels

An inconsistency surfaced while assembling the tables. `clubSandwich::coef_test()`
computes p-values using Satterthwaite degrees of freedom — the small-sample
adjustment that accounts for how many clusters actually carry identifying
variation for each coefficient. `modelsummary`, given a fitted model and a
variance-covariance matrix, applies the correct CR2 standard errors but derives
p-values from large-sample degrees of freedom instead.

The two agree wherever effective degrees of freedom are high. They diverge
precisely where the small-sample adjustment matters: six coefficients in the GT
table were initially assigned stronger significance levels than the Satterthwaite
p-values support. `median_income` in Model B is the clearest case — Satterthwaite
p = 0.021 (one star) against large-sample p < 0.001 (three stars), on a
coefficient with 5.0 effective degrees of freedom.

The tables are therefore built directly from `coef_test()` output: coefficients,
standard errors and p-values all come from the same function used throughout the
analysis, so the tables and the text cannot diverge. The alternative — reporting
the discrepancy in a footnote — was rejected, on the grounds that a note
explaining why a number is wrong is worse than the correct number.

The direction of the error is worth recording. Large-sample degrees of freedom
overstate significance exactly for the coefficients that the diagnostics had
already flagged as weakly identified. Published as first generated, the tables
would have presented the study's most fragile estimates as its most certain ones.

---

## Results against pre-registered expectations

Four expectations were recorded in writing in the Phase 2 report, before any model
was estimated.

| Expectation | Result | Verdict |
|---|---|---|
| Model A R² of order 1–2% in GT | 1.86% | **Held** |
| Model A R² below 1% in Pro | 0.38% | **Held** |
| `IPS_mean` dominant in Model B | CR2 t = 30.4; R² rises 1.9% → 44.1% | **Held emphatically** |
| `fibre_coverage` non-significant | Significant and negative in both tracks | **Did not hold** |

The fourth expectation broke, and the response was to investigate rather than
respecify. Six checks were run, reported above in full including those that
weakened the initial confounding interpretation. The headline specification was
not switched to whichever refit produced a larger coefficient — doing so after
seeing results is precisely what pre-registration exists to prevent.

**Reconciliation of two Phase 2 findings.** Phase 2 reported a persistent rural
advantage in the vocational track (rural schools exceeding urban core by 5–7
percentage points in every year observed), and separately that value-added showed
no urban/rural gradient. Those observations resolve each other: because
value-added is flat across urban/rural categories, the raw rural advantage in Pro
**cannot** be an effectiveness advantage. It must reflect intake composition,
school size, or programme mix. The Phase 3 results confirm this — no urban/rural
contrast in Model A or A+ Pro approaches significance.

---

## Summary of findings

1. **Territorial conditions do not explain lycée value-added.** Model A accounts
   for 1.9% of variance in GT and 0.4% in Pro, where it is not jointly
   significant. Digital infrastructure availability, commune income and commune
   poverty account for almost nothing once student intake composition is netted
   out.

2. **Social composition dominates.** `IPS_mean` alone raises explained variance
   from 1.9% to 44.1% in the general track and carries a CR2 t-statistic of 30.4.
   Post-COVID educational inequality in France, as measured here, resides in who
   attends each school rather than in the municipal conditions surrounding it.

3. **In the vocational track, most of the socioeconomic gradient runs along the
   public/private divide.** Adding `secteur` to Model B reduces the IPS
   coefficient by 64% in Pro and raises R² from 17.6% to 32.3%. In GT the same
   movement is −17.8%.

4. **Approximately three quarters of the private-sector advantage in Pro is intake
   composition.** A raw gap of 13 percentage points decomposes into roughly 9.75
   points of composition and 3.25 points remaining net of intake (Model A+,
   SE 0.325). In GT the sector coefficient is unchanged between Model B+ (−1.91)
   and Model A+ (−1.90), so the smaller general-track advantage does not appear to
   be composition.

5. **Sector is the only predictor that explains value-added in the vocational
   track.** Model A Pro is jointly non-significant; adding `secteur` raises R²
   elevenfold and makes the model jointly significant, with no territorial
   predictor reaching significance.

6. **FTTH coverage shows a small negative association with value-added in the
   general track**, contrary to the digital-divide hypothesis and to the
   pre-registered expectation. It is robust to sparse-tail exclusion but loses
   45% of its magnitude and falls below conventional significance under
   département fixed effects. In the vocational track it is not robust. Reported
   without a proposed mechanism.

7. **Commune poverty does not predict value-added within départements.** The
   positive coefficient in Model A vanishes entirely (p = 0.994) under regional
   fixed effects.

8. **Clustered inference materially changes the precision of the territorial
   estimates.** Standard errors rise 22–35% under CR2 clustering relative to
   classical inference, on exactly the predictors the study was designed to test.

---

## Limitations

**Effective N was misreported in Phase 1.** The listwise-deletion set omitted
`poverty_rate`, producing certified figures above the attainable maximum. The
recertified figures are used throughout; the erratum is recorded at the head of
this report and Phase 1 is not retroactively edited.

**No formal influence diagnostics.** Cook's distance was not computed. The
sparse-tail exclusion identified the high-leverage clusters indirectly through
movement in effective degrees of freedom and the results survived their removal,
but no formal diagnostic was run and extreme value-added observations in Pro
(range −55 to +29) were not cross-tabulated against cohort size.

**No temporal stability check.** Adjacent-year refits of Model A on 2022 and 2024
were not executed. Coefficient stability over time is therefore unverified. This
matters because the panel fixed-effects robustness check specified in the original
Brief was formally withdrawn — territorial predictors are single-vintage and
time-invariant within school, so school fixed effects would absorb them entirely
and the specification is not identified. The adjacent-year check was its
replacement, and it was not run.

**The density mechanism was not tested.** A continuous commune population control
was recommended and not executed, because the variable was not carried through the
Phase 1 pipeline. The most plausible explanation for the fibre association remains
untested rather than excluded.

**Cluster level is a compromise.** No single clustering level is correct for all
predictors. `fibre_coverage` and `urban_rural3` are constant across Paris
arrondissements and belong at `commune_terr`; `median_income` and `poverty_rate`
vary across them and are artificially constrained by it. The conservative level was
chosen for the headline and the consequence documented.

**Data limitations carried from earlier phases.** ARCEP coverage is a 2024
snapshot measured against a 2020–21 exposure window and captures availability
rather than household usage. Filosofi income carries a two-year lag. IPS
definitions break between the 2022 and 2023 series. The rural cell contains 22
schools in GT and 34 in Pro, so rural contrasts are estimated but not interpreted.
The raw pass rate is bounded above in GT, where a linear fit extrapolates beyond
100%.

**Design limitations.** This is a cross-sectional analysis of associations. No
causal identification strategy is employed and no coefficient should be read as a
causal effect. Value-added is a residual from DEPP's model, not a direct measure
of school effectiveness, and it may over- or under-adjust for intake.

---

*End of Phase 3 — Regression Analysis.*