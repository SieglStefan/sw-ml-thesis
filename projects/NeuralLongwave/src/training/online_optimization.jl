### Functions for the main online optimization loop for training the (Neural)LinearLongwave parameterization



# Helper function for extracting parameters from a LinearLongwave parameterization
function extract_parameters(radiation::LinearLongwave)
    return (radiation.a, radiation.b)
end


# Helper function for extracting parameters from a NeuralLinearLongwave parameterization
function extract_parameters(radiation::NeuralLinearLongwave)
    return copy(radiation.ps)
end



# XXX
function run_online_optimization!(; scheme_step!,
                                    radiation,          
                                    spectral_grid,        
                                    eta,             
                                    t_spinup,     
                                    n_ic,
                                    n_updates,                
                                    n_gap,
                                    n_steps,          
                                    printing_ic,  
                                    printing_updates,
                                    opt_state)   

    
    # Create template model and simulation and extract time stepping
    sim_template, dt = create_template(spectral_grid)
    

    # Creating different IC and calibrate/train radiation on them
    for ic in 1:n_ic

        # Build (create, copy and spinup) target and training simulation out of the template simulation
        sim_target, sim_train = create_sim_pair(spectral_grid, sim_template; 
                                                radiation = radiation,
                                                t_spinup = t_spinup)

        # Create reference simulation (later sim_target and sim_train are pulled back on this simulation)
        sim_ref = deepcopy(sim_target)

        
        # Online training loop
        for step in 1:n_updates

            # Pull the target and training simulation on the reference simulation
            vars0 = sim_pair_pullback!(sim_ref, sim_target, sim_train)

            # Do one timestep! for the target and training simulation needed for loss seeding
            sim_pair_timestep!(sim_target, sim_train, dt)
            
            # Do one training step and update parameters of radiation
            loss, grads, opt_state = scheme_step!(; radiation,
                                                    vars0, 
                                                    sim_target, 
                                                    sim_train,
                                                    dt,
                                                    eta,
                                                    opt_state,
                                                    step,
                                                    printing_updates)                          

            # Store loss, parameters and gradients
            push!(L, loss)
            push!(P, extract_parameters(radiation))
            push!(G, deepcopy(grads))


            # Propagate reference simulation
            propagate_reference!(sim_ref, n_gap)

        end

        # Print information about loss for debugging#
        if printing_ic
            println("IC $ic, loss: $(L[end])")
        end
        
    end    
end