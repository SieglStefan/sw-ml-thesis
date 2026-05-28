### Test file for crashing Julia REPL
###
### Important: First run setup.jl: experiments/setup.jl
### Uses Lux.apply() in SpeedyWeather.parameterization!() (parameterizations/neural_llw.jl)
### Crahes REPL after about ~ 1 hour




using SpeedyWeather

spectral_grid = SpectralGrid(trunc=31, nlayers=4)

config = NeuralLinearLongwaveConfig(
    width = 4,
    n_hidden = 1,
)

radiation_nllw = NeuralLinearLongwave(spectral_grid; config)


L, P, G, PN, GN = run_training!(radiation_nllw, 
                        spectral_grid;
                        eta0 = 1f-3,

                        n_ic = 1,              
                        n_traj = 1,
                        n_epochs = 1,
                        n_gap = 1,
                        n_steps = 1,

                        printing_ic = true,
                        printing_traj = true,
                        printing_epochs = true,

                        test_mode = false)


plot_training(L, P, G, PN, GN)