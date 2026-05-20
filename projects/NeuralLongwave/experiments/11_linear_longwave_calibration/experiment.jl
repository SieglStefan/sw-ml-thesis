### Experiment
    # XXX
    # XXX
    # XXX

include("setup.jl")

using SpeedyWeather
using .NeuralLongwave

spectral_grid = SpectralGrid(trunc=31, nlayers=4)
radiation_llw = LinearLongwave()

L, a, b = run_calibration!(radiation_llw; spectral_grid,
                            eta = 1f-8,            
                            n_ic = 10,              
                            n_steps = 20,        
                            n_gap = 100,
                            printing_step = false)


plot_calibration(L, a, b)
