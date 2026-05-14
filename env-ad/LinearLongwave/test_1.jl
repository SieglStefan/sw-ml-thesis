using SpeedyWeather, CairoMakie, Random

include("LinearLongwave.jl")
include("loss_MSE.jl")



spectral_grid = SpectralGrid(trunc=63, nlayers=8)

my_radiation1 = LinearLongwave(spectral_grid; a=-1e-6, b=1e-3)
my_radiation2 = LinearLongwave(spectral_grid; a=0., b=0.)

model1 = PrimitiveDryModel(spectral_grid; longwave_radiation=my_radiation1)
model2 = PrimitiveDryModel(spectral_grid; longwave_radiation=my_radiation2)

simulation1 = initialize!(model1)
simulation2 = initialize!(model2)

#Random.seed!(123)

noise = 0.001 .* (
    randn(Float32, size(simulation1.variables.prognostic.temperature)) .+
    im * randn(Float32, size(simulation1.variables.prognostic.temperature))
)

simulation1.variables.prognostic.temperature .+= noise
simulation2.variables.prognostic.temperature .+= noise


run!(simulation1, period=Hour(1))
run!(simulation2, period=Hour(1))


temp = simulation1.variables.grid.temperature[:, 4] - simulation2.variables.grid.temperature[:, 4]
heatmap(temp, title="Temperature difference [K] at layer 4")

#loss_mse = MSE(simulation1.variables.grid.temperature, simulation2.variables.grid.temperature)