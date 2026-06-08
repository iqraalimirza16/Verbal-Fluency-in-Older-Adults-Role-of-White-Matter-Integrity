# ============================================================
# MemoLife - Merge SNAFU Results into Main Dataset
# Author: Iqra Ali Mirza
#
# Description: Merges clustering, switching, mean AoA, and
#              mean word frequency (Zipf) from SNAFU output
#              into the main MemoLife dataset.
#
# Input files:
#   memolife_04062024_plus_cneuro.xlsx  : main dataset
#   MemoLife_SNAFU_results_updated.csv  : SNAFU output
#
# Output:
#   MemoLife_merged.csv : merged dataset ready for analysis
# ============================================================

# Install packages if needed (run once)
# install.packages("readxl")
# install.packages("dplyr")
# install.packages("writexl")

library(dplyr)

# ============================================================
# STEP 1: LOAD DATA
# ============================================================

# Load main dataset
main <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/memolife_04062024_plus_cneuro.csv")

# Load SNAFU results
snafu <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_SNAFU_results_updated.csv")

cat("Main dataset dimensions:", nrow(main), "rows,", ncol(main), "columns\n")
cat("SNAFU results dimensions:", nrow(snafu), "rows,", ncol(snafu), "columns\n")

# ============================================================
# STEP 2: MERGE
# ============================================================

# Merge on participant ID
# main uses 'memolife_id', snafu uses 'id'
# left join: keeps all participants from main dataset
# participants without SNAFU data (e.g. participant 163)
# will have NA for the SNAFU columns

merged <- left_join(main, snafu, by = c("memolife_id" = "id"))

cat("\nMerged dataset dimensions:", nrow(merged), "rows,", ncol(merged), "columns\n")

# ============================================================
# STEP 3: CHECK THE MERGE
# ============================================================

# How many participants have SNAFU data
cat("\nParticipants with SNAFU data:", sum(!is.na(merged$clustering)), "\n")
cat("Participants without SNAFU data:", sum(is.na(merged$clustering)), "\n")

# Quick check of merged columns
cat("\nFirst 5 rows of key columns:\n")
print(head(merged[, c("memolife_id", "clustering", "switching", "mean_aoa", "mean_zipf", "total_responses")]))

# ============================================================
# STEP 4: SAVE MERGED DATASET
# ============================================================

# Save as CSV
write.csv(merged, "C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_merged.csv", row.names = FALSE)
cat("\nMerged dataset saved as: MemoLife_merged.csv\n")

# Optionally save as Excel
# write_xlsx(merged, "C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_merged.xlsx")