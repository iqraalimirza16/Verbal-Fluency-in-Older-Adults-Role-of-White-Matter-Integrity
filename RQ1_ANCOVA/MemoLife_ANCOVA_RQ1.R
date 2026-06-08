# ============================================================
# MemoLife - ANCOVA for RQ1
# Author: Iqra Ali Mirza
#
# RQ1: Do cognitively healthy older adults with high CAC (>=300)
#      differ from those with absent CAC (0) in animal fluency
#      metrics (total words, mean cluster size, number of switches)?
#
# Covariates: age_at_baseline, sex, education_years,
#             interval_cac_memolife_npo
# Exclusions: MMSE < 25, CAC > 5000
# ============================================================
library(dplyr)
library(car)
library(emmeans)

# ============================================================
# STEP 1: LOAD DATA
# ============================================================
df <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_merged_with_SNAFU.csv")
cat("Dataset dimensions:", nrow(df), "rows,", ncol(df), "columns\n")

# ============================================================
# STEP 2: PREPARE VARIABLES
# ============================================================
df_ancova <- df %>%
  filter(CAC_group %in% c(0, 1)) %>%
  filter(mmse_score_tot >= 25) %>%
  filter(CAC <= 5000) %>%
  select(memolife_id, CAC_group, age_at_baseline, sex,
         education_years, interval_cac_memolife_npo,
         clustering, switching, fluency_good,
         mmse_score_tot) %>%
  na.omit()

df_ancova$CAC_group <- factor(df_ancova$CAC_group,
                              levels = c(0, 1),
                              labels = c("Absent", "High"))
df_ancova$sex <- factor(df_ancova$sex)

cat("\nSample after filtering (MMSE >= 25, CAC <= 5000):\n")
cat("Total N:", nrow(df_ancova), "\n")
cat("CAC group counts:\n")
print(table(df_ancova$CAC_group))

# ============================================================
# STEP 3: DESCRIPTIVE STATISTICS PER GROUP
# ============================================================
cat("\n--- Descriptive Statistics by CAC Group ---\n")

outcomes <- c("fluency_good", "clustering", "switching")

for (var in outcomes) {
  cat("\n", var, ":\n")
  desc <- df_ancova %>%
    group_by(CAC_group) %>%
    summarise(
      N    = n(),
      Mean = round(mean(.data[[var]], na.rm = TRUE), 3),
      SD   = round(sd(.data[[var]], na.rm = TRUE), 3)
    )
  print(desc)
}

# ============================================================
# STEP 4: RUN ANCOVA FOR EACH OUTCOME
# ============================================================
cat("\n--- ANCOVA Results ---\n")

p_values <- c()

for (var in outcomes) {
  cat("\n========================================\n")
  cat("Outcome:", var, "\n")
  cat("========================================\n")
  
  formula <- as.formula(paste(var,
                              "~ CAC_group + age_at_baseline + sex + education_years + interval_cac_memolife_npo"))
  
  model <- lm(formula, data = df_ancova)
  
  anova_result <- Anova(model, type = "III")
  print(anova_result)
  
  p_cac <- anova_result["CAC_group", "Pr(>F)"]
  p_values <- c(p_values, p_cac)
  
  emm <- emmeans(model, ~ CAC_group)
  cat("\nAdjusted means (controlling for covariates):\n")
  print(summary(emm))
  
  ss_cac   <- anova_result["CAC_group", "Sum Sq"]
  ss_resid <- anova_result["Residuals", "Sum Sq"]
  partial_eta2 <- ss_cac / (ss_cac + ss_resid)
  cat("\nPartial eta squared for CAC_group:", round(partial_eta2, 4), "\n")
}

# ============================================================
# STEP 5: FDR CORRECTION
# ============================================================
cat("\n--- FDR Correction (Benjamini-Hochberg) ---\n")

fdr_results <- data.frame(
  Outcome     = outcomes,
  p_value     = round(p_values, 4),
  p_fdr       = round(p.adjust(p_values, method = "BH"), 4),
  Significant = p.adjust(p_values, method = "BH") < 0.05
)

print(fdr_results)

write.csv(fdr_results,
          "C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/ANCOVA_RQ1_results.csv",
          row.names = FALSE)

cat("\nResults saved as: ANCOVA_RQ1_results.csv\n")

for (var in outcomes) {
  cat(var, ": Total Mean =", round(mean(df_ancova[[var]]), 2),
      "SD =", round(sd(df_ancova[[var]]), 2), "\n")
}

# How many after CAC group filter only
df %>% filter(CAC_group %in% c(0, 1)) %>% nrow()

# How many after adding MMSE filter
df %>% filter(CAC_group %in% c(0, 1)) %>% filter(mmse_score_tot >= 25) %>% nrow()

# How many after adding CAC > 5000 filter
df %>% filter(CAC_group %in% c(0, 1)) %>% filter(mmse_score_tot >= 25) %>% filter(CAC <= 5000) %>% nrow()

# Start with CAC and MMSE and CAC<=5000 filtered dataset (before na.omit)
df_check <- df %>%
  filter(CAC_group %in% c(0, 1)) %>%
  filter(mmse_score_tot >= 25) %>%
  filter(CAC <= 5000) %>%
  select(memolife_id, CAC_group, age_at_baseline, sex,
         education_years, interval_cac_memolife_npo,
         clustering, switching, fluency_good,
         mmse_score_tot)

# Show which rows have any missing values
missing_rows <- df_check[!complete.cases(df_check), ]
cat("Participants excluded due to missing data:\n")
print(missing_rows)

# Show exactly which columns have NAs for those participants
cat("\nWhich variables are missing:\n")
print(is.na(missing_rows))

# ============================================================
# MemoLife - Assumption Checks for RQ1 ANCOVA
# Author: Iqra Ali Mirza
# ============================================================
library(dplyr)
library(car)

# ============================================================
# STEP 1: LOAD AND FILTER DATA (same exclusions as main script)
# ============================================================
df <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/SNAFU data/MemoLife_merged_with_SNAFU.csv")

df_ancova <- df %>%
  filter(CAC_group %in% c(0, 1)) %>%
  filter(mmse_score_tot >= 25) %>%
  filter(CAC <= 5000) %>%
  select(memolife_id, CAC_group, age_at_baseline, sex,
         education_years, interval_cac_memolife_npo,
         clustering, switching, fluency_good,
         mmse_score_tot) %>%
  na.omit()

df_ancova$CAC_group <- factor(df_ancova$CAC_group,
                              levels = c(0, 1),
                              labels = c("Absent", "High"))
df_ancova$sex <- factor(df_ancova$sex)

cat("Final N:", nrow(df_ancova), "\n")

outcomes <- c("fluency_good", "clustering", "switching")

# ============================================================
# STEP 2: OUTLIER CHECK (IQR method per CAC group)
# ============================================================
cat("\n--- Outlier Check (IQR method per CAC group) ---\n")

for (var in outcomes) {
  cat("\n", var, ":\n")
  for (grp in levels(df_ancova$CAC_group)) {
    vals <- df_ancova[[var]][df_ancova$CAC_group == grp]
    Q1 <- quantile(vals, 0.25, na.rm = TRUE)
    Q3 <- quantile(vals, 0.75, na.rm = TRUE)
    IQR_val <- Q3 - Q1
    lower <- Q1 - 1.5 * IQR_val
    upper <- Q3 + 1.5 * IQR_val
    outliers <- vals[vals < lower | vals > upper]
    cat("  Group:", grp, "| Lower fence:", round(lower, 2),
        "| Upper fence:", round(upper, 2),
        "| N outliers:", length(outliers), "\n")
    if (length(outliers) > 0) cat("  Outlier values:", outliers, "\n")
  }
}

# ============================================================
# STEP 3: NORMALITY OF RESIDUALS
# ============================================================
cat("\n--- Normality of Residuals (Shapiro-Wilk) ---\n")

par(mfrow = c(1, 3))

for (var in outcomes) {
  formula <- as.formula(paste(var,
                              "~ CAC_group + age_at_baseline + sex + education_years + interval_cac_memolife_npo"))
  model <- lm(formula, data = df_ancova)
  resids <- residuals(model)
  
  sw <- shapiro.test(resids)
  cat("\n", var, ": W =", round(sw$statistic, 3), ", p =", round(sw$p.value, 4), "\n")
  
  # Q-Q plot
  qqnorm(resids, main = paste("Q-Q Plot:", var))
  qqline(resids, col = "red")
}

# ============================================================
# STEP 4: HOMOGENEITY OF VARIANCE (Levene's Test)
# ============================================================
cat("\n--- Levene's Test for Homogeneity of Variance ---\n")

for (var in outcomes) {
  lev <- leveneTest(df_ancova[[var]] ~ df_ancova$CAC_group)
  cat("\n", var, ": F =", round(lev$`F value`[1], 3),
      ", p =", round(lev$`Pr(>F)`[1], 4), "\n")
}

# ============================================================
# STEP 5: HOMOGENEITY OF REGRESSION SLOPES
# ============================================================
cat("\n--- Homogeneity of Regression Slopes (CAC group x covariate interactions) ---\n")

covariates <- c("age_at_baseline", "sex", "education_years", "interval_cac_memolife_npo")

for (var in outcomes) {
  cat("\nOutcome:", var, "\n")
  for (cov in covariates) {
    formula <- as.formula(paste(var,
                                "~ CAC_group *", cov, "+ age_at_baseline + sex + education_years + interval_cac_memolife_npo"))
    model_int <- lm(formula, data = df_ancova)
    anova_int <- Anova(model_int, type = "III")
    interaction_term <- paste0("CAC_group:", cov)
    if (interaction_term %in% rownames(anova_int)) {
      p_int <- anova_int[interaction_term, "Pr(>F)"]
      cat("  CAC_group x", cov, ": p =", round(p_int, 4), "\n")
    }
  }
}