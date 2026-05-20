# Functions for saving and loading data



# Function for saving a NeuralLinearLongwave model using JLD2
function save(; path::String, para::NeuralLinearLongwave)
    
    # Create folder and create file path
    mkpath(path)
    filepath = joinpath(path, para.config.name * ".jld2")
    
    # Save it
    JLD2.jldsave(
        filepath;  
        config = para.config,
        ps = para.ps,
        st = para.st,
    )

    return filepath
end


# Function for loading a NeuralLinearLongwave model
function load_neural_longwave(; path::String, name::String, SG::SpeedyWeather.SpectralGrid)
    
    # Create file path and load data
    filepath = joinpath(path, name * ".jld2")
    data = JLD2.load(filepath)

    # Extract data
    config = data["config"]
    ps = data["ps"]
    st = data["st"]

    # Create temporary NeuralLinearLongwave (NN is empty)
    tmp = NeuralLinearLongwave(SG; config=config)

    # Return initialized NLL
    return NeuralLinearLongwave(tmp.nn, ps, st, config)

end