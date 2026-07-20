# ------------------------------------------------------------
# DA-FR-1 — Phase 2: Descriptive Statistics & EDA
# Works on df_reg (certified 2023 cross-section) + df_full (panel, for the trend).
# All analysis is PER TRACK (GT / Pro) — never pooled.
# ------------------------------------------------------------

library(tidyverse)

# Load the certified artifacts from Phase 1 (no need to re-run 01–03)
df_reg  <- read_rds("data/processed/df_reg.rds")
df_full <- read_rds("data/processed/df_full.rds")

# Confirm they loaded
nrow(df_reg)      # 4,340
nrow(df_full)     # 60,743

# ------------------------------------------------------------
# P2-T1 — SUMMARY STATISTICS TABLE (per track)
# ------------------------------------------------------------

# Continuous model variables → moments (n, mean, median, SD, min, max, NA)
summary_continuous <- df_reg |>
  group_by(track) |>
  summarise(
    across(
      c(DV1_va, DV2_taux, IPS_mean, IPS_std,
        fibre_coverage, median_income, poverty_rate),
      list(
        n      = ~ sum(!is.na(.)),
        mean   = ~ round(mean(., na.rm = TRUE), 2),
        median = ~ round(median(., na.rm = TRUE), 2),
        sd     = ~ round(sd(., na.rm = TRUE), 2),
        min    = ~ round(min(., na.rm = TRUE), 2),
        max    = ~ round(max(., na.rm = TRUE), 2),
        na     = ~ sum(is.na(.))
      ),
      .names = "{.col}__{.fn}"
    ),
    .groups = "drop"
  )

# The table is very wide (7 stats × 7 vars). Pivot to long/readable form:
summary_long <- summary_continuous |>
  pivot_longer(-track, names_to = c("variable", "stat"), names_sep = "__") |>
  pivot_wider(names_from = stat, values_from = value) |>
  arrange(track, variable)

print(summary_long, n = 40)