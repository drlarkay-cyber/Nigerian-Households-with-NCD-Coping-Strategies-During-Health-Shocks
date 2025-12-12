################################################################################
# UPSET PLOTS FOR COPING STRATEGY COMBINATIONS
# Paper: Decisions and Dilemmas - Health Shocks and Coping Strategies in Nigeria
# Author: Adelakun Odunyemi
# Date: December 2024
#
# This script creates UpSet plots comparing coping strategy combinations
# between NCD-affected and non-NCD-affected households
#
# Input: health_strategies.xls (exported from Stata)
# Output: Multiple UpSet plot PNG files
################################################################################

# Clear workspace
rm(list = ls())

# Load required libraries
required_packages <- c("readxl", "dplyr", "UpSetR", "tidyr")

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load libraries
library(readxl)
library(dplyr)
library(UpSetR)
library(tidyr)

################################################################################
# 1. LOAD AND PREPARE DATA
################################################################################

# Read the Excel file
cat("Loading data...\n")

# Try to read the file (handles both .xls and .xlsx)
tryCatch({
  data <- read_excel("health_strategies.xls")
  cat("Successfully loaded data from health_strategies.xls\n")
}, error = function(e) {
  # If .xls fails, try .xlsx
  tryCatch({
    data <- read_excel("health_strategies.xlsx")
    cat("Successfully loaded data from health_strategies.xlsx\n")
  }, error = function(e2) {
    stop("Could not find health_strategies.xls or health_strategies.xlsx in working directory.\n",
         "Current working directory: ", getwd(), "\n",
         "Please ensure the file is in the correct location.")
  })
})

# Display basic information about the data
cat("\n=== DATA SUMMARY ===\n")
cat("Data dimensions:", nrow(data), "rows x", ncol(data), "columns\n")
cat("\nColumn names:\n")
print(colnames(data))
cat("\nFirst few rows:\n")
print(head(data, 3))

################################################################################
# 2. VARIABLE RELABELING
################################################################################

cat("\n=== RELABELING VARIABLES ===\n")

# Define mapping from original to full names
variable_mapping <- c(
  "form_ass" = "Formal Assistance",
  "child_disp" = "Child Withdrawal",
  "sale" = "Asset Sale",
  "work_add" = "Additional Work",
  "borrow" = "Borrowing from Family/Friends",
  "saving" = "Financing from Savings",
  "loan" = "Using Loans/Credit",
  "rednonfood" = "Reduced Non-food Consumption",
  "inf_ass" = "Informal Assistance",
  "redfood" = "Reduced Food Consumption"
)

# Check which variables exist in the data
available_strategies <- names(variable_mapping)[names(variable_mapping) %in% names(data)]

if(length(available_strategies) == 0) {
  stop("No matching strategy variables found in data.\n",
       "Expected variables: ", paste(names(variable_mapping), collapse=", "), "\n",
       "Found variables: ", paste(names(data), collapse=", "))
}

cat("Found", length(available_strategies), "strategy variables:\n")
print(available_strategies)

# Create a clean working dataset with renamed variables
# First, identify NCD variable
ncd_col <- names(data)[tolower(names(data)) == "ncd"]
if(length(ncd_col) == 0) {
  stop("NCD variable not found in data. Please ensure 'ncd' column exists.")
}

# Select and rename strategy columns
coping_df <- data %>%
  select(all_of(c(ncd_col, available_strategies)))

# Rename columns to full names
old_names <- names(coping_df)
old_names <- old_names[old_names != ncd_col]  # Exclude NCD column from renaming

for(old_name in old_names) {
  if(old_name %in% names(variable_mapping)) {
    new_name <- variable_mapping[old_name]
    names(coping_df)[names(coping_df) == old_name] <- new_name
    cat("Renamed:", old_name, "→", new_name, "\n")
  }
}

# Standardize NCD column name to lowercase
names(coping_df)[names(coping_df) == ncd_col] <- "ncd"

cat("\nFinal column names:\n")
print(names(coping_df))

################################################################################
# 3. DATA PREPARATION
################################################################################

cat("\n=== PREPARING DATA ===\n")

# Get strategy column names (excluding 'ncd')
strategy_cols <- setdiff(names(coping_df), 'ncd')

# Ensure binary numeric format and compute number of strategies per household
coping_bin <- coping_df %>%
  mutate(across(all_of(strategy_cols), ~ as.integer(as.numeric(.) > 0))) %>%
  rowwise() %>%
  mutate(num_strategies = sum(c_across(all_of(strategy_cols)), na.rm = TRUE)) %>%
  ungroup()

# Remove households with missing NCD status
coping_bin <- coping_bin %>% filter(!is.na(ncd))

# Summary statistics
cat("\nTotal households:", nrow(coping_bin), "\n")
cat("NCD-affected households:", sum(coping_bin$ncd == 1, na.rm=TRUE), "\n")
cat("Non-NCD households:", sum(coping_bin$ncd == 0, na.rm=TRUE), "\n")
cat("\nStrategy count distribution:\n")
print(table(coping_bin$num_strategies))

# Check for zero-variance columns
zero_var_cols <- strategy_cols[colSums(coping_bin[strategy_cols], na.rm=TRUE) == 0]
if(length(zero_var_cols) > 0) {
  cat("\nWarning: Strategies with zero usage:", paste(zero_var_cols, collapse=", "), "\n")
  cat("These will be excluded from plots.\n")
  strategy_cols <- setdiff(strategy_cols, zero_var_cols)
}

# Filter to households with at least 2 strategies (multiple strategy users)
coping_2plus <- coping_bin %>% filter(num_strategies >= 2)

cat("\nHouseholds using ≥2 strategies:", nrow(coping_2plus), "\n")
cat("  - NCD-affected:", sum(coping_2plus$ncd == 1), "\n")
cat("  - Non-NCD:", sum(coping_2plus$ncd == 0), "\n")

################################################################################
# 4. CREATE UPSET PLOTS BY NCD STATUS
################################################################################

cat("\n=== CREATING UPSET PLOTS ===\n")

# Split by NCD status and keep only strategy columns
coping_ncd1 <- coping_2plus %>% 
  filter(ncd == 1) %>% 
  select(all_of(strategy_cols))

coping_ncd0 <- coping_2plus %>% 
  filter(ncd == 0) %>% 
  select(all_of(strategy_cols))

# Check if we have data for both groups
if(nrow(coping_ncd1) == 0) {
  cat("Warning: No NCD-affected households with ≥2 strategies. Skipping NCD plot.\n")
}

if(nrow(coping_ncd0) == 0) {
  cat("Warning: No non-NCD households with ≥2 strategies. Skipping non-NCD plot.\n")
}

################################################################################
# Plot 1: NCD-Affected Households (All Combinations)
################################################################################

if(nrow(coping_ncd1) > 0) {
  cat("\nCreating UpSet plot for NCD-affected households...\n")
  
  png('Figure_2A_UpSet_NCD_Households.png', 
      width = 12, height = 8, units = "in", res = 300)
  
  print(upset(as.data.frame(coping_ncd1),
        nsets = length(strategy_cols),
        nintersects = ,  # Not restricted to a specific number
        order.by = 'freq',
        decreasing = TRUE,
        main.bar.color = 'steelblue',  # Red for NCD
        sets.bar.color = 'darkred',
        matrix.color = 'darkblue',
        text.scale = c(1.3, 1.3, 1.2, 1.2, 1.5, 1.2),
        point.size = 3.5,
        line.size = 1,
        mainbar.y.label = 'Number of Households',
        sets.x.label = 'Strategy Prevalence',
        mb.ratio = c(0.65, 0.35),
        set_size.show = TRUE
  ))
  
  dev.off()
  cat("✓ Saved: Figure_2A_UpSet_NCD_Households.png\n")
  cat("  (n =", nrow(coping_ncd1), "NCD-affected households)\n")
}

################################################################################
# Plot 2: Non-NCD Households (All Combinations)
################################################################################

if(nrow(coping_ncd0) > 0) {
  cat("Creating UpSet plot for non-NCD households...\n")
  
  png('Figure_2B_UpSet_NonNCD_Households.png', 
      width = 12, height = 8, units = "in", res = 300)
  
  print(upset(as.data.frame(coping_ncd0),
        nsets = length(strategy_cols),
        nintersects = ,  # Not restricted to a specific number
        order.by = 'freq',
        decreasing = TRUE,
        main.bar.color = 'steelblue',  # Blue for non-NCD
        sets.bar.color = 'darkred',
        matrix.color = 'darkblue',
        text.scale = c(1.3, 1.3, 1.2, 1.2, 1.5, 1.2),
        point.size = 3.5,
        line.size = 1,
        mainbar.y.label = 'Number of Households',
        sets.x.label = 'Strategy Prevalence',
        mb.ratio = c(0.65, 0.35),
        set_size.show = TRUE
  ))
  
  dev.off()
  cat("✓ Saved: Figure_2B_UpSet_NonNCD_Households.png\n")
  cat("  (n =", nrow(coping_ncd0), "non-NCD households)\n")
}


################################################################################
# Plot 3: Combined Plot (All Health Shock Households, ≥2 strategies)
################################################################################

cat("Creating combined UpSet plot for all households...\n")

png('Figure_1_UpSet_All_Households.png', 
    width = 12, height = 8, units = "in", res = 300)

print(upset(as.data.frame(coping_2plus %>% select(all_of(strategy_cols))),
      nsets = length(strategy_cols),
      nintersects = 30,  # Show top 30 combinations
      order.by = 'freq',
      decreasing = TRUE,
      main.bar.color = 'steelblue',
      sets.bar.color = 'darkred',
      matrix.color = 'navy',
      text.scale = c(1.3, 1.3, 1.2, 1.2, 1.5, 1.2),
      point.size = 3.5,
      line.size = 1,
      mainbar.y.label = 'Number of Households',
      sets.x.label = 'Strategy Prevalence',
      mb.ratio = c(0.65, 0.35),
      set_size.show = TRUE
))

dev.off()
cat("✓ Saved: Figure_1_UpSet_All_Households.png\n")
cat("  (n =", nrow(coping_2plus), "households using ≥2 strategies)\n")


################################################################################
# 5. GENERATE SUMMARY STATISTICS
################################################################################

cat("\n=== SUMMARY STATISTICS ===\n")

# Individual strategy prevalence
cat("\nIndividual Strategy Prevalence (% of households using ≥2 strategies):\n")
strategy_prev <- coping_2plus %>%
  select(all_of(strategy_cols)) %>%
  summarise(across(everything(), ~ mean(., na.rm=TRUE) * 100)) %>%
  pivot_longer(everything(), names_to = "Strategy", values_to = "Prevalence") %>%
  arrange(desc(Prevalence))

print(strategy_prev, n = Inf)

# By NCD status
cat("\nStrategy Prevalence by NCD Status:\n")
prev_by_ncd <- coping_2plus %>%
  group_by(ncd) %>%
  summarise(across(all_of(strategy_cols), ~ mean(., na.rm=TRUE) * 100)) %>%
  pivot_longer(-ncd, names_to = "Strategy", values_to = "Prevalence") %>%
  pivot_wider(names_from = ncd, values_from = Prevalence, names_prefix = "NCD_")

print(prev_by_ncd, n = Inf)

# Average number of strategies
cat("\nAverage Number of Strategies:\n")
cat("Overall:", mean(coping_2plus$num_strategies, na.rm=TRUE), "\n")
cat("NCD-affected:", 
    mean(coping_2plus$num_strategies[coping_2plus$ncd == 1], na.rm=TRUE), "\n")
cat("Non-NCD:", 
    mean(coping_2plus$num_strategies[coping_2plus$ncd == 0], na.rm=TRUE), "\n")

# Most common combinations
cat("\nTop 10 Most Common Combinations:\n")
combos <- coping_2plus %>%
  select(all_of(strategy_cols)) %>%
  group_by(across(everything())) %>%
  summarise(count = n(), .groups = 'drop') %>%
  arrange(desc(count)) %>%
  head(10)

print(combos)

################################################################################
# 6. SAVE SUMMARY TO FILE
################################################################################

# Create summary text file
sink("UpSet_Analysis_Summary.txt")
cat("=================================================================\n")
cat("COPING STRATEGY COMBINATIONS - UPSET PLOT ANALYSIS SUMMARY\n")
cat("=================================================================\n\n")
cat("Date:", format(Sys.Date(), "%B %d, %Y"), "\n")
cat("Working Directory:", getwd(), "\n\n")

cat("SAMPLE SIZE:\n")
cat("Total households (≥2 strategies):", nrow(coping_2plus), "\n")
cat("  NCD-affected:", sum(coping_2plus$ncd == 1), "\n")
cat("  Non-NCD:", sum(coping_2plus$ncd == 0), "\n\n")

cat("AVERAGE NUMBER OF STRATEGIES:\n")
cat("Overall:", round(mean(coping_2plus$num_strategies, na.rm=TRUE), 2), "\n")
cat("NCD-affected:", 
    round(mean(coping_2plus$num_strategies[coping_2plus$ncd == 1], na.rm=TRUE), 2), "\n")
cat("Non-NCD:", 
    round(mean(coping_2plus$num_strategies[coping_2plus$ncd == 0], na.rm=TRUE), 2), "\n\n")

cat("INDIVIDUAL STRATEGY PREVALENCE (%):\n")
print(strategy_prev, n = Inf)

cat("\n\nFILES GENERATED:\n")
cat("1. Figure_1_UpSet_All_Households.png - Combined plot\n")
if(nrow(coping_ncd1) > 0) cat("2. Figure_2A_UpSet_NCD_Households.png - NCD-affected only\n")
if(nrow(coping_ncd0) > 0) cat("3. Figure_2B_UpSet_NonNCD_Households.png - Non-NCD only\n")
if(nrow(coping_ncd1) > 0 && nrow(coping_ncd0) > 0)cat("6. UpSet_Analysis_Summary.txt - This summary file\n")
sink()

cat("\n✓ Summary saved to: UpSet_Analysis_Summary.txt\n")

################################################################################
# 7. COMPLETION MESSAGE
################################################################################

cat("\n=================================================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("=================================================================\n")
cat("\nGenerated files:\n")
cat("  ✓ Figure_1_UpSet_All_Households.png\n")
if(nrow(coping_ncd1) > 0) cat("  ✓ Figure_2A_UpSet_NCD_Households.png\n")
if(nrow(coping_ncd0) > 0) cat("  ✓ Figure_2B_UpSet_NonNCD_Households.png\n")
if(nrow(coping_ncd1) > 0 && nrow(coping_ncd0) > 0)
cat("  ✓ UpSet_Analysis_Summary.txt\n")
cat("\nAll files saved to:", getwd(), "\n")
cat("=================================================================\n")

################################################################################
# END OF SCRIPT
################################################################################