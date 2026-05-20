### Different validation metrics



# Simple mean squared error loss function
function MSE(x,y)
    return sum((y .- x).^2) / length(x)
end