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
