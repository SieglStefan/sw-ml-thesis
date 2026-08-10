### Script for generating rollouts for evaluation
###
### Objective: Propagate a specific scheme for certain horizons over 
###     a year and reduce it against a reference data set



### Load packages
using Revise
using NeuralParam
using SpeedyWeather
using Dates
using Random



### Include the experiment (selected by bash ...)
# Include the experiment file
exp_name = get(ENV, "NP_EXP", "exp_TEST")
include(joinpath(@__DIR__, "experiments", exp_name * ".jl"))
@assert EXP == exp_name "EXP in $(exp_name).jl is \"$EXP\" — must match the file name"

# Choose subtask
task = parse(Int, get(ENV, "SLURM_ARRAY_TASK_ID", "0"))
e = experiments[task+1]





### Define and extract parameters

# General
NAME         = get(e, :name, "NoName_default")      # name of the rollout

# Spectral grid
TRUNC        = get(e, :trunc, 31)                   # truncation of spectral grid
NLAYERS      = get(e, :nlayers, 8)                  # number of vertical layers      

# Rollout scheme and reference
SCHEME       = get(e, :scheme, :OBLW)               # scheme to roll out
REFERENCE    = get(e, :reference, "OBLW_default")   # reference for comparison

# Model and parameters
MODEL        = get(e, :model, PrimitiveWetModel)    # used model
EM_OCEAN     = get(e, :em_ocean, 0.98f0)            # ocean emissivity
EM_LAND      = get(e, :em_land, 0.98f0)             # land emissivity

# Variables
PROBES       = get(e, :probes, DEF_PROBES)          # probed fields

# Rollout
MAX_HORIZON  = get(e, :max_horizon, 31)             # maximum forecast length in days
N_TRAJ       = get(e, :n_traj, 52)                  # number of trajectories sampled
ROLLOUT_T    = get(e, :rollout_t, 365)              # sampling time of rollout

# Heatmaps
HEATMAP_DAYS = get(e, :heatmap_days, [1,7,31])      # lead days for which entire fields are returned
HEATMAP_TRAJ = get(e, :heatmap_traj, 1)             # choice of specific trajectory for heatmap





### Prepare output and spectral grid
# Create output folder
out_dir = startswith(NAME, "TEST") ? fresh_out_dir : prepare_out_dir
DIR = out_dir(rollout_dir(EXP), NAME)

# Spectral grid
SG = SpectralGrid(trunc = TRUNC, nlayers = NLAYERS)





### Construct/load to be rolled out scheme
#   - Symbol: an analytic scheme, built here.  String: a trained scheme, loaded from disk
lw_scheme = SCHEME isa Symbol ?
    build_scheme(SCHEME, SG; em_ocean = EM_OCEAN, em_land = EM_LAND) :
    NeuralParam.load(; dir = scheme_dir(EXP, SCHEME), file = "scheme.jld2")





### Generate the rollout
rollout = generate_rollout(;
    spectral_grid   = SG,
    name            = NAME,
    dir             = DIR,

    lw_scheme       = lw_scheme,
    reference       = REFERENCE,
    model           = MODEL,
    probes          = PROBES,

    max_horizon     = MAX_HORIZON,
    n_traj          = N_TRAJ,
    rollout_t       = ROLLOUT_T,

    heatmap_days    = HEATMAP_DAYS,
    heatmap_traj    = HEATMAP_TRAJ,
)





### Create and store info.toml file
write_info(;
    dir = DIR,
    file = "info.toml",

    general = (;
        name        = NAME,
        experiment  = EXP,
        created     = now(),
        julia       = string(VERSION),
        sw_vers     = string(pkgversion(SpeedyWeather)),
    ),

    grid = (;
        trunc       = TRUNC,
        nlayers     = NLAYERS,
        grid_type   = string(nameof(SG.Grid)),
    ),

    lw_scheme = (;
        info_scheme(lw_scheme)...,
    ),

    rollout = (;
        reference    = REFERENCE,
        model        = string(nameof(MODEL)),
        em_ocean     = EM_OCEAN,
        em_land      = EM_LAND,
        probes       = [string(p) for p in keys(PROBES)],
        metrics      = ["rmse", "bias", "maxdiff", "mean"],
    ),

    sampling = (;
        max_horizon  = MAX_HORIZON,
        n_traj       = N_TRAJ,
        rollout_t    = ROLLOUT_T,
        start_days   = rollout.start_days,
        heatmap_days = HEATMAP_DAYS,
        heatmap_traj = HEATMAP_TRAJ,
    ),
)
