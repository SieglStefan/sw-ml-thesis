### Functions for benchmark evaluation
###
### Two measurements:
###   - evaluate_benchmark: cost of a full timestep with that scheme (dynamics included)
###   - benchmark_scheme:   cost of the parameterization sweep alone (the scheme itself)
###
### Prefer benchmark_scheme for COMPARING schemes: the LW parameterization is only a few percent
### of a timestep, so differencing two whole-timestep timings buries the signal in machine noise.



# Cost of one full timestep with a given scheme
function evaluate_benchmark(
    scheme;
    spectral_grid,
    model = PrimitiveWetModel,
    n_steps = 10,
    samples = 20,
)

    # Initialize simulation and do the first timesteps
    sim = initialize!(model(spectral_grid; longwave_radiation = scheme))
    first_steps!(sim; planned_steps = n_steps + 1)

    # Fresh simulation per sample: sim_timesteps! mutates, so samples must not chain
    b = @benchmark sim_timesteps!(s, $n_steps) setup=(s = deepcopy($sim)) evals=1 samples=samples seconds=60

    return (;
        time_ms = minimum(b).time / n_steps / 1e6,              # ns -> ms
        med_ms  = Statistics.median(b).time / n_steps / 1e6,
        kb      = minimum(b).memory / n_steps / 1024,           # bytes -> KB
        allocs  = minimum(b).allocs / n_steps,
    )
end


# Cost of the parameterization sweep alone: one call per grid column
function benchmark_scheme(
    scheme;
    spectral_grid,
    model = PrimitiveWetModel,
    samples = 100,
)

    # Initialize simulation so the variables are filled
    sim = initialize!(model(spectral_grid; longwave_radiation = scheme))
    first_steps!(sim; planned_steps = 2)

    # Extract what the parameterization needs and the number of grid columns
    vars, m = sim.variables, sim.model
    npoints = length(vars.parameterizations.outgoing_longwave)

    # One sample = one sweep over all columns
    b = @benchmark (for ij in 1:$npoints
                        SpeedyWeather.parameterization!(ij, $vars, $scheme, $m)
                    end) evals=1 samples=samples

    return (;
        time_ms = minimum(b).time / 1e6,
        med_ms  = Statistics.median(b).time / 1e6,
        kb      = minimum(b).memory / 1024,
        allocs  = minimum(b).allocs,
    )
end


# Wrappers for a list (NamedTuple) of schemes
evaluate_benchmark(schemes::NamedTuple; kwargs...) = map(s -> evaluate_benchmark(s; kwargs...), schemes)
benchmark_scheme(schemes::NamedTuple;   kwargs...) = map(s -> benchmark_scheme(s;   kwargs...), schemes)


# Print benchmark results as a table, one row per scheme
#   - med/min well above 1 means the machine was busy during the run: rerun it
function print_benchmark(results::NamedTuple; baseline = first(keys(results)), unit = "step")

    base = results[baseline].time_ms

    println(rpad("scheme", 22), lpad("ms/$unit", 11), lpad("med/min", 10),
            lpad("KB/$unit", 12), lpad("allocs", 12), lpad("rel.", 8))
    println("-"^75)

    for (name, r) in pairs(results)
        println(rpad(String(name), 22),
                lpad(round(r.time_ms, digits = 4), 11),
                lpad(round(r.med_ms / r.time_ms, digits = 2), 10),
                lpad(round(r.kb, digits = 1), 12),
                lpad(round(Int, r.allocs), 12),
                lpad(string(round(r.time_ms / base, digits = 2), "×"), 8))
    end

    return results
end