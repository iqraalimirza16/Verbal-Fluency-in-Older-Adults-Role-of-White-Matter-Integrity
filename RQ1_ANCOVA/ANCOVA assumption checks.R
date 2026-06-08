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