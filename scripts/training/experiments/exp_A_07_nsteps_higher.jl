### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_07_nsteps_higher"



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

    # 0: n_steps = 15, n_gap = 45
    (; name = "Steps15_Gap45", n_steps_0 = 15, n_gap = 45, CONFIG...),

    # 1: n_steps = 20, n_gap = 40
    (; name = "Steps20_Gap40", n_steps_0 = 20, n_gap = 40, CONFIG...),

    # 2: n_steps = 25, n_gap = 35
    (; name = "Steps25_Gap35", n_steps_0 = 25, n_gap = 35, CONFIG...),

    # 3: n_steps = 30, n_gap = 30
    (; name = "Steps30_Gap30", n_steps_0 = 30, n_gap = 30, CONFIG...),
]