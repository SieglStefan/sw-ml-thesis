### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_06_arch_smaller"



# Define parameters for the experiment
REF     = "OBLW_spinup_365"
SKILL   = (; max_horizon = 31,  n_traj = 52, heatmap_days = [1, 3, 7, 14, 31])
STAB    = (; max_horizon = 365, n_traj = 12, heatmap_days = [30, 90, 180, 365])   



# Define experiments
experiments = [
    
    ### OneBandLongwave (sanity test, should lead to zero rmse, bias,...)
    # 0. Skill
    (;  name            = "OBLW_skill",
        scheme          = :OBLW,
        reference       = REF,
        SKILL...
    ),
    # 1. Stability
    (;  name            = "OBLW_stab",
        scheme          = :OBLW,
        reference       = REF,
        STAB...
    ),


    ### hidden layers = 1, width = 16
    # 2. Skill
    (;  name            = "NLW_H1_W16_skill",
        scheme          = "NLW_H1_W16",
        reference       = REF,
        SKILL...
    ),
    # 3. Stability
    (;  name            = "NLW_H1_W16_stab",
        scheme          = "NLW_H1_W16",
        reference       = REF,
        STAB...
    ),

    ### hidden layers = 1, width = 32
    # 4. Skill
    (;  name            = "NLW_H1_W32_skill",
        scheme          = "NLW_H1_W32",
        reference       = REF,
        SKILL...
    ),
    # 5. Stability
    (;  name            = "NLW_H1_W32_stab",
        scheme          = "NLW_H1_W32",
        reference       = REF,
        STAB...
    ),

    ### hidden layers = 1, width = 64
    # 6. Skill
    (;  name            = "NLW_H1_W64_skill",
        scheme          = "NLW_H1_W64",
        reference       = REF,
        SKILL...
    ),
    # 7. Stability
    (;  name            = "NLW_H1_W64_stab",
        scheme          = "NLW_H1_W64",
        reference       = REF,
        STAB...
    ),

    ### hidden layers = 1, width = 128
    # 8. Skill
    (;  name            = "NLW_H1_W128_skill",
        scheme          = "NLW_H1_W128",
        reference       = REF,
        SKILL...
    ),
    # 9. Stability
    (;  name            = "NLW_H1_W128_stab",
        scheme          = "NLW_H1_W128",
        reference       = REF,
        STAB...
    ),
]