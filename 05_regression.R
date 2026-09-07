# ------------------------------------------------------------
# DA-FR-1 — Phase 3: Regression Analysis (Models A, B, B+)
# Works on df_reg (certified 2023 cross-section).
# All models are estimated PER TRACK (GT / Pro) — never pooled.
# Headline inference: CR2 commune-clustered standard errors.

# Required packages (install once, not part of the analysis):
#   install.packages(c("tidyverse", "clubSandwich", "lmtest",
#                      "car", "modelsummary"))
# ------------------------------------------------------------

library(tidyverse)

# Load the certified artifact from Phase 1
df_reg <- read_rds("data/processed/df_reg.rds")

nrow(df_reg)   # 4,340

# ------------------------------------------------------------
# T0 — EFFECTIVE N RECERTIFICATION
# Phase 1 Step 3 built its complete.cases() set on median_income
# (86 NA) but omitted poverty_rate (184 NA). The two do not share
# the same missing rows: poverty carries additional NAs from INSEE
# small-commune suppression ("s" / "nd"). Effective N is therefore
# lower than certified. Recomputed here on the full predictor set.
# ------------------------------------------------------------

# Variable sets exactly as they enter each model
vars_A <- c("DV1_va",
            "fibre_coverage", "median_income", "poverty_rate", "urban_rural3")

vars_B <- c("DV2_taux", "IPS_mean",
            "fibre_coverage", "median_income", "poverty_rate", "urban_rural3")

vars_Bplus <- c(vars_B, "secteur")

# Effective N per track, per model
n_eff <- df_reg |>
  group_by(track) |>
  summarise(
    n_rows      = n(),
    n_model_A   = sum(complete.cases(pick(all_of(vars_A)))),
    n_model_B   = sum(complete.cases(pick(all_of(vars_B)))),
    n_model_Bp  = sum(complete.cases(pick(all_of(vars_Bplus)))),
    .groups = "drop"
  )

n_eff

# ------------------------------------------------------------
# T1 — MODEL A (primary): value-added ~ territorial factors
# Estimated per track. IPS excluded by design (circularity).
# Headline inference: CR2 commune-clustered standard errors.
# ------------------------------------------------------------

library(clubSandwich)

# Complete-case frames per track, matching the T0 recertified N.
# Rows are filtered before fitting so the cluster vector aligns
# with the observations lm() actually uses.
df_gt_A <- df_reg |>
  filter(track == "GT",  complete.cases(pick(all_of(vars_A))))

df_pro_A <- df_reg |>
  filter(track == "Pro", complete.cases(pick(all_of(vars_A))))

nrow(df_gt_A)    # expect 2243
nrow(df_pro_A)   # expect 1909


# --- Model A, GT ---
model_A_gt <- lm(DV1_va ~ fibre_coverage + median_income +
                   poverty_rate + urban_rural3,
                 data = df_gt_A)

summary(model_A_gt)

coef_test(model_A_gt,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)


# --- Model A, Pro ---
model_A_pro <- lm(DV1_va ~ fibre_coverage + median_income +
                    poverty_rate + urban_rural3,
                  data = df_pro_A)

summary(model_A_pro)

coef_test(model_A_pro,
          vcov    = "CR2",
          cluster = df_pro_A$commune_terr)

# ------------------------------------------------------------
# T2 — MODEL B (secondary) and MODEL B+ (sector control)
# DV = raw Bac pass rate. IPS_mean included (no circularity here).
# B and B+ are fitted on an identical sample so that coefficient
# movement reflects the added control, not a change in the data.
# ------------------------------------------------------------

# One frame per track, built on the Model B+ variable set.
# secteur has no missing values, so N is identical for B and B+.
df_gt_B <- df_reg |>
  filter(track == "GT",  complete.cases(pick(all_of(vars_Bplus))))

df_pro_B <- df_reg |>
  filter(track == "Pro", complete.cases(pick(all_of(vars_Bplus))))

nrow(df_gt_B)    # expect 2237
nrow(df_pro_B)   # expect 1907


# --- Model B, GT (baseline: Brief specification) ---
model_B_gt <- lm(DV2_taux ~ IPS_mean + fibre_coverage + median_income +
                   poverty_rate + urban_rural3,
                 data = df_gt_B)

summary(model_B_gt)

coef_test(model_B_gt, vcov = "CR2", cluster = df_gt_B$commune_terr)


# --- Model B+, GT (adds secteur) ---
model_Bp_gt <- lm(DV2_taux ~ IPS_mean + fibre_coverage + median_income +
                    poverty_rate + urban_rural3 + secteur,
                  data = df_gt_B)

summary(model_Bp_gt)

coef_test(model_Bp_gt, vcov = "CR2", cluster = df_gt_B$commune_terr)


# --- Model B, Pro ---
model_B_pro <- lm(DV2_taux ~ IPS_mean + fibre_coverage + median_income +
                    poverty_rate + urban_rural3,
                  data = df_pro_B)

summary(model_B_pro)

coef_test(model_B_pro, vcov = "CR2", cluster = df_pro_B$commune_terr)


# --- Model B+, Pro (adds secteur) ---
model_Bp_pro <- lm(DV2_taux ~ IPS_mean + fibre_coverage + median_income +
                     poverty_rate + urban_rural3 + secteur,
                   data = df_pro_B)

summary(model_Bp_pro)

coef_test(model_Bp_pro, vcov = "CR2", cluster = df_pro_B$commune_terr)

# ------------------------------------------------------------
# T3a — CORE DIAGNOSTIC BATTERY
# VIF (multicollinearity), Breusch-Pagan (reported only —
# cluster-robust SEs already absorb heteroskedasticity), and
# cluster-robust joint significance via Wald_test. The F statistic
# printed by summary() uses classical inference and is not
# comparable to the CR2 individual tests.
# ------------------------------------------------------------

library(car)
library(lmtest)

# --- VIF: Model A ---
vif(model_A_gt)
vif(model_A_pro)

# --- VIF: Model B and B+ ---
vif(model_B_gt)
vif(model_Bp_gt)
vif(model_B_pro)
vif(model_Bp_pro)

# --- Breusch-Pagan (diagnostic only, not gating) ---
bptest(model_A_gt)
bptest(model_A_pro)
bptest(model_B_gt)
bptest(model_B_pro)

# --- Cluster-robust joint significance (CR2) ---
# Tests all slope coefficients jointly = 0, excluding the intercept.
# Model A has 6 coefficients (intercept + 5), so constraints are 2:6.
Wald_test(model_A_gt,
          constraints = constrain_zero(2:6),
          vcov        = "CR2",
          cluster     = df_gt_A$commune_terr)

Wald_test(model_A_pro,
          constraints = constrain_zero(2:6),
          vcov        = "CR2",
          cluster     = df_pro_A$commune_terr)

# Model B has 7 coefficients (intercept + 6), so 2:7.
Wald_test(model_B_gt,
          constraints = constrain_zero(2:7),
          vcov        = "CR2",
          cluster     = df_gt_B$commune_terr)

Wald_test(model_B_pro,
          constraints = constrain_zero(2:7),
          vcov        = "CR2",
          cluster     = df_pro_B$commune_terr)

# ------------------------------------------------------------
# T3b — median_income: diagnosing the low effective df
# VIF is only ~2.6, so collinearity does not explain df = 5.02.
# Hypothesis (Lead): Filosofi retains arrondissement granularity,
# so income varies widely across Paris, but commune_terr collapses
# all Paris arrondissements into one cluster — concentrating the
# widest income spread in France inside a single unit of information.
# Test: re-cluster on commune_final (arrondissements separate) and
# re-read the effective df. Coefficients are unchanged; only the
# variance estimator differs.
# ------------------------------------------------------------

# --- Re-cluster Model B on commune_final ---
coef_test(model_B_gt,
          vcov    = "CR2",
          cluster = df_gt_B$commune_final)

coef_test(model_B_pro,
          vcov    = "CR2",
          cluster = df_pro_B$commune_final)


# --- Where does income's identifying variation sit? ---
# NOTE: income was joined on commune_final (arrondissements intact),
# so it is NOT constant within commune_terr for Paris, Lyon and
# Marseille. The cluster unit for income is therefore commune_final.
income_clusters <- df_gt_B |>
  group_by(commune_final) |>
  summarise(income    = first(median_income),
            n_schools = n(),
            .groups   = "drop") |>
  arrange(desc(income))

head(income_clusters, 15)

quantile(income_clusters$income, probs = c(0.50, 0.90, 0.95, 0.99, 1.00))

# Income spread inside the collapsed Paris cluster
df_gt_B |>
  filter(commune_terr == "75056") |>
  summarise(n_schools   = n(),
            n_arrond    = n_distinct(commune_final),
            income_min  = min(median_income),
            income_max  = max(median_income))

# --- Pre-specified variants (Ruling 3): now confirmatory ---
# Effective df recovered under commune_final, so these test whether
# the income coefficient is robust to functional form and to the
# high-income tail, rather than diagnosing a fragile estimate.

# (a) log(median_income) variant, Model B, GT
model_B_gt_log <- lm(DV2_taux ~ IPS_mean + fibre_coverage +
                       log(median_income) + poverty_rate + urban_rural3,
                     data = df_gt_B)

coef_test(model_B_gt_log,
          vcov    = "CR2",
          cluster = df_gt_B$commune_final)

# (b) Sensitivity: drop the top 1% income communes
income_p99 <- quantile(df_gt_B$median_income, probs = 0.99)

df_gt_B_trim <- df_gt_B |>
  filter(median_income <= income_p99)

nrow(df_gt_B_trim)   # how many schools remain

model_B_gt_trim <- lm(DV2_taux ~ IPS_mean + fibre_coverage + median_income +
                        poverty_rate + urban_rural3,
                      data = df_gt_B_trim)

coef_test(model_B_gt_trim,
          vcov    = "CR2",
          cluster = df_gt_B_trim$commune_final)

# ------------------------------------------------------------
# T3c — Decomposing the fibre_coverage effect (Lead Ruling 1)
# Hypothesis: fibre proxies urban density rather than digital
# access. Fibre's Satterthwaite df is 28.7 out of 1,337 clusters —
# it is identified off a small set of low-coverage communes, the
# same places producing the positive rural contrast. Three refits
# test whether fibre and urban_rural3 compete for the same variation.
# ------------------------------------------------------------

# (1) Model A without urban_rural3 — does fibre's coefficient grow?
model_A_gt_nourb <- lm(DV1_va ~ fibre_coverage + median_income + poverty_rate,
                       data = df_gt_A)

coef_test(model_A_gt_nourb,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)


# (2) Model A without fibre_coverage — do the urban/rural contrasts grow?
model_A_gt_nofib <- lm(DV1_va ~ median_income + poverty_rate + urban_rural3,
                       data = df_gt_A)

coef_test(model_A_gt_nofib,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)


# (3) Model A on the dense-coverage sample only (fibre >= 85)
# If significance evaporates, the effect lives entirely in the
# sparse left tail rather than across the range where schools sit.
df_gt_A_dense <- df_gt_A |>
  filter(fibre_coverage >= 85)

nrow(df_gt_A_dense)   # schools remaining

model_A_gt_dense <- lm(DV1_va ~ fibre_coverage + median_income +
                         poverty_rate + urban_rural3,
                       data = df_gt_A_dense)

coef_test(model_A_gt_dense,
          vcov    = "CR2",
          cluster = df_gt_A_dense$commune_terr)

# --- Same decomposition on Pro (fibre was individually significant there) ---
df_pro_A_dense <- df_pro_A |>
  filter(fibre_coverage >= 85)

nrow(df_pro_A_dense)

model_A_pro_dense <- lm(DV1_va ~ fibre_coverage + median_income +
                          poverty_rate + urban_rural3,
                        data = df_pro_A_dense)

coef_test(model_A_pro_dense,
          vcov    = "CR2",
          cluster = df_pro_A_dense$commune_terr)


# --- Joint significance on the dense GT sample ---
# Model A GT was jointly significant on the full sample (p<0.001);
# confirm it holds where the fibre effect is strongest.
Wald_test(model_A_gt_dense,
          constraints = constrain_zero(2:6),
          vcov        = "CR2",
          cluster     = df_gt_A_dense$commune_terr)

# ------------------------------------------------------------
# T3c-bis — Alternative explanations for the fibre association
# The continuous population-density control (Lead Ruling 3) was
# not run: NBPERSMENFISC21 was not carried through the Phase 1
# pipeline. Documented as a limitation — the density mechanism is
# untested, not ruled out. Two cheaper checks are run instead.
# ------------------------------------------------------------

# (1) Finer urban gradient: full 5-level CATEAAV2020
model_A_gt_cat5 <- lm(DV1_va ~ fibre_coverage + median_income +
                        poverty_rate + factor(CATEAAV2020),
                      data = df_gt_A)

coef_test(model_A_gt_cat5,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)

# (2) Regional fixed effects — is the association a regional artefact?
# No département column was carried through the pipeline, but the
# département is the first two characters of the INSEE commune code.
# Derived locally here (analysis-only, not a pipeline change).
df_gt_A <- df_gt_A |>
  mutate(dept = str_sub(commune_terr, 1, 2))

n_distinct(df_gt_A$dept)

model_A_gt_dept <- lm(DV1_va ~ fibre_coverage + median_income +
                        poverty_rate + urban_rural3 + factor(dept),
                      data = df_gt_A)

coef_test(model_A_gt_dept,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)[1:6, ]

# ------------------------------------------------------------
# T3d — MODEL A+ : sector effect net of intake (Lead Ruling 4)
# DV1_va already nets out intake composition via DEPP's model, so
# the sector coefficient here is the defensible effectiveness
# estimate — as opposed to Model B+, where the sector coefficient
# still contains composition that IPS_mean alone does not capture.
# Caveat: value-added is a residual from DEPP's model, which may
# itself over- or under-adjust. Not a pure effectiveness measure.
# ------------------------------------------------------------

# Complete-case frames including secteur.
# secteur has no missing values, so N matches Model A exactly.
df_gt_Ap <- df_reg |>
  filter(track == "GT",  complete.cases(pick(all_of(c(vars_A, "secteur")))))

df_pro_Ap <- df_reg |>
  filter(track == "Pro", complete.cases(pick(all_of(c(vars_A, "secteur")))))

nrow(df_gt_Ap)    # expect 2243
nrow(df_pro_Ap)   # expect 1909


# --- Model A+, GT ---
model_Ap_gt <- lm(DV1_va ~ fibre_coverage + median_income +
                    poverty_rate + urban_rural3 + secteur,
                  data = df_gt_Ap)

summary(model_Ap_gt)

coef_test(model_Ap_gt,
          vcov    = "CR2",
          cluster = df_gt_Ap$commune_terr)


# --- Model A+, Pro ---
model_Ap_pro <- lm(DV1_va ~ fibre_coverage + median_income +
                     poverty_rate + urban_rural3 + secteur,
                   data = df_pro_Ap)

summary(model_Ap_pro)

coef_test(model_Ap_pro,
          vcov    = "CR2",
          cluster = df_pro_Ap$commune_terr)

# Cluster-robust joint significance for Model A+ (7 coefficients: intercept + 6)
Wald_test(model_Ap_gt,
          constraints = constrain_zero(2:7),
          vcov        = "CR2",
          cluster     = df_gt_Ap$commune_terr)

Wald_test(model_Ap_pro,
          constraints = constrain_zero(2:7),
          vcov        = "CR2",
          cluster     = df_pro_Ap$commune_terr)

# ------------------------------------------------------------
# T4 — ROBUSTNESS: urban/rural coding
# P2-T3 adopted urban_rural3 (3 levels) over the original binary
# urban_rural. This refits Model A with the binary variable to
# confirm that the territorial coefficients are not driven by
# that coding decision.
# ------------------------------------------------------------

model_A_gt_bin <- lm(DV1_va ~ fibre_coverage + median_income +
                       poverty_rate + urban_rural,
                     data = df_gt_A)

coef_test(model_A_gt_bin,
          vcov    = "CR2",
          cluster = df_gt_A$commune_terr)


model_A_pro_bin <- lm(DV1_va ~ fibre_coverage + median_income +
                        poverty_rate + urban_rural,
                      data = df_pro_A)

coef_test(model_A_pro_bin,
          vcov    = "CR2",
          cluster = df_pro_A$commune_terr)

# ------------------------------------------------------------
# T5 — PUBLICATION COEFFICIENT TABLES
# Four specifications (A, B, B+, A+) per track.
# Coefficients, standard errors AND p-values are taken directly
# from coef_test(), so significance stars use the Satterthwaite
# small-sample degrees of freedom rather than large-sample df.
# This matters for coefficients with few effective df (e.g.
# median_income, df = 5.0), where large-sample p-values would
# overstate significance.
# ------------------------------------------------------------

library(modelsummary)

dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)

# Helper: convert a fitted model + cluster vector into the structure
# modelsummary expects, carrying CR2 estimates and Satterthwaite p-values.
ms_from_coeftest <- function(mod, cluster_vec) {
  ct <- coef_test(mod, vcov = "CR2", cluster = cluster_vec)
  
  tidy_part <- data.frame(
    term      = ct$Coef,
    estimate  = ct$beta,
    std.error = ct$SE,
    p.value   = ct$p_Satt
  )
  
  glance_part <- data.frame(
    nobs          = nobs(mod),
    r.squared     = summary(mod)$r.squared,
    adj.r.squared = summary(mod)$adj.r.squared
  )
  
  out <- list(tidy = tidy_part, glance = glance_part)
  class(out) <- "modelsummary_list"
  out
}

# Readable variable labels (also controls row order)
var_labels <- c(
  "IPS_mean"             = "School social index (IPS)",
  "fibre_coverage"       = "FTTH coverage (%)",
  "median_income"        = "Median income (EUR)",
  "poverty_rate"         = "Poverty rate (%)",
  "urban_rural3Suburban" = "Suburban (ref: Urban core)",
  "urban_rural3Rural"    = "Rural (ref: Urban core)",
  "secteurpublic"        = "Public sector (ref: private)",
  "(Intercept)"          = "Constant"
)

table_note <- paste(
  "CR2 cluster-robust standard errors, clustered on commune;",
  "p-values use Satterthwaite degrees of freedom.",
  "DV: Models A and A+ = IVAL value-added;",
  "Models B and B+ = raw Bac pass rate.",
  "Median income is measured in euros, so its coefficient is small by construction:",
  "a EUR 1,000 difference corresponds to roughly 0.3 percentage points."
)


# --- GT table ---
models_gt <- list(
  "Model A"  = ms_from_coeftest(model_A_gt,  df_gt_A$commune_terr),
  "Model B"  = ms_from_coeftest(model_B_gt,  df_gt_B$commune_terr),
  "Model B+" = ms_from_coeftest(model_Bp_gt, df_gt_B$commune_terr),
  "Model A+" = ms_from_coeftest(model_Ap_gt, df_gt_Ap$commune_terr)
)

modelsummary(
  models_gt,
  coef_map = var_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  fmt      = fmt_significant(3),
  title    = "Model results, general and technological track (GT)",
  notes    = table_note,
  output   = "output/tables/coefficients_gt.md"
)


# --- Pro table ---
models_pro <- list(
  "Model A"  = ms_from_coeftest(model_A_pro,  df_pro_A$commune_terr),
  "Model B"  = ms_from_coeftest(model_B_pro,  df_pro_B$commune_terr),
  "Model B+" = ms_from_coeftest(model_Bp_pro, df_pro_B$commune_terr),
  "Model A+" = ms_from_coeftest(model_Ap_pro, df_pro_Ap$commune_terr)
)

modelsummary(
  models_pro,
  coef_map = var_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  fmt      = fmt_significant(3),
  title    = "Model results, vocational track (Pro)",
  notes    = table_note,
  output   = "output/tables/coefficients_pro.md"
)