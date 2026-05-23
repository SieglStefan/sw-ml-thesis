### Functions for computing gradients for the LinearLongwave and NeuralLinearLongwave parameterization



# Helper function for extracting gradients from a LinearLongwave parameterization
extract_gradients(::LinearLongwave, bmodel_rad) = (;a = bmodel_rad.longwave_radiation.a,
                                                    b = bmodel_rad.longwave_radiation.b)


# Helper function for extracting gradients from a NeuralLinearLongwave parameterization
extract_gradients(::NeuralLinearLongwave, bmodel_rad) = bmodel_rad.longwave_radiation.ps



# Function for computing gradients with Enzyme.autodiff.
    # vars0:        initial variables, point where the gradient is calculated
    # sim_target:   propagated simulation with normal parameterization, only used for seeding (loss function)
    # sim_train:             -//-         with to be trained parameterization,            -//-                
function compute_gradients(vars0, sim_target, sim_train, dt)

    # Extract temperature fields of target and training simulation
    T_target = sim_target.variables.grid.temperature
    T_train = sim_train.variables.grid.temperature
    N = length(T_train)


    # Copy initial variables, so they do not get changed by timestep!()
    vars_ad = deepcopy(vars0)

    # Create variables gradients container and seed MSE
    bvars_ad = make_zero(vars_ad)
    bvars_ad.grid.temperature .= 2 .* (T_train .- T_target) ./ N

    # Create model gradients container and seed 0
    model_ad = deepcopy(sim_train.model)
    bmodel_ad = make_zero(model_ad)

    # Differentiate timestep!() in reverse mode
    Enzyme.autodiff(Reverse,
                    SpeedyWeather.timestep!, 
                    Const,                                 
                    Duplicated(vars_ad, bvars_ad),         
                    Const(dt),                            # timestep does not change
                    Duplicated(model_ad, bmodel_ad))      
       

    # Extract gradients
    grads = extract_gradients(model_ad.longwave_radiation, bmodel_ad)  
    
    # Calculate RMSE loss
    L = rmse(T_train, T_target)

    return L, grads
end


