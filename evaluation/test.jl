using NeuralParam, SpeedyWeather, Statistics

SG   = SpectralGrid(trunc = 31, nlayers = 8)
OBLW = OneBandLongwave(SG;
    transmissivity     = FriersonLongwaveTransmissivity(SG),
    radiative_transfer = OneBandLongwaveRadiativeTransfer(SG;
                             emissivity_ocean = 0.98f0, emissivity_land = 0.98f0))

rmse_T(a, b) = sqrt(mean(abs2, SpeedyWeather.get_step(a.grid.temperature) .-
                               SpeedyWeather.get_step(b.grid.temperature)))

with_reference("TEST_REFERENCE") do ref
    spd = 36

    # (a) exactly what sample_trajectory does today
    sim = initialize!(PrimitiveWetModel(SG; longwave_radiation = OBLW))
    first_steps!(sim; planned_steps = spd + 1)
    copy!(sim.variables, ref[0])
    sim_timesteps!(sim, spd)
    e_now = rmse_T(sim.variables, ref[1])

    # (b) same, but rebuild the implicit operators from the restart state
    sim = initialize!(PrimitiveWetModel(SG; longwave_radiation = OBLW))
    first_steps!(sim; planned_steps = spd + 1)
    copy!(sim.variables, ref[0])
    sim.model.implicit.Δt[] = 0                             # force the rebuild
    SpeedyWeather.reinitialize!(sim.model, sim.variables)
    sim_timesteps!(sim, spd)
    e_fixed = rmse_T(sim.variables, ref[1])

    @show e_now e_fixed
end