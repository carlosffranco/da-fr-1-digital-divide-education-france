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