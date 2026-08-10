### Script for generating reference data for evaluation/testing
###
### Objective: Propagate a specific model and save its state every day for 2 years



### Load packages
using Revise
using NeuralParam
using SpeedyWeather
using Dates
using Random





### Define possible variants for reference data generation
variants = [

    # 0. Test variant for quick testing  
    (;  name        = "TEST_REFERENCE",
        t_spinup    = Day(1),
        sim_days    = 10,
        fac_pert_t  = 2f0,
        fac_pert_q  = 0.2f0,
    ),

    # 1. OneBandLongwave default                  
    (;  name = "OBLW_default", lw_ref_type = :OBLW),
]

# Get task number and choose task
task = parse(Int, get(ENV, "SLURM_ARRAY_TASK_ID", "0"))
v = variants[task+1]





### Define and extract variables

# General
NAME        = get(v, :name, "default")            # name of the training run
SEED        = get(v, :seed, 1)                    # used seed for rng

# Spectral grid
TRUNC       = get(v, :trunc, 31)                  # truncation of spectral grid
NLAYERS     = get(v, :nlayers, 8)                 # number of vertical layers

# Model and parameters
MODEL       = get(v, :model, PrimitiveWetModel)   # used SW model
EM_OCEAN    = get(v, :em_ocean, 0.98f0)           # ocean emissivity
EM_LAND     = get(v, :em_land,  0.98f0)           # land emissivity
CO2         = get(v, :CO2, 280f0)                 # CO2 concentration in ppm

# Target scheme
LW_REF_TYPE = get(v, :lw_ref_type, :OBLW)         # LW  reference scheme

# Sampling
T_SPINUP    = get(v, :t_spinup, Day(30))                     # spinup time in days
START_DATE  = get(v, :start_date, DateTime(2005, 1, 1))      # sampling starting date
SIM_DAYS    = get(v, :sim_days, 2*365)                       # sampling time in days

# Perturbation
FAC_PERT_T  = get(v, :fac_pert_t, 2f0)            # additive perturbation amplitude for temperature
FAC_PERT_Q  = get(v, :fac_pert_q, 0.2f0)          # multiplicative perturbation amplitude for humidity (zeromin = true)





### Prepare output, seeding and spectral grid
# Create output folder
out_dir = startswith(NAME, "TEST") ? fresh_out_dir : prepare_out_dir
DIR = out_dir(reference_dir(), NAME)

# Set seed for reproducability
Random.seed!(SEED)

# Spectral grid
SG = SpectralGrid(trunc = TRUNC, nlayers = NLAYERS)



### Define reference scheme
lw_reference = build_scheme(LW_REF_TYPE, SG; em_ocean = EM_OCEAN, em_land = EM_LAND)



### Generate the reference data set
ref = generate_reference(;
    spectral_grid   = SG,
    name            = NAME,
    dir             = DIR,
    seed            = SEED,

    model           = MODEL,
    lw_scheme       = lw_reference,

    t_spinup        = T_SPINUP,
    start_date      = START_DATE,
    sim_days        = SIM_DAYS,

    fac_pert_T      = FAC_PERT_T,
    fac_pert_q      = FAC_PERT_Q,
)





### Create and store info.toml file
write_info(;
    dir = DIR,
    file = "info.toml",

    general = (;
        name             = NAME, 
        created          = now(), 
        seed             = SEED,
        julia            = string(VERSION), 
        sw_vers          = string(pkgversion(SpeedyWeather)),
    ),

    grid = (;
        trunc            = TRUNC,
        nlayers          = NLAYERS,
        grid_type        = string(nameof(SG.Grid)),
    ),

    model = (;
        model            = string(nameof(MODEL)),
        em_ocean         = EM_OCEAN,
        em_land          = EM_LAND,
        co2              = CO2,
    ),

    reference = (;
        info_scheme(lw_reference)...,
    ),

    sampling = (;
        t_spinup         = string(T_SPINUP),
        start_date       = string(START_DATE),
        sim_days         = SIM_DAYS,
        steps_per_day    = ref.steps_per_day,
    ),

    perturbation = (;
        fac_pert_T       = FAC_PERT_T,
        fac_pert_q       = FAC_PERT_Q,
    ),
)
