module NeuralLongwave

using SpeedyWeather
using Lux
using Optimisers
using Enzyme

using Random
using JLD2
using Plots



# General utils
include("utils/utils.jl")
include("utils/metrics.jl")
include("utils/plotting.jl")
include("utils/perturb_vars.jl")


# Structs / Parameterizations
include("parameterizations/linear_longwave.jl")
include("parameterizations/neural_linear_longwave.jl")

# IO
include("utils/io.jl")


# Training infrastructure
include("training/simulation_pair.jl")
include("training/gradients.jl")
include("training/run_calibration.jl")
include("training/run_training.jl")


end