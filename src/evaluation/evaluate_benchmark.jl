### Functions for benchmark evaluation
###
### One measurement: the cost of the LW parameterization sweep — one `parameterization!` call
### per column, which is exactly the LW work done in one model timestep.
###
### Do NOT compare schemes by timing whole timesteps. The LW parameterization is a few percent
### of a step, so differencing two whole-step timings buries the signal in machine noise, and it
### costs minutes because every scheme needs its own `initialize!`.
###
### What makes the numbers reproducible across sessions:
###   - GC is off during each timed sweep. The NN schemes allocate several MB per sweep, so
###     otherwise part of what is timed is collection work, whose cost depends on how big the
###     session's live heap happens to be — that is the run-to-run level shift, not the scheme.
###   - BLAS is pinned to one thread. The per-column matvecs are tiny; multithreaded OpenBLAS
###     on tiny matvecs is the largest remaining noise source.
###   - schemes are sampled round-robin, so a load spike or a CPU clock change is shared by all
###     rows instead of landing entirely on whichever scheme was being measured at the time.
###   - every scheme gets the same number of samples (a time budget gives slow schemes fewer
###     samples, and a minimum over fewer samples is biased high).
###
### Reported `time_ms` therefore excludes GC. That is the right number for RANKING schemes; the
### allocation cost the ranking leaves out is the `KB/step` column, which is exact by construction.



# One sweep over all columns
@noinline function _sweep!(vars, scheme, m, npoints)
    for ij in 1:npoints
        SpeedyWeather.parameterization!(ij, vars, scheme, m)
    end
    return nothing
end


# Time one sweep in ms
#   - the dynamic dispatch on `scheme` happens at the call into this function, so it is not
#     inside the timed region
#   - try/finally is not optional: an error with GC disabled would poison the whole session
function _timed_sweep(vars, scheme, m, npoints)

    GC.gc(false)                # drop the previous sample's garbage, outside the timer
    GC.enable(false)

    try
        t0 = time_ns()
        _sweep!(vars, scheme, m, npoints)
        return (time_ns() - t0) / 1e6
    finally
        GC.enable(true)
    end
end



# Benchmark several schemes on ONE shared simulation state
#   - parameterization! takes the scheme explicitly, so the expensive setup happens once and
#     every scheme sees the identical state
function benchmark_scheme(schemes::NamedTuple;
    spectral_grid,
    model = PrimitiveWetModel,
    samples = 20,
    warmups = 3,
)

    # One simulation for all schemes
    sim = initialize!(model(spectral_grid; longwave_radiation = first(schemes)))
    first_steps!(sim; planned_steps = 2)

    vars    = sim.variables
    m       = sim.model
    npoints = length(vars.parameterizations.outgoing_longwave)

    # Pin BLAS for the measurement, restore afterwards
    n_blas = LinearAlgebra.BLAS.get_num_threads()
    LinearAlgebra.BLAS.set_num_threads(1)

    try
        # Compile every scheme's sweep and let the clock settle. Not recorded.
        for _ in 1:warmups, s in schemes
            _timed_sweep(vars, s, m, npoints)
        end

        # Allocations are exact, so one measurement per scheme is enough
        alloc = map(schemes) do s
            b = @benchmark _sweep!($vars, $s, $m, $npoints) samples=1 evals=1
            (; kb = minimum(b).memory / 1024, allocs = minimum(b).allocs)
        end

        # Round-robin sampling
        times = map(_ -> Float64[], schemes)

        for _ in 1:samples
            for (k, s) in pairs(schemes)
                push!(times[k], _timed_sweep(vars, s, m, npoints))
            end
        end

        return map(times, alloc) do t, a
            (; time_ms = minimum(t),
               med_ms  = Statistics.median(t),
               kb      = a.kb,
               allocs  = a.allocs)
        end

    finally
        LinearAlgebra.BLAS.set_num_threads(n_blas)
    end
end



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

    # Loud, because a noisy run looks exactly like a real difference
    worst = maximum(r.med_ms / r.time_ms for r in results)
    worst > 1.05 && @warn "Machine was not quiet (med/min up to $(round(worst, digits=2))) — rerun before trusting differences."

    return results
end