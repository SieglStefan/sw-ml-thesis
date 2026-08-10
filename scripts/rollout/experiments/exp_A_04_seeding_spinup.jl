### NLW seeding experiment
###
### Questions:
###     - How important is the initial seed of the neural network for the performance of the NLW scheme?



# Define experiment name
EXP = "exp_A_04_seeding_spinup"



# Define parameters for the experiment
REF     = "OBLW_spinup_365"
SKILL   = (; max_horizon = 31,  n_traj = 52, heatmap_days = [1, 3, 7, 14, 31])
STAB    = (; max_horizon = 365, n_traj = 12,  heatmap_days = [30, 90, 180, 365])   



# Define experiments
experiments = [
    
    # 0: OneBandLongwave (sanity test, should lead to zero rmse, bias,...)
    (;  name            = "OBLW_skill",
        scheme          = :OBLW,
        reference       = REF,
        SKILL...
    ),

    # 1: NLW_direct for comparison
    (;  name            = "NLW_direct_skill",
        scheme          = "NLW_direct",
        reference       = REF,
        SKILL...
    ),
    
    # 2: NLW_linear for comparison
    (;  name            = "NLW_linear_skill",
        scheme          = "NLW_linear",
        reference       = REF,
        SKILL...
    ),


    # 3: Seed 1
    (;  name            = "NLW_seed1_skill",
        scheme          = "NLW_seed1",
        reference       = REF,
        SKILL...
    ),

    # 4: Seed 2
    (;  name            = "NLW_seed2_skill",
        scheme          = "NLW_seed2",
        reference       = REF,
        SKILL...
    ),

    # 5: Seed 3
    (;  name            = "NLW_seed3_skill",
        scheme          = "NLW_seed3",
        reference       = REF,
        SKILL...
    ),

]