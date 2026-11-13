# Social composition, not territory, predicts Bac outcomes in France

## 1. Context and research question

In spring 2020, French schools closed and teaching moved online. The
baccalauréat exams were cancelled that year, and grades were awarded on
continuous assessment. In 2021 the exams returned, but in a reduced form.

These disruptions raised a concern: students without good internet access at
home might fall behind. If that were true, schools in poorly connected areas
should show weaker results after the pandemic. This is the "digital divide"
hypothesis, and it was the starting point of this study.

The question I set out to answer is:

> What socioeconomic and territorial factors predict Baccalauréat outcomes
> across French lycées in the post-COVID period?

I work at the level of the lycée, for two reasons. The Bac is the exam that
closes the lycée, so it is the natural outcome to measure. And the Ministry of
Education publishes results for every lycée, including a value-added indicator
that accounts for the profile of the students each school receives.

French lycées have two main tracks: general and technological (GT), and
vocational (Pro). They teach different students, with different pass rates and
different social backgrounds. I analyse them separately throughout.

## 2. Data and method

### Data

The study combines nine public datasets.

| Source | Publisher | What it provides |
|---|---|---|
| IVAL (GT and Pro) | DEPP, Ministry of Education | Pass rate and value-added for each lycée |
| IPS 2022, 2023 | DEPP | Social position index of each school's students |
| Annuaire de l'éducation | Ministry of Education | School directory, used to locate each lycée |
| Bac results by département | DEPP | Pass rates by département, 2023–2025 |
| Filosofi 2021 | INSEE | Median income and poverty rate by commune |
| MCI 2024 T4 | ARCEP | Share of premises with fibre (FTTH) by commune |
| AAV 2020 | INSEE | Urban/rural classification of each commune |

The main sample is the 2023 session: 4,340 observations, one per lycée and
track (2,331 GT, 2,009 Pro). A school that offers both tracks appears twice,
because its GT and Pro students are different populations. A 2019–2024 panel is
used only to describe how pass rates moved over time.

Merging these files took most of the data work. Three problems are worth
naming. First, 983 lycées appeared in both the GT and the Pro files, so each
row needed a track label to stay unique. Second, some commune codes did not
match across sources, because one dataset splits Paris, Lyon and Marseille into
districts and the others do not. Third, income figures were silently lost on
import, because French files use a decimal comma and INSEE hides small-commune
values behind text codes. Each problem was fixed in the pipeline and checked
with row counts after every join.

### Two outcomes

I use two measures of school results:

- **Raw pass rate:** the share of candidates who passed the Bac.
- **Value-added:** the school's actual pass rate minus the rate expected
  given its students' profile. It is calculated by the Ministry.

Value-added is the main outcome. The raw rate has a ceiling problem: half of
GT lycées pass 97% or more of their candidates, so there is little room left to
explain. Value-added also removes the effect of who the school enrols, which is
exactly what a fair comparison between schools needs.

### Models

Four regression models, each run separately for GT and Pro:

| Model | Outcome | Explanatory variables |
|---|---|---|
| A | Value-added | Fibre coverage, median income, poverty rate, urban/rural |
| B | Raw pass rate | Model A + school social index (IPS) |
| B+ | Raw pass rate | Model B + public/private sector |
| A+ | Value-added | Model A + public/private sector |

Model A leaves out the social index on purpose: value-added already accounts
for it. The data confirm this. The correlation between value-added and the
social index is 0.05 in GT and 0.00 in Pro.

### Two choices that shape the results

**GT and Pro are never pooled.** The tracks differ in pass rates (median 97%
against 84%), in social background (average social index 113 against 96) and in
how strongly these two are linked. One combined model would average two
different systems into a number that describes neither.

**Standard errors account for shared location.** Schools in the same commune
share exactly the same income, poverty and fibre values, so they are not
independent observations. I use cluster-robust standard errors (CR2), grouped
by commune. This makes the estimates more honest about their uncertainty:
standard errors on the territorial variables rose by 22–35%.

Before running any model, I wrote down what I expected to find. Section 3
reports whether each expectation held.

## 3. Results

### 3.1 Territory explains almost nothing about how well a school performs

Model A asks whether a lycée's location predicts its value-added, that is, how
far its pass rate sits above or below what its intake would predict. The answer
is close to no. Fibre coverage, median income, poverty and urban/rural status
together explain 1.9% of the variation in value-added in GT and 0.4% in Pro. In
Pro the four variables are not even jointly significant (p = 0.28): the model
cannot rule out that none of them matters. I expected this before running the
model, and it held.

### 3.2 Who attends the school explains a great deal

The raw pass rate tells a different story. Adding the school's social index
(IPS) to the same territorial variables (Model B) raises the explained variation
from 1.9% to 44.1% in GT, and from 0.4% to 17.6% in Pro. In GT, a lycée whose
students score 10 points higher on the index passes about 2 percentage points
more of its candidates. This is the most precisely estimated relationship in the
study.

The two models answer different parts of the question. Model B shows that pass
rates differ between schools mostly because their students differ. Model A,
the main test, shows that once intake is taken into account, what remains has
little to do with where the school is located.

### 3.3 Private lycées do better, and in Pro most of the gap is intake

Public lycées have lower value-added than private ones in both tracks: about
1.9 points in GT and 3.3 points in Pro (Model A+). In Pro, sector is the only
variable that explains anything about value-added. Adding it raises R² from
0.4% to 4.1%.

What sits behind the gap differs by track. In Pro, private lycées pass about 13
points more of their candidates than public ones. Roughly 10 of those points
reflect the students each sector enrols; about 3 remain once intake is fully
taken into account. In GT the social index captures intake well: the sector gap
is the same whether I control for IPS (−1.91) or use value-added (−1.90). In Pro
it does not (−9.83 against −3.25), so a single social index misses a large part
of how private and public vocational intakes differ.

This is an association, not proof that private schools teach better. Private
lycées may differ in ways that neither measure captures.

### 3.4 The result I did not expect: fibre

Before estimation, I expected fibre coverage to have no relationship with
value-added. In GT it did, and in the opposite direction to the digital-divide
hypothesis: lycées in better-connected communes had slightly lower value-added
(−0.027 per percentage point of coverage, p = 0.004). Going from 85% to 100%
coverage, the range where most communes sit, corresponds to about 0.4 points of
value-added, against a standard deviation of 3.0. The effect is small, but large
enough to be detected.

I did not replace the main model with a different specification, and I did not
explain the result away. I ran six checks instead:

| Check | Question it answers | Result |
|---|---|---|
| Keep only communes with ≥85% coverage | Is the result driven by a few poorly connected communes? | Still negative and significant (−0.066, p = 0.02). The confidence intervals overlap with the main estimate, so this confirms the sign, not a larger effect |
| Remove urban/rural from the model | Is fibre standing in for urbanity? | Fibre coefficient barely moved |
| Remove fibre from the model | Do the other variables absorb its effect? | Other coefficients barely moved |
| Replace the 3-level urban variable with the 5-level INSEE one | Does a finer urban gradient change the picture? | The three urban sub-categories were statistically indistinguishable, so the finer coding added nothing |
| Add département fixed effects | Is this a regional pattern rather than a local one? | Coefficient fell by 45% (−0.015) and lost conventional significance (p = 0.075) |
| Repeat in Pro | Does it hold in the other track? | Not robust; the Pro model is jointly non-significant, so no single coefficient in it is interpreted |

The association is in the data, it is small, it is partly regional, and I
cannot explain it. The most likely candidate is population density: fibre
reached dense areas first. The urban/rural variable is too coarse to test that
properly, and I did not run a continuous density control (see Section 4). I
report the association as unexplained rather than invent a mechanism for it.

What the result does show is that these data offer no support for the idea that
poorly connected communes have weaker lycée value-added.

### 3.5 Two smaller results

Rural lycées in GT show higher value-added than those in urban cores
(+1.4 points). The rural group is small (56 lycées across both tracks), so this
estimate is imprecise.

Commune poverty has a small positive coefficient in Model A, but it disappears
completely once département fixed effects are added (p = 0.99). It reflects
differences between regions, not between communes.

### 3.6 What I expected and what I found

| Expectation, written before estimation | Result |
|---|---|
| Territorial variables explain little of value-added in GT | Held (R² 1.9%) |
| Territorial variables explain little of value-added in Pro | Held (R² 0.4%, jointly non-significant) |
| The social index dominates the raw pass rate | Held (R² from 1.9% to 44.1% in GT) |
| Fibre coverage is not significant | Did not hold in GT (small, negative); not robust in Pro |

Three of four expectations held. The one that failed led to the most careful
part of the analysis.