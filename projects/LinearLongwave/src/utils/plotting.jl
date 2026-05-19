### Utility functions for all kinds of plotting


# Function for plotting the results of a calibration run. Plots the loss and the parameters a and b against calibration steps
function plot_calibration(L, a, b)

    # Plot for loss
    p1 = plot(
        0:length(L)-1,
        L,
        yscale=:log10,              # loss plot gets special y-axis scaling
        xlabel="Training step",
        ylabel="Loss",
        title="Loss evolution",
        label="Loss"
    )

    # Plot for a
    p2 = plot(
        0:length(a)-1,
        a,
        xlabel="Training step",
        ylabel="a",
        title="Parameter a",
        label="a"
    )

    # Plot for b
    p3 = plot(
        0:length(b)-1,
        b,
        xlabel="Training step",
        ylabel="b",
        title="Parameter b",
        label="b"
    )

    # Plot the subplots
    display(plot(p1, p2, p3, layout=(3,1)))
end