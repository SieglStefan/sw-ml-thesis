### OneBandLongwave scheme calibration/training
###
### Calibrate a ConstLW or train a NeuralLW scheme



### Load packages
using Revise
using NeuralParam
using SpeedyWeather
using Dates, Random



### Include possible experiments (one at a time)
#include("experiments/exp_TEST.jl")
#include("experiments/exp_A_01_CLW_outputForms.jl")
#include("experiments/exp_A_02_NLW_outputForms.jl")

task = parse(Int, get(ENV, "SLURM_ARRAY_TASK_ID", "0"))
e = experiments[task+1]





### Define and extract variables

# General
NAME            = get(e, :name, "default")            # name of the training run
SEED            = get(e, :seed, 2)                    # used seed for rng

# Spectral grid
TRUNC           = get(e, :trunc, 31)                  # truncation of spectral grid
NLAYERS         = get(e, :nlayers, 8)                 # number of vertical layers

# Model and parameters
MODEL           = get(e, :model, PrimitiveWetModel)   # used SW model
EM_OCEAN        = get(e, :em_ocean, 0.98f0)           # ocean emissivity
EM_LAND         = get(e, :em_land,  0.98f0)           # land emissivity
CO2             = get(e, :CO2, 280f0)                 # CO2 concentration in ppm

# Target scheme
LW_TARGET_TYPE  = get(e, :lw_target_type, :OBLW)      # LW target scheme type (OBLW or ABR)

# Trained scheme
LW_TRAIN_TYPE   = get(e, :lw_train_type, :ConstLW)                        # to be trained LW scheme type (ConstLW or NeuralLW)    
OUTPUT_FORM     = get(e, :output_form, LinearOutput())                    # output form of trained scheme
ZSCORE_NAME     = get(e, :zscore_name, "zscore_OBLW_default")             # used zscore statistics

# Architecture
ARCH_TYPE       = get(e, :arch_type, :MLP)            # architecture type (MLP or RNN)
N_HIDDEN        = get(e, :n_hidden, 2)                # number of hidden layers
WIDTH           = get(e, :width, 32)                  # width of hidden layers
ACT             = get(e, :act, tanh)                 # activation function

# Input specification
INPUT_SPEC      = get(e, :input_spec, input_spec(:T, :Ts, :lat))          # input specification for NeuralLW

# Learning parameters
ETA0            = get(e, :eta0, 1f-2)                 # initial learning rate
ETA_DECAY       = get(e, :eta_decay, 0.7f0)           # learning rate decay factor
CLIP_NORM       = get(e, :clip_norm, 1f0)             # gradient clipping norm
WEIGHT_DECAY    = get(e, :weight_decay, 1f-4)         # weight decay factor

# Loss
WEIGHTS         = get(e, :weights, (; T = 1f0, olw = 1f0, slwd = 1f0))    # weights for loss function

# Spinup and start date
T_SPINUP        = get(e, :t_spinup, Day(30))                              # spinup time
START_DATE      = get(e, :start_date, DateTime(2000, 1, 1))               # sampling starting date

# Training steps parameters
N_IC            = get(e, :n_ic, 5)                    # nr. of ic used for training
N_TRAJ          = get(e, :n_traj, 100)                 # nr. of trajectroies per ic
N_BATCH         = get(e, :n_batch, 2)                 # batch size for training
N_STEPS_0       = get(e, :n_steps_0, 10)               # nr. of initial training steps per update
N_STEPS_INC     = get(e, :n_steps_inc, 0)             # increase of n_steps after an ic
N_GAP           = get(e, :n_gap, 50)                  # nr. of timestep!() between two trajectories

# Perturbation
FAC_PERT_T      = get(e, :fac_pert_T, 2f0)            # additive perturbation factor for temperature
FAC_PERT_Q      = get(e, :fac_pert_q, 0.2f0)          # multiplicative perturbation factor for humidity





### Prepare output, seeding and spectral grid
# Create output folder
out_dir = startswith(NAME, "TEST") ? fresh_out_dir : prepare_out_dir
DIR = out_dir(scheme_dir(EXP), NAME)

# Set seed for reproducability
Random.seed!(SEED)

# Spectral grid
SG = SpectralGrid(trunc = TRUNC, nlayers = NLAYERS)





### Prepare target scheme
if LW_TARGET_TYPE == :OBLW
    lw_target = OneBandLongwave(SG;
        transmissivity     = FriersonLongwaveTransmissivity(SG),
        radiative_transfer = OneBandLongwaveRadiativeTransfer(SG;
                                emissivity_ocean = EM_OCEAN, 
                                emissivity_land  = EM_LAND
        ),
    )
else 
    error("Unknown target scheme type: $LW_TARGET_TYPE")
end





### Define to be calibrated/trained scheme

# Define architecture
if ARCH_TYPE == :MLP
    arch_config = MLPConfig(
        n_hidden  = N_HIDDEN,
        width     = WIDTH,
        act       = ACT,
    )
else
    error("Unknown architecture type: $ARCH_TYPE")
end

# Define final scheme
if LW_TRAIN_TYPE == :ConstLW
    lw_train = ConstLW(
        spectral_grid = SG;
        output_form   = OUTPUT_FORM,
        zscore_name   = ZSCORE_NAME, 
        def_ocean_em  = EM_OCEAN, 
        def_land_em   = EM_LAND,
        def_co2       = CO2
    )

elseif LW_TRAIN_TYPE == :NeuralLW
    lw_train = NeuralLW(
        spectral_grid = SG;
        arch_config   = arch_config,
        input_spec    = INPUT_SPEC,
        output_form   = OUTPUT_FORM,
        zscore_name   = ZSCORE_NAME, 
        def_ocean_em  = EM_OCEAN, 
        def_land_em   = EM_LAND,
        def_co2       = CO2
    )
else
    error("Unknown LW scheme type: $LW_TRAIN_TYPE")
end

# Choose the same scheme as target if identity test
NAME == "TEST_IDENTITY_NLW" && (lw_target = deepcopy(lw_train))





### Prepare training run
loss_config = LossConfig(
    spectral_grid = SG, 
    zscore_name   = ZSCORE_NAME,
    weights       = WEIGHTS,
)

# Define run configuration
train_config = TrainConfig(
    seed         = SEED,
    name         = NAME,
    dir          = DIR,

    model        = MODEL,
    lw_target    = lw_target,

    eta0         = ETA0,
    eta_decay    = ETA_DECAY,
    clip_norm    = CLIP_NORM,
    weight_decay = WEIGHT_DECAY,
    loss_config  = loss_config,

    t_spinup     = T_SPINUP,
    start_date   = START_DATE,

    n_ic         = N_IC,
    n_traj       = N_TRAJ,
    n_batch      = N_BATCH,
    n_steps_0    = N_STEPS_0,
    n_steps_inc  = N_STEPS_INC,
    n_gap        = N_GAP,
    
    fac_pert_T   = FAC_PERT_T,
    fac_pert_q   = FAC_PERT_Q,
    
    do_autodiff  = true,
)

# Run the calibration/training
lw_trained = fetch(schedule(Task(() -> run_training(SG, lw_train, train_config), 1<<29)))





### Create and store info.toml file
write_info(; 
    dir = DIR, 
    file = "info.toml",

    general = (;
        name             = NAME, 
        experiment       = EXP,
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

    target = (;
        info_scheme(lw_target)...,
    ),

    lw_train = (;
        info_scheme(lw_trained)...,
    ),

    learning_parameters = (;
        eta0             = ETA0, 
        eta_decay        = ETA_DECAY,
        clip_norm        = CLIP_NORM,
        weight_decay     = WEIGHT_DECAY,
    ),

    loss = (;
        weights          = WEIGHTS,
        zscore_name      = ZSCORE_NAME,
    ),

    training_time = (;
        t_spinup         = string(T_SPINUP), 
        start_date       = string(START_DATE),
    ),

    steps = (;
        n_ic             = N_IC, 
        n_traj           = N_TRAJ, 
        n_batch          = N_BATCH,
        n_steps_0        = N_STEPS_0, 
        n_steps_inc      = N_STEPS_INC, 
        n_gap            = N_GAP,
    ),

    perturbation = (;
        fac_pert_T       = FAC_PERT_T,
        fac_pert_q       = FAC_PERT_Q,
    ),
)