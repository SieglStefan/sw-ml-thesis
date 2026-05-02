# Test from SW documentation

using SpeedyWeather
spectral_grid = SpectralGrid(trunc=63, nlayers=1)
still_earth = Earth(spectral_grid, rotation=0)
initial_conditions = RandomVelocity(spectral_grid)
forcing = nothing
drag = nothing
model = BarotropicModel(spectral_grid; initial_conditions, planet=still_earth, forcing, drag)
simulation = initialize!(model)
run!(simulation, period=Day(20))