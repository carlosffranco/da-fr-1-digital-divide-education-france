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

# ------------------------------------------------------------
# P2-T2 — DISTRIBUTION DIAGNOSTICS (histograms, per track)
# ------------------------------------------------------------

# Histogram 1: DV2_taux (raw Bac rate) — ceiling effect (NA filtered)
df_reg |>
  filter(!is.na(DV2_taux)) |>
  ggplot(aes(x = DV2_taux)) +
  geom_histogram(binwidth = 2, fill = "steelblue", color = "white") +
  facet_wrap(~ track, scales = "free_y") +
  labs(
    title = "Distribution of Raw Bac Pass Rate (DV2) by Track",
    subtitle = "GT compressed against the 100% ceiling; Pro more dispersed",
    x = "Raw Bac pass rate (%)",
    y = "Number of lycées"
  ) +
  theme_minimal()

ggsave("output/figures/p2t2_dv2_hist.png", width = 9, height = 5, dpi = 300)

# Histogram 2: DV1_va (value-added) — symmetric, centered on 0 (NA filtered)
df_reg |>
  filter(!is.na(DV1_va)) |>
  ggplot(aes(x = DV1_va)) +
  geom_histogram(binwidth = 1, fill = "darkorange", color = "white") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  facet_wrap(~ track, scales = "free_y") +
  labs(
    title = "Distribution of Value-Added Score (DV1) by Track",
    subtitle = "Centered on 0 (a residual by construction); Pro has fatter tails",
    x = "Value-added score (points above/below expected)",
    y = "Number of lycées"
  ) +
  theme_minimal()

ggsave("output/figures/p2t2_dv1_hist.png", width = 9, height = 5, dpi = 300)

# Histogram 3: fibre_coverage — Catch 1 (NA filtered before plotting for clean output)
df_reg |>
  filter(!is.na(fibre_coverage)) |>
  ggplot(aes(x = fibre_coverage)) +
  geom_histogram(binwidth = 5, fill = "seagreen", color = "white") +
  facet_wrap(~ track, scales = "free_y") +
  labs(
    title = "Distribution of Fibre Coverage by Track",
    subtitle = "Left-skewed: saturated near 90-100% with a long left tail (rural low-coverage communes)",
    x = "FTTH fibre coverage (%)",
    y = "Number of lycées"
  ) +
  theme_minimal()

ggsave("output/figures/p2t2_fibre_hist.png", width = 9, height = 5, dpi = 300)

# ------------------------------------------------------------
# P2-T3 — URBAN/RURAL CODING DECISION (Catch 2)
# ------------------------------------------------------------

# Full CATEAAV2020 distribution per track (the 5 real categories)
# 11 = large urban centre, 12 = mid, 13 = small urban centre,
# 20 = suburban belt (couronne), 30 = rural / outside AAV
df_reg |>
  count(track, CATEAAV2020) |>
  pivot_wider(names_from = track, values_from = n, values_fill = 0) |>
  arrange(CATEAAV2020)

# Compare against the current binary
df_reg |>
  count(track, urban_rural)

# Adopted coding: 3-level urban_rural3 (created in 03_execute_joins.R)
df_reg |>
  count(track, urban_rural3) |>
  pivot_wider(names_from = track, values_from = n, values_fill = 0)

# Consistency check: binary vs 3-level coding
df_reg |>
  count(urban_rural, urban_rural3)

# ------------------------------------------------------------
# P2-T4 — CORRELATION MATRIX & COLLINEARITY PRE-CHECK
# ------------------------------------------------------------
# Pearson correlations among continuous model variables, per track.
# Pre-check only: VIF on the estimation sample (Phase 3) is the
# authoritative multicollinearity diagnostic.

cor_vars <- c("DV1_va", "DV2_taux", "IPS_mean",
              "fibre_coverage", "median_income", "poverty_rate")

# --- GT ---
cor_gt <- df_reg |>
  filter(track == "GT") |>
  select(all_of(cor_vars)) |>
  cor(use = "pairwise.complete.obs") |>
  round(2)

cor_gt

# --- Pro ---
cor_pro <- df_reg |>
  filter(track == "Pro") |>
  select(all_of(cor_vars)) |>
  cor(use = "pairwise.complete.obs") |>
  round(2)

cor_pro

