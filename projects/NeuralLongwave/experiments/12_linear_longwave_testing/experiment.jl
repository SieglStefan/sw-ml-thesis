using SpeedyWeather
using .NeuralLongwave
using CairoMakie

spectral_grid = SpectralGrid(trunc=42, nlayers=8)

initial_conditions = (; vordiv = RossbyHaurwitzWave(spectral_grid),
                        temp = JablonowskiTemperature(spectral_grid),
                        pres = PressureOnOrography(spectral_grid))

my_radiation = LinearLongwave(a=-4f-6, b=1f-3)

my_radiation0 = LinearLongwave(a=0., b=0.)



model_target = PrimitiveWetModel(spectral_grid; initial_conditions)

model_llw = PrimitiveWetModel(spectral_grid; initial_conditions, longwave_radiation = my_radiation)

model_baseline = PrimitiveWetModel(spectral_grid; initial_conditions, longwave_radiation = my_radiation0)



sim_target = initialize!(model_target)
sim_llw = initialize!(model_llw)
sim_baseline = initialize!(model_baseline)



run!(sim_target, period=Day(3))
run!(sim_llw, period=Day(3))
run!(sim_baseline, period=Day(3))


T_target = sim_target.variables.grid.temperature[:,4]
T_llw = sim_llw.variables.grid.temperature[:,4]
T_baseline= sim_baseline.variables.grid.temperature[:,4]


cmin = min(minimum(T_target), minimum(T_llw), minimum(T_baseline))
cmax = max(maximum(T_target), maximum(T_llw), maximum(T_baseline))

crange = (cmin, cmax)

display(heatmap(T_target,   title = "target (with Rossby)",   colorrange = crange))
display(heatmap(T_llw,      title = "llw (with Rossby)",      colorrange = crange))
display(heatmap(T_baseline, title = "baseline (with Rossby)", colorrange = crange))

println(MSE(T_target, T_llw))
println(MSE(T_target, T_baseline))



