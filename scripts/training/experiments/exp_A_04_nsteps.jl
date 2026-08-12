### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_04_nsteps"



# Define parameters for the experiment
CONFIG = (;
    lw_target_type = :OBLW,
    seed           = 3000,

    lw_train_type  = :NeuralLW,

    eta0           = 1f-2,
    eta_decay      = 0.7f0,
)



# Define experiments
experiments = [

    # 0: n_steps = 1, n_gap = 59
    (; name = "Steps1_Gap59", n_steps_0 = 1, n_gap = 59, CONFIG...),

    # 1: n_steps = 2, n_gap = 58
    (; name = "Steps2_Gap58", n_steps_0 = 2, n_gap = 58, CONFIG...),

    # 2: n_steps = 5, n_gap = 55
    (; name = "Steps5_Gap55", n_steps_0 = 5, n_gap = 55, CONFIG...),


    # 3: n_steps = 15, n_gap = 45
    (; name = "Steps15_Gap45", n_steps_0 = 15, n_gap = 45, CONFIG...),

    # 4: n_steps = 20, n_gap = 40
    (; name = "Steps20_Gap40", n_steps_0 = 20, n_gap = 40, CONFIG...),

    # 5: n_steps = 30, n_gap = 30
    (; name = "Steps30_Gap30", n_steps_0 = 30, n_gap = 30, CONFIG...),

]