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
