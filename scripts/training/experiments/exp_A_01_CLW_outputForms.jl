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

    eta0           = 1f-1,
    eta_decay      = 0.7f0,
    weight_decay   = 0f0,
)



# Define experiments
experiments = [

    # 0: Direct output, seed = 10
    (; name = "CLW_direct_s1000", output_form = DirectOutput(), seed = 1000, CLW_OBLW_CONFIG...),

    # 1: Linear output, seed = 10
    (; name = "CLW_linear_s1000", output_form = LinearOutput(), seed = 1000, CLW_OBLW_CONFIG...),

    # 2: Planck output, seed = 10
    (; name = "CLW_planck_s1000", output_form = PlanckOutput(), seed = 1000, CLW_OBLW_CONFIG...),


    # 3: Direct output, seed = 20
    (; name = "CLW_direct_s2000", output_form = DirectOutput(), seed = 2000, CLW_OBLW_CONFIG...),

    # 4: Linear output, seed = 20
    (; name = "CLW_linear_s2000", output_form = LinearOutput(), seed = 2000, CLW_OBLW_CONFIG...),

    # 5: Planck output, seed = 20
    (; name = "CLW_planck_s2000", output_form = PlanckOutput(), seed = 2000, CLW_OBLW_CONFIG...),

]