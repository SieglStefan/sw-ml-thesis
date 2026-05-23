### Utility functions for handling simulations (creating, propagating, copying, pullback-ing,...)



# Function for creating the template simulation, which is later copied (faster then intializing again) and extracting timestepping
function create_template(spectral_grid)

    # Create template model and simulation
    model_template = PrimitiveWetModel(; spectral_grid)
    sim_template = initialize!(model_template)

    # Extract time stepping
    (; Δt, Δt_millisec) = model_template.time_stepping
    dt = 2Δt

    return sim_template, dt
end



# 
function propagate_reference!(sim_ref, n_gap)
    for _ in 1:n_gap
        SpeedyWeather.later_timestep!(sim_ref)
    end

    return nothing
end









# Function for creating, perturbing and spinup-ing the target and training simulation
function create_sim_pair(spectral_grid, sim_template; radiation, t_spinup)

    # Copy template simulation
    sim_pert = deepcopy(sim_template)

    # Perturbate the prepared simulation and spinup
    perturb_grid_temp!(sim_pert)
    run!(sim_pert, period=Hour(t_spinup))

    # Create the target simulation by copying the perturbated simulation
    sim_target = deepcopy(sim_pert)

    # Create the training model and create training simulation by copying
    model_train = PrimitiveWetModel(; spectral_grid, longwave_radiation = radiation)
    sim_train = initialize!(model_train)
    copy!(sim_train.variables, sim_pert.variables)

    return sim_target, sim_train
end


# Function for pullback-ing the target and training simulation to the reference simulation
function sim_pair_pullback!(sim_ref, sim_target, sim_train)

    # Pull the target and trianing simulation back onto the reference simulation
    vars0 = deepcopy(sim_ref.variables)
    copy!(sim_target.variables, vars0)
    copy!(sim_train.variables, vars0)

    return vars0
end


# Function for propagating the target and training simulation to obtain timestep! output variables needed for autodiff-seeding
function sim_pair_timestep!(sim_target, sim_train, dt)

    # Propagate the target simulation
    SpeedyWeather.timestep!(sim_target.variables, dt, sim_target.model)

    # Propagate the training simulation
    SpeedyWeather.timestep!(sim_train.variables, dt, sim_train.model)

    return nothing
end




