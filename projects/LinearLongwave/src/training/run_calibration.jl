### Functions for calibrating the LinearLongwave parameterization



# Function for performing one calibration step (Calculating gradients and updating NN)
function calibration_step!(;radiation,
                            vars0, 
                            sim_target, 
                            sim_calib,
                            dt,
                            eta,
                            step,
                            printing_step)

    # Compute gradients 
    loss, grads = compute_gradients(vars0, sim_target, sim_calib, dt)
 
    # Calculate new parameters with gradient descent 
        # (multiplication with parameters at the end = normalizing learning rate eta)
    a_new = radiation.a - eta * grads.a * radiation.a
    b_new = radiation.b - eta * grads.b * radiation.a

    # Update radiation parameter
    radiation.a = a_new
    radiation.b = b_new


    # Print information about calibration for debugging
    if printing_step
        println("Step $step, Loss=$loss, a=$a_new, b=$b_new, ba=$(grads.a), bb=$(grads.b)")
    end

    return loss, a_new, b_new
end



# Function for calibrating a LinearLongwave parameterization
function run_calibration(   radiation_llw;          # to be calibrated NeuralLinearLongwave parameterization
                            spectral_grid,          # defines truncation and number of vertical layers  
                            eta = 1f-4,             # learning rate
                            n_ic = 10,              # number of IC used
                            n_steps = 100,          # number of steps per IC used
                            n_gap = 10,             # number of timesteps between 2 calibration points
                            printing_step = true,   # if true: loss, a, b, ba, bb are printed after every calibration step
                            printing_ic = true)     # if true: loss is printed after every IC

    # Create template model and simulation
    model_template = PrimitiveWetModel(; spectral_grid)
    sim_template = initialize!(model_template)

    # Extract timestepping
    (; Δt, Δt_millisec) = model_template.time_stepping
    dt = 2Δt

    
    # Create loss and gradients containers
    L = Float32[]
    a = Float32[]
    b = Float32[]

    push!(a, radiation_llw.a)
    push!(b, radiation_llw.b)


    # Creating different IC and calibrate the radiation_llw on them
    for i in 1:n_ic

        # Build (create, copy and spinup) target and calibration simulation out of the template simulation
        sim_target, sim_calib = create_sim_pair(spectral_grid, sim_template; radiation=radiation_llw)

        # Create reference simulation (later sim_target and sim_calib are pulled back on this simulation)
        sim_ref = deepcopy(sim_target)


        # Calibration loop
        for step in 1:n_steps

            # Pull the target and training simulation on the reference simulation
            vars0 = sim_pair_pullback!(sim_ref, sim_target, sim_calib)

            # Do one timestep! for the target and training simulation needed for loss seeding
            sim_pair_timestep!(sim_target, sim_calib, dt)

            # Do one calibration step and update parameters of radiation_llw
            loss, a_new, b_new = calibration_step!(;radiation = radiation_llw,
                                                    vars0,
                                                    sim_target,
                                                    sim_calib,
                                                    dt,
                                                    eta,
                                                    step,
                                                    printing_step)

            # Store loss and gradients
            push!(L, loss)
            push!(a, a_new)
            push!(b, b_new)


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

    return L, a, b
end