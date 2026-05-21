using AnalyticBandRadiation

nlayers = 8
σ_half  = collect(range(0.0, 1.0, length = nlayers + 1))
grid    = ColumnGrid(σ_half)

# Lapse-rate profile: top of atmosphere (k=1) cold, surface (k=nlayers) warm.
profile = AtmosphereProfile(
    temperature      = collect(range(220.0, 295.0, length = nlayers)),
    humidity         = fill(0.005, nlayers),
    geopotential     = zeros(nlayers),
    surface_pressure = 100_000.0,
    CO₂              = 280.0,
)

surface = SurfaceState(
    sea_surface_temperature  = 295.0,
    land_surface_temperature = 285.0,
    land_fraction            = 0.3,
    ocean_albedo             = 0.07,
    land_albedo              = 0.25,
    cos_zenith               = 0.5,
)

# Schemes, constants, and output buffers all wrap up here.
rtm = RadiativeTransferColumn(; grid, profile, surface)

solve_longwave!(rtm)
solve_shortwave!(rtm)

@show rtm.longwave_diagnostics.outgoing_longwave        # W m⁻²
@show rtm.longwave_diagnostics.surface_longwave_down    # W m⁻²
@show rtm.shortwave_diagnostics.surface_shortwave_down  # W m⁻²
@show rtm.temperature_tendency                           # K s⁻¹ per layer