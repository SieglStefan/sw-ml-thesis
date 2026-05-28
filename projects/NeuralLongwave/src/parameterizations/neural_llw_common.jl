### Shared config and helper functions for NeuralLinearLongwave parameterizations
###
### Important:
### - Both NeuralLinearLongwave and NeuralLinearLongwaveAD use the same Lux architecture.
### - NeuralLinearLongwave uses Lux.apply() in parameterization!().
### - NeuralLinearLongwaveAD uses a generated scalar forward pass in parameterization!().



# Convenience container for the parameters of a NeuralLinearLongwave NN
@kwdef struct NeuralLinearLongwaveConfig
    name::String = "default_name"           # name of model used for storing and loading
    width::Int = 32                         # number neurons per hidden layer
    n_hidden::Int = 2                       # number of hidden layers
    activation::Symbol = :tanh              # activation function
    sc_a::Float32 = 5.5f-8                  # scaling factor for a-output (calculated from calibration)
    sc_b::Float32 = 4.6f-6                  # scaling factor for b-output (-//-)
    T_mean::Float32 = 249.83f0              # mean temperature for zscore, calculated in "zscore_calc_params.jl"
    T_std::Float32 = 23.09f0                # temperature std for zscore, calculated in "zscore_calc_params.jl"
end



# Helper function for building the Lux NN architecture and parameters
function build_neural_linear_longwave_nn(
    SG::SpeedyWeather.SpectralGrid,
    config::NeuralLinearLongwaveConfig,
    rng = Random.default_rng(),
)
    # Extract spectral grid parameters
    n_in = SG.nlayers
    n_out = 2n_in

    # Extract NN parameters
    width = config.width
    n_hidden = config.n_hidden

    # Choose activation function
    if config.activation == :tanh
        act = tanh
    else
        @warn "Activation function not defined! tanh is used"
        act = tanh
    end

    # Create hidden layers and NN
    hidden = [Lux.Dense(width => width, act) for _ in 1:n_hidden]

    nn = Lux.Chain(
        Lux.Dense(n_in => width, act),
        hidden...,
        Lux.Dense(width => n_out),
    )

    # Setup NN
    ps, st = Lux.setup(rng, nn)
    st = Lux.testmode(st)

    return nn, ps, st
end