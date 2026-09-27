# ==============================================================================
# ANALISYS SCRIPTS
# ==============================================================================
# Author: João Dornelas, Valner Jordão, Andressa Novaes & Domingos Cardoso
# Modified: Wed Oct  2 11:22:11 2024
#date()

# ==============================================================================
# SETUP
# ==============================================================================

# ---- Packages (shared across all scripts) ------------------------------------
library(cowplot)
library(ggplot2)
library(viridis)

library(adegenet)
library(openxlsx)
library(dplyr)
library(purrr)
library(ggside)
library(factoextra)
library(vegan)
library(cluster)
library(MASS)
library(mclust)
library(dendextend)
library(sf)
library(ggspatial)
library(rnaturalearth)
library(rnaturalearthdata)
library(geodata)
library(terra)
library(reshape2)
library(tidyr)
library(dunn.test)
library(candisc)
library(caret)
library(ecospat)
library(ggnewscale)
library(patchwork)
library(flexsdm) #devtools::install_github("sjevelazco/flexsdm")

library(moRphoTaxa)

#_______________________________________________________________________________
# Load raw data ####

if (!dir.exists("output_data/")) {
  dir.create("output_data/")
}

#_______________________________________________________________________________
# Create the analysis matrix ####

# ---- Build morphometric matrix + block structure ----------------------------

res <- morph_matrix_setting(xlsx_path = "output_data/all_data.xlsx",
                            taxon_col = "taxon",
                            species_selected = NULL,
                            trait_name_type = "code",
                            veg_first = "petiole_length/PETIlng",
                            flo_first = "inflorescence_length/INFLlng",
                            fru_first = "fruit_stipe_length/FRSTlng")

# ==============================================================================
# DATA QUALITY & EXPLORATION
# ==============================================================================

#_______________________________________________________________________________
# Normality test ####

morph_normality(analysis_data = res$analysis_data,
                base_cols = res$base_cols,
                norm_alpha = 0.05,
                norm_qq = 10, 
                verbose = TRUE) 

#_______________________________________________________________________________
# Boxplots ####

morph_boxplots(analysis_data = res$analysis_data,
               species_all = res$species_all,
               species_selected = NULL,
               plot_type = "violin",
               show_jitter = TRUE,
               min_n_total = 10,
               verbose = TRUE)
  
  




#_______________________________________________________________________________
# Pairwise similarity ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
sim_blocks   <- "all" # "veg", "flo", "fru", "all"

# Choose method : 
sim_method   <- "pearson" # "pearson" | "spearman" | "kendall"

# p-value adjustment method
sim_p_adjust <- "BH" # "bonferroni", "holm", "BH", "none"

# Significance threshold
sim_alpha    <- 0.05

# Minimum specimens to run
sim_min_n    <- 5

# List of specific pairs to plot
sim_pairs    <- NULL # If NULL, only the heatmap is produced.
#                Example: sim_pairs <- list(c("petiole_length/PETIlng",
#                                             "rachis_length/RACHlng"))

source("full_pipeline/analysis/pairwise_similarity.R")

# ==============================================================================
# ORDINATION
# ==============================================================================

#_______________________________________________________________________________
# PCA ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
pca_blocks   <- "all" # "veg", "flo", "fru", "all"

# Build combined datasets automatically
make_combined_sets <- TRUE

source("full_pipeline/analysis/PCA.R")

#_______________________________________________________________________________
# NMDS ####

# ---- Presets -----------------------------------------------------------------

# Trait blocks to test
nmds_blocks  <- "all" # "veg", "flo", "fru", "all"

# Distance method
nmds_dist    <- "gower" # vegan::vegdist:"bray", "jaccard", "euclidean", "manhattan", "gower"

# Number of NMDS dimensions
nmds_k       <- 2

# Max iteration
nmds_trymax  <- 100

source("full_pipeline/analysis/NMDS.R")

# ==============================================================================
# CLUSTERING
# ==============================================================================

#_______________________________________________________________________________
# Dendrogram ####

# ---- Presets -----------------------------------------------------------------
# Build combined datasets automatically
make_combined_sets <- TRUE

# Distance method
dist_method <- "bray" # vegan::vegdist:"bray", "jaccard", "euclidean", "manhattan", "gower"

source("full_pipeline/analysis/dendrogram.R")

#_______________________________________________________________________________
# K-means clustering ####

# ---- Presets -----------------------------------------------------------------

# Number of clusters
kmeans_k <- NULL # If NULL, optimal k is chosen automatically via gap statistic.

# Max number of clusters
kmeans_k_max <- 10

# Bootstrap replicates
kmeans_B <- 50

# Number of starts
kmeans_nstart <- 25

# PCs to cluster on
kmeans_pcs <- c("PC1", "PC2")

# Trait blocks to test
kmeans_blocks <- "all" # veg, flo, fru, all

source("full_pipeline/analysis/K_means.R")

#_______________________________________________________________________________
# NMMs ####

# ---- Packages ----------------------------------------------------------------

# Trait blocks to test
nmm_blocks <- "all" # "veg", "flo", "fru", "all"

# Top PC1-contributing traits
nmm_top_traits <- 10

# Minimum specimens to run
nmm_min_n      <- 10

source("full_pipeline/analysis/NMMs.R")

# ==============================================================================
# CONFIRMATORY
# ==============================================================================

#_______________________________________________________________________________
# ANOVA ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
anova_blocks   <- "all" # "veg", "flo", "fru", "all"

# p-value adjustment method
anova_p_adjust <- "BH" # "bonferroni", "holm", "BH", "none"

# Significance threshold
anova_alpha    <- 0.05

source("full_pipeline/analysis/ANOVA.R")

#_______________________________________________________________________________
# Kruskal-Wallis (non-parametric) ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
kw_blocks   <- "all" # "veg", "flo", "fru", "all"

# p-value adjustment method
kw_p_adjust <- "BH" # "bonferroni", "holm", "BH", "none"

# Significance threshold
kw_alpha    <- 0.05

source("full_pipeline/analysis/kruskal_wallis.R")

#_______________________________________________________________________________
# LDA ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
lda_blocks   <- "all" # "veg", "flo", "fru", "all"

# Discriminant axes to plot
lda_lds     <- c("LD1", "LD2")

# Confidence level for ellipses
lda_ellipse <- 0.95

# Minimum specimens to run
lda_min_n   <- 3

source("full_pipeline/analysis/LDA.R")

#_______________________________________________________________________________
# CVA ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
cva_blocks   <- "all" # "veg", "flo", "fru", "all"

# Confidence level for ellipses
cva_ellipse <- 0.95

# Minimum specimens to run
cva_min_n   <- 3

source("full_pipeline/analysis/CVA.R")

#_______________________________________________________________________________
# DAPC ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
dapc_blocks  <- "all" # "veg", "flo", "fru", "all"

# Number of PCs to retain
dapc_n_pca   <- NULL     # NULL = auto (80% variance)

# Number of discriminant functions
dapc_n_da <- NULL

# Minimum specimens to run
dapc_min_n   <- 3

source("full_pipeline/analysis/DAPC.R")

# ==============================================================================
# SPATIAL & ENVIRONMENTAL
# ==============================================================================
# ---- Transform the raw data into geographical matrix -------------------------
# WorldClim resolution in minutes of arc (0.5, 2.5, 5, or 10)
wc_res <- 2.5

source("full_pipeline/analysis/geo_matrix_setting.R")

#_______________________________________________________________________________
# Bioclimatic analysis ####

# ---- Presets -----------------------------------------------------------------
# Path to the Brazil states shapefile — set to NULL to skip sub-national borders
show_country_states <- "brazil"  # set to NULL to skip sub-national borders

# BIO variable shown as the raster background on the map (integer 1–19)
# BIO0 = Elevation (m)
# BIO1  = Annual Mean Temperature       BIO11 = Mean Temp Coldest Quarter
# BIO2  = Mean Diurnal Range            BIO12 = Annual Precipitation
# BIO3  = Isothermality                 BIO13 = Precipitation Wettest Month
# BIO4  = Temperature Seasonality       BIO14 = Precipitation Driest Month
# BIO5  = Max Temp Warmest Month        BIO15 = Precipitation Seasonality
# BIO6  = Min Temp Coldest Month        BIO16 = Precipitation Wettest Quarter
# BIO7  = Temperature Annual Range      BIO17 = Precipitation Driest Quarter
# BIO8  = Mean Temp Wettest Quarter     BIO18 = Precipitation Warmest Quarter
# BIO9  = Mean Temp Driest Quarter      BIO19 = Precipitation Coldest Quarter
# BIO10 = Mean Temp Warmest Quarter
bio_map_layer <- 12

# BIO variables for the scatter plot axes (integer 1–19)
bio_x <- 15
bio_y <- 12

# Add river lines on the map 
show_rivers <- TRUE

# Natural Earth river resolution 
river_scale <- 10   # 10 = fine detail, 50/110 = coarser/faster

source("full_pipeline/analysis/bioclim_PCA.R")
source("full_pipeline/analysis/bioclim_maps.R")

#_______________________________________________________________________________
# Mantel ####

# ---- Presets -----------------------------------------------------------------
# Choose method
mantel_method <- "pearson"   # "pearson" | "spearman" | "kendall"

# Number of permutations
mantel_permutations <- 999

# Distance method
mantel_dist_method <- "gower"  # vegan::vegdist:"bray", "jaccard", "euclidean", "manhattan", "gower"
# Gower handles NAs pairwise — no specimens dropped, no imputation needed

source("full_pipeline/analysis/Mantel.R")

#_______________________________________________________________________________
# Spatial autocorrelation of traits ####

# ---- Presets -----------------------------------------------------------------
# Pearson pairs to correlate 
autocor_blocks <- "all" # "veg", "flo", "fru", "all"

# Choose method : 
autocor_method <- "pearson" # "pearson" | "spearman" | "kendall"

# Data ordination parameter
autocor_order_by <- "latitude" #   "latitude"  → order specimens by decimalLatitude (default)
#   "longitude" → order specimens by decimalLongitude
#   "none" → keep original row order (collection number)

source("full_pipeline/analysis/autocorrelation.R")

#_______________________________________________________________________________
# RDA ####

# ---- Presets -----------------------------------------------------------------
# Trait blocks to test
rda_blocks <- "all" # "veg", "flo", "fru", "all"

# Bioclimatic variables to use
rda_env_vars <- NULL  # NULL = auto-select all bio* columns

# Numbers of permutations
rda_permutations <- 999

# Scale morpho and env data
rda_scale <- TRUE

source("full_pipeline/analysis/RDA.R")

# ==============================================================================
# NICHE ANALYSIS
# ==============================================================================
# Path to the Brazil states shapefile — set to NULL to skip sub-national borders
show_country_states <- "brazil"  # set to NULL to skip sub-national borders

# ---- Add edaphic variables to geodata matrix -------------------------
# WorldClim resolution in minutes of arc (0.5, 2.5, 5, or 10)
wc_res <- 2.5

# Soil variables
edaphic_vars  <- c("clay", "sand", "silt", "soc", "phh2o", "cec",
                   "nitrogen", "bdod", "cfvo", "ocd", "ocs")

# Depth of soil in centimeters (5, 15, 30, 60, 100 or 200)
edaphic_depth <- 5 

source("full_pipeline/analysis/geo_matrix_setting.R") # Run the geodata if isnt already setted
source("full_pipeline/analysis/edaphic_matrix_setting.R")

#_______________________________________________________________________________
# ENM ####

# ---- Presets -----------------------------------------------------------------
# Buffer for calibration area
enm_buffer_km  <- 100

# Pseudo-absences per presence
enm_pa_ratio <- 2

# Number of cross-validation fold
enm_folds <- 5

# Minimum records to model a taxon
enm_min_occ  <- 3

# Permutations for variable importance
enm_importance_perm <- 10

source("full_pipeline/analysis/ENM.R")

#_______________________________________________________________________________
# Niche Overlap ####

# ---- Presets -----------------------------------------------------------------
# Cumulative variance to retain
niche_var_threshold <- 0.95

# Drop variables with |r| >
niche_cor_cutoff <- 0.8

# Resolution of the environmental density grid
niche_grid_size <- 100

# Permutations for equivalency/similarity tests
niche_iterations <- 1000

# Significance threshold
niche_alpha <- 0.05

# Minimum occurrences per taxon
niche_min_occ <- 3

# Cores for ecospat parallelization
niche_n_cores <- 1

source("full_pipeline/analysis/nicheoverlap.R")