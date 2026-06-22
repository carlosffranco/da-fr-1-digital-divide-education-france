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