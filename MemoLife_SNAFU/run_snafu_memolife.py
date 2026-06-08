# ============================================================
# MemoLife SNAFU Analysis
# Author: Iqra Ali Mirza
# Reference: Zemla et al. (2020), Behavior Research Methods
#            Rofes et al. (2023) Dutch semantic scheme
#
# Description: Computes average cluster size (clustering) and
#              number of cluster switches (switching) from
#              animal fluency data using the Dutch semantic
#              scheme and SNAFU. Uses STATIC clustering per
#              Troyer et al. (1997).
#
# Notes from Zemla et al. (2020) paper:
#   - Static clustering: a switch occurs when the next word
#     does not share a category with ANY previous word since
#     the start of the last cluster (more conservative than fluid)
#   - Perseverations and intrusions are KEPT IN for clustering
#   - Scheme file is read line-by-line as category,item
#     (no header row expected by SNAFU internally)
#   - Items with multiple category memberships get all labels
#     joined by semicolons 
# ============================================================
# --- INSTALL SNAFU (run once in terminal) ---
# pip install git+https://github.com/AusterweilLab/snafu-py.git

import snafu
import pandas as pd

# ============================================================
# STEP 1: SET FILES AS PATH: INTERNSHIP AND THESIS
# ============================================================

INPUT_CSV   = "Memolife_animals_snafu.csv"       # output from R preprocessing script
SCHEME_FILE = "Dutch_animals_snafu_scheme.csv"   # Rofes et al. 2023 Dutch scheme
OUTPUT_CSV  = "MemoLife_SNAFU_results.csv"       # output of these results will be saved in the directory

# ============================================================
# STEP 2: CLEAN THE INPUT DATA
# ============================================================

print("=" * 55)
print("STEP 2: Cleaning input data")
print("=" * 55)

df = pd.read_csv(INPUT_CSV, encoding='latin-1')  # latin-1 handles Dutch special characters

# Strip whitespace and lowercase all animal words
# (SNAFU scheme is also lowercased internally, so this must match)
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
# Items must be in the order they were spoken
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
# - removePerseverations=False: keep repeated words in the list.
#   Standard practice in the literature (Troyer et al. 1997).
#   Change to True only if Rofes et al. 2023 specifies otherwise.
# - removeIntrusions=False: keep words not in scheme.
#   Intrusion detection in SNAFU has low agreement with human
#   coders (r=0.01, Zemla et al. 2020) so not recommended.
# - hierarchical=False: one list per participant, correct here.

fluencydata = snafu.load_fluency_data(
    CLEANED_CSV,
    scheme=SCHEME_FILE,
    removePerseverations=False,
    removeIntrusions=False,
    hierarchical=False
)

print(f"Participants loaded: {len(fluencydata.subs)}")

# ============================================================
# STEP 4: COMPUTE MEAN CLUSTER SIZE AND NUMBER OF SWITCHES
# ============================================================

print("\n" + "=" * 55)
print("STEP 4: Computing clustering and switching (static)")
print("=" * 55)

# Average cluster size per participant
# Static: cluster ends when next word does not share a category
# with ANY word since the start of the current cluster
clustering = snafu.clusterSize(
    fluencydata.labeledlists,
    SCHEME_FILE,
    clustertype='static'
)

# Number of cluster switches per participant
# switchrate=False returns raw count, not proportion
# Raw count is what Troyer et al. 1997 and most FBA studies use
switching = snafu.clusterSwitch(
    fluencydata.labeledlists,
    SCHEME_FILE,
    clustertype='static',
    switchrate=False
)

print("Done.")

# ============================================================
# STEP 5: BUILD RESULTS DATAFRAME
# ============================================================

print("\n" + "=" * 55)
print("STEP 5: Building results dataframe")
print("=" * 55)

# Convert IDs to integer for correct numerical sorting
# (SNAFU returns IDs as strings, causing 1,10,100 ordering if not fixed)
results = pd.DataFrame({
    'id':         [int(s) for s in fluencydata.subs],
    'clustering': clustering,
    'switching':  switching
})

# Sort by participant ID numerically
results = results.sort_values('id').reset_index(drop=True)

# Add total responses per participant
# Zemla et al. (2020) warn that raw switching count is confounded
# with list length -- include total_responses as covariate in GLM
list_lengths = df.groupby('id')['item'].count().reset_index()
list_lengths.columns = ['id', 'total_responses']
list_lengths['id'] = list_lengths['id'].astype(int)
results = results.merge(list_lengths, on='id', how='left')

# ============================================================
# STEP 6: BASIC DESCRIPTIVE STATISTICS
# ============================================================

print("\n--- Descriptive Statistics ---")
print(results[['clustering', 'switching', 'total_responses']].describe().round(3))

# ============================================================
# STEP 7: SAVE OUTPUT AND SEE FIRST FEW ROWS FOR CONFIRMATION
# ============================================================

results.to_csv(OUTPUT_CSV, index=False)
print(f"\nResults saved to: {OUTPUT_CSV}")
print(f"Final shape: {results.shape}")
print("\nFirst 10 rows:")
print(results.head(10).to_string(index=False))
