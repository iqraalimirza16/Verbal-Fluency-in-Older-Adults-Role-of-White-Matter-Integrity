# ============================================================
# MemoLife - Descriptive Statistics and Group Comparisons
# Author: Iqra Ali Mirza
# ============================================================
library(dplyr)

# ============================================================
# STEP 1: LOAD AND FILTER DATA
# ============================================================
df <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_merged_with_SNAFU.csv")

df_ancova <- df %>%
  filter(CAC_group %in% c(0, 1)) %>%
  filter(mmse_score_tot >= 25) %>%
  filter(CAC <= 5000) %>%
  select(memolife_id, CAC_group, age_at_baseline, sex,
         education_years, interval_cac_memolife_npo,
         clustering, switching, fluency_good,
         mmse_score_tot, CAC) %>%
  na.omit()

df_ancova$CAC_group <- factor(df_ancova$CAC_group,
                              levels = c(0, 1),
                              labels = c("Absent", "High"))
df_ancova$sex <- factor(df_ancova$sex)

cat("Final N:", nrow(df_ancova), "\n")
print(table(df_ancova$CAC_group))

# ============================================================
# STEP 2: SEX DISTRIBUTION (Chi-square)
# ============================================================
cat("\n--- Sex Distribution ---\n")

sex_table <- table(df_ancova$CAC_group, df_ancova$sex)
print(sex_table)

# Proportion female per group (sex == 2 is female based on data dictionary)
cat("\nProportion female per group:\n")
prop_female <- prop.table(sex_table, margin = 1)
print(round(prop_female, 3))

chi_sex <- chisq.test(sex_table)
cat("\nChi-square test:\n")
print(chi_sex)

# ============================================================
# STEP 3: AGE (Welch t-test)
# ============================================================
cat("\n--- Age ---\n")

age_desc <- df_ancova %>%
  group_by(CAC_group) %>%
  summarise(N = n(),
            Mean = round(mean(age_at_baseline), 2),
            SD = round(sd(age_at_baseline), 2))
print(age_desc)

t_age <- t.test(age_at_baseline ~ CAC_group, data = df_ancova)
cat("\nWelch t-test:\n")
print(t_age)

# ============================================================
# STEP 4: EDUCATION (Welch t-test)
# ============================================================
cat("\n--- Education (years) ---\n")

edu_desc <- df_ancova %>%
  group_by(CAC_group) %>%
  summarise(N = n(),
            Mean = round(mean(education_years), 2),
            SD = round(sd(education_years), 2))
print(edu_desc)

t_edu <- t.test(education_years ~ CAC_group, data = df_ancova)
cat("\nWelch t-test:\n")
print(t_edu)

# ============================================================
# STEP 5: MMSE (Welch t-test)
# ============================================================
cat("\n--- MMSE Total Score ---\n")

mmse_desc <- df_ancova %>%
  group_by(CAC_group) %>%
  summarise(N = n(),
            Mean = round(mean(mmse_score_tot), 2),
            SD = round(sd(mmse_score_tot), 2))
print(mmse_desc)

t_mmse <- t.test(mmse_score_tot ~ CAC_group, data = df_ancova)
cat("\nWelch t-test:\n")
print(t_mmse)

# ============================================================
# STEP 6: INTERVAL (Welch t-test)
# ============================================================
cat("\n--- ImaLife-MemoLife Interval ---\n")

int_desc <- df_ancova %>%
  group_by(CAC_group) %>%
  summarise(N = n(),
            Mean = round(mean(interval_cac_memolife_npo), 2),
            SD = round(sd(interval_cac_memolife_npo), 2))
print(int_desc)

t_int <- t.test(interval_cac_memolife_npo ~ CAC_group, data = df_ancova)
cat("\nWelch t-test:\n")
print(t_int)

# ============================================================
# STEP 7: CAC SCORE (Mann-Whitney U)
# ============================================================
cat("\n--- CAC Score (Mann-Whitney U) ---\n")

cac_desc <- df_ancova %>%
  group_by(CAC_group) %>%
  summarise(N = n(),
            Median = round(median(CAC), 2),
            IQR = round(IQR(CAC), 2))
print(cac_desc)

mw_cac <- wilcox.test(CAC ~ CAC_group, data = df_ancova)
cat("\nMann-Whitney U test:\n")
print(mw_cac)

# ============================================================
# STEP 8: OVERALL TOTALS
# ============================================================
cat("\n--- Overall Sample Descriptives ---\n")

overall <- df_ancova %>%
  summarise(
    N = n(),
    Female_n = sum(sex == 2),
    Female_pct = round(mean(sex == 2) * 100, 1),
    Age_mean = round(mean(age_at_baseline), 2),
    Age_sd = round(sd(age_at_baseline), 2),
    Edu_mean = round(mean(education_years), 2),
    Edu_sd = round(sd(education_years), 2),
    MMSE_mean = round(mean(mmse_score_tot), 2),
    MMSE_sd = round(sd(mmse_score_tot), 2),
    Interval_mean = round(mean(interval_cac_memolife_npo), 2),
    Interval_sd = round(sd(interval_cac_memolife_npo), 2),
    CAC_median = round(median(CAC), 2),
    CAC_IQR = round(IQR(CAC), 2)
  )
print(t(overall))