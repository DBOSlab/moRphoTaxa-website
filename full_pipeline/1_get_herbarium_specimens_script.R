# Script to get herbarium collections from REFLORA, JABOT, speciesLink and GBIF ####

# Authors: João Dornelas & Domingos Cardoso
# Modified: Wed Aug  6 22:25:23 2025
# date()

#_______________________________________________________________________________
# Load packages ####

#install.packages("devtools")

# refloraR: https://dboslab.github.io/refloraR-website/
#devtools::install_github("DBOSlab/refloraR")
library(refloraR)

# jabotR: https://dboslab.github.io/jabotR-website/
#devtools::install_github("DBOSlab/jabotR")
library(jabotR)

# rspeciesLink: https://github.com/LimaRAF/plantR
# rgbif2: https://github.com/LimaRAF/plantR
#devtools::install_github("LimaRAF/plantR")
library(plantR)

library(dplyr)
library(openxlsx)

#_______________________________________________________________________________
# Load functions ####

source("functions/auxiliary_functions.R")

#_______________________________________________________________________________
# Create folder to save data ####

if (!dir.exists("output_data/")) {
  dir.create("output_data/")
}

all_data_path <- file.path("output_data/", paste0("all_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx"))

#_______________________________________________________________________________
# Get herbarium specimen data ####

targeted_taxa <- c("Trischidium limae",
                   "Bocoa limae")

# Get speciesLink data ####

# API key needed, get one at specieslink.net/aut/profile/apikeys
personal_key = "DBpBRprOuNV8ZWoxRFcr"

# Making a request for multiple species
data_speciesLink <- lapply(targeted_taxa, 
                           function(x) plantR::rspeciesLink(dir = "output_data/",
                                                            filename = "spLink_records_search",
                                                            save = FALSE,
                                                            key = personal_key,
                                                            basisOfRecord = NULL,
                                                            family = NULL,
                                                            species = x,
                                                            collectionCode = NULL,
                                                            country = NULL,
                                                            stateProvince = NULL,
                                                            county = NULL,
                                                            Coordinates = NULL,
                                                            Scope = NULL,
                                                            Synonyms = "no synomyms",
                                                            Typus = FALSE,
                                                            Images = FALSE,
                                                            RedList = NULL,
                                                            MaxRecords = 5000,
                                                            file.format = "csv",
                                                            compress = FALSE))

# Adding species names to each element of the list

names(data_speciesLink) = targeted_taxa

# Binding all searchs and keeping a column w/ the named used in the search

data_speciesLink <- dplyr::bind_rows(data_speciesLink, .id = "original_search")

# Standardizing column names to match Darwin Core

#_______________________________________________________________________________
# Function to fix column names from speciesLink database ####

fix_column_names <- function(df) {
  col_map <- c(
    "collectioncode" = "collectionCode",
    "catalognumber" = "catalogNumber",
    "scientificname" = "scientificName",
    "yearcollected" = "year",         
    "monthcollected" = "month",          
    "daycollected" = "day",
    "stateprovince" = "stateProvince",
    "institutioncode" = "institutionCode",
    "identifiedby" = "identifiedBy",
    "basisofrecord" = "basisOfRecord",
    "specificepithet" = "specificEpithet",
    "recordedby" = "recordedBy",
    "recordnumber" = "recordNumber",
    "decimallatitude" = "decimalLatitude",
    "decimallongitude" = "decimalLongitude",
    "continentocean" = "continent",
    "scientificnameauthorship" = "scientificNameAuthorship",
    "typestatus" = "typeStatus",
    "occurrenceremarks" = "occurrenceRemarks",
    "fieldnumber" = "fieldNumber",
    "minimumelevationinmeters" = "minimumElevationInMeters",
    "maximumelevationinmeters" = "maximumElevationInMeters"
  )
  
  names(df) <- ifelse(
    names(df) %in% names(col_map),
    col_map[names(df)],
    names(df)
  )
  
  ensure_cols <- function(df, cols) {
    missing_cols <- setdiff(cols, names(df))
    for (col in missing_cols) df[[col]] <- NA_character_
    df
  }
  
  tf <- names(df) %in% "yearidentified"
  if (any(tf)) {
    
    df <- ensure_cols(df, c(
      "dayidentified", "monthidentified", "yearidentified",
      "scientificName", "scientificNameAuthorship",
      "recordNumber", "fieldNumber",
      "institutionCode", "taxonRank", "family", "genus",
      "specificEpithet", "taxonName", "eventDate",
      "lifeStage", "identificationRemarks"
    ))
    
    df$species <- df$scientificName
    
    df <- df %>%
      mutate(
        dayidentified   = as.integer(dayidentified),
        monthidentified = as.integer(monthidentified),
        yearidentified  = as.integer(yearidentified),
        
        dateIdentified = case_when(
          !is.na(dayidentified) & !is.na(monthidentified) & !is.na(yearidentified) ~ sprintf("%02d/%02d/%04d", dayidentified, monthidentified, yearidentified),
          is.na(dayidentified) & !is.na(monthidentified) & !is.na(yearidentified) ~ sprintf("%02d/%04d", monthidentified, yearidentified),
          is.na(dayidentified) & is.na(monthidentified) & !is.na(yearidentified) ~ as.character(yearidentified),
          TRUE ~ NA_character_),
        
        scientificName = case_when(
          !is.na(scientificName) & !is.na(scientificNameAuthorship) ~ sprintf("%s %s", scientificName, scientificNameAuthorship),
          is.na(scientificNameAuthorship) & !is.na(scientificName) ~ scientificName,
          TRUE ~ NA_character_),
        
        recordNumber = if_else(
          is.na(recordNumber) & !is.na(fieldNumber),
          as.character(fieldNumber),
          recordNumber)) %>%
      
      select(-fieldNumber, -dayidentified, -monthidentified, -yearidentified,
             -institutionCode, -taxonRank, -family, -genus, -specificEpithet,
             -species, -taxonName, -scientificNameAuthorship, -eventDate,
             -lifeStage, -identificationRemarks)
  }
  
  df <- ensure_cols(df, c("occurrenceRemarks", "fieldNotes", "eventRemarks", "county", "municipality"))
  
  df <- df %>%
    mutate(
      occurrenceRemarks = coalesce(occurrenceRemarks, "") |>
        paste(fieldNotes, eventRemarks, sep = " | ") |>
        gsub("(^ \\| | \\| $)", "", x = _),
      county = coalesce(county, municipality)
    )
  
  return(df)
}

data_speciesLink <- fix_column_names(data_speciesLink)

# Get REFLORA data ####

data_reflora <- refloraR::reflora_records(herbarium = NULL,
                                          repatriated = TRUE,
                                          taxon = targeted_taxa,
                                          state = NULL,
                                          recordYear = NULL,
                                          indets = TRUE,
                                          reorder = c("herbarium", "taxa", "collector", "area", "year"),
                                          path = NULL,
                                          updates = TRUE,
                                          verbose = TRUE,
                                          save = FALSE,
                                          dir = "output_data/",
                                          filename = "reflora_records_search")

# Delete the download files in the working directory

unlink("reflora_download/", recursive = TRUE, force = TRUE)

# Get JABOT data ####

data_jabot <- jabotR::jabot_records(herbarium = NULL,
                                    taxon = targeted_taxa,
                                    state = NULL,
                                    recordYear = NULL,
                                    indets = TRUE,
                                    reorder = c("herbarium", "taxa", "collector", "area", "year"),
                                    path = NULL,
                                    updates = TRUE,
                                    verbose = TRUE,
                                    save = FALSE,
                                    dir = "input_data/",
                                    filename = "jabot_records_search")

# Delete the download files in the working directory

unlink("jabot_download/", recursive = TRUE, force = TRUE)

# Get GBIF data ####

# Making a request for multiple species
data_gbif <- lapply(targeted_taxa, function(x) plantR::rgbif2(dir = "input_data/", 
                                                              filename = "gbif_records_search",
                                                              species = x,
                                                              n.records = 5000,
                                                              force = TRUE,
                                                              remove_na = FALSE,
                                                              save = FALSE,
                                                              file.format = "csv",
                                                              compress = FALSE))

# Adding species names to each element of the list
names(data_gbif) = targeted_taxa

# Binding all searches and keeping a column w/ the name used in the search
data_gbif <- dplyr::bind_rows(data_gbif, .id = "original_search")

# Creating columns for data source ####

data_gbif$source <- "GBIF"
data_jabot$source <- "JABOT"
data_reflora$source <- "REFLORA"
data_speciesLink$source <- "speciesLink"

#_______________________________________________________________________________
# Convert all cells to character and merge all data frames (optional) ####

data_list <- list(data_gbif, data_jabot, data_reflora, data_speciesLink)
data_list <- lapply(data_list, function(df) {
  df %>% dplyr::mutate(across(everything(), as.character))
})

all_data <- dplyr::bind_rows(data_list)

#_______________________________________________________________________________
# Export to Excel (optional) ####

openxlsx::write.xlsx(all_data, file = all_data_path)

