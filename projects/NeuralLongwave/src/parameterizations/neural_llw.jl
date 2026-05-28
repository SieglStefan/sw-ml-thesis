### NeuralLinearLongwave parameterization 
###
### Lux-based LinearLongwave parameterization using (a_k, b_k) = f_NN(T_k) 
### for upgrading tendencies dTk = a_k * T_k + b_k.
###
### Important:
### - This version is meant for normal simulations / testing / inference.
### - Uses Lux.apply in parameterization!, which may allocate temporary arrays.
### - This version is NOT meant for online-trainig with Enzyme through SpeedyWeather.timestep!() .
###     - Using it in run_training! will lead to a crash (Lux.apply allocates much memory).
###     - For AD-based online training, use NeuralLinearLongwaveAD.
### - TODO Uses Reactant to speed up usage of the NN



# NeuralLinearLongwave parameterization
@kwdef mutable struct NeuralLinearLongwave{M,P,S,C} <: AbstractNeuralLinearLongwave
    nn::M               # neural network (Lux)
    ps::P               # parameters of the NN (Lux)
    st::S               # state of the NN (Lux)
    config::C           # configuration of the NN
end


# Constructor for creating Lux NN architecture and parameters
function NeuralLinearLongwave(
    SG::SpeedyWeather.SpectralGrid;
    config = NeuralLinearLongwaveConfig(),
    rng = Random.default_rng(),
)

    # Build Lux model and Lux parameter structure    
    nn, ps, st = build_neural_linear_longwave_nn(SG, config, rng)

    return NeuralLinearLongwave{typeof(nn), typeof(ps), typeof(st), typeof(config)}(;
        nn,
        ps,
        st,
        config,
    )
end



# Initializing function for SpeedyWeather which does nothing (nothing is needed here yet)
function SpeedyWeather.initialize!(::NeuralLinearLongwave, ::SpeedyWeather.AbstractModel)
    return nothing
end


# Calculate tendencies using Lux.apply.
Base.@propagate_inbounds function SpeedyWeather.parameterization!(
    ij,
    vars::SpeedyWeather.Variables,
    para::NeuralLinearLongwave,
    model::SpeedyWeather.AbstractModel,
)

    # Extract NN parameters
    (; nn, ps, st, config) = para
    nlayers = model.spectral_grid.nlayers

    # Extracting and z-score transform current column temperatures
    Tij = Float32[vars.grid.temperature[ij, k] for k in 1:nlayers]
    Tij_norm = (Tij .- config.T_mean) ./ config.T_std

    
    # Lux forward pass with Lux.apply()
    # TODO Reactant
    y, _ = Lux.apply(nn, Tij_norm, ps, st)

    # Update tendencies
    for k in 1:nlayers
        ak = config.sc_a * y[2k - 1]
        bk = config.sc_b * y[2k]

        vars.tendencies.grid.temperature[ij, k] += ak * Tij[k] + bk
    end

    return nothing
end



# Convenience constructor for converting an AD-safe NLLW into the Lux inference version
function NeuralLinearLongwave(radiation::NeuralLinearLongwaveAD)
    return NeuralLinearLongwave(;
        nn = radiation.nn,
        ps = radiation.ps,
        st = radiation.st,
        config = radiation.config,
    )
end