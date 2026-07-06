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
