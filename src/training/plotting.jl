### Plotting of training runs
###
### Functions for plotting training data
###     - plot_training:        plots loss and also parameter- and gradient norm over training steps
###     - plot_metrics_norm:    plots normalized metrics (loss, rmse, bias) from a training .csv file
###     - plot_metrics_raw:     plots raw metrics (rmse, bias) from a training .csv file



const JL_BLUE   = RGB(0.251, 0.388, 0.847)
const JL_GREEN  = RGB(0.220, 0.596, 0.149)
const JL_RED    = RGB(0.796, 0.235, 0.200)
const JL_PURPLE = RGB(0.584, 0.345, 0.698)

# Colours are from the Okabe-Ito colourblind-safe palette
# One colour per field, shared by every training and rollout plot
const FIELD_COLORS = (;
    total = :black,
    T     = JL_RED,
    olw   = JL_BLUE,
    slwd  = JL_GREEN,
)

# One colour per SCHEME KIND, matched on the run name, so a scheme keeps its colour
# in every figure - training comparisons, rollouts and heatmaps alike
const SCHEME_COLORS = (;   
    direct = JL_BLUE,
    linear = JL_GREEN,
    planck = JL_RED,
    OBLW   = :grey,
    ZeroLW = JL_PURPLE,
)

# Fallback palette for runs whose name matches no entry of SCHEME_COLORS
const RUN_COLORS = [
    RGB(0.34, 0.71, 0.91), RGB(0.94, 0.89, 0.26), RGB(0.35, 0.35, 0.35),
    RGB(0.55, 0.34, 0.29), RGB(0.47, 0.47, 0.70),
]

# Colour of one run: matched on its name, otherwise taken from the fallback palette
function scheme_color(name, i = 1)
    for (kind, color) in pairs(SCHEME_COLORS)
        occursin(String(kind), String(name)) && return color
    end
    return RUN_COLORS[mod1(i, length(RUN_COLORS))]
end

# Reference schemes: not trained, only there to compare against -> drawn dashed
const BASELINES = ("OBLW", "ZeroLW")

# Line style of one run: dashed for the baselines, solid for a trained scheme
scheme_style(name) = any(occursin(b, String(name)) for b in BASELINES) ? :dash : :solid

# Utility function for not-breaking the axis for log10 plots
log_or_lin(v) = all(>(0), v) ? :log10 : :identity

# Utility function for plotting vertical lines at the end of each initial condition
ic_bounds(ic::AbstractVector) = [i + 0.5 for i in 1:length(ic)-1 if ic[i] != ic[i+1]]

# Shared layout for stacked training panels
function _stack(panels...; height = 320, width = 800, ncols = 1, plot_kwargs = (;))
    nrows = cld(length(panels), ncols)
    defaults = (;
        layout        = (nrows, ncols),
        size          = (width * ncols, height * nrows),
        link          = :x,
        left_margin   = 10Plots.mm,
        right_margin  =  6Plots.mm,
        bottom_margin = 10Plots.mm,
        top_margin    =  6Plots.mm,
        plot_titlefontsize = 20,
        tickfontsize  = 10,
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





