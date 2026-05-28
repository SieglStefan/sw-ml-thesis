### Constant linear longwave parameterization
###
### Simple baseline scheme of the form dT = a*T + b.
### Here, a and b are constant global calibratable parameters.



# ConstLinearLongwave parameterization
@kwdef mutable struct ConstLinearLongwave{NF} <: AbstractLinearLongwave
    a::NF = -6.3f-7                     # linear temperature coefficient
    b::NF = 1.4f-4                      # constant temperature tendency
    sc_a::Float32 = 5.5f-8              # scaling factor for gradient descent update of a
    sc_b::Float32 = 4.6f-6              # scaling factor for gradient descent update of b
end


# Convenience constructor
function ConstLinearLongwave(SG::SpeedyWeather.SpectralGrid; kwargs...)
    return ConstLinearLongwave{SG.NF}(; kwargs...)
end



# Initializing function for SpeedyWeather which does nothing (nothing is needed here yet)
function SpeedyWeather.initialize!(::ConstLinearLongwave, ::SpeedyWeather.AbstractModel)
    return nothing
end


# SpeedyWeather parameterization function for updating temperature tendencies 
Base.@propagate_inbounds function SpeedyWeather.parameterization!(
    ij,
    vars::SpeedyWeather.Variables,
    para::ConstLinearLongwave,
    model::SpeedyWeather.AbstractModel,
)

    # Loop over vertical layers and update tendencies
    for k in 1:model.spectral_grid.nlayers
        Tk = vars.grid.temperature[ij, k]
        dTk = para.a * Tk + para.b

        vars.tendencies.grid.temperature[ij, k] += dTk
    end

    return nothing
end