### NLW seeding experiment
###
### Questions:
###     - How important is the initial seed of the neural network for the performance of the NLW scheme?



# Define experiment name
EXP = "exp_A_04_seeding_spinup"



# Define parameters for the experiment
CONFIG = (;
    lw_target_type = :OBLW,
    
    lw_train_type  = :NeuralLW,
    zscore_name    = "zscore_OBLW_365",
    
    eta0           = 1f-2,
    eta_decay      = 0.7f0,

    t_spinup       = Day(365),

    n_ic           = 5,
    n_traj         = 100,
    n_batch        = 2,
    n_steps_0      = 10,
    n_steps_inc    = 0,
    n_gap          = 50,
)



# Define experiments
experiments = [

    # 0: NLW with direct output for comparison
    (; name = "NLW_direct", seed = 1000, output_form = DirectOutput(), CONFIG...),

    # 1: NLW with linear output for comparison
    (; name = "NLW_linear", seed = 1000, output_form = LinearOutput(), CONFIG...),

    # 2: NLW direct, seed 0
    (; name = "NLW_seed1",  seed = 1000, output_form = PlanckOutput(), CONFIG...),

    # 3: NLW direct, seed 1
    (; name = "NLW_seed2",  seed = 2000, output_form = PlanckOutput(), CONFIG...),

    # 4: NLW direct, seed 2
    (; name = "NLW_seed3",  seed = 3000, output_form = PlanckOutput(), CONFIG...),
]