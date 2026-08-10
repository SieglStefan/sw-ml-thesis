### Abstract types for longwave parameterizations
#
# Structure:
#
# SpeedyWeather.AbstractLongwave        # longwave radiation parameterization schemes from SW
#   - AbstractLW                        # schemes from this project
#       - ConstLW                       # constant parameters scheme
#       - NeuralLW                      # neural network scheme           



# Common supertype for all longwave schemes in this project
abstract type AbstractLW <: SpeedyWeather.AbstractLongwave end






# Build an analytic scheme from its name - the ONE place that knows the recipe
build_scheme(name::Symbol, SG; kwargs...) = build_scheme(Val(name), SG; kwargs...)

build_scheme(::Val{:OBLW}, SG; em_ocean = 0.98f0, em_land = 0.98f0, kwargs...) =
    OneBandLongwave(SG;
        transmissivity     = FriersonLongwaveTransmissivity(SG),
        radiative_transfer = OneBandLongwaveRadiativeTransfer(SG;
                                emissivity_ocean = em_ocean,
                                emissivity_land  = em_land))

build_scheme(::Val{:ZeroLW}, SG; kwargs...) = ZeroLW()

build_scheme(v::Val, SG; kwargs...) = error("Unknown scheme recipe: $(typeof(v).parameters[1])")