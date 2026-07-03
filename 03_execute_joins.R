# ------------------------------------------------------------
# DA-FR-1 — Phase 1, Step 3: Execute Joins & Derive Variables
# Reconcile dual commune sources → arrondissement mapping →
# execute join sequence with row-count assertions → derive
# variables → post-merge integrity audit → certify df_reg.
# Inputs (from Step 2, in memory): crosswalk_final, filosofi_input,
# arcep_input, aav_input, ival_anchor, ips_input.
# ------------------------------------------------------------

library(tidyverse)

