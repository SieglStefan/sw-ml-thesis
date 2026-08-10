### Plotting of training runs
###
### Functions for plotting training data
###     - plot_training:        plots loss and also parameter- and gradient norm over training steps
###     - plot_metrics_norm:    plots normalized metrics (loss, rmse, bias) from a training .csv file
###     - plot_metrics_raw:     plots raw metrics (rmse, bias) from a training .csv file



# One colour per field, shared by every training and rollout plot
const FIELD_COLORS = (;
    total = :black,
    T     = :firebrick,
    olw   = :steelblue,
    slwd  = :rebeccapurple,
)

# One colour per run, used by every comparison plot
const RUN_COLORS = [
    :steelblue, :firebrick, :seagreen,   :darkorange,    :rebeccapurple,
    :goldenrod, :teal,      :deeppink,   :slategray,     :saddlebrown,
]

# Utility function for not-breaking the axis for log10 plots
log_or_lin(v) = all(>(0), v) ? :log10 : :identity

# Utility function for plotting vertical lines at the end of each initial condition
ic_bounds(ic::AbstractVector) = [i + 0.5 for i in 1:length(ic)-1 if ic[i] != ic[i+1]]

# Shared layout for stacked training panels
function _stack(panels...; height = 320, width = 800, plot_kwargs = (;))
    n = length(panels)
    defaults = (;
        layout        = Plots.grid(n, 1, heights = fill(1/n, n)),
        size          = (width, height * n),
        link          = :x,
        left_margin   = 10Plots.mm,
        right_margin  =  6Plots.mm,
        bottom_margin =  4Plots.mm,
        plot_titlefontsize = 20,
        tickfontsize = 10,
        guidefontsize = 14,
    )
    return Plots.plot(panels...; merge(defaults, plot_kwargs)...)
end



# Plot timeseries of loss, parameter- and gradient norm of a training run
function plot_training(; 
    dir="", file="training.csv", 
    n_batch = 1, 
    plot_kwargs = (;),
    loss_kwargs = (;),
    pnorm_kwargs = (;),
    gnorm_kwargs = (;)
)

    # Load data and compute ic bounds
    df = csv_read(; dir, file)
    bounds = ic_bounds(df.ic)

    # Mean over consecutive blocks of n_batch steps, and their x-positions
    bmean(v) = [Statistics.mean(@view v[i:min(i+n_batch-1, lastindex(v))]) for i in 1:n_batch:length(v)]
    xb = [min(i+n_batch-1, length(df.loss_total)) for i in 1:n_batch:length(df.loss_total)]


    # Loss plot
    p1 = Plots.plot(
        df.loss_total;
        ylabel = "Loss",
        yscale = log_or_lin(df.loss_total),
        legend = false, 
        loss_kwargs...,
    )
    Plots.plot!(p1, xb, bmean(df.loss_total); label = "batch mean", lw = 2, color = :black)
    isempty(bounds) || Plots.vline!(p1, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    # Parameter norm plot
    p2 = Plots.plot(
        df.pnorm;
        ylabel = "Parameter norm",
        legend = false,  
        pnorm_kwargs...,
    )
    Plots.plot!(p2, xb, bmean(df.pnorm); label = "batch mean", lw = 2, color = :black)
    isempty(bounds) || Plots.vline!(p2, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    # Gradient norm plot
    p3 = Plots.plot(
        df.gnorm;
        xlabel="Training step",
        ylabel="Gradient norm",
        yscale=log_or_lin(df.gnorm),
        legend = false,  
        gnorm_kwargs...,
    )
    Plots.plot!(p3, xb, bmean(df.gnorm); label = "batch mean", lw = 2, color = :black)
    isempty(bounds) || Plots.vline!(p3, bounds; color = :gray, ls = :dot, lw = 1, label = "")


    return _stack(p1, p2, p3; plot_kwargs)
end




# Plot normalized metrics of a training run: losses, normalized rmse and bias
function plot_metrics_norm(;
    dir="", file="training.csv", 
    weights=nothing, 
    plot_kwargs = (;)
)

    # Load data and compute ic bounds
    df = csv_read(; dir, file)
    bounds = ic_bounds(df.ic)

    # Weights are not stored in the .csv, so they have to be passed in
    w    = isnothing(weights) ? (; T = 1, olw = 1, slwd = 1) : weights


    # Losses: total and per-field contributions
    p1 = Plots.plot(w.T .* df.loss_T ./ df.loss_total;
        ylabel = "loss share", ylims = (0, 1), lw = 2, label = "T", color = FIELD_COLORS.T, legend = :topleft)
    Plots.plot!(p1, w.olw  .* df.loss_olw  ./ df.loss_total; lw = 2, label = "olw",  color = FIELD_COLORS.olw)
    Plots.plot!(p1, w.slwd .* df.loss_slwd ./ df.loss_total; lw = 2, label = "slwd", color = FIELD_COLORS.slwd)
    Plots.vline!(p1, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    # Normalized rmse (in units of the field's std)
    p2 = Plots.plot(df.nrmse_T;
        ylabel = "norm. RMSE [Tₑᵣᵣ/σ]", yscale = log_or_lin(df.nrmse_T), lw = 2,
        label = "T", color = FIELD_COLORS.T, legend = :topleft)
    Plots.plot!(p2, df.nrmse_olw;  lw = 2, label = "olw",  color = FIELD_COLORS.olw)
    Plots.plot!(p2, df.nrmse_slwd; lw = 2, label = "slwd", color = FIELD_COLORS.slwd)
    Plots.vline!(p2, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    # Normalized bias (in units of the field's std)
    p3 = Plots.plot(df.nbias_T;
        xlabel = "Training step", ylabel = "norm. bias [Tₑᵣᵣ/σ]", lw = 2,
        label = "T", color = FIELD_COLORS.T, legend = :topleft)
    Plots.plot!(p3, df.nbias_olw;  lw = 2, label = "olw",  color = FIELD_COLORS.olw)
    Plots.plot!(p3, df.nbias_slwd; lw = 2, label = "slwd", color = FIELD_COLORS.slwd)
    Plots.hline!(p3, [0]; color = :black, ls = :dash, lw = 1, label = "")
    Plots.vline!(p3, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    return _stack(p1, p2, p3; plot_kwargs)
end



# Plot raw metrics of a training run in physical units, grouped by unit
function plot_metrics_raw(; 
    dir="", 
    file="training.csv", 
    plot_kwargs = (;)
)

    # Load data and compute ic bounds
    df = csv_read(; dir, file)
    bounds = ic_bounds(df.ic)

    # Temperature [K]
    p1 = Plots.plot(df.rmse_T; ylabel = "T [K]", lw = 2, label = "RMSE", color = FIELD_COLORS.T, legend = :topleft)
    Plots.plot!(p1, df.bias_T; lw = 2, label = "bias", color = FIELD_COLORS.T, ls = :dash)
    Plots.hline!(p1, [0]; color = :black, ls = :dash, lw = 1, label = "")
    Plots.vline!(p1, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    # Fluxes [W/m²] — same unit, so they share a panel
    p2 = Plots.plot(df.rmse_olw;  xlabel = "Training step", ylabel = "Flux [W/m²]",
                    lw = 2, label = "RMSE olw",  color = FIELD_COLORS.olw, legend = :topleft)
    Plots.plot!(p2, df.bias_olw;  lw = 2, label = "bias olw",  color = FIELD_COLORS.olw,  ls = :dash)
    Plots.plot!(p2, df.rmse_slwd; lw = 2, label = "RMSE slwd", color = FIELD_COLORS.slwd)
    Plots.plot!(p2, df.bias_slwd; lw = 2, label = "bias slwd", color = FIELD_COLORS.slwd, ls = :dash)
    Plots.hline!(p2, [0]; color = :black, ls = :dash, lw = 1, label = "")
    Plots.plot!(p2, df.bias_C; lw = 2, label = "bias C", color = :black, ls = :dot)
    Plots.vline!(p2, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    return _stack(p1, p2; plot_kwargs)
end





### Comparison plots
###
### Per-run plots use one colour per FIELD; comparison plots invert this and use one colour
### per RUN, so every scheme shares an axis. Note these show SKILL only - stability is not
### visible in training metrics (see the _stab rollouts).



# Block mean over consecutive windows of w steps, and the x-positions of the blocks
function _block_mean(v, w)
    w <= 1 && return (collect(eachindex(v)), collect(v))
    x = [min(i + w - 1, length(v))                              for i in 1:w:length(v)]
    y = [Statistics.mean(@view v[i:min(i + w - 1, lastindex(v))]) for i in 1:w:length(v)]
    return x, y
end


# Load several training runs and align them for comparison
#   - exp: one experiment for all runs, or one experiment per run
function _comp_runs(exp, names, labels, file)

    # Broadcast a single experiment over all names
    exps = exp isa AbstractString ? fill(exp, length(names)) : collect(exp)
    length(exps) == length(names) || error("exp has $(length(exps)) entries, names has $(length(names))")

    # Load every run
    dfs = [csv_read(; dir = scheme_dir(e, n), file) for (e, n) in zip(exps, names)]

    # Truncate to the shortest run, so the step axis stays aligned
    n_min = minimum(nrow, dfs)
    all(nrow(df) == n_min for df in dfs) || @warn "Runs differ in length - truncated to $(n_min) steps"
    dfs = [df[1:n_min, :] for df in dfs]

    # IC boundaries, only if every run shares the same structure
    bnds   = [ic_bounds(df.ic) for df in dfs]
    bounds = all(b == first(bnds) for b in bnds) ? first(bnds) : Float64[]

    # One colour per run, keyed by sorted label so it does not depend on the call order
    order  = sortperm(collect(labels))
    colors = Dict(labels[j] => RUN_COLORS[mod1(i, length(RUN_COLORS))] for (i, j) in enumerate(order))

    return dfs, bounds, colors
end


# Axis scale of one column, decided over ALL runs so panels cannot flip between figures
_comp_scale(dfs, col) = log_or_lin(reduce(vcat, [df[!, col] for df in dfs]))


# One panel: one logged column, one line per run
function _comp_panel(dfs, labels, colors, col;
    ylabel, bounds, smooth,
    xlabel = "", title = "", yscale = :identity, ylims = :auto,
    zeroline = false, legend = false,
)

    p = Plots.plot(; ylabel, xlabel, title, yscale, ylims, legend)

    # One line per run
    for (df, l) in zip(dfs, labels)
        x, y = _block_mean(df[!, col], smooth)
        Plots.plot!(p, x, y; label = l, lw = 2, color = colors[l])
    end

    zeroline && Plots.hline!(p, [0]; color = :black, ls = :dash, lw = 1, label = "")
    isempty(bounds) || Plots.vline!(p, bounds; color = :gray, ls = :dot, lw = 1, label = "")

    return p
end



# Compare loss, parameter- and gradient norm of several training runs
function plot_training_comp(;
    exp,
    names,
    labels = names,
    file = "training.csv",
    smooth = 10,
    plot_kwargs = (;),
)

    # Load and align the runs
    dfs, bounds, colors = _comp_runs(exp, names, labels, file)

    # Loss (the objective itself)
    p1 = _comp_panel(dfs, names, colors, :loss_total;
        ylabel = "Loss", yscale = _comp_scale(dfs, :loss_total),
        bounds, smooth, legend = :topleft)

    # Gradient norm - answers "did it train ENOUGH", not "did it train best"
    p2 = _comp_panel(dfs, names, colors, :gnorm;
        ylabel = "Gradient norm", yscale = _comp_scale(dfs, :gnorm),
        bounds, smooth)

    # Parameter norm - catches weight-decay dominance and runaway parameters
    p3 = _comp_panel(dfs, names, colors, :pnorm;
        ylabel = "Parameter norm", xlabel = "Training step",
        bounds, smooth)

    return _stack(p1, p2, p3; plot_kwargs)
end



# Compare normalized rmse and bias per field of several training runs
function plot_metrics_comp(;
    exp,
    names,
    labels = names,
    file = "training.csv",
    smooth = 10,
    plot_kwargs = (;),
)

    # Load and align the runs
    dfs, bounds, colors = _comp_runs(exp, names, labels, file)

    # One row per field, rmse left and bias right
    panels = Plots.Plot[]
    for (i, f) in enumerate((:T, :olw, :slwd))

        last_row = (i == 3)
        unit     = f === :T ? "Tₑᵣᵣ" : "σ"

        # Left column: normalized rmse - carries the row label
        push!(panels, _comp_panel(dfs, labels, colors, Symbol("nrmse_", f);
            ylabel = "$(f)  [$(unit)]",
            title  = i == 1 ? "norm. RMSE" : "",
            xlabel = last_row ? "Training step" : "",
            ylims  = (0, Inf),
            bounds, smooth, legend = (i == 1 ? :topleft : false)))

        # Right column: normalized bias - same unit as the left, so no repeated label
        push!(panels, _comp_panel(dfs, labels, colors, Symbol("nbias_", f);
            ylabel = " ",
            title  = i == 1 ? "norm. bias" : "",
            xlabel = last_row ? "Training step" : "",
            bounds, smooth, zeroline = true))
    end

    # 3x2 grid instead of the stacked default
    grid_kwargs = (; layout = Plots.grid(3, 2), size = (1400, 960), titlefontsize = 15)

    return _stack(panels...; plot_kwargs = merge(grid_kwargs, plot_kwargs))
end



# Summary table of several training runs: mean over the LAST initial condition
function compare_runs(; exp, names, labels = names, file = "training.csv")

    exps = exp isa AbstractString ? fill(exp, length(names)) : collect(exp)

    rows = map(zip(exps, names, labels)) do (e, n, l)

        # Load the run and keep only the last initial condition
        df   = csv_read(; dir = scheme_dir(e, n), file)
        last = df[df.ic .== maximum(df.ic), :]

        (;  scheme     = n,
            loss       = Statistics.mean(last.loss_total),
            nrmse_T    = Statistics.mean(last.nrmse_T),
            nrmse_olw  = Statistics.mean(last.nrmse_olw),
            nrmse_slwd = Statistics.mean(last.nrmse_slwd),
            nbias_T    = Statistics.mean(last.nbias_T),
            nbias_olw  = Statistics.mean(last.nbias_olw),
            nbias_slwd = Statistics.mean(last.nbias_slwd),
            bias_C     = Statistics.mean(last.bias_C),
            gnorm      = Statistics.mean(last.gnorm),
            pnorm      = Base.last(last.pnorm),
        )
    end

    return DataFrame(rows)
end