###
###
###



EXP = "exp_TEST"

experiments = [

    # 0: Test variant for quick testing
    (;  name            = "TEST_ROLLOUT",
        scheme          = "TEST_QUICK_NLW",
        reference       = "TEST_REFERENCE",
        max_horizon     = 5,
        n_traj          = 2,
        rollout_t       = 5,
        heatmap_days    = [0,1],
        heatmap_traj    = 1,
    ),
]