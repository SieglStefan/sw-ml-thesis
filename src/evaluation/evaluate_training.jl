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
function _comp_runs(exp, names, file)

    # Broadcast a single experiment over all names
    exps = exp isa AbstractString ? fill(exp, length(names)) : collect(exp)

    # Load every run and truncate to the shortest, so the step axis stays aligned
    dfs   = [csv_read(; dir = scheme_dir(e, n), file) for (e, n) in zip(exps, names)]
    n_min = minimum(nrow, dfs)
    dfs   = [df[1:n_min, :] for df in dfs]

    # IC boundaries, plus colour and line style per run (fixed by scheme name)
    bounds = ic_bounds(first(dfs).ic)
    colors = [scheme_color(n, i) for (i, n) in enumerate(names)]
    styles = [scheme_style(n)    for n in names]

    return dfs, bounds, colors, styles
end


# Axis scale of one column, decided over ALL runs so panels cannot flip between figures
_comp_scale(dfs, col) = log_or_lin(reduce(vcat, [df[!, col] for df in dfs]))


# One panel: one logged column, one line per run
function _comp_panel(dfs, labels, colors, styles, col;
    ylabel, bounds, smooth,
    xlabel = "", yscale = :identity, zeroline = false, legend = false,
)

    p = Plots.plot(; ylabel, xlabel, yscale, legend,
                     background_color_legend = RGBA(1, 1, 1, 0.6),
                     foreground_color_legend = nothing)

    # One line per run
    for (df, l, c, s) in zip(dfs, labels, colors, styles)
        x, y = _block_mean(df[!, col], smooth)
        Plots.plot!(p, x, y; label = l, lw = 2, color = c, ls = s)
    end

    zeroline && Plots.hline!(p, [0]; color = :black, ls = :dash, lw = 1, label = "")
    Plots.vline!(p, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    return p
end



# Compare loss, gradient- and parameter norm of several training runs
function plot_training_comp(;
    exp, names, labels = names,
    file = "training.csv", smooth = 10, plot_kwargs = (;),
)

    # Load and align the runs
    dfs, bounds, colors, styles = _comp_runs(exp, names, file)

    # Loss (the objective itself)
    p1 = _comp_panel(dfs, labels, colors, styles, :loss_total;
        ylabel = "Loss", yscale = _comp_scale(dfs, :loss_total),
        bounds, smooth, legend = :topleft)

    # Gradient norm - answers "did it train ENOUGH", not "did it train best"
    p2 = _comp_panel(dfs, labels, colors, styles, :gnorm;
        ylabel = "Gradient norm", yscale = _comp_scale(dfs, :gnorm),
        bounds, smooth)

    # Parameter norm - catches weight-decay dominance and runaway parameters
    p3 = _comp_panel(dfs, labels, colors, styles, :pnorm;
        ylabel = "Parameter norm", xlabel = "Training step",
        bounds, smooth)

    return _stack(p1, p2, p3; plot_kwargs = merge((; plot_title = "Training Comparison"), plot_kwargs))
end



# Compare normalized rmse and bias per field of several training runs
function plot_metrics_comp(;
    exp, names, labels = names,
    file = "training.csv", smooth = 10, plot_kwargs = (;),
)

    # Load and align the runs
    dfs, bounds, colors, styles = _comp_runs(exp, names, file)

    # One row per field, rmse left and bias right
    panels = Plots.Plot[]
    for (i, f) in enumerate((:T, :olw, :slwd))

        unit   = f === :T ? "Tₑᵣᵣ" : "σ"
        xlabel = i == 3 ? "Training step" : ""

        push!(panels, _comp_panel(dfs, labels, colors, styles, Symbol("nrmse_", f);
            ylabel = "$(f) RMSE [$(unit)]", xlabel, bounds, smooth,
            legend = (i == 1 ? :topleft : false)))

        push!(panels, _comp_panel(dfs, labels, colors, styles, Symbol("nbias_", f);
            ylabel = "$(f) bias [$(unit)]", xlabel, bounds, smooth, zeroline = true))
    end

    # Two columns: rmse left, bias right
    return _stack(panels...; ncols = 2,
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
