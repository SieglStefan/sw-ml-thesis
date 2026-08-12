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

    eta0           = 1f-2,
    eta_decay      = 0.7f0,
)



# Define experiments
experiments = [

    # 0: Direct output, seed = 1000
    (; name = "NLW_direct_s1000", output_form = DirectOutput(), seed = 1000, NLW_OBLW_CONFIG...),

    # 1: Linear output, seed = 1000
    (; name = "NLW_linear_s1000", output_form = LinearOutput(), seed = 1000, NLW_OBLW_CONFIG...),

    # 2: Planck output, seed = 1000
    (; name = "NLW_planck_s1000", output_form = PlanckOutput(), seed = 1000, NLW_OBLW_CONFIG...),


    # 3: Direct output, seed = 2000
    (; name = "NLW_direct_s2000", output_form = DirectOutput(), seed = 2000, NLW_OBLW_CONFIG...),

    # 4: Linear output, seed = 2000
    (; name = "NLW_linear_s2000", output_form = LinearOutput(), seed = 2000, NLW_OBLW_CONFIG...),

    # 5: Planck output, seed = 2000
    (; name = "NLW_planck_s2000", output_form = PlanckOutput(), seed = 2000, NLW_OBLW_CONFIG...),

]