# ------------------------------------------------------------
# DA-FR-1 — Phase 1, Step 3: Execute Joins & Derive Variables
# Reconcile dual commune sources → arrondissement mapping →
# execute join sequence with row-count assertions → derive
# variables → post-merge integrity audit → certify df_reg.
# Inputs (from Step 2, in memory): crosswalk_final, filosofi_input,
# arcep_input, aav_input, ival_anchor, ips_input.
# ------------------------------------------------------------

library(tidyverse)

# ------------------------------------------------------------
# T0 — RECONCILE DUAL COMMUNE SOURCES
# ------------------------------------------------------------

# T0.1 — inspect & clean the IVAL-native commune code
# (ival_anchor already has a 'code_commune' column from IVAL's own record)
ival_anchor |> select(UAI, annee, code_commune) |> head(5)      # what does it look like?
sum(is.na(ival_anchor$code_commune))                            # any missing?

# Clean it the same Corsica-safe way (strip .0 if present, pad to 5)
ival_anchor <- ival_anchor |>
  mutate(commune_ival = str_pad(str_remove(code_commune, "\\.0$"), 5, pad = "0"))

# Validate format
ival_anchor |>
  filter(!str_detect(commune_ival, "^(\\d{5}|2[AB]\\d{3})$")) |>
  distinct(commune_ival) |> head(20)      # any malformed? (inspect)

# T0.2 — compare IVAL-native vs crosswalk commune (2023 slice) → agreement rate

# Bring the crosswalk commune alongside the IVAL-native one, for 2023
recon_2023 <- ival_anchor |>
  filter(annee == 2023) |>
  select(UAI, annee, commune_ival) |>
  left_join(crosswalk_final |> select(UAI, commune_xwalk = code_commune),
            by = "UAI")

# How many 2023 school-rows have each source?
nrow(recon_2023)                                          # total 2023 rows
sum(is.na(recon_2023$commune_ival))                       # missing IVAL-native (expect 0)
sum(is.na(recon_2023$commune_xwalk))                      # missing crosswalk (the gap)

# Agreement rate WHERE BOTH exist
recon_both <- recon_2023 |> filter(!is.na(commune_xwalk))
agreement <- mean(recon_both$commune_ival == recon_both$commune_xwalk)
round(agreement * 100, 2)                                 # % agreement (QC metric)

# Where they DISAGREE — how many, and a peek
recon_both |> filter(commune_ival != commune_xwalk) |> nrow()
recon_both |> filter(commune_ival != commune_xwalk) |> head(10)

# T0.3 — build commune_final = coalesce(IVAL-native, crosswalk)
# IVAL-native wins (contemporaneous to Bac year); crosswalk fills only if IVAL missing (never, here)

# First bring crosswalk commune onto the FULL anchor (all years), then coalesce
ival_anchor <- ival_anchor |>
  left_join(crosswalk_final |> select(UAI, commune_xwalk = code_commune),
            by = "UAI") |>
  mutate(commune_final = coalesce(commune_ival, commune_xwalk))

# Verify: commune_final should have NO missing (IVAL-native is complete)
sum(is.na(ival_anchor$commune_final))                     # expect 0
nrow(ival_anchor)                                         # still 60,743? (no fan-out)

# Restate 2023 commune coverage after coalesce
ival_anchor |>
  filter(annee == 2023) |>
  summarise(
    total       = n(),
    has_commune = sum(!is.na(commune_final)),
    coverage    = round(mean(!is.na(commune_final)) * 100, 2)
  )

# ------------------------------------------------------------
# T1 — ARRONDISSEMENT VERIFICATION + MAPPING (Ruling 1)
# ------------------------------------------------------------

# T1.1 — VERIFY (do not assume): which sources carry arrondissement codes?
# Paris arrondissements = 751xx; Lyon = 6938x; Marseille = 132xx
# Global codes: Paris 75056, Lyon 69123, Marseille 13055

# Helper: does a source contain Paris arrondissement codes? global code?
check_arr <- function(df, key) {
  key <- df[[key]]
  tibble(
    paris_arr    = sum(str_detect(key, "^751[0-2][0-9]$"), na.rm = TRUE),  # 75101-75120
    paris_global = sum(key == "75056", na.rm = TRUE),
    lyon_arr     = sum(str_detect(key, "^6938[0-9]$"), na.rm = TRUE),      # 69381-69389
    lyon_global  = sum(key == "69123", na.rm = TRUE),
    mars_arr     = sum(str_detect(key, "^132[0-1][0-9]$"), na.rm = TRUE),  # 13201-13216
    mars_global  = sum(key == "13055", na.rm = TRUE)
  )
}

# Run the check on each territorial source
check_arr(filosofi_input, "CODGEO")      # income  — expect arrondissements PRESENT
check_arr(arcep_input,    "code_insee")  # fibre   — expect global only?
check_arr(aav_input,      "CODGEO")      # urban   — expect global only?

# T1.2 — build commune_terr: map arrondissements → parent global code (ARCEP/AAV only)
# commune_final keeps arrondissements (for Filosofi income join)

ival_anchor <- ival_anchor |>
  mutate(commune_terr = case_when(
    str_detect(commune_final, "^751[0-2][0-9]$") ~ "75056",   # Paris arr → global
    str_detect(commune_final, "^6938[0-9]$")     ~ "69123",   # Lyon arr → global
    str_detect(commune_final, "^132[0-1][0-9]$") ~ "13055",   # Marseille arr → global
    TRUE                                          ~ commune_final  # everything else unchanged
  ))

# Validate: commune_terr well-formed, no NAs, and arrondissements are gone
sum(is.na(ival_anchor$commune_terr))                                   # expect 0
ival_anchor |> filter(!str_detect(commune_terr, "^(\\d{5}|2[AB]\\d{3})$")) |> nrow()  # malformed? expect 0

# Confirm the mapping worked: how many rows were remapped?
ival_anchor |>
  filter(commune_final != commune_terr) |>
  count(commune_final, commune_terr) |>
  arrange(desc(n)) |> head(10)

# ------------------------------------------------------------
# T2 — EXECUTE JOIN SEQUENCE (with row-count assertions)
# ------------------------------------------------------------

# Baseline row count — every join must preserve this
n_base <- nrow(ival_anchor)
n_base                                            # 60,743

# ── Join 1: anchor → IPS (by UAI + annee) ──────────────────
# Note: IPS replicates across GT/Pro rows of an LPO — expected, NOT fan-out (row count preserved)
df <- ival_anchor |>
  left_join(ips_input, by = c("UAI", "annee"))

stopifnot(nrow(df) == n_base)                     # assert: no fan-out
nrow(df)                                          # confirm still 60,743

# ── Join 2: df → Filosofi (income) BY commune_final (arrondissements kept) ──
df <- df |>
  left_join(filosofi_input, by = c("commune_final" = "CODGEO"))

stopifnot(nrow(df) == n_base)                     # assert: no fan-out
nrow(df)                                          # confirm still 60,743

# ── Join 3: df → ARCEP (fibre) BY commune_terr (arrondissements collapsed) ──
df <- df |>
  left_join(arcep_input, by = c("commune_terr" = "code_insee"))

stopifnot(nrow(df) == n_base)                     # assert: no fan-out
nrow(df)                                          # confirm still 60,743

# ── Join 4: df → AAV (urban/rural) BY commune_terr (arrondissements collapsed) ──
df <- df |>
  left_join(aav_input, by = c("commune_terr" = "CODGEO"))

stopifnot(nrow(df) == n_base)                     # assert: no fan-out
nrow(df)                                          # confirm still 60,743

# ── Assertion summary table (all 4 joins) ──────────────────
tibble(
  step       = c("baseline (anchor)", "1: + IPS", "2: + Filosofi", "3: + ARCEP", "4: + AAV"),
  join_key   = c("—", "UAI + annee", "commune_final", "commune_terr", "commune_terr"),
  nrow_after = c(n_base, n_base, n_base, n_base, nrow(df)),
  preserved  = nrow(df) == n_base
)
# ------------------------------------------------------------
# T3 — DERIVE ANALYTICAL VARIABLES
# ------------------------------------------------------------

df <- df |>
  mutate(
    # Convert raw territorial cols to numeric (were character from intake)
    elig_ftth = as.numeric(elig_ftth),
    nbr       = as.numeric(nbr),
    
    # fibre_coverage with divide-by-zero guard
    fibre_coverage = if_else(nbr == 0, NA_real_, elig_ftth / nbr * 100),
    
    # urban_rural: binary factor (30 = Rural, else Urban)
    urban_rural = factor(if_else(CATEAAV2020 == "30", "Rural", "Urban"),
                         levels = c("Urban", "Rural")),
    
    # exclude_regression flag: 2020 = COVID automatic passes
    exclude_regression = (annee == "2020")
  )

# ── Guard checks the Lead required ─────────────────────────
sum(df$nbr == 0, na.rm = TRUE)                          # how many divide-by-zero (now NA)?
sum(is.na(df$fibre_coverage))                           # total NA in fibre_coverage
df |> filter(fibre_coverage > 100) |> nrow()           # values >100 (data errors)? inspect
summary(df$fibre_coverage)                              # distribution sanity check

# Quick check on the other two derived variables
df |> count(urban_rural)                         # Urban/Rural distribution + any NA
df |> count(exclude_regression)                  # TRUE only for 2020?
df |> filter(exclude_regression) |> count(annee) # confirm exclude flag = 2020 only

# Rename Filosofi columns to analytical names (match model & formulas)
df <- df |>
  rename(
    median_income = MED21,
    poverty_rate  = TP6021,
    income_d1     = D121,
    income_ratio  = RD21
  )

# Confirm the rename worked
df |> select(median_income, poverty_rate, income_d1, income_ratio) |> names()

# Preview: NA counts in the 2023 slice for the derived/territorial vars
df |>
  filter(annee == "2023") |>
  summarise(
    n_2023         = n(),
    na_fibre       = sum(is.na(fibre_coverage)),
    na_urban_rural = sum(is.na(urban_rural)),
    na_income      = sum(is.na(median_income)),
    na_poverty     = sum(is.na(poverty_rate))
  )

# ------------------------------------------------------------
# T4 — POST-MERGE INTEGRITY AUDIT (NA audit, DV-focused)
# ------------------------------------------------------------

# Convert model variables to numeric (were character from intake)
df <- df |>
  mutate(
    DV1_va   = as.numeric(DV1_va),
    DV2_taux = as.numeric(DV2_taux),
    IPS_mean = as.numeric(IPS_mean),
    IPS_std  = as.numeric(IPS_std),
    presents = as.numeric(presents)
  )

# ── T4.1 — global NA audit on all model variables (full df) ──
df |>
  summarise(across(
    c(DV1_va, DV2_taux, IPS_mean, fibre_coverage,
      median_income, poverty_rate, urban_rural),
    ~ sum(is.na(.))
  ))

# ── T4.2 — DV-specific NA audit in the 2023 slice (sets effective N) ──
df_2023 <- df |> filter(annee == "2023", !exclude_regression)
nrow(df_2023)                                    # total 2023 rows (pre-deletion)

df_2023 |>
  summarise(
    n_total      = n(),
    na_DV1       = sum(is.na(DV1_va)),           # value-added missing (Model A)
    na_DV2       = sum(is.na(DV2_taux)),         # raw rate missing (Model B)
    na_IPS       = sum(is.na(IPS_mean)),         # IPS missing (Model B)
    pct_DV1_na   = round(mean(is.na(DV1_va)) * 100, 1),
    pct_DV2_na   = round(mean(is.na(DV2_taux)) * 100, 1)
  )

# Effective N per model, per track (listwise deletion on each model's variables)

# Model A vars: DV1_va + territorial (fibre, income, poverty, urban_rural)
# Model B vars: DV2_taux + IPS_mean + territorial
df_2023 |>
  group_by(track) |>
  summarise(
    n_rows = n(),
    # Model A effective N: complete cases on DV1 + territorial predictors
    n_modelA = sum(complete.cases(DV1_va, fibre_coverage, median_income, poverty_rate, urban_rural)),
    # Model B effective N: complete cases on DV2 + IPS + territorial predictors
    n_modelB = sum(complete.cases(DV2_taux, IPS_mean, fibre_coverage, median_income, poverty_rate, urban_rural))
  )

# T4.3 — characterize schools dropped by listwise deletion (Model A)
# Flag complete vs dropped for Model A
df_2023 <- df_2023 |>
  mutate(dropped_A = !complete.cases(
    DV1_va, fibre_coverage, median_income, poverty_rate, urban_rural
  ))

# Which variable causes each drop? (diagnose the source of missingness)
df_2023 |>
  filter(dropped_A) |>
  summarise(
    n_dropped     = n(),
    miss_DV1      = sum(is.na(DV1_va)),
    miss_fibre    = sum(is.na(fibre_coverage)),
    miss_income   = sum(is.na(median_income)),
    miss_urban    = sum(is.na(urban_rural))
  )

# Are dropped schools systematically different? Compare by sector and track
df_2023 |>
  group_by(dropped_A) |>
  summarise(
    n           = n(),
    pct_private = round(mean(str_detect(secteur, regex("privé", ignore_case = TRUE))) * 100, 1),
    pct_rural   = round(mean(urban_rural == "Rural", na.rm = TRUE) * 100, 1),
    mean_presents = round(mean(presents, na.rm = TRUE), 0)
  )
# ------------------------------------------------------------
# T5 — BUILD & CERTIFY df_reg (regression-ready 2023 cross-section)
# ------------------------------------------------------------

# Filter to the analysis universe: 2023 session, non-excluded
df_reg <- df |>
  filter(annee == "2023", !exclude_regression)

# ── Certify: dimensions and per-track effective N ──────────
nrow(df_reg)                                     # total rows (should be 4,340)
df_reg |> count(track)                            # rows per track

# Formal effective-N certification per model, per track
df_reg |>
  group_by(track) |>
  summarise(
    rows      = n(),
    modelA_N  = sum(complete.cases(DV1_va, fibre_coverage, median_income, poverty_rate, urban_rural)),
    modelB_N  = sum(complete.cases(DV2_taux, IPS_mean, fibre_coverage, median_income, poverty_rate, urban_rural)),
    .groups = "drop"
  )

# ── Final structural check: confirm regression-ready ───────
df_reg |>
  summarise(
    distinct_uai_track = n_distinct(paste(UAI, track)),   # unique school-track units
    all_2023           = all(annee == "2023"),            # only 2023?
    no_excluded        = all(!exclude_regression),        # no COVID year?
    dv1_class          = class(DV1_va),                   # numeric?
    ips_class          = class(IPS_mean)
  )
