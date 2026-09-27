# Script to merge and clean the occurrence dataset ####

# Authors: João Dornelas & Domingos Cardoso
# Modified: Wed Aug  6 22:25:23 2025
# date()

#_______________________________________________________________________________
# Load packages ####

# LCVP: https://github.com/idiv-biodiversity/LCVP
#install.packages("devtools")
#devtools::install_github("idiv-biodiversity/LCVP")
library(LCVP)

# lcvplants: https://github.com/idiv-biodiversity/lcvplants
#install.packages("devtools")
#devtools::install_github("idiv-biodiversity/lcvplants")
library(lcvplants)

# barRoso: https://github.com/DBOSlab/barRoso
#install.packages("devtools")
#devtools::install_github("DBOSlab/barRoso")
library(barRoso)

library(dplyr)
library(openxlsx)

#_______________________________________________________________________________
# Load functions ####

source("functions/auxiliary_functions.R")

#_______________________________________________________________________________
# Load the occurence data (optional) ####

all_data <- read.csv(file.path("output_data/"), stringsAsFactors = FALSE)

all_data <- read.xlsx("output_data/all_data_20260112_104323.xlsx")

#_______________________________________________________________________________
# Create folder to save data ####

if (!dir.exists("output_data/")) {
  dir.create("output_data/")
}

clean_data_path <- file.path("output_data/", paste0("clean_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx"))

#_______________________________________________________________________________
# Merge the occurrence dataset ####

# merged_data <- barroso_cat(list_sources = list(GBIF = data_gbif,
#                                                JABOT = data_jabot,
#                                                REFLORA = data_reflora,
#                                                speciesLink = data_speciesLink) ,
#                            keep_source = "GBIF")

#_______________________________________________________________________________
# Standardizing country names to English (optional) ####

#_______________________________________________________________________________
# Function to convert Portuguese country names to English ####
.convert_country_EN <- function(vec) {
  en <- countrycode::countryname(sourcevar = vec,
                                 destination = "country.name.en")
  en[is.na(en)] <- vec[is.na(en)]  # Keep original for unmatched
  return(en)
}

all_data$country <- .convert_country_EN(all_data$country)

#_______________________________________________________________________________
# Save wanted columns and add missing ones (optional) ####

#_______________________________________________________________________________
# Function to insert a word after another word in a string ####

.insert_after_word <- function(vec, insert_map) {
  for (i in seq_along(insert_map)) {
    after <- names(insert_map)[i]
    insert <- insert_map[[i]]
    if (!insert %in% vec && after %in% vec) {
      vec <- append(vec, insert, after = match(after, vec))
    }
  }
  vec
}

cols <- c(names(data_reflora))

cols <- .insert_after_word(cols, c(
  basisOfRecord = "gbifID",
  stateProvince = "county",
  scientificName = "acceptedScientificName",
  maximumElevationInMeters = "elevation",
  identificationRemarks = "vernacularName",
  identificationRemarks = "eventRemarks",
  fieldNotes = "habitat"
))

all_data <- all_data %>% 
  select(any_of(cols)) %>%
  filter(basisOfRecord %in% c("PRESERVED_SPECIMEN", "Preservedspecimen")) %>%
  select(-basisOfRecord)

#_______________________________________________________________________________
# Clean the occurrence dataset ####

clean_data <- barRoso::barroso_std(all_data,
                                   unvouchered = TRUE,
                                   delunkcoll = TRUE,
                                   flag_missid = TRUE,
                                   flag_duplicates = TRUE,
                                   rm_duplicates = TRUE,
                                   rm_original_column = TRUE)

#_______________________________________________________________________________
# Export to Excel (optional) ####

openxlsx::write.xlsx(clean_data, file = clean_data_path)

#_______________________________________________________________________________
# Reload the dataset after manual corrections (optional) ####
# You may need to rerun the barroso_std() function after this step

clean_data <- read.xlsx("output_data/clean_data_20260112_160824.xlsx")