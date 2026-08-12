### tests/test_rnn.jl
###
### Standalone check of the VerticalRNN architecture, in three stages:
###   1. the network alone            (seconds)      — forward pass + Enzyme gradient
###   2. the scheme inside SpeedyWeather (minutes)   — real timesteps, no autodiff
###   3. the full training path       (~1h compile)  — Enzyme through time_step!
###
### Run with:  julia --project=. tests/test_rnn.jl

using NeuralParam
using SpeedyWeather
using Lux
using Enzyme
using Random
using Dates


### Shared setup
TRUNC   = 31
NLAYERS = 8
ZSCORE  = "zscore_OBLW_365"
SPEC    = input_spec(:T, :sst, :lst, :lf, :lat, :p)

SG = SpectralGrid(trunc = TRUNC, nlayers = NLAYERS)

ARCH = RNNConfig(width = 16, act = Lux.gelu)





#############################################################
### STAGE 1 — the network alone
#############################################################

@info "STAGE 1: bare network"

n_in  = NeuralParam.n_inputs(SPEC, NLAYERS)
n_out = NLAYERS + 2

nn, ps, st = NeuralParam.setup_arch(ARCH, n_in, n_out, Random.Xoshiro(0);
                                    input_spec = SPEC, nlayers = NLAYERS)

@info "sizes" n_in n_out params = Lux.parameterlength(nn)


# Forward pass
X = randn(Float32, n_in)
Y, _ = Lux.apply(nn, X, ps, st)

@assert length(Y) == n_out          "Y has length $(length(Y)), expected $n_out"
@assert eltype(Y) == Float32        "Y has eltype $(eltype(Y)) — something promoted to Float64"
@assert all(isfinite, Y)            "Y contains non-finite entries"

@info "forward pass ok" Y


# Enzyme gradient through the recurrence only
f(nn, X, ps, st) = sum(first(Lux.apply(nn, X, ps, st)))

dps = Enzyme.make_zero(ps)

@info "differentiating the network (first call compiles)..."
@time Enzyme.autodiff(
    Enzyme.Reverse, f, Enzyme.Active,
    Enzyme.Const(nn), Enzyme.Const(X),
    Enzyme.Duplicated(ps, dps), Enzyme.Const(st),
)

g = NeuralParam.tree_l2norm(dps)
@assert isfinite(g) && g > 0        "gradient is zero or non-finite: |g| = $g"

# Every sub-layer must receive gradient — a zero here means a disconnected path
for k in keys(dps)
    gk = NeuralParam.tree_l2norm(dps[k])
    @assert isfinite(gk) && gk > 0  "sub-layer :$k received no gradient — check its wiring"
    println("    :$k  |g| = $gk")
end

@info "STAGE 1 passed" total_grad_norm = g





#############################################################
### STAGE 2 — the scheme inside SpeedyWeather (no autodiff)
#############################################################

@info "STAGE 2: scheme inside SpeedyWeather"

lw_rnn = NeuralLW(
    spectral_grid = SG;
    arch_config   = ARCH,
    input_spec    = SPEC,
    output_form   = DirectOutput(),
    zscore_name   = ZSCORE,
)

@info "scheme built" info_scheme(lw_rnn)...

model = PrimitiveWetModel(SG; longwave_radiation = lw_rnn)
sim   = first_steps!(SpeedyWeather.initialize!(model))

sim_timesteps!(sim, 10)

T = SpeedyWeather.get_step(sim.variables.grid.temperature)
olw  = sim.variables.parameterizations.outgoing_longwave
slwd = sim.variables.parameterizations.surface_longwave_down

@assert all(isfinite, T)     "temperature went non-finite after 10 steps"
@assert all(isfinite, olw)   "olw non-finite"
@assert all(isfinite, slwd)  "slwd non-finite"
@assert !all(iszero, olw)    "olw is all zeros — write_lw! never ran?"

@info "STAGE 2 passed" T_range = extrema(T) olw_range = extrema(olw) slwd_range = extrema(slwd)





#############################################################
### STAGE 3 — full training path (SLOW: ~1h Enzyme compile)
#############################################################

@info "STAGE 3: full training path — expect a long Enzyme compile"

tc = TrainConfig(
    seed        = 1000,
    name        = "TEST_RNN",
    dir         = mktempdir(),

    model       = PrimitiveWetModel,
    lw_target   = build_scheme(:OBLW, SG),
    loss_config = LossConfig(spectral_grid = SG, zscore_name = ZSCORE),

    eta0        = 1f-2,
    t_spinup    = Day(1),

    n_ic        = 1,
    n_traj      = 2,
    n_batch     = 1,
    n_steps_0   = 2,
    n_steps_inc = 0,
    n_gap       = 2,
)

@time lw_trained = fetch(schedule(Task(() -> run_training(SG, lw_rnn, tc), 1<<29)))

@assert lw_trained isa NeuralLW
@assert NeuralParam.tree_l2norm(lw_trained.ps) > 0

@info "STAGE 3 passed — RNN trains end to end"