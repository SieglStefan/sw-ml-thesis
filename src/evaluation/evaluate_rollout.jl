### Functions for skill and rollout evaluation
###
### Evaluates rollouts of trained schemes and compares them to reference data sets, including skill scores and heatmaps of fields



# Reduce the column dimension of one metric
#   - rmse combines in quadrature, maxdiff takes the worst layer, everything else averages
reduce_cols(a, metric) =
    metric === :rmse    ? sqrt.(mean(abs2, a; dims = 3)) :      # combines in quadrature
    metric === :maxdiff ? maximum(a; dims = 3)           :      # takes the worst layer
                          mean(a; dims = 3)                     # rest averages



# Reduce one curve over trajectories: (day, traj, col) -> vector over lead days
#   - layer = nothing reduces all column entries, an integer picks one vertical layer
function rollout_curve(r, probe, metric; layer = nothing, f = mean)

    # Pick the metric and reduce the column dimension
    a = r.scores[probe][metric]
    a = isnothing(layer) ? reduce_cols(a, metric) : a[:, :, layer:layer]

    # Reduce over trajectories
    return vec(f(dropdims(a; dims = 3); dims = 2))
end


# Plot ONE metric for several probed fields, one column per field (1x3 for T, olw, slwd)
#   - one line per scheme, ribbon = spread over the trajectories
#   - only the first panel carries the legend, every panel shares the same schemes
function plot_rollout(;
    rollouts::NamedTuple,
    metric::Symbol,
    probes = (:T, :olw, :slwd),
    labels = nothing,
    colors = nothing,
    layer = nothing,
    ribbon = true,
    ncols = length(probes),
    plot_kwargs = (;),
)

    # Legend names: the rollout keys unless given explicitly
    labs = isnothing(labels) ? [String(k) for k in keys(rollouts)] : collect(labels)
    length(labs) == length(rollouts) || error("labels has $(length(labs)) entries, rollouts has $(length(rollouts))")

    # Colour and line style are fixed by scheme name unless given explicitly
    names = collect(keys(rollouts))
    cols = isnothing(colors) ? [scheme_color(n, i) for (i, n) in enumerate(names)] :
           [isnothing(c) ? scheme_color(names[i], i) : c for (i, c) in enumerate(colors)]
    length(cols) == length(rollouts) || error("colors has $(length(cols)) entries, rollouts has $(length(rollouts))")
    styles = [scheme_style(n) for n in names]

    # One panel per probed field (the ylabel names the field, so no panel title)
    panels = map(enumerate(collect(probes))) do (j, probe)

        unit = get(DEF_PROBE_UNITS, probe, "")
        p = Plots.plot(; xlabel = "forecast horizon [days]",
                         ylabel = isempty(unit) ? String(probe) : "$(probe) [$(unit)]",
                         legend = j == 1 ? :topleft : false,
                         background_color_legend = RGBA(1, 1, 1, 0.6),
                         foreground_color_legend = nothing)

        # One line per scheme
        for (i, r) in enumerate(values(rollouts))
            rib = ribbon ? rollout_curve(r, probe, metric; layer, f = std) : nothing
            Plots.plot!(p, collect(r.days), rollout_curve(r, probe, metric; layer);
                        label = labs[i], lw = 2, color = cols[i], ls = styles[i],
                        ribbon = rib, fillalpha = 0.15)
        end

        return p
    end

    # Arrange in a grid, one column per field by default -> 1x3 for the three loss fields
    lay = isnothing(layer) ? "all layers" : "layer $(layer)"

    return _stack(panels...; ncols, width = 650, height = 380,
        plot_kwargs = merge((; plot_title = "$(metric) - $(lay)"), plot_kwargs))
end


# One figure per metric, keyed by metric name; stored as .png if dir is given
function plot_rollout_metrics(;
    rollouts::NamedTuple,
    metrics = (:rmse, :bias, :maxdiff, :mean),
    dir = nothing,
    kwargs...
)

    # One figure per metric
    figs = (; (m => plot_rollout(; rollouts, metric = m, kwargs...) for m in metrics)...)

    # Save one .png per metric
    if !isnothing(dir)
        mkpath(dir)
        for (name, fig) in pairs(figs)
            Plots.savefig(fig, joinpath(dir, "rollout_$(name).png"))
        end
        @info "Rollout plots stored at $(dir)!"
    end

    return figs
end



### Heatmaps of all rollouts, one figure per heatmap day
# Heatmap field of one rollout: j indexes heatmap_days, layer optional (2D vars have none)
hm_field(r, var, j; layer = nothing) =
    isnothing(layer) ? r.heatmap_states[var][j] : r.heatmap_states[var][j][:, layer]




function plot_rollout_heatmaps(;
    rollouts::NamedTuple,
    var::Symbol = :T,               # a PROBE name, heatmap_states is keyed by probes
    labels = nothing,
    layer = nothing,
    ref = nothing,
    colorrange = nothing,           # nothing = derive one common range over all days
    kwargs...
)

    # All rollouts of one protocol share the heatmap days
    days = first(values(rollouts)).heatmap_days

    # Panel names: the rollout keys unless given explicitly
    all_names = collect(keys(rollouts))
    all_labs  = isnothing(labels) ? String.(all_names) : collect(labels)
    length(all_labs) == length(rollouts) || error("labels has $(length(all_labs)) entries, rollouts has $(length(rollouts))")

    # Difference to itself is zero everywhere, so drop the reference panel and its label
    keep  = [n != ref for n in all_names]
    names = all_names[keep]
    labs  = all_labs[keep]

    # Name of the reference, for the title
    ref_lab = isnothing(ref) ? "" : all_labs[findfirst(==(ref), all_names)]

    lay = isnothing(layer) ? "" : ", layer $(layer)"


    # Collect the fields of every day FIRST, so all figures can share one colorbar
    #   - with ref given, plot the difference to that rollout instead
    fields_per_day = map(eachindex(days)) do j

        fields = [hm_field(rollouts[n], var, j; layer) for n in names]

        isnothing(ref) && return fields

        ref_f = hm_field(rollouts[ref], var, j; layer)
        return [f .- ref_f for f in fields]
    end

    # One common colorrange over every day, so the figures are comparable
    all_fields = reduce(vcat, fields_per_day)
    crange = !isnothing(colorrange) ? colorrange :
             isnothing(ref)         ? finite_range(all_fields) : sym_range(all_fields)

    # Diverging colormap for difference maps
    cmap = isnothing(ref) ? (;) : (; colormap = :balance)


    # One figure per heatmap day
    return map(enumerate(days)) do (j, d)

        title = isnothing(ref) ? "$(var)$(lay) - day $(d)" :
                                 "$(var)$(lay) - day $(d), difference to $(ref_lab)"

        style = (; colorrange = crange, cmap..., suptitle = title)

        plot_heatmaps(fields_per_day[j]; titles = labs, merge(style, values(kwargs))...)
    end
end