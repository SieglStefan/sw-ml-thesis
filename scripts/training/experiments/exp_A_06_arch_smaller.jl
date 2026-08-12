### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_06_arch_smaller"



# Define parameters for the experiment
CONFIG = (;
    lw_target_type = :OBLW,
    seed           = 1000,

    lw_train_type  = :NeuralLW,
    zscore_name    = "zscore_OBLW_365",
    output_form    = PlanckOutput(),

    act = Lux.gelu,
    
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

    # 0: hidden layers = 1, width = 16
    (; name = "NLW_H1_W16", n_hidden = 1, width = 16, CONFIG...),

    # 1: hidden layers = 1, width = 32
    (; name = "NLW_H1_W32", n_hidden = 1, width = 32, CONFIG...),

    # 2: hidden layers = 1, width = 64
    (; name = "NLW_H1_W64", n_hidden = 1, width = 64, CONFIG...),

    # 3: hidden layers = 1, width = 128
    (; name = "NLW_H1_W128", n_hidden = 1, width = 128, CONFIG...), 
]