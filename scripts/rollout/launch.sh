#!/bin/bash
#
# Launch rollout generation (from repo root):
#   bash scripts/rollout/launch.sh exp_A_01_CLW_outputForms        # all variants
#   bash scripts/rollout/launch.sh exp_A_01_CLW_outputForms 0-3    # a subset
#   bash scripts/rollout/launch.sh exp_TEST 0                      # a single variant
#
# Without ARRAY, every entry of experiments/<name>.jl is submitted.

set -euo pipefail

STAGE="rollout"
PREFIX="rollout"
EXP=${1:?"Usage: bash scripts/$STAGE/launch.sh <experiment-name> [ARRAY]"}
EXP_FILE="scripts/$STAGE/experiments/${EXP}.jl"

[[ -f "$EXP_FILE" ]] || { echo "No such experiment: $EXP_FILE" >&2; exit 1; }

# Array: given explicitly, or every entry of the experiment file
if [[ $# -ge 2 ]]; then
    ARRAY=$2
else
    N=$(awk '
        /^[[:space:]]*experiments[[:space:]]*=[[:space:]]*\[/ { inblock = 1; next }
        inblock && /^\]/                                      { exit }
        inblock && /^[[:space:]]+\(;/                         { n++ }
        END { print n+0 }
    ' "$EXP_FILE")
    [[ "$N" -gt 0 ]] || { echo "No experiment entries found in $EXP_FILE" >&2; exit 1; }
    ARRAY="0-$((N-1))"
fi

JOB="${PREFIX}_${EXP}"
mkdir -p slurm_logs
echo "Submitting $JOB | array $ARRAY"

sbatch --job-name="$JOB" \
       --array="$ARRAY" \
       --export=ALL,NP_EXP="$EXP" \
       --output="slurm_logs/${EXP}_%A_%a.out" \
       --error="slurm_logs/${EXP}_%A_%a.err" \
       "scripts/$STAGE/submit.sh"