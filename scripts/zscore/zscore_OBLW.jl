### Script for calculating zscore stats for a OneBandLongwave (LW) target scheme
###
### Objective: Calculate statistics for:
### - input variables:      T, q, p, lat, lf, sst, lst, Ts
### - direct outputs:       dT, olw, slwd
### - regression outputs:   a, b (per layer), c, d, e (olw), f, g (slwd)
###
### Additionally:
###     - stores meta data of creation of stats at info.toml
###     - stores histograms of normalized variables and regression scatter plots



### Load packages
using Revise
using NeuralParam
using SpeedyWeather
using Dates
using Random



### Define parameters for sampling

# General
NAME        = "zscore_OBLW_default"         # name of statistics
SEED        = 3                         # seed used

# Spectral grid
TRUNC       = 31                        # truncation of spectral grid
NLAYERS     = 8                         # number of vertical layers

# Model and parameters
MODEL = PrimitiveWetModel               # used SW model
EM_OCEAN    = 0.98f0                    # ocean emissivity
EM_LAND     = 0.98f0                    # land emissivity
CO2         = 280f0                     # CO2 concentration in ppm

# Target scheme
LW_SCHEME   = :OBLW                     # used LW scheme (OBLW or ABR)

# Sampling
T_SPINUP    = Day(365)                  # spinup time
START_DATE  = DateTime(2000, 1, 1)      # start date of simulation
N_IC        = 3                         # number of initial conditions
SIM_TIME    = 365                       # sampling time in days
SAMPLE_GAP  = 3.65                      # days between sampling

# Perturbation
FAC_PERT_T  = 2f0                       # temperature perturbation amplitude
FAC_PERT_Q  = 0.2f0                     # humidity perturbation amplitude (multiplicative)

# Output forms (for fitting parameters)
OUTPUT_FORMS = (DirectOutput(), LinearOutput(), PlanckOutput())




### Prepare output, seeding an spectral grid
# Create output folder
DIR = prepare_out_dir(stats_dir(), NAME)

# Set seed for reproducability
Random.seed!(SEED)

# Spectral grid
SG = SpectralGrid(trunc = TRUNC, nlayers = NLAYERS)



### Construct/load to be rolled out scheme
#   - Symbol: an analytic scheme, built here.  String: a trained scheme, loaded from disk
lw_scheme = LW_SCHEME isa Symbol ?
    build_scheme(LW_SCHEME, SG; em_ocean = EM_OCEAN, em_land = EM_LAND) :
    load(; dir = scheme_dir(EXP, LW_SCHEME), file = "scheme.jld2")



### Generate zscore statistics
zs = generate_zscore(;
    spectral_grid   = SG,
    name            = NAME,
    dir             = DIR,
    seed            = SEED,

    model           = MODEL,
    lw_scheme       = lw_scheme,

    output_forms    = OUTPUT_FORMS,

    t_spinup        = T_SPINUP,
    start_date      = START_DATE,
    n_ic            = N_IC,
    sim_time        = SIM_TIME,
    sample_gap      = SAMPLE_GAP,

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
        info_scheme(lw_scheme)...,
    ),

    sampling = (;
        t_spinup         = string(T_SPINUP),
        start_date       = string(START_DATE),
        n_ic             = N_IC,
        sim_time         = SIM_TIME,
        sample_gap       = SAMPLE_GAP,
    ),

    perturbation = (;
        fac_pert_t = FAC_PERT_T,
        fac_pert_q = FAC_PERT_Q,
    ),

    io = (;
        inputs  = ["T", "q", "p", "lat", "lf", "sst", "lst", "Ts"],
        groups  = [string(output_group(f)) for f in OUTPUT_FORMS],
        keys    = [string(nameof(typeof(f))) * ": " * join(string.(output_keys(f)), ", ")
                   for f in OUTPUT_FORMS],
        forms   = ["affine: dT = a + b*P(T)", "olw = c + d*P(T[nlayers÷2]) + e*P(Ts)",
                   "slwd = f + g*P(T[nlayers])", "P = identity (linear) or x^4 (planck)"],
    ),
)
