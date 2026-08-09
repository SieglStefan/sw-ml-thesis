### CLW output forms experiment
###
### Questions:
###     - Is a CLW scheme stable? How does it perform?
###     - How does the choice of output form affect performance and stability?
###     - Are there any possible improvements in the chosen training parameters?



# Define experiment name
EXP = "exp_A_01_CLW_outputForms"



# Define parameters for the experiment
CLW_OBLW_CONFIG = (;
    lw_target_type = :OBLW,

    lw_train_type  = :ConstLW,
    zscore_name    = "zscore_OBLW_default",

    eta0           = 1f-1,
    eta_decay      = 0.7f0,
    weight_decay   = 0f0,

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
    (; name = "CLW_direct", output_form = DirectOutput(), CLW_OBLW_CONFIG...),

    # 1: Linear output
    (; name = "CLW_linear", output_form = LinearOutput(), CLW_OBLW_CONFIG...),

    # 2: Planck output
    (; name = "CLW_planck", output_form = PlanckOutput(), CLW_OBLW_CONFIG...),

]