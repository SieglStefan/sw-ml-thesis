### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_03_arch"



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

    # 1: n_hidden = 1, width = 16
    (; name = "NLW_H1_W16", n_hidden = 1, width = 16, CONFIG...),

    # 2: n_hidden = 1, width = 32
    (; name = "NLW_H1_W32", n_hidden = 1, width = 32, CONFIG...),

    # 3: n_hidden = 1, width = 64
    (; name = "NLW_H1_W64", n_hidden = 1, width = 64, CONFIG...),

    # 4: n_hidden = 1, width = 128
    (; name = "NLW_H1_W128", n_hidden = 1, width = 128, CONFIG...),


    # 5: n_hidden = 2, width = 16
    (; name = "NLW_H2_W16", n_hidden = 2, width = 16, CONFIG...),

    # 6: Baseline: n_hidden = 2, width = 32, act = tanh
    (; name = "NLW_H2_W32", n_hidden = 2, width = 32, CONFIG...),

    # 7: n_hidden = 2, width = 64
    (; name = "NLW_H2_W64", n_hidden = 2, width = 64, CONFIG...),

    # 8: n_hidden = 2, width = 128
    (; name = "NLW_H2_W128", n_hidden = 2, width = 128, CONFIG...),
    


    # 9: n_hidden = 3, width = 16
    (; name = "NLW_H3_W16", n_hidden = 3, width = 16, CONFIG...),

    # 10: n_hidden = 3, width = 32
    (; name = "NLW_H3_W32", n_hidden = 3, width = 32, CONFIG...),


    # 11: Baseline, act = gelu
    (; name = "NLW_gelu", act = Lux.gelu, CONFIG...),

    # 12: Baseline, act = relu
    (; name = "NLW_relu", act = Lux.relu, CONFIG...),

]