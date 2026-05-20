using SpeedyWeather

spectral_grid = SpectralGrid(trunc=31, nlayers=4)
model = PrimitiveWetModel(spectral_grid)
sim = initialize!(model)

model.initial_conditions
