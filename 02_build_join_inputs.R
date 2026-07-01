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

# ------------------------------------------------------------
# T2 — STANDARDIZE COMMUNE-LEVEL KEYS (Filosofi, ARCEP, AAV)
# No derivations here — keys + column selection only. Transforms are Step 3.
# ------------------------------------------------------------

# ── T2a — Filosofi ─────────────────────────────────────────
filosofi_input <- filosofi |>
  mutate(CODGEO = str_pad(str_remove(CODGEO, "\\.0$"), 5, pad = "0")) |>  # standardize key
  select(CODGEO, MED21, TP6021, D121, RD21)          # needed cols + robustness (D121, RD21)

# Validate key format + uniqueness
filosofi_input |>
  filter(!str_detect(CODGEO, "^(\\d{5}|2[AB]\\d{3})$"))    # malformed? expect 0 rows
n_distinct(filosofi_input$CODGEO)                          # distinct keys
nrow(filosofi_input)                                       # total rows (should match)

# ── T2b — ARCEP ─────────────────────────────────────────────
arcep_input <- arcep |>
  mutate(code_insee = str_pad(str_remove(code_insee, "\\.0$"), 5, pad = "0")) |>
  select(code_insee, elig_ftth, nbr)                 # raw — derive fibre_coverage in Step 3

arcep_input |>
  filter(!str_detect(code_insee, "^(\\d{5}|2[AB]\\d{3})$"))   # malformed? expect 0 rows
n_distinct(arcep_input$code_insee)
nrow(arcep_input)

# ── T2c — AAV ───────────────────────────────────────────────
aav_input <- aav |>
  mutate(CODGEO = str_pad(str_remove(CODGEO, "\\.0$"), 5, pad = "0")) |>
  select(CODGEO, CATEAAV2020)                        # raw — recode urban/rural in Step 3

aav_input |>
  filter(!str_detect(CODGEO, "^(\\d{5}|2[AB]\\d{3})$"))       # malformed? expect 0 rows
n_distinct(aav_input$CODGEO)
nrow(aav_input)

# ------------------------------------------------------------
# T3 — ASSEMBLE IVAL ANCHOR (track-stratified, Ruling 1)
# ------------------------------------------------------------

# T3.1 — confirm C1: do GT and Pro share the same 88 column names?
length(names(ival_gt))                          # how many cols in GT
length(names(ival_pro))                         # how many cols in Pro

setdiff(names(ival_gt), names(ival_pro))        # columns ONLY in GT
setdiff(names(ival_pro), names(ival_gt))        # columns ONLY in Pro

intersect(names(ival_gt), names(ival_pro))      # columns in BOTH (common core candidates)

# T3.2 — select common core BY EXACT NAME, rename to clean names, add track

# ── GT track ────────────────────────────────────────────────
ival_gt_core <- ival_gt |>
  select(
    UAI,
    annee            = `Année`,
    etablissement    = Etablissement,
    code_commune     = `Code commune`,
    secteur          = Secteur,
    presents         = `Présents - Toutes séries`,                          # GT: with accent
    DV2_taux         = `Taux de réussite - Toutes séries`,                  # raw Bac rate
    DV1_va           = `Valeur ajoutée du taux de réussite - Toutes séries` # value-added
  ) |>
  mutate(track = "GT")

# ── Pro track ───────────────────────────────────────────────
ival_pro_core <- ival_pro |>
  select(
    UAI,
    annee            = `Année`,
    etablissement    = Etablissement,
    code_commune     = `Code commune`,
    secteur          = Secteur,
    presents         = `Présents - Toutes series`,                          # Pro: NO accent (!)
    DV2_taux         = `Taux de réussite - Toutes séries`,
    DV1_va           = `Valeur ajoutée du taux de réussite - Toutes séries`
  ) |>
  mutate(track = "Pro")

# Verify both now have identical names
names(ival_gt_core)
names(ival_pro_core)
identical(names(ival_gt_core), names(ival_pro_core))    # MUST be TRUE

# T3.3 — bind the two tracks into the IVAL anchor
ival_anchor <- bind_rows(ival_gt_core, ival_pro_core)

nrow(ival_anchor)                                    # should be 32,485 + 28,258 = 60,743

# ── Prove the panel key UAI + annee + track is unique ──────
ival_anchor |> count(UAI, annee, track) |> filter(n > 1)    # MUST return 0 rows

# ── Confirm the 983 LPO now appear as paired GT+Pro rows ───
ival_anchor |>
  filter(UAI %in% shared_uai) |>                     # the 983 shared UAIs from Obj. 3
  count(track)                                        # should show both GT and Pro rows