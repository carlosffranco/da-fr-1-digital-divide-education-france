# ------------------------------------------------------------
# DA-FR-1 — Phase 4: Dashboard data preparation (Model C)
# Exports three CSVs for Tableau. All aggregation happens here,
# not in Tableau, so the dashboard inputs stay reproducible.
#
# Required packages (install once, not part of the analysis):
#   install.packages(c("tidyverse"))
# ------------------------------------------------------------

library(tidyverse)

# Certified artefacts from earlier phases
df_reg  <- read_rds("data/processed/df_reg.rds")    # 2023 cross-section
df_full <- read_rds("data/processed/df_full.rds")   # 2019-2024 panel

nrow(df_reg)    # 4,340
nrow(df_full)   # 60,743

# Raw département-level Bac results (semicolon-delimited, French format)
bac_dept <- read_csv2("data/raw/bac_par_departement_2023_2025.csv",
                      show_col_types = FALSE)

nrow(bac_dept)  # 1,818

dir.create("output/dashboard_data", showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------
# T1a — Département-level pass rates (Model C)
# The source file has no total row: every row is one département
# x one Voie x one Genre x one Session. The overall rate must be
# computed as sum(admis) / sum(presents) * 100. Averaging the
# rate column would weight a track with 50 candidates equally
# with one of 3,000.
#
# Département codes in this file are Education Nationale internal
# codes, not INSEE: zero-padded to three characters, with Corsica
# as 620 / 720 rather than 2A / 2B. Converted below so Tableau can
# match them geographically.
#
# Voie is mapped to the study's track definition: GT (Générale +
# Technologique) vs Pro, so dashboard filters can be shared
# across all views.
# ------------------------------------------------------------

bac_clean <- bac_dept |>
  rename(
    session   = Session,
    dept_raw  = `Code département`,
    dept_name = `Libellé département`,
    voie      = Voie,
    genre     = Genre,
    presents  = `Nombre de présents à l'examen`,
    admis     = `Nombre d'admis à l'examen`
  ) |>
  mutate(
    dept_code = case_when(
      dept_raw == "620"            ~ "2A",
      dept_raw == "720"            ~ "2B",
      str_starts(dept_raw, "97")   ~ dept_raw,
      .default = str_sub(dept_raw, 2, 3)
    ),
    track = if_else(voie == "Professionnelle", "Pro", "GT")
  ) |>
  select(session, dept_code, dept_name, track, voie, genre, presents, admis)

# Check the conversion
bac_clean |> distinct(dept_code) |> nrow()          # expect 101
bac_clean |> filter(dept_code %in% c("2A", "2B", "01", "95", "971")) |>
  distinct(dept_code, dept_name)


# --- All tracks combined, per département and session ---
dept_bac_all <- bac_clean |>
  group_by(session, dept_code, dept_name) |>
  summarise(
    presents = sum(presents),
    admis    = sum(admis),
    .groups  = "drop"
  ) |>
  mutate(taux_reussite = admis / presents * 100,
         track         = "All tracks")


# --- By track (GT / Pro), per département and session ---
dept_bac_track <- bac_clean |>
  group_by(session, dept_code, dept_name, track) |>
  summarise(
    presents = sum(presents),
    admis    = sum(admis),
    .groups  = "drop"
  ) |>
  mutate(taux_reussite = admis / presents * 100)


# --- Stack both, so Tableau can filter "All tracks", GT or Pro ---
dept_bac <- bind_rows(dept_bac_all, dept_bac_track) |>
  arrange(session, dept_code, track)

nrow(dept_bac)   # expect 909 = 101 départements x 3 sessions x 3 tracks


# --- Sanity check: national rate should land around 90-93% ---
bac_clean |>
  group_by(session) |>
  summarise(
    presents      = sum(presents),
    admis         = sum(admis),
    taux_national = admis / presents * 100,
    .groups       = "drop"
  )

# ------------------------------------------------------------
# T1b — School-level scatter data and national trend
# ------------------------------------------------------------

# --- school_scatter.csv: 2023 cross-section, school level ---
school_scatter <- df_reg |>
  select(UAI, track, secteur, IPS_mean, DV2_taux, DV1_va,
         urban_rural3, commune_final) |>
  filter(!is.na(IPS_mean), !is.na(DV2_taux))

nrow(school_scatter)   # 4,324


# --- trend.csv: national pass rate by year and track ---
# 2020 and 2021 are kept in the data and flagged, so the dashboard
# can annotate them as atypical sessions rather than hide them.
trend <- df_full |>
  filter(annee %in% as.character(2019:2024), !is.na(DV2_taux)) |>
  group_by(annee, track) |>
  summarise(
    mean_taux = mean(DV2_taux),
    n_schools = n(),
    .groups   = "drop"
  ) |>
  mutate(
    annee_num = as.integer(annee),
    session_flag = case_when(
      annee == "2020" ~ "COVID automatic passes",
      annee == "2021" ~ "Relaxed assessment",
      .default = "Standard"
    )
  ) |>
  arrange(track, annee_num)

trend


# --- Export all three ---
write_csv(dept_bac,       "output/dashboard_data/dept_bac.csv")
write_csv(school_scatter, "output/dashboard_data/school_scatter.csv")
write_csv(trend,          "output/dashboard_data/trend.csv")

list.files("output/dashboard_data")