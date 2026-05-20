### Convenience script for loading NeuralLongwave for experiment

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..", ".."))

include(joinpath(@__DIR__, "..", "..", "src", "LinearLongwave.jl"))
using .NeuralLongwave
