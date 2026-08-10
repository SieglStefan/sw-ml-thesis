### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_04_arch"



# Define parameters for the experiment
CONFIG = (;
    lw_target_type = :OBLW,
    
    lw_train_type  = :NeuralLW,
    zscore_name    = "zscore_OBLW_default",
    output_form    = PlanckOutput(),
    
    eta0           = 1f-2,
    eta_decay      = 0.7f0,

    n_ic           = 5,
    n_traj         = 100,
    n_batch        = 2,
    n_steps_0      = 10,
    n_steps_inc    = 0,
    n_gap          = 50,
)



# Define experiments
experiments = [

    # 0: hidden layers = 2, width = 64
    (; name = "NLW_H2_W64",  n_hidden = 2, width = 64,  CONFIG...),

    # 1: hidden layers = 3, width = 64
    (; name = "NLW_H3_W64",  n_hidden = 3, width = 64,  CONFIG...),

    # 2: hidden layers = 3, width = 128
    (; name = "NLW_H3_W128", n_hidden = 3, width = 128, CONFIG...),

    # 3: activation function: gelu
    (; name = "NLW_gelu", act = gelu, CONFIG...),
]