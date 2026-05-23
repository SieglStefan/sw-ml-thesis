### Utility functions for all kinds of plotting



# Function for plotting the results of a calibration run. Plots the loss and the parameters a and b against calibration steps
function plot_calibration(L, a, b;
                            loss_kwargs = (;),
                            a_kwargs = (;),
                            b_kwargs = (;),
                            plot_kwargs = (;))

    # Plot for loss
    p1 = Plots.plot(
        0:length(L)-1,
        L,
        yscale=:log10,              # loss plot gets special y-axis scaling
        ylabel="Loss",
        title="Loss evolution",
        loss_kwargs...
    )

    # Plot for a
    p2 = Plots.plot(
        0:length(a)-1,
        a,
        ylabel="a",
        title="Parameter a",
        a_kwargs...
    )

    # Plot for b
    p3 = Plots.plot(
        0:length(b)-1,
        b,
        xlabel="Training step",
        ylabel="b",
        title="Parameter b",
        b_kwargs...
    )

    # Combine subplots
    p = Plots.plot(p1, p2, p3, layout=(3,1); plot_kwargs...)

    # Plot it
    display(p)

    return p
end



# Function for only plotting the loss
function plot_loss(L; kwargs...) 
    
    
    p = Plots.plot(
        0:length(L)-1, 
        L;
        yscale=:log10,
        xlabel = "Step Nr.",
        ylabel = "Loss",
        title = "Loss evolution",
        kwargs...)

    display(p)

    return p
end



# Function for plotting the RMSE difference between target and training simulation
function plot_rmse_diff(T_target, T_train;
                        dt,                     # time in seconds between two timesteps
                        kwargs...)

    t_days = (0:length(T_target)-1) .* Dates.value(dt) ./ (60 * 60 * 24)

    p = Plots.plot(
        t_days,
        rmse(T_train .- T_target);
        xlabel = "Time (days)",
        ylabel = "RMSE Temperature (K)",
        title = "RMSE difference evolution",
        kwargs...)

    display(p)

    return p
end



# Function for plotting the bias difference between target and training simulation
function plot_bias_diff(T_target, T_train;
                        dt,                     # time in seconds between two timesteps
                        kwargs...)

    t_days = (0:length(T_target)-1) .* Dates.value(dt) ./ (60 * 60 * 24)

    p = Plots.plot(
        t_days,
        bias(T_train .- T_target);
        xlabel = "Time (days)",
        ylabel = "Bias Temperature (K)",
        title = "Bias difference evolution",
        kwargs...)

    display(p)

    return p
end


# Function for plotting the correlation difference between target and training simulation
function plot_correlation_diff(T_target, T_train;
                               dt,                     # time in seconds between two timesteps
                               kwargs...)

    t_days = (0:length(T_target)-1) .* Dates.value(dt) ./ (60 * 60 * 24)

    p = Plots.plot(
        t_days,
        correlation(T_train .- T_target);
        xlabel = "Time (days)",
        ylabel = "Correlation",
        title = "Correlation difference evolution",
        kwargs...)

    display(p)

    return p
end