### General utility functions
###
### Small helper functions used across scripts and analysis code.



# Calculate the z-score transformation of x
zscore(x, μ, σ) = (x .- μ) ./ σ


# Extract vertical layer k from a series of temperature fields
extract_layer(k, T) = [Ti[:, k] for Ti in T]