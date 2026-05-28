### Abstract types for LinearLongwave parameterizations


# Common supertype for all linear longwave schemes of the form dT = a*T + b
abstract type AbstractLinearLongwave <: SpeedyWeather.AbstractLongwave end

# Common supertype for neural versions where a and b are predicted by a NN
abstract type AbstractNeuralLinearLongwave <: AbstractLinearLongwave end