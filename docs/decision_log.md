# Decision Log — DA-FR-1

Substantive analytical decisions taken during execution, several of which depart from
the original case study brief. Each entry records the situation, the decision, the
reasoning, the alternatives rejected, and the consequences accepted.

**This is an append-only record.** Entries are not rewritten as the project develops. A
decision that is later reversed is marked `Superseded` and a new entry is added
explaining why. The history of the reasoning is the point.

**Status key:** `Accepted` · `Superseded` · `Withdrawn`

| # | Decision | Stage | Status |
|---|---|---|---|
| [001](#adr-001) | Track-stratified analysis | 1 | Accepted |
| [002](#adr-002) | Dual commune source with coalesce | 1 | Accepted |
| [003](#adr-003) | Asymmetric arrondissement handling | 1 | Accepted |
| [004](#adr-004) | Three-level urban/rural coding | 2 | Accepted |
| [005](#adr-005) | Pipeline-level numeric conversion fix | 1 | Accepted |
| [006](#adr-006) | Social index harmonisation across a definitional break | 1 | Accepted |
| [007](#adr-007) | Withdrawal of the panel fixed-effects claim | 2 | Accepted |
| [008](#adr-008) | Commune-clustered standard errors (CR2) | 2 | Accepted |

---

<a name="adr-001"></a>
## ADR-001 — Track-stratified analysis

**Status:** Accepted · **Stage:** 1

### Context

French upper secondary education is organised into two tracks that lead to different
Baccalauréat qualifications: *general and technological* (GT) and *vocational* (Pro). The
original brief did not specify whether they should be analysed together or separately.

### Decision

All analysis is run separately for GT and Pro. The two tracks are never pooled, at any
stage, in any model.

### Rationale

The tracks differ on all three dimensions that matter for a regression:

| Dimension | GT | Pro |
|---|---|---|
| Median pass rate | 97% | 84% |
| Mean social index (IPS) | 113 | 96 |
| IPS ↔ pass rate correlation | 0.63 | 0.40 |

The third row is decisive. A difference in *level* could be absorbed by a dummy variable.
A difference in the *strength of association* cannot: it means the same predictor operates
differently in each population. A pooled coefficient would be a weighted average of two
distinct regimes, describing neither.

### Alternatives rejected

- **Pooling with a track dummy** — corrects the intercept but not the slope. Rejected on
  the correlation evidence above.
- **Pooling with full interaction terms** — algebraically equivalent to stratifying, but
  harder to read and to present. Rejected on communication grounds.

### Consequences

- Every table, figure and coefficient in the project is reported twice.
- Statistical power is reduced relative to a pooled model.
- The two tracks can be compared directly on identical specifications, which turns out to
  be a substantive result in its own right rather than a by-product.

---

<a name="adr-002"></a>
## ADR-002 — Dual commune source with coalesce

**Status:** Accepted · **Stage:** 1

### Context

Schools must be matched to their commune in order to attach municipal-level predictors
(income, poverty, broadband, urban/rural class). The dataset guide prescribed a single
route: the national school directory used as a crosswalk.

### Decision

Two commune sources are combined with a coalesce: the commune code carried natively in the
outcome files takes precedence, with the directory crosswalk as fallback.

### Rationale

The outcome files carry a commune code contemporaneous to the exam year. The directory
crosswalk is a separate, later snapshot. Where they disagree, the contemporaneous code is
the correct one — it describes where the school was at the moment the outcome was measured.

Coverage for the 2023 session rose from 98.5% to 100%.

### Alternatives rejected

- **Crosswalk only**, as prescribed by the guide — loses 1.5% of schools for no reason.
- **Native code only** — not available for every file in the panel.

### Consequences

- Supersedes the guide's "always use the crosswalk" rule; the departure is documented here.
- Complete commune coverage on the regression frame, removing a source of non-random
  missingness that would otherwise have needed its own caveat.

---

<a name="adr-003"></a>
## ADR-003 — Asymmetric arrondissement handling

**Status:** Accepted · **Stage:** 1

### Context

Paris, Lyon and Marseille are subdivided into arrondissements. The source datasets disagree
on how to report them: the income survey reports each arrondissement separately, while the
broadband and urban/rural datasets report the three cities as single units.

This surfaced as a join failure. The initial hypothesis was that unmatched communes were
overseas territories. Checking the actual unmatched set showed only 3 of 64 were overseas;
45 were arrondissements of these three cities. The problem was granularity, not geography.

### Decision

Two commune keys are maintained in parallel:

- `commune_final` — arrondissements preserved, used to join income data
- `commune_terr` — arrondissements mapped to the parent city, used to join broadband and
  urban/rural data

### Rationale

Each source is joined at the granularity at which it was actually published. Forcing a
single key would require either aggregating income data upward (discarding real
within-city variation in the three largest cities) or disaggregating city-level data
downward (inventing variation that was never measured).

### Alternatives rejected

- **Single key at city level** — destroys genuine income heterogeneity across Paris
  arrondissements, which is substantial.
- **Excluding the three cities** — removes a large share of the urban core from a study
  whose research question is territorial inequality. Not defensible.

### Consequences

- Two keys must be tracked through the pipeline; the join topology is more complex.
- Broadband and urban/rural values are identical across arrondissements within each of the
  three cities. This is a property of the published source, not an artefact introduced
  here, and is disclosed as a limitation.

---

<a name="adr-004"></a>
## ADR-004 — Three-level urban/rural coding

**Status:** Accepted · **Stage:** 2

### Context

The original brief specified a binary urban/rural variable. The underlying national
classification has five levels.

### Decision

A three-level variable: **Urban core / Suburban / Rural**, with Urban core as the reference
category. The binary version is retained as a robustness variant.

### Rationale

The binary coding assigned 747 schools — 17.2% of the sample — to "Urban" despite their
being in the suburban belt. Given that the research question is territorial inequality,
collapsing the suburban belt into the urban core erases exactly the distinction the study
exists to measure.

The full five-level coding leaves cells too small to estimate reliably. Three levels is the
finest partition the data supports.

Urban core is the reference level because it is the largest group. Using a small category
as reference inflates the standard errors of every contrast against it.

### Alternatives rejected

- **Binary, as briefed** — erases the suburban belt. Rejected on substantive grounds.
- **Full five-level coding** — cells too small; coefficients would be uninterpretable.
- **Dissolving the thin rural category into Suburban** — would make a rural effect
  unmeasurable by construction. Rejected: a category cannot be removed because it is
  inconvenient to estimate when its existence is the hypothesis under test.

### Consequences

- The rural cell is thin (22 GT / 34 Pro schools). Its coefficient will be **estimated and
  reported but not interpreted**, and the constraint is disclosed rather than hidden.
- One additional dummy per model.
- The binary variant provides a direct robustness check on the recoding itself.

---

<a name="adr-005"></a>
## ADR-005 — Pipeline-level numeric conversion fix

**Status:** Accepted · **Stage:** 1

### Context

Income variables converted to entirely missing values during the merge. No error was raised
and no warning was printed. The scripts ran clean and produced a silently unusable column.

Two compounding causes: French numeric formatting uses the comma as decimal separator, and
the statistical office encodes confidential small-commune values as the character strings
`s` and `nd` rather than as blanks.

### Decision

The conversion is fixed in the pipeline script, at the point where raw data is read — not
in the analysis script downstream.

### Rationale

Fixing it downstream would work for the current analysis and fail for every future one. The
pipeline is the single source of truth for what the processed artefacts contain; a
correction applied anywhere else is a correction that will eventually be forgotten.

### Alternatives rejected

- **Fixing in the analysis script** — leaves a known defect in the artefact and relies on
  every future consumer applying the same patch.
- **Manual correction of the source files** — breaks reproducibility and violates the
  standing rule that raw data is never modified.

### Consequences

- Establishes the working principle recorded from this episode: **a clean run is not a
  correct run.** Silent type coercion is now explicitly checked after every read.
- Suppression codes become genuine missing values, which propagates into listwise deletion
  and, ultimately, into ADR-related recertification of effective sample size.

---

<a name="adr-006"></a>
## ADR-006 — Social index harmonisation across a definitional break

**Status:** Accepted · **Stage:** 1

### Context

The school social position index (IPS) is published annually. The 2022 and 2023 files use
different column definitions — the publisher changed the schema between editions.

### Decision

Both files are harmonised to a common schema. The 2023 session uses the 2022 definition.

### Rationale

The panel requires a consistent measure across years. Using each year's native definition
would mean that any change over time confounds a real change in school composition with a
change in how composition is measured.

### Alternatives rejected

- **Using each year's native definition** — makes year-to-year comparison meaningless.
- **Restricting to a single year** — would eliminate the descriptive panel, which is a
  deliverable of the study.

### Consequences

- Comparisons across the break are caveated wherever adjacent years are compared.
- Constrains the robustness design: adjacent-year stability checks are interpretable for
  models that exclude the social index, and confounded for models that include it. This
  constraint is carried forward into ADR-007.

---

<a name="adr-007"></a>
## ADR-007 — Withdrawal of the panel fixed-effects claim

**Status:** Accepted · **Stage:** 2

### Context

The original brief promised a panel fixed-effects specification as a robustness check on
the territorial predictors.

### Decision

The claim is **formally withdrawn**. It is replaced by adjacent-year coefficient stability
on the primary model.

### Rationale

The territorial predictors are single-vintage: each school has one broadband value, one
income value, one poverty value, constant across all panel years. Under school fixed
effects, any variable that does not vary within school demeans to exactly zero. The
coefficients are not merely imprecise — they are **not identified**. The specification
cannot be estimated as written.

### Alternatives rejected

- **Running it anyway and reporting whatever emerges** — would produce output that looks
  like a result and is not one.
- **Silently omitting it** — the claim exists in the brief; withdrawing it without record
  would leave an unexplained gap between what was promised and what was delivered.

### Consequences

- The primary specification is the 2023 cross-section with commune-clustered standard
  errors (ADR-008).
- Robustness is provided by re-estimating the primary model on 2022 and 2024 and comparing
  coefficient stability.
- For models including the social index, this check is confounded by the definitional break
  documented in ADR-006, and must be caveated or omitted.
- The panel survives for the descriptive outcome trend only.

---

<a name="adr-008"></a>
## ADR-008 — Commune-clustered standard errors (CR2)

**Status:** Accepted · **Stage:** 2

### Context

Identified while reading a scatter plot during exploratory analysis. Points formed distinct
vertical columns rather than a diffuse cloud. The cause: every school in a given commune
shares identical territorial predictor values, because those variables are measured at
commune level and attached to schools.

The consequence is that residuals are correlated within commune. Conventional standard
errors assume independent observations and will therefore be **downward-biased on precisely
the predictors the study is about**, overstating significance.

### Decision

Inference uses CR2 cluster-robust standard errors clustered by commune (approximately 1,393
clusters), computed with `clubSandwich`, reported alongside classical standard errors.

### Rationale

CR2 rather than CR1: the clusters are strongly size-heterogeneous and many are singletons —
a single school in its commune. CR1 performs poorly under exactly these conditions; CR2
applies a bias reduction designed for them.

Reporting both sets side by side makes the magnitude of the correction visible rather than
burying it in a methods note.

### Alternatives rejected

- **Classical standard errors** — known to be biased in this design. Not defensible once
  the clustering structure is identified.
- **Clustering at département level** — too few clusters for reliable asymptotics.
- **CR1** — inappropriate given cluster size heterogeneity and singletons.

### Consequences

- Standard errors on territorial predictors are expected to widen, possibly substantially.
- Effective information content is closer to the number of communes than the number of
  schools, which links the inference problem directly to the study's statistical power.
- Adds a package dependency (`clubSandwich`).

---

## Appended at Stage 3 and beyond

New decisions are appended below as later stages proceed. Existing entries are not edited.
