# ============================================================
# MemoLife SNAFU Analysis — Updated
# Author: Iqra Ali Mirza
# Reference: Zemla et al. (2020), Behavior Research Methods
#            Rofes et al. (2023) Dutch semantic scheme
#            Brysbaert et al. (2014) Dutch AoA norms
#            Keuleers et al. (2010) SUBTLEX-NL
#
# Description: Computes average cluster size (clustering) and
#              number of cluster switches (switching) from
#              animal fluency data using the Dutch semantic
#              scheme and SNAFU. Uses STATIC clustering per
#              Troyer et al. (1997). Also extracts mean age
#              of acquisition (AoA) and mean word frequency
#              (Zipf) per participant.
#
# Notes from Zemla et al. (2020) paper:
#   - Static clustering: a switch occurs when the next word
#     does not share a category with ANY previous word since
#     the start of the last cluster (more conservative than fluid)
#   - Perseverations are REMOVED before analysis for consistency
#     across all metrics (clustering, switching, AoA, frequency)
#   - Scheme file is read line-by-line as category,item
#     (no header row expected by SNAFU internally)
#   - Items with multiple category memberships get all labels
#     joined by semicolons
#
# Notes on word property databases:
#   - AoA: Average column from Brysbaert et al. (2014)
#     supplementary material 2, combining ratings from
#     Ghyselinck (2000, 2003), Moors (2013), Brysbaert (2014)
#     16 words with Excel #DIV/0! errors were excluded
#   - Frequency: Zipf column from SUBTLEX-NL (Keuleers et al.
#     2010), log-transformed frequency per billion words
#   - Missing words (not in database) are ignored by SNAFU
#     by default (missing=None), meaning they do not
#     contribute to the mean for that participant
# ============================================================

# --- INSTALL SNAFU (run once in terminal) ---
# pip install git+https://github.com/AusterweilLab/snafu-py.git

import snafu
import pandas as pd

# ============================================================
# STEP 1: SET FILE PATHS
# ============================================================

INPUT_CSV    = "Memolife_animals_snafu_SNAFUOK.csv"  # fluency data: id, item, listnum
SCHEME_FILE  = "Dutch_animals_snafu_scheme.csv"      # Rofes et al. 2023 Dutch scheme
AOA_FILE     = "aoa_dutch.csv"                       # Brysbaert et al. 2014 AoA norms
FREQ_FILE    = "frequency_dutch.csv"                 # Keuleers et al. 2010 SUBTLEX-NL Zipf
OUTPUT_CSV   = "MemoLife_SNAFU_results_updated.csv"  # final output

# ============================================================
# STEP 2: CLEAN THE INPUT DATA
# ============================================================

print("=" * 55)
print("STEP 2: Cleaning input data")
print("=" * 55)

df = pd.read_csv(INPUT_CSV, encoding='latin-1')

# Strip whitespace and lowercase all animal words
df['item'] = df['item'].str.strip().str.lower()

# Identify and report participants with missing items BEFORE dropping
n_before = len(df)
null_rows = df[df['item'].isnull() | (df['item'] == '')]
if len(null_rows) > 0:
    print(f"WARNING: Found {len(null_rows)} null/empty item(s):")
    print(f"  Affected participant IDs: {sorted(null_rows['id'].dropna().astype(int).unique().tolist())}")
    print(f"  These participants will be EXCLUDED from analysis.")
    print(f"  --> Check their raw recordings before finalising results.")

# Drop null/empty items
df = df.dropna(subset=['item'])
df = df[df['item'] != '']
n_after = len(df)

print(f"\nRows before cleaning:  {n_before}")
print(f"Rows after cleaning:   {n_after}")
print(f"Unique participants:   {df['id'].nunique()}")

# Verify chronological order is preserved (critical for SNAFU)
print(f"\nOrder check (participant 1, first 5 items):")
print(df[df['id']==1]['item'].head(5).tolist())

# Save cleaned CSV for SNAFU
CLEANED_CSV = "memolife_snafu_clean.csv"
df.to_csv(CLEANED_CSV, index=False, encoding='utf-8')
print(f"\nCleaned file saved as: {CLEANED_CSV}")

# ============================================================
# STEP 3: LOAD DATA INTO SNAFU
# ============================================================

print("\n" + "=" * 55)
print("STEP 3: Loading data into SNAFU")
print("=" * 55)

# Note on parameters (Zemla et al. 2020):
# - removePerseverations=True: repeated words are removed before
#   analysis. This applies to clustering, switching, AoA, and
#   frequency for consistency. Perseverations are rare in healthy
#   older adults but removing them ensures they do not artificially
#   bias mean psycholinguistic properties (AoA, frequency).
# - removeIntrusions=False: keep words not in scheme.
#   Intrusion detection in SNAFU has low agreement with human
#   coders (r=0.01, Zemla et al. 2020) so not recommended.
# - hierarchical=False: one list per participant, correct here.

fluencydata = snafu.load_fluency_data(
    CLEANED_CSV,
    scheme=SCHEME_FILE,
    removePerseverations=True,
    removeIntrusions=False,
    hierarchical=False
)

print(f"Participants loaded: {len(fluencydata.subs)}")

# ============================================================
# STEP 4: COMPUTE CLUSTERING AND SWITCHING
# ============================================================

print("\n" + "=" * 55)
print("STEP 4: Computing clustering and switching (static)")
print("=" * 55)

# Average cluster size per participant
clustering = snafu.clusterSize(
    fluencydata.labeledlists,
    SCHEME_FILE,
    clustertype='static'
)

# Number of cluster switches per participant
switching = snafu.clusterSwitch(
    fluencydata.labeledlists,
    SCHEME_FILE,
    clustertype='static',
    switchrate=False
)

print("Done.")

# ============================================================
# STEP 5: COMPUTE MEAN AOA AND WORD FREQUENCY
# ============================================================

print("\n" + "=" * 55)
print("STEP 5: Computing mean AoA and word frequency")
print("=" * 55)

# Mean age of acquisition per participant
# Based on Brysbaert et al. (2014) Dutch norms (Average column)
# Words not found in the database are ignored (missing=None)
aoa = snafu.wordStat(
    fluencydata.labeledlists,
    data=AOA_FILE,
    missing=None
)

# Mean word frequency per participant
# Based on SUBTLEX-NL Zipf values (Keuleers et al. 2010)
# Zipf = log10(frequency per billion words)
# Words not found in the database are ignored (missing=None)
frequency = snafu.wordStat(
    fluencydata.labeledlists,
    data=FREQ_FILE,
    missing=None
)

print("Done.")

# ============================================================
# STEP 6: BUILD RESULTS DATAFRAME
# ============================================================

print("\n" + "=" * 55)
print("STEP 6: Building results dataframe")
print("=" * 55)

# wordStat returns a list of (subject, value) tuples, not a flat list
# We need to extract them carefully and merge on id
ids = [int(s) for s in fluencydata.subs]

# wordStat returns a flat list of values, one per participant
# in the same order as fluencydata.subs
print(f"Number of participants: {len(ids)}")
print(f"Length of aoa output: {len(aoa)}")
print(f"Length of frequency output: {len(frequency)}")

# wordStat returns a tuple of (values, missing_words)
# We only need the first element - the list of mean values per participant
aoa_values = list(aoa[0])
freq_values = list(frequency[0])

print(f"Length of aoa values: {len(aoa_values)}")
print(f"Length of freq values: {len(freq_values)}")

results = pd.DataFrame({
    'id':         ids,
    'clustering': clustering,
    'switching':  switching,
    'mean_aoa':   aoa_values,
    'mean_zipf':  freq_values
})

# Sort by participant ID numerically
results = results.sort_values('id').reset_index(drop=True)

# Add total responses per participant
list_lengths = df.groupby('id')['item'].count().reset_index()
list_lengths.columns = ['id', 'total_responses']
list_lengths['id'] = list_lengths['id'].astype(int)
results = results.merge(list_lengths, on='id', how='left')

# ============================================================
# STEP 7: DESCRIPTIVE STATISTICS
# ============================================================

print("\n--- Descriptive Statistics ---")
print(results[['clustering', 'switching', 'mean_aoa', 'mean_zipf', 'total_responses']].describe().round(3))

# ============================================================
# STEP 8: SAVE OUTPUT
# ============================================================

results.to_csv(OUTPUT_CSV, index=False)
print(f"\nResults saved to: {OUTPUT_CSV}")
print(f"Final shape: {results.shape}")
print("\nFirst 10 rows:")
print(results.head(10).to_string(index=False))
