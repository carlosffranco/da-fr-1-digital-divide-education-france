# ════════════════════════════════════════════════════════════
# DA-FR-1 — Phase 1, Step 2: Build & Validate Join Inputs
# Objective: produce 4 uniquely-keyed input frames + coverage diagnostics
# NO joins executed here — inputs only. Joins are Step 3.
# ════════════════════════════════════════════════════════════

library(tidyverse)
library(readxl)

# ════════════════════════════════════════════════════════════
# T1 — CLEAN CROSSWALK (Annuaire)
# ════════════════════════════════════════════════════════════

# T1.1 — defensive filter to lycées + start building the crosswalk
crosswalk <- annuaire |>
  filter(Type_etablissement == "Lycée") |>            # defensive: 100% already, but future-proof
  # T1.2 — clean code_commune: strip ".0" artifact, then zero-pad to 5 chars
  mutate(code_commune = str_pad(str_remove(Code_commune, "\\.0$"), 5, pad = "0"))

# Validate: every code must be 5 digits OR Corsica (2A/2B + 3 digits)
crosswalk |>
  filter(!str_detect(code_commune, "^(\\d{5}|2[AB]\\d{3})$")) |>
  select(Identifiant_de_l_etablissement, Code_commune, code_commune)   # show any malformed (expect 0 rows)

# Quick before/after sanity check on the cleaning:
crosswalk |> select(Code_commune, code_commune) |> head(3)

# T1.3 — isolate GENUINE conflicts (same UAI → different communes)
genuine_conflicts <- crosswalk |>
  distinct(Identifiant_de_l_etablissement, code_commune) |>   # benign dups collapse here
  count(Identifiant_de_l_etablissement) |>
  filter(n > 1)                                               # only UAIs with >1 distinct commune

genuine_conflicts        # how many genuine conflicts? (you found ~1 in Obj. 3)

# T1.4a — pull the full conflicting rows to inspect them
conflict_uais <- genuine_conflicts |>
  pull(Identifiant_de_l_etablissement)          # the 19 conflicting UAIs

crosswalk |>
  filter(Identifiant_de_l_etablissement %in% conflict_uais) |>
  distinct(Identifiant_de_l_etablissement, code_commune, Nom_etablissement, Nom_commune) |>
  arrange(Identifiant_de_l_etablissement)        # see each UAI's competing communes

# Print ALL conflicting rows
crosswalk |>
  filter(Identifiant_de_l_etablissement %in% conflict_uais) |>
  distinct(Identifiant_de_l_etablissement, code_commune, Nom_etablissement, Nom_commune) |>
  arrange(Identifiant_de_l_etablissement) |>
  print(n = 39)        # force-print all 39 rows

# T1.4b — conflict resolution table (19 manual decisions, see intake report)
# Each row: the UAI + the chosen commune + status + rationale.
# 'resolved' = firm textual basis; 'pending' = provisional, needs external verification.
conflict_log <- tribble(
  ~UAI,        ~code_commune, ~status,    ~rationale,
  "0440980B",  "44079",       "resolved", "Ancenis is 'site d'' secondary; Le Landreau is main seat",
  "0570279U",  "57177",       "resolved", "Freyming is 'Annexe'; Dieuze is main seat",
  "0690543R",  "69149",       "resolved", "Mornant is 'Annexe'; Oullins is main seat",
  "0690521S",  "69385",       "resolved", "La Verpilliere is 'site de'; Lyon 5e is main seat",
  "0570225K",  "57097",       "resolved", "Kept the 'Lycee professionnel' record (Boulay), not the 'Centre d'accueil'",
  "0573734Z",  "57463",       "resolved", "3 sites; Metz is main seat of the Institut",
  "0690539L",  "69387",       "resolved", "Lyon 7e is main urban seat of Assomption Bellevue",
  "0770920G",  "77079",       "resolved", "'Lycee polyvalent La Fayette' fuller name = main seat",
  "0382371W",  "38138",       "pending",  "No annexe marker; Cremieu chosen provisionally",
  "0740283F",  "74213",       "pending",  "Two neighbouring rural communes; Poisy provisional",
  "0750770E",  "75103",       "pending",  "Paris arrondissement conflict; needs official annuaire check",
  "0752845K",  "75112",       "pending",  "Paris arrondissement conflict; needs official annuaire check",
  "0754025T",  "75106",       "pending",  "Paris arrondissement conflict; needs official annuaire check",
  "0754874R",  "75105",       "pending",  "Paris arrondissement conflict; needs official annuaire check",
  "0754875S",  "75105",       "pending",  "Paris arrondissement conflict; needs official annuaire check",
  "0350778F",  "35238",       "pending",  "Different school names (Assomption vs Mennais); needs verification",
  "0783288A",  "78586",       "pending",  "Different school names (Jean-Paul II vs Notre-Dame); needs verification",
  "0820725T",  "82037",       "pending",  "Different school names across depts (82 vs 46); needs verification",
  "9840160B",  "98738",       "pending",  "French Polynesia; different communes; likely no territorial coverage anyway"
)

conflict_log            # review the full table
nrow(conflict_log)      # should be 19

# T1.5 — apply the conflict_log to produce a 1-row-per-UAI crosswalk

# Step 1: NON-conflicting UAIs → collapse benign dups (distinct on UAI + commune)
crosswalk_clean_part <- crosswalk |>
  filter(!Identifiant_de_l_etablissement %in% conflict_uais) |>   # exclude the 19 conflicts
  distinct(Identifiant_de_l_etablissement, code_commune, Statut_public_prive)

# Step 2: CONFLICTING UAIs → keep only the row matching the decided commune
crosswalk_conflict_part <- crosswalk |>
  filter(Identifiant_de_l_etablissement %in% conflict_uais) |>
  semi_join(conflict_log, by = c("Identifiant_de_l_etablissement" = "UAI",
                                 "code_commune" = "code_commune")) |>   # keep only decided commune
  distinct(Identifiant_de_l_etablissement, code_commune, Statut_public_prive)

# Step 3: recombine into the final crosswalk
crosswalk_final <- bind_rows(crosswalk_clean_part, crosswalk_conflict_part) |>
  rename(UAI = Identifiant_de_l_etablissement,
         sector = Statut_public_prive)

# ── Prove uniqueness: 1 row per UAI ────────────────────────
nrow(crosswalk_final)
n_distinct(crosswalk_final$UAI)
crosswalk_final |> count(UAI) |> filter(n > 1)    # MUST return 0 rows