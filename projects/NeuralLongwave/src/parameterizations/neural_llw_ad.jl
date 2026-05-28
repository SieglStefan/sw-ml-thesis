### AD-safe NeuralLinearLongwave parameterization
###
### This NLLW-version is meant for Enzyme reverse-mode differentiation through SpeedyWeather.timestep!().
###
### Important:
### - Uses Lux only for architecture setup and parameter structure.
###     (Lux.apply() is not used because of data allocations)
### - Uses a out of symbolic expreesions generated forward pass to avoid local array allocations.



# NeuralLinearLongwaveAD parameterization
@kwdef mutable struct NeuralLinearLongwaveAD{M,P,S,C,N,W,H} <: AbstractNeuralLinearLongwave
    nn::M               # neural network (Lux)
    ps::P               # parameters of the NN (Lux)
    st::S               # state of the NN (Lux)
    config::C           # configuration of the NN
end


# Constructor: creates an online-trainable NLLW parameterization
function NeuralLinearLongwaveAD(
    SG::SpeedyWeather.SpectralGrid;
    config = NeuralLinearLongwaveConfig(),
    rng = Random.default_rng()
)

    # For now, only tanh activation is supported
    if config.activation != :tanh
        error("NeuralLinearLongwaveAD currently only supports activation = :tanh")
    end

    # Architecture parameters as compile-time type parameters
    N = SG.nlayers
    W = config.width
    H = config.n_hidden

    # Build Lux model and Lux parameter structure
    nn, ps, st = build_neural_linear_longwave_nn(SG, config, rng)

    return NeuralLinearLongwaveAD{typeof(nn), typeof(ps), typeof(st), typeof(config), N, W, H}(;
        nn,
        ps,
        st,
        config,
    )
end



# Initializing function for SpeedyWeather which does nothing (nothing is needed here yet)
function SpeedyWeather.initialize!(::NeuralLinearLongwaveAD, ::SpeedyWeather.PrimitiveWetModel)
    return nothing
end


# SpeedyWeather parameterization wrapper function for updating temperature tendencies using generated_nllw_tendency!()
Base.@propagate_inbounds function SpeedyWeather.parameterization!(
    ij,
    vars::SpeedyWeather.Variables,
    para::NeuralLinearLongwaveAD{M,P,S,C,N,W,H},
    model::SpeedyWeather.PrimitiveWetModel,
) where {M,P,S,C,N,W,H}

    # No array allocation here!
    generated_nllw_tendency!(
        ij,
        vars,
        para.ps,
        para.config,
        Val(N),
        Val(W),
        Val(H),
    )

    return nothing
end


# Function for updating NLLW tendencies using a generated scalar forward pass
# 
# Important:
# - @generated builds Julia code from symbolic expressions.
# - N, W, H must be known at compile time, so the function can generate
#   the scalar NN forward pass for the given architecture.
# - Allocates no local arrays in parameterization!().
@generated function generated_nllw_tendency!(
    ij,
    vars,
    ps,
    config,
    ::Val{N},       # number of vertical layers in the used SpectralGrid
    ::Val{W},       # NN layer width (number of neurons per layer)
    ::Val{H},       # NN number of hidden layers
) where {N,W,H}

    # Container for all symbolic expressions generated
    lines = Expr[]

    # Helper functions for getting ps fields, 
    layer(i) = :(getproperty(ps, $(QuoteNode(Symbol(:layer_, i)))))                 # := ps.layer_i
    weight(i) = :(getproperty($(layer(i)), $(QuoteNode(:weight))))                  # := ps.layer_i.weight
    bias(i) = :(getproperty($(layer(i)), $(QuoteNode(:bias))))                      # := ps.layer_i.bias



    ### Scaling: unscaled T -> scaled x (zscore-transformation)

    # List of inputs T and x
    T = [Symbol(:T_, k) for k in 1:N]                                               # := T = [T_1, ...]
    x = [Symbol(:x_, k) for k in 1:N]                                               # := x = [x_1, ...]

    # Loop over vertical grid cells k
    for k in 1:N
        push!(lines, :($(T[k]) = vars.grid.temperature[ij, $k]))                    # := T[k] = vars.grid.temperature[ij,k]
        push!(lines, :($(x[k]) = ($(T[k]) - config.T_mean) / config.T_std))         # := x[k] = (T[k] - config.T_mean) / config.T_std
    end

    

    ### Input layer: input N -> hidden W

    # List of input neurons
    prev = [Symbol(:h0_, j) for j in 1:W]

    # Loop over neurons j
    for j in 1:W            
        expr = :($(bias(1))[$j])                                                    # := expr = ps.layer_1.bias[j] 

        # Loop over inputs i of neuron j
        for i in 1:N
            expr = :($expr + $(weight(1))[$j, $i] * $(x[i]))                        # := expr = expr + ps.layer_1.weight[j,i] * x[i]
        end

        push!(lines, :($(prev[j]) = tanh($expr)))                                   # := h0_j = tanh(expr)
    end



    ### Hidden layers: hidden W -> hidden W, repeated H times

    # Loop over hidden layers l
    for l in 1:H
        layer_index = l + 1                                     
        curr = [Symbol(:h, l, :_, j) for j in 1:W]                                  # := curr = [hl_1, ...]

        # Loop over neurons j
        for j in 1:W
            expr = :($(bias(layer_index))[$j])                                      # := expr = bias(layer_index)[j]

            # Loop over inputs i of neuron j
            for i in 1:W
                expr = :($expr + $(weight(layer_index))[$j, $i] * $(prev[i]))       # := expr = expr + ps.layer_(layer_index)[j,i] * h(layer_index-1)[i]
            end

            push!(lines, :($(curr[j]) = tanh($expr)))                               # := curr[j] = tanh(expr)
        end

        # Set the previous layer to the current one for new hidden layers loop
        prev = curr                                                                 
    end 



    ### Output layer: hidden W -> output 2*N

    # List of output layers
    output_layer = H + 2
    y = [Symbol(:y_, j) for j in 1:(2N)]                                            # := y = [y_1, ...]

    # Loop over output neurons j
    for j in 1:(2N)
        expr = :($(bias(output_layer))[$j])                                         # := expr = bias(output_layer)[j]

        # Loop over hidden inputs i of neuron j
        for i in 1:W
            expr = :($expr + $(weight(output_layer))[$j, $i] * $(prev[i]))          # := expr = expr + ps.layer_output_layer[j,i] * h(output_layer-1)[i]
        end

        push!(lines, :($(y[j]) = $expr))                                            # := y[j] = expr
    end



    ### Unscale and update tendencies: 

    # Loop over vertical grid cells k
    for k in 1:N
        y_a = y[2k - 1]                   # y[2k-1] = unscaled a-output for layer k
        y_b = y[2k]                       # y[2k]   = unscaled b-output for layer k

        push!(
            # Scale a (a = sc_a * y_a) and b and update tendencies: dT = a * T + b
            lines,
            :(
                vars.tendencies.grid.temperature[ij, $k] +=                         # := vars.tendencies.grid.temperature[ij,k] +=
                    (config.sc_a * $y_a) * $(T[k]) + config.sc_b * $y_b             #   (config.sc_a * y_a) * T[k] + config.sc_b * y_b
            )
        )
    end

    

    # Function should return nothing (inplace)
    push!(lines, :(return nothing))

    # Return executable function build out of lines
    return Expr(:block, lines...)
end


