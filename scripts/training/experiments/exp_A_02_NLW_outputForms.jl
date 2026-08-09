### NLW output forms experiment
###
### Questions:
###     - Does a NLW scheme outperform a CLW scheme? How does it perform?
###     - How does the choice of output form affect performance and stability?
###     - Are there any possible improvements in the chosen training parameters?



# Define experiment name
EXP = "exp_A_02_NLW_outputForms"



# Define parameters for the experiment
NLW_OBLW_CONFIG = (;
    lw_target_type = :OBLW,

    lw_train_type  = :NeuralLW,
    zscore_name    = "zscore_OBLW_default",

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

    # 0: Direct output
    (; name = "NLW_direct", output_form = DirectOutput(), NLW_OBLW_CONFIG...),

    # 1: Linear output
    (; name = "NLW_linear", output_form = LinearOutput(), NLW_OBLW_CONFIG...),

    # 2: Planck output
    (; name = "NLW_planck", output_form = PlanckOutput(), NLW_OBLW_CONFIG...),

]