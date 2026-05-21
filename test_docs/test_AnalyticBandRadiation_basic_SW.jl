using SpeedyWeather, AnalyticBandRadiation
const SpeedyExt = Base.get_extension(AnalyticBandRadiation,
                                     :AnalyticBandRadiationSpeedyWeatherExt)

spectral_grid = SpectralGrid(trunc = 31, nlayers = 8)
longwave = SpeedyExt.SpeedyAnalyticBandLongwave(spectral_grid)
model = PrimitiveWetModel(spectral_grid; longwave_radiation = longwave)

sim = initialize!(model)
run!(sim)

using CairoMakie
heatmap(sim.variables.grid.temperature[:,8])