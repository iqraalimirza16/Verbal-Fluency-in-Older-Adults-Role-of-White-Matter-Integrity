# MemoLife_SNAFU preprocessing
# Author: Iqra Ali Mirza

# Install & load packages 

install.packages("readxl")
install.packages("dplyr")

library(readxl)
library(dplyr)

# Set working directory 

setwd("C:/Users/iqraa/Desktop/Internship and Thesis Resources/Data")

# Read MemoLife Excel, fix names, drop extra header

memolife_raw <- read_excel(
  "MemoLife-Animal_Fluency_Test_DATA.xlsx",
  col_names = FALSE
)

names(memolife_raw) <- c(
  "order",
  "memolife_id",
  "redcap_event_name",
  "redcap_repeat_instrument",
  "redcap_repeat_instance",
  "memo_id",
  "umcg_dummy",
  "fluency_good",
  "fluency_errors",
  "fluency_double",
  "animal",
  "correct",
  "verbal_word_fluency_animals_complete",
  "repetition",
  "Comments",
  "gender",
  "age",
  "verhage",
  "cluster_size",
  "switches"
)

# Remove duplicated header row
memolife <- memolife_raw[-1, ]

# Build SNAFU file: id, listnum, item (mentioned in Zemla et al., 2020)

memo_fluency <- memolife %>%
  filter(redcap_repeat_instrument == "verbal_word_fluency_animals") %>%
  transmute(
    id      = as.integer(memolife_id),      # participant ID
    listnum = 1L,                           # one animal list per person as this was animal fluency data 
    item    = tolower(trimws(animal)),
    order   = as.integer(order)             # keep for sorting
  ) %>%
  arrange(id, listnum, order) %>%           # ensure items are in spoken order
  select(id, item, listnum)                 # final 3 columns only

# Save CSV file
write.csv(
  memo_fluency,
  "Memolife_animals_snafu.csv",
  row.names = FALSE
)
