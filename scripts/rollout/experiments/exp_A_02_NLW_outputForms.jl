### NLW output forms experiment
###
### Questions:
###     - Does a NLW scheme outperform a CLW scheme? How does it perform?
###     - How does the choice of output form affect performance and stability?
###     - Are there any possible improvements in the chosen training parameters?



# Define experiment name
EXP = "exp_A_02_NLW_outputForms"



# Define parameters for the experiment
REF     = "OBLW_default"
SKILL   = (; max_horizon = 31,  n_traj = 52, heatmap_days = [1, 3, 7, 14, 31])
STAB    = (; max_horizon = 365, n_traj = 4,  heatmap_days = [30, 90, 180, 365])                



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


    ##### Seed 10
    ### NLW: direct output
    # 4. Skill
    (;  name            = "NLW_direct_s1000_skill",
        scheme          = "NLW_direct_s1000",
        reference       = REF,
        SKILL...
    ),
    # 5. Stability
    (;  name            = "NLW_direct_s1000_stab",
        scheme          = "NLW_direct_s1000",
        reference       = REF,
        STAB...
    ),

    ### NLW: linear output
    # 6. Skill
    (;  name            = "NLW_linear_s1000_skill",
        scheme          = "NLW_linear_s1000",
        reference       = REF,
        SKILL...
    ),
    # 7. Stability
    (;  name            = "NLW_linear_s1000_stab",
        scheme          = "NLW_linear_s1000",
        reference       = REF,
        STAB...
    ),

    ### NLW: planck output
    # 8. Skill
    (;  name            = "NLW_planck_s1000_skill",
        scheme          = "NLW_planck_s1000",
        reference       = REF,
        SKILL...
    ),
    # 9. Stability
    (;  name            = "NLW_planck_s1000_stab",
        scheme          = "NLW_planck_s1000",
        reference       = REF,
        STAB...
    ),



    ##### Seed 20
    ### NLW: direct output
    # 10. Skill
    (;  name            = "NLW_direct_s2000_skill",
        scheme          = "NLW_direct_s2000",
        reference       = REF,
        SKILL...
    ),
    # 11. Stability
    (;  name            = "NLW_direct_s2000_stab",
        scheme          = "NLW_direct_s2000",
        reference       = REF,
        STAB...
    ),

    ### NLW: linear output
    # 12. Skill
    (;  name            = "NLW_linear_s2000_skill",
        scheme          = "NLW_linear_s2000",
        reference       = REF,
        SKILL...
    ),
    # 13. Stability
    (;  name            = "NLW_linear_s2000_stab",
        scheme          = "NLW_linear_s2000",
        reference       = REF,
        STAB...
    ),

    ### NLW: planck output
    # 14. Skill
    (;  name            = "NLW_planck_s2000_skill",
        scheme          = "NLW_planck_s2000",
        reference       = REF,
        SKILL...
    ),
    # 15. Stability
    (;  name            = "NLW_planck_s2000_stab",
        scheme          = "NLW_planck_s2000",
        reference       = REF,
        STAB...
    ),
]



