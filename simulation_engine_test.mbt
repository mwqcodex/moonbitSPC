///|
test "simulation is reproducible and reports causes" {
  let scenario = ProcessScenario::new(
    name="demo",
    center=10.0,
    deviation=0.1,
    lower=Some(9.0),
    upper=Some(11.0),
    drift=0.0,
    outlier_probability=0.0,
    seed=42,
  )
  let first = simulate_process(scenario, 5)
  let second = simulate_process(scenario, 5)
  debug_inspect(
    simulation_delta(first, second),
    content="Some([0, 0, 0, 0, 0])",
  )
  inspect(simulation_defects(first), content="0")
  inspect(simulation_causes(first)[0].category, content="common-cause")
}

///|
test "simulation drift becomes observable in latent centers" {
  let scenario = ProcessScenario::new(
    name="drift",
    center=1.0,
    deviation=0.1,
    lower=None,
    upper=None,
    drift=0.2,
    outlier_probability=0.0,
    seed=7,
  )
  let points = simulate_process(scenario, 4)
  assert_true(observed_simulation_drift(points) is Some(_))
  inspect(simulated_subgroups(scenario, 4, 2) is Some(_), content="true")
}
