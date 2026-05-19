### Utility functions for pertubing ICs of simulations


# Function for pertubing the grid temperature field of an simulation for IC sampling using white noise
function perturb_grid_temp!(sim; A=1., rng=Random.default_rng())

    # Copy the grid temperature field
    T_grid = copy(sim.variables.grid.temperature)

    # Create white noise
    noise = randn!(rng, similar(T_grid))

    # Add noise to the grid temperature field
    T_grid .+= A .* noise

    # Assigning the perturbated field to the simulation and initialize it (without initialize!, sim.prognostic is not actualized)
    set!(sim, temperature = T_grid)
    initialize!(sim)

    return nothing
end