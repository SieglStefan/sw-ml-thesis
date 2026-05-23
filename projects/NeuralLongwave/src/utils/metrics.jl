### Different validation metrics



# Root mean squared error metric
function rmse(x,y)
    return sqrt(sum((y .- x).^2) / length(x))
end


# Bias metric
function bias(x,y)
    return sum(y .- x) / length(x)
end


# Correlation metric
function correlation(x,y)
    return cor(vec(x), vec(y))
end