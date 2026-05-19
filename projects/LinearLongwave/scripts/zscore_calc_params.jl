### Script for calculating the mean and standard-deviation for global temperature fields for zscore-transformation for NN inputs

using SpeedyWeather 
using Statistics, Random
using CairoMakie

# Include function for perturbing temperature fields
include(joinpath(@__DIR__, "..", "src", "utils", "perturb_IC.jl"))

# Define parameters for simulation
const TRUNC = 31            # spectral grid truncation
const NLAYERS = 4           # number of vertical layers

const TSPINUP = 24*2        # time of spinup after IC pertubation in hours
const N_GAP = 10             # number of timesteps done between sampling

const N_IC = 1              # number of sampled ICs
const N_STEPS = 100         # number sampled steps after spinup per IC

const AMP = 2.              # amplitude of temperature pertubation



# Define spectral grid and model
spectral_grid = SpectralGrid(trunc=TRUNC, nlayers=NLAYERS)
model = PrimitiveWetModel(spectral_grid)

# Extract timestepping
(; Δt_sec) = model.time_stepping

# Print information
println("Time after random IC (Days): ", (TSPINUP + Δt_sec*N_STEPS / 3600) / 24)
println("Total number of temperature fields: ", N_IC * N_STEPS)
println("Time between sampling: ", N_GAP * Δt_sec)

# Declare temperature fields container
Ts = Float32[]



# Main loop: Define a simulation, perturb temperature, run spinup
for i in 1:N_IC

    # Initialize simulation (without that, variables.grid is not updated and therefore empty)
    sim = initialize!(model)
    
    # Perturbate temperature field
    perturb_grid_temp!(sim, amp=AMP)

    # Run model
    run!(sim, period=Hour(TSPINUP))

    # Propagate a certain IC and sample temperature fields
    for j in 1:N_STEPS-1

        # Propagate simulation and store temperatures
        run!(sim, period=Second(N_GAP*Δt_sec))
        append!(Ts, vec(sim.variables.grid.temperature))

    end

end



# Calculate T_mean and T_std 
T_mean = mean(Ts)
T_std = std(Ts)

# Print
println("T_mean: ", T_mean)
println("T_std: ", T_std)
