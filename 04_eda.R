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