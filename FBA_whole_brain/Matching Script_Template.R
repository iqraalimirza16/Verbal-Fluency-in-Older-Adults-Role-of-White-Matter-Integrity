# ============================================================
# FBA Template Matching Script
# Goal: 30 participants total
#       15 high-CAC + 15 absent-CAC
#       8 males + 7 females per CAC group
#       Matched on age, sex (exact), and education
# ============================================================

library(readxl)
library(MatchIt)
library(writexl)

# ------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------

data <- read.csv("C:/Users/iqraa/Desktop/Internship and Thesis/Data/FBA_sample_214.csv")

match_df <- data[, c("memolife_id", "memo_id", "age_at_baseline", "sex", "education_years", "CAC_group")]

# 0 = male (sex==1), 1 = female (sex==2)
match_df$sex_binary <- ifelse(match_df$sex == 1, 0, 1)

# ------------------------------------------------------------
# 2. Run matching with exact constraint on sex
# ------------------------------------------------------------

m_out <- matchit(
  CAC_group ~ age_at_baseline + sex_binary + education_years,
  data     = match_df,
  method   = "nearest",
  distance = "mahalanobis",
  exact    = ~ sex_binary,
  ratio    = 1,
  replace  = FALSE
)

matched_data <- match.data(m_out)

# ------------------------------------------------------------
# 3. Select 8 male pairs + 7 female pairs = 15 pairs (30 participants)
# ------------------------------------------------------------

male_subclasses   <- unique(matched_data$subclass[matched_data$sex_binary == 0])
female_subclasses <- unique(matched_data$subclass[matched_data$sex_binary == 1])

cat("Available male pairs:  ", length(male_subclasses), "\n")
cat("Available female pairs:", length(female_subclasses), "\n\n")

top_male   <- male_subclasses[1:8]
top_female <- female_subclasses[1:7]

top15_subclasses <- c(top_male, top_female)
template_subset  <- matched_data[matched_data$subclass %in% top15_subclasses, ]

# ------------------------------------------------------------
# 4. Summary
# ------------------------------------------------------------

cat("=== Template subset ===\n")
cat("Total participants:", nrow(template_subset), "\n\n")

cat("CAC group breakdown:\n")
print(table(template_subset$CAC_group,
            dnn = "CAC group (0=absent, 1=high)"))

cat("\nSex breakdown:\n")
print(table(template_subset$sex_binary,
            dnn = "Sex (0=male, 1=female)"))

cat("\nSex by CAC group:\n")
print(table(template_subset$CAC_group, template_subset$sex_binary,
            dnn = c("CAC group", "Sex (0=male, 1=female)")))

cat("\nAge -- mean (SD):", round(mean(template_subset$age_at_baseline), 1),
    "(", round(sd(template_subset$age_at_baseline), 1), ")\n")
cat("Education -- mean (SD):", round(mean(template_subset$education_years), 1),
    "(", round(sd(template_subset$education_years), 1), ")\n")

# ------------------------------------------------------------
# 5. Export
# ------------------------------------------------------------

template_ids <- template_subset[, c("memolife_id", "memo_id", "CAC_group",
                                    "age_at_baseline", "sex", "education_years")]
template_ids <- template_ids[order(template_ids$CAC_group, template_ids$memolife_id), ]

write_xlsx(template_ids,
           "C:/Users/iqraa/Desktop/Internship and Thesis/Data/template_participants_final.xlsx")

writeLines(as.character(template_ids$memo_id),
           "C:/Users/iqraa/Desktop/Internship and Thesis/Data/template_memo_ids_final.txt")

cat("\nSaved: template_participants_final.xlsx\n")
cat("Saved: template_memo_ids_final.txt\n")
cat("\nParticipant list:\n")
print(template_ids)