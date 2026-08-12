### Comparison of several training runs
###
### Per-run plots (plotting.jl) use one colour per FIELD, comparison plots use one colour per RUN,
### so every scheme shares an axis. These show SKILL only - stability is not visible in the
### training metrics (see the _stab rollouts).



# Block mean over consecutive windows of w steps, and the x-positions of the blocks
function _block_mean(v, w)
    x = [min(i + w - 1, length(v))                                for i in 1:w:length(v)]
    y = [Statistics.mean(@view v[i:min(i + w - 1, lastindex(v))]) for i in 1:w:length(v)]
    return x, y
end


# Load several training runs and align them for comparison
#   - exp: one experiment for all runs, or one experiment per run
function _comp_runs(exp, names, file, colors = nothing, steps = nothing)

    # Broadcast a single experiment over all names
    exps = exp isa AbstractString ? fill(exp, length(names)) : collect(exp)

    # Load every run and truncate to the shortest, so the step axis stays aligned
    dfs   = [csv_read(; dir = scheme_dir(e, n), file) for (e, n) in zip(exps, names)]
    n_min = minimum(nrow, dfs)

    # Step window: nothing = all, a range (100:500), or a fraction (0.8 = last 80 %)
    win = isnothing(steps)        ? (1:n_min) :
          steps isa AbstractRange ? (max(1, first(steps)):min(n_min, last(steps))) :
                                    (max(1, round(Int, n_min * (1 - steps)) + 1):n_min)
    dfs = [df[win, :] for df in dfs]

    # IC boundaries and x-offset, so the axis keeps ABSOLUTE step numbers after slicing
    x0     = first(win) - 1
    bounds = ic_bounds(first(dfs).ic) .+ x0

    # Colour and line style per run (nothing = default from the scheme name)
    colors = isnothing(colors) ? [scheme_color(n, i) for (i, n) in enumerate(names)] :
             [isnothing(c) ? scheme_color(names[i], i) : c for (i, c) in enumerate(colors)]
    styles = [scheme_style(n) for n in names]

    return dfs, bounds, colors, styles, x0
end


# Axis scale of one column, decided over ALL runs so panels cannot flip between figures
_comp_scale(dfs, col) = log_or_lin(reduce(vcat, [df[!, col] for df in dfs]))


# One panel: one logged column, one line per run
function _comp_panel(dfs, labels, colors, styles, col;
    ylabel, bounds, smooth, x0 = 0,
    xlabel = "", yscale = :identity, zeroline = false, legend = false,
)

    p = Plots.plot(; ylabel, xlabel, yscale, legend,
                     background_color_legend = RGBA(1, 1, 1, 0.6),
                     foreground_color_legend = nothing)

    # One line per run
    for (df, l, c, s) in zip(dfs, labels, colors, styles)
        x, y = _block_mean(df[!, col], smooth)
        Plots.plot!(p, x .+ x0, y; label = l, lw = 2, color = c, ls = s)
    end

    zeroline && Plots.hline!(p, [0]; color = :black, ls = :dash, lw = 1, label = "")
    Plots.vline!(p, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    return p
end



# Compare loss, gradient- and parameter norm of several training runs
function plot_training_comp(;
    exp, names, labels = names, colors = nothing,
    steps = nothing, heights = [0.5, 0.25, 0.25],
    file = "training.csv", smooth = 10, plot_kwargs = (;),
)

    dfs, bounds, colors, styles, x0 = _comp_runs(exp, names, file, colors, steps)

    p1 = _comp_panel(dfs, labels, colors, styles, :loss_total;
        ylabel = "Loss", yscale = _comp_scale(dfs, :loss_total),
        bounds, smooth, x0, legend = :topleft)

    p2 = _comp_panel(dfs, labels, colors, styles, :gnorm;
        ylabel = "Gradient norm", yscale = _comp_scale(dfs, :gnorm),
        bounds, smooth, x0)

    p3 = _comp_panel(dfs, labels, colors, styles, :pnorm;
        ylabel = "Parameter norm", xlabel = "Training step",
        bounds, smooth, x0)

    # Loss gets half the height, the two norms a quarter each
    grid_kwargs = (; layout = Plots.grid(3, 1, heights = heights), size = (800, 800))

    return _stack(p1, p2, p3;
        plot_kwargs = merge((; plot_title = "Training Comparison"), grid_kwargs, plot_kwargs))
end


# Compare normalized rmse per field of several training runs
function plot_metrics_comp(;
    exp, names, labels = names, colors = nothing,
    steps = nothing,
    file = "training.csv", smooth = 10, plot_kwargs = (;),
)

    dfs, bounds, colors, styles, x0 = _comp_runs(exp, names, file, colors, steps)

    # One panel per field, stacked
    panels = Plots.Plot[]
    for (i, f) in enumerate((:T, :olw, :slwd))

        unit = f === :T ? "Tₑᵣᵣ" : "σ"

        push!(panels, _comp_panel(dfs, labels, colors, styles, Symbol("nrmse_", f);
            ylabel = "$(f) RMSE [$(unit)]",
            xlabel = i == 3 ? "Training step" : "",
            bounds, smooth, x0, legend = (i == 1 ? :topleft : false)))
    end

    return _stack(panels...;
        plot_kwargs = merge((; plot_title = "Metrics Comparison"), plot_kwargs))
end



# Summary table of several training runs: mean over the LAST initial condition
function compare_runs(; exp, names, labels = names, file = "training.csv")

    exps = exp isa AbstractString ? fill(exp, length(names)) : collect(exp)

    rows = map(zip(exps, names, labels)) do (e, n, l)

        # Load the run and keep only the last initial condition
        df = csv_read(; dir = scheme_dir(e, n), file)
        ic = df[df.ic .== maximum(df.ic), :]

        (;  scheme     = l,
            loss       = Statistics.mean(ic.loss_total),
            nrmse_T    = Statistics.mean(ic.nrmse_T),
            nrmse_olw  = Statistics.mean(ic.nrmse_olw),
            nrmse_slwd = Statistics.mean(ic.nrmse_slwd),
            nbias_T    = Statistics.mean(ic.nbias_T),
            nbias_olw  = Statistics.mean(ic.nbias_olw),
            nbias_slwd = Statistics.mean(ic.nbias_slwd),
            bias_C     = Statistics.mean(ic.bias_C),
            gnorm      = Statistics.mean(ic.gnorm),
            pnorm      = last(ic.pnorm),
        )
    end

    return DataFrame(rows)
end
