### Initial-condition perturbation utilities
###
### Helper functions for perturbing simulation variables, mainly used for
### IC sampling in scripts and online optimization.



# Perturb the grid temperature field of a simulation with white noise
function perturb_grid_temp!(sim; amp = 2.0, rng = Random.default_rng())

    # Initialize simulation if needed; otherwise grid variables may be empty
    initialize!(sim)

    # Copy grid temperature field and add white noise
    T_grid = copy(sim.variables.grid.temperature)
    noise = randn!(rng, similar(T_grid))

    T_grid .+= amp .* noise

    # Use set! so that prognostic variables are updated consistently
    set!(sim, temperature = T_grid)
    initialize!(sim)

    return nothing
end