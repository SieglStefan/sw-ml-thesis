### Functions for training the NeuralLinearLongwave parameterization



# Function for performing one training step (Calculating gradients and updating NN)
function training_step!(;radiation,
                        vars0, 
                        sim_target, 
                        sim_train,
                        dt,
                        opt_state,
                        step,
                        printing_step)

    # Compute gradients 
    loss, grads = compute_gradients(vars0, sim_target, sim_train, dt)

    # Update parameterization
    opt_state, ps_new = Optimisers.update(opt_state, radiation.ps, grads)
    radiation.ps = ps_new


    # Print information about training for debugging
    if printing_step
        println("Step $step, Loss=$loss")
        @show grads
    end

    return loss, grads, opt_state
end


# Function for training NeuralLinearLongwave parameterization online
function run_training!( radiation_nllw;                 # to be trained NeuralLinearLongwave parameterization
                        spectral_grid,                  # defines truncation and number of vertical layers
                        eta = 1f-4,                     # learning rate
                        n_ic = 10,                      # number of IC trained
                        n_steps = 100,                  # number of steps per IC trained 
                        n_gap = 10,                     # number of timesteps between 2 training points
                        printing_step = true,           # if true: loss,and grads are printed after every calibration step
                        printing_ic = true)             # if true: loss is printed after every IC

    # Create template model and simulation
    model_template = PrimitiveWetModel(; spectral_grid)
    sim_template = initialize!(model_template)

    # Extract time stepping
    (; Δt, Δt_millisec) = model_template.time_stepping
    dt = 2Δt
    

    # Create loss and gradients containers
    L = Float32[]
    G = []

    # Setup the Optimisers for training
    rule = Optimisers.Adam(eta)
    opt_state = Optimisers.setup(rule, radiation_nllw.ps)


    # Creating different IC and train the radiation_nlw on them
    for i in 1:n_ic

        # Build (create, copy and spinup) target and training simulation out of the template simulation
        sim_target, sim_train = create_sim_pair(spectral_grid, sim_template; radiation=radiation_nllw)

        # Create reference simulation (later sim_target and sim_train are pulled back on this simulation)
        sim_ref = deepcopy(sim_target)

        
        # Online training loop
        for step in 1:n_steps

            # Pull the target and training simulation on the reference simulation
            vars0 = sim_pair_pullback!(sim_ref, sim_target, sim_train)

            # Do one timestep! for the target and training simulation needed for loss seeding
            sim_pair_timestep!(sim_target, sim_train, dt)
            
            # Do one training step and update parameters of radiation_nllw
            loss, grads, opt_state = training_step!(;   radiation = radiation_nllw,
                                                        vars0, 
                                                        sim_target, 
                                                        sim_train,
                                                        dt,
                                                        opt_state,
                                                        step,
                                                        printing_step)                          

            # Store loss and gradients
            push!(L, loss)
            push!(G, deepcopy(grads))


            # Propagate reference simulation
            for _ in 1:n_gap
                SpeedyWeather.later_timestep!(sim_ref)
            end

        end

        # Prints information
        if printing_ic
            println("Initial condition Nr. $i / $n_ic finished!, current loss: $loss")
        end
    end

    return L, G
end
