### Utility functions for creating, timestepping and pullback-ing the trainin



# Function for creating, perturbing and spinup-ing the target and training simulation
function create_sim_pair(spectral_grid, sim_template; radiation, spinup = 24.)

    # Copy template simulation
    sim_pert = deepcopy(sim_template)

    # Perturbate the prepared simulation and spinup
    perturb_grid_temp!(sim_pert)
    run!(sim_pert, period=Hour(spinup))

    # Create the target simulation by copying the perturbated simulation
    sim_target = deepcopy(sim_pert)

    # Create the training model and create training simulation by copying
    model_train = PrimitiveWetModel(; spectral_grid, longwave_radiation = radiation)
    sim_train = initialize!(model_train)
    copy!(sim_train.variables, sim_pert.variables)

    return sim_target, sim_train
end



# Function for propagating the target and training simulation to obtain timestep! output variables needed for autodiff-seeding
function sim_pair_timestep!(sim_target, sim_train, dt)

    # Propagate the target simulation
    SpeedyWeather.timestep!(sim_target.variables, dt, sim_target.model)

    # Propagate the training simulation
    SpeedyWeather.timestep!(sim_train.variables, dt, sim_train.model)

    return nothing
end



# Function for pullback-ing the target and training simulation to the reference simulation
function sim_pair_pullback!(sim_ref, sim_target, sim_train)

    # Pull the target and trianing simulation back onto the reference simulation
    vars0 = deepcopy(sim_ref.variables)
    copy!(sim_target.variables, vars0)
    copy!(sim_train.variables, vars0)

    return vars0
end