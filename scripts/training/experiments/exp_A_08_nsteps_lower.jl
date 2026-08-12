### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_08_nsteps_lower"



# Define parameters for the experiment
CONFIG = (;
    lw_target_type = :OBLW,
    seed           = 1000,

    lw_train_type  = :NeuralLW,
    zscore_name    = "zscore_OBLW_365",
    output_form    = PlanckOutput(),

    n_hidden       = 1,
    width          = 64,
    act            = Lux.gelu,

    eta0           = 1f-2,
    eta_decay      = 0.7f0,

    t_spinup       = Day(365),

    n_ic           = 5,
    n_traj         = 100,
    n_batch        = 2,
    n_steps_inc    = 0,
)



# Define experiments
experiments = [

    # 0: n_steps = 1, n_gap = 59
    (; name = "Steps1_Gap59", n_steps_0 = 1, n_gap = 59, CONFIG...),

    # 1: n_steps = 2, n_gap = 58
    (; name = "Steps2_Gap58", n_steps_0 = 2, n_gap = 58, CONFIG...),

    # 2: n_steps = 5, n_gap = 55
    (; name = "Steps5_Gap55", n_steps_0 = 5, n_gap = 55, CONFIG...),
]