### NLW seeding experiment
###
### Questions:
###     - Are other architectures better at learning the NLW scheme than the default MLP architecture?



# Define experiment name
EXP = "exp_A_08_nsteps_smaller"



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


    ### n_steps = 1, n_gap = 59
    # 2. Skill
    (;  name            = "Steps1_Gap59_skill",
        scheme          = "Steps1_Gap59",
        reference       = REF,
        SKILL...
    ),
    # 3. Stability
    (;  name            = "Steps1_Gap59_stab",
        scheme          = "Steps1_Gap59",
        reference       = REF,
        STAB...
    ),

    ### n_steps = 2, n_gap = 58
    # 4. Skill
    (;  name            = "Steps2_Gap58_skill",
        scheme          = "Steps2_Gap58",
        reference       = REF,
        SKILL...
    ),
    # 5. Stability
    (;  name            = "Steps2_Gap58_stab",
        scheme          = "Steps2_Gap58",
        reference       = REF,
        STAB...
    ),

    ### n_steps = 5, n_gap = 55
    # 6. Skill
    (;  name            = "Steps5_Gap55_skill",
        scheme          = "Steps5_Gap55",
        reference       = REF,
        SKILL...
    ),
    # 7. Stability
    (;  name            = "Steps5_Gap55_stab",
        scheme          = "Steps5_Gap55",
        reference       = REF,
        STAB...
    ),
]