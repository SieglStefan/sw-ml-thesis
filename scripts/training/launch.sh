#!/bin/bash
#
# Launch a training/calibration job (from repo root):
#   bash scripts/training/launch.sh exp_A_01_CLW_outputForms        # all variants
#   bash scripts/training/launch.sh exp_A_01_CLW_outputForms 0-1    # a subset
#   bash scripts/training/launch.sh exp_TEST 2                      # a single variant
#
# Without ARRAY, every entry of experiments/<name>.jl is submitted.

set -euo pipefail

STAGE="training"
EXP=${1:?"Usage: bash scripts/$STAGE/launch.sh <experiment-name> [ARRAY]"}
EXP_FILE="scripts/$STAGE/experiments/${EXP}.jl"

[[ -f "$EXP_FILE" ]] || { echo "No such experiment: $EXP_FILE" >&2; exit 1; }

# Array: given explicitly, or every entry of the experiment file
if [[ $# -ge 2 ]]; then
    ARRAY=$2
else
    N=$(julia --startup-file=no -e '
        n = 0
        for a in Meta.parseall(read(ARGS[1], String)).args
            if a isa Expr && a.head === :(=) && a.args[1] === :experiments
                n = length(a.args[2].args)
            end
        end
        n == 0 && error("no `experiments = [...]` found in " * ARGS[1])
        print(n)
    ' "$EXP_FILE")
    ARRAY="0-$((N-1))"
fi

mkdir -p slurm_logs
echo "Submitting $STAGE | $EXP | array $ARRAY"

sbatch --job-name="$EXP" \
       --array="$ARRAY" \
       --export=ALL,NP_EXP="$EXP" \
       --output="slurm_logs/${EXP}_%A_%a.out" \
       --error="slurm_logs/${EXP}_%A_%a.err" \
       "scripts/$STAGE/submit.sh"