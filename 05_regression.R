# ------------------------------------------------------------
# DA-FR-1 — Phase 3: Regression Analysis (Models A, B, B+)
# Works on df_reg (certified 2023 cross-section).
# All models are estimated PER TRACK (GT / Pro) — never pooled.
# Headline inference: CR2 commune-clustered standard errors.
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