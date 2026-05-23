module NeuralLongwave

using SpeedyWeather
using Lux
using Optimisers
using Enzyme

using Random
using JLD2
using Plots

export  
        # utils (without io)
        zscore,
        rmse,
        bias,
        correlation,
        plot_calibration,
        plot_loss,
        plot_rmse_diff,
        plot_bias_diff,
        plot_correlation_diff,

        # parameterizations
        LinearLongwave,
        NeuralLinearLongwaveConfig,
        NeuralLinearLongwave,

        # io
        save,
        load_neural_longwave,

        # training
        create_template,
        propagate_reference!,
        create_sim_pair,
        sim_pair_pullback!,
        sim_pair_timestep!,
        extract_parameters,
        run_online_optimization!,
        extract_gradients,
        compute_gradients,
        calibration_step!,
        run_calibration!,
        training_step!
        run_training!




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
include("training/simulation.jl")
include("training/online_optimization.jl")
include("training/gradients.jl")
include("training/run_calibration.jl")
include("training/run_training.jl")


end
