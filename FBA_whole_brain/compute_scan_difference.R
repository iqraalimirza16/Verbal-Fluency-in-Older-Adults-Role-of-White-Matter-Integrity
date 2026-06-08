# ============================================================
# Compute difference between MRI date and ImaLife scan date
# Author: Iqra Ali Mirza
# ============================================================

library(readxl)
library(dplyr)

# Load data
df <- read_excel("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/memolife_04062024_plus_cneuro.xlsx")

# Convert date columns to Date format
# Both are in day-month-year format (e.g. 19-6-2022)
df$mri_date_clean        <- as.Date(df$mri_date,        format = "%d-%m-%Y")
df$scan_date_imalife_clean <- as.Date(df$scan_date_Imalife, format = "%d-%m-%Y")

# Compute difference in days (MRI date - ImaLife scan date)
df$days_between_scans <- as.numeric(df$mri_date_clean - df$scan_date_imalife_clean)

# Quick summary
cat("Summary of days between ImaLife scan and MRI:\n")
print(summary(df$days_between_scans))
cat("\nMean (years):", round(mean(df$days_between_scans, na.rm = TRUE) / 365.25, 2), "\n")
cat("SD (years):", round(sd(df$days_between_scans, na.rm = TRUE) / 365.25, 2), "\n")
cat("Missing values:", sum(is.na(df$days_between_scans)), "\n")

# Save updated dataset
write.csv(df, "C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/memolife_with_scan_diff.csv",
          row.names = FALSE)
cat("\nSaved as memolife_with_scan_diff.csv\n")
