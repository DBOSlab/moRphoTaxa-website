# Script to create and associates a data frame of morphological traits

# Authors: João Dornelas & Domingos Cardoso
# Modified: Mon Jul 28 18:05:48 2025
# date()


#_______________________________________________________________________________
# Load packages ####

library(openxlsx)
library(moRphoTaxa)


#_______________________________________________________________________________
# Load functions ####


#_______________________________________________________________________________
# Load the occurence data (optional) ####

csv_data <- read.csv(file.path("output_data/"), stringsAsFactors = FALSE)

xlsx_data <- read.xlsx("output_data/")

#_______________________________________________________________________________
# Generate a help data frame containing all base data (optional) ####
 
data(traits_database)

#_______________________________________________________________________________
# Add morphological traits ####

df_morph_traits <- morph_add_traits(base_df = NULL,
                                    trait_name = "both",
                                    quali_default = TRUE,
                                    quanti_default = TRUE,
                                    quali_specific = "leguminosae_pap",
                                    quanti_specific = "leguminosae_pap",
                                    save = TRUE)
