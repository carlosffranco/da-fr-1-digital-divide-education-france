library(tidyverse)
library(readxl)
# ── ARCEP MCI — reconnaissance ──────────────────────────────
arcep <- read_delim(
  "data/raw/arcep_mci_commune_2024T4.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read all columns as character
  locale     = locale(encoding = "UTF-8")
)

dim(arcep)       # rows x columns
glimpse(arcep)   # structure: each column, its type and first values
names(arcep)     # EXACT column names (verbatim)

# ── IVAL GT — reconnaissance (anchor dataset) ──────────────
ival_gt <- read_delim(
  "data/raw/ival_gt_lycees_2023.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(ival_gt)        # rows x columns
names(ival_gt)      # EXACT column names (verbatim) — locate the year column

# ── Flag #3 check: how many years does IVAL GT cover? ──────
ival_gt |> count(`Année`)   # distinct years + rows per year

# ── IVAL Pro — reconnaissance ──────────────────────────────
ival_pro <- read_delim(
  "data/raw/ival_pro_lycees_2023.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(ival_pro)              # rows x columns
ival_pro |> count(`Année`) # distinct years + rows per year

# ── IPS Lycées 2023 — reconnaissance ───────────────────────
ips_2023 <- read_delim(
  "data/raw/ips_Lycees_2023.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(ips_2023)                       # rows x columns
names(ips_2023)                     # EXACT column names (verbatim)
ips_2023 |> count(`Rentrée scolaire`)   # how many cohorts are stacked?

# ── IPS Lycées 2022 — reconnaissance ───────────────────────
ips_2022 <- read_delim(
  "data/raw/ips_Lycees_2022.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(ips_2022)                       # rows x columns
names(ips_2022)                     # EXACT column names (verbatim)
ips_2022 |> count(`Rentrée scolaire`)   # how many cohorts?

# ── Filosofi 2021 COM — reconnaissance ─────────────────────
filosofi <- read_delim(
  "data/raw/cc_filosofi_2021_COM.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(filosofi)        # rows x columns
names(filosofi)      # EXACT column names — look for CODGEO, MED21, TP6021

# ── Bac par département — reconnaissance (Model C only) ─────
bac_dept <- read_delim(
  "data/raw/bac_par_departement_2023_2025.csv",
  delim      = ";",
  col_types  = cols(.default = "c"),          # read everything as character
  locale     = locale(encoding = "UTF-8")
)

dim(bac_dept)        # rows x columns
names(bac_dept)      # EXACT column names (verbatim)

# ── Flag #6 check: what dimensions split the rows? ─────────
bac_dept |> count(Voie)     # what 'voie' values exist? (GT / Pro / ensemble?)
bac_dept |> count(Genre)    # what 'genre' values exist? (M / F / ensemble?)
bac_dept |> count(Session)  # which years/sessions are covered?

# ── Annuaire éducation (xlsx) — reconnaissance ─────────────
library(readxl)   # already loaded, but explicit here for clarity

# Step 1: list the sheets BEFORE reading
excel_sheets("data/raw/rep_annuaire_edu_V2.xlsx")

# Step 2: read the sheet (everything as text), then inspect
annuaire <- read_xlsx(
  "data/raw/rep_annuaire_edu_V2.xlsx",
  sheet     = "Sheet1",
  col_types = "text"          # read everything as character (readxl syntax)
)

dim(annuaire)        # rows x columns
names(annuaire)      # EXACT column names (verbatim)

# ── AAV2020 urban/rural (xlsx) — reconnaissance ────────────
# Step 1: list the sheets BEFORE reading
excel_sheets("data/raw/aav2020_urban_rural.xlsx")

# Step 2 (corrected): real header is on row 6 → skip the first 5 rows
aav <- read_xlsx(
  "data/raw/aav2020_urban_rural.xlsx",
  sheet     = "Composition_communale",
  skip      = 5,               # skip 5 title/metadata rows; row 6 becomes header
  col_types = "text"           # preserve CODGEO leading zeros
)

dim(aav)        # rows x columns
names(aav)      # EXACT column names — should now show CODGEO, CATEAAV2020, etc.

# ── Inspect the urban/rural category values ────────────────
aav |> count(CATEAAV2020)   # category codes + distribution (expect 11/12/13/20/30)

ls()   # list objects currently in the Environment

# ════════════════════════════════════════════════════════════
# OBJECTIVE 3 — KEY INTEGRITY CHECKS
# ════════════════════════════════════════════════════════════

# ── Flag #7: ARCEP — is there exactly ONE row per code_insee? ──
n_distinct(arcep$code_insee)          # how many unique communes?
nrow(arcep)                           # total rows — compare to the line above

arcep |> count(code_insee) |> filter(n > 1)   # duplicate keys (expect 0 rows)

arcep |> count(type)                  # what does the 'type' column actually contain?

# ── Filosofi — one row per CODGEO? ─────────────────────────
n_distinct(filosofi$CODGEO)
nrow(filosofi)
filosofi |> count(CODGEO) |> filter(n > 1)        # duplicates (expect 0)
sum(is.na(filosofi$CODGEO))                       # any missing keys? (expect 0)

# ── AAV — one row per CODGEO? + check for footnote rows ────
n_distinct(aav$CODGEO)
nrow(aav)
aav |> count(CODGEO) |> filter(n > 1)             # duplicates (expect 0)
sum(is.na(aav$CODGEO))                            # missing keys / footnote rows?

# ── Annuaire — UAI integrity (crosswalk must be 1 row per UAI) ──

# Layer 1: full file (all establishment types)
n_distinct(annuaire$Identifiant_de_l_etablissement)
nrow(annuaire)
annuaire |> count(Identifiant_de_l_etablissement) |> filter(n > 1)   # dups in full file

# What establishment types are in here? (explains the 4,907 rows)
annuaire |> count(Type_etablissement)

# Layer 2: what does multi_uai contain?
annuaire |> count(multi_uai)

# ── Do the duplicate UAIs disagree on code_commune? ────────
dup_uai <- annuaire |>
  count(Identifiant_de_l_etablissement) |>
  filter(n > 1) |>
  pull(Identifiant_de_l_etablissement)        # extract the 33 duplicate UAIs

annuaire |>
  filter(Identifiant_de_l_etablissement %in% dup_uai) |>
  select(Identifiant_de_l_etablissement, Code_commune, Nom_etablissement) |>
  arrange(Identifiant_de_l_etablissement)      # view the pairs side by side

# ── IVAL GT — duplicate UAI WITHIN the same year? (panel key = UAI + Année) ──
ival_gt |> count(UAI, `Année`) |> filter(n > 1)     # expect 0 rows

# ── IVAL Pro — same check ──────────────────────────────────
ival_pro |> count(UAI, `Année`) |> filter(n > 1)    # expect 0 rows

# ── GT vs Pro: do any UAIs appear in BOTH files? (should be separate institutions) ──
ival_gt |> distinct(UAI) |> inner_join(ival_pro |> distinct(UAI), by = "UAI") |> nrow()

# ── Confirm the overlap = lycées polyvalents (same UAI in both tracks) ──
shared_uai <- ival_gt |> distinct(UAI) |>
  inner_join(ival_pro |> distinct(UAI), by = "UAI") |>
  pull(UAI)

# Look at one shared UAI in each file (same school, both tracks)
ival_gt  |> filter(UAI %in% shared_uai) |> distinct(UAI, Etablissement, Secteur) |> head(5)
ival_pro |> filter(UAI %in% shared_uai) |> distinct(UAI, Etablissement, Secteur) |> head(5)

# ── IPS 2023 — duplicate UAI WITHIN a cohort? (key = UAI + Rentrée scolaire) ──
ips_2023 |> count(UAI, `Rentrée scolaire`) |> filter(n > 1)   # expect 0 rows

# ── IPS 2023 — distinct UAI per cohort vs rows per cohort ──
ips_2023 |>
  group_by(`Rentrée scolaire`) |>
  summarise(rows = n(), distinct_uai = n_distinct(UAI))

# ── IPS 2022 — same checks (single cohort) ─────────────────
ips_2022 |> count(UAI, `Rentrée scolaire`) |> filter(n > 1)   # expect 0 rows
n_distinct(ips_2022$UAI)
nrow(ips_2022)