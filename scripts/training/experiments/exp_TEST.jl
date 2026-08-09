###
###
###



# Define experiment name
EXP = "exp_TEST"



# Define experiments
experiments = [

    # 0: Test variant for quick testing ConstLW
    (;  name            = "TEST_QUICK_CLW",
        lw_train_type   = :ConstLW,
        t_spinup        = Day(1),
        n_ic            = 2,
        n_traj          = 10,
        n_batch         = 2,
        n_steps_0       = 2,
        n_steps_inc     = 1,
        n_gap           = 5,
    ),

    # 1: Test variant for quick testing NeuralLW
    (;  name            = "TEST_QUICK_NLW",
        lw_train_type   = :NeuralLW,
        t_spinup        = Day(1),
        n_ic            = 2,
        n_traj          = 10,
        n_batch         = 2,
        n_steps_0       = 2,
        n_steps_inc     = 1,
        n_gap           = 5,
    ),

    # 2: Identity test - must provide zeros in parameters and loss
    (;  name            = "TEST_IDENTITY_NLW",
        lw_train_type   = :NeuralLW,
        eta0            = 0f0,
        t_spinup        = Day(1),
        n_ic            = 2,
        n_traj          = 10,
        n_batch         = 2,
        n_steps_0       = 2,
        n_steps_inc     = 1,
        n_gap           = 5,
    ),
    
]