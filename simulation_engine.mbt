///|
/// A repeatable simulation scenario for demonstrations and regression tests.
pub(all) struct ProcessScenario {
  name : String
  center : Double
  deviation : Double
  lower : Double?
  upper : Double?
  drift : Double
  outlier_probability : Double
  seed : Int
} derive(Debug, ToJson)

///|
/// One simulated record with its latent cause.
pub(all) struct SimulatedPoint {
  index : Int
  value : Double
  center : Double
  cause : String
  in_spec : Bool
} derive(Debug, ToJson)

///|
/// Summary of a simulation run.
pub(all) struct SimulationSummary {
  scenario : String
  points : Int
  mean : Double?
  deviation : Double?
  defects : Int
  alarms : Int
} derive(Debug, ToJson)

///|
/// Construct a stable process scenario.
pub fn ProcessScenario::new(
  name~ : String,
  center~ : Double,
  deviation~ : Double,
  lower~ : Double?,
  upper~ : Double?,
  drift~ : Double,
  outlier_probability~ : Double,
  seed~ : Int,
) -> ProcessScenario {
  {
    name,
    center,
    deviation: deviation.abs(),
    lower,
    upper,
    drift,
    outlier_probability: outlier_probability.max(0.0).min(1.0),
    seed,
  }
}

///|
/// Generate deterministic pseudo-normal noise by summing uniform draws.
pub fn simulated_noise(seed : Int) -> Double {
  let samples = sample_uniform(12, seed~, lower=-1.0, upper=1.0)
  if samples.length() == 0 {
    0.0
  } else {
    sum_of(samples) / 2.0
  }
}

///|
/// Generate a deterministic process sequence with optional drift and faults.
pub fn simulate_process(
  scenario : ProcessScenario,
  count : Int,
) -> Array[SimulatedPoint] {
  let result : Array[SimulatedPoint] = []
  if count <= 0 {
    result
  } else {
    for index in 0..<count {
      let center = scenario.center + scenario.drift * index.to_double()
      let noise = simulated_noise(scenario.seed + index * 17) *
        scenario.deviation
      let fault_selector = sample_uniform(
        1,
        seed=scenario.seed + index * 31,
        lower=0.0,
        upper=1.0,
      )
      let fault = fault_selector.length() > 0 &&
        fault_selector[0] < scenario.outlier_probability
      let value = if fault {
        center + 4.0 * scenario.deviation
      } else {
        center + noise
      }
      let in_spec = match (scenario.lower, scenario.upper) {
        (Some(lower), Some(upper)) => value >= lower && value <= upper
        _ => true
      }
      let cause = if fault {
        "special-cause"
      } else if scenario.drift != 0.0 {
        "drift"
      } else {
        "common-cause"
      }
      result.push({ index, value, center, cause, in_spec })
    }
    result
  }
}

///|
/// Extract values from simulated points.
pub fn simulated_values(points : Array[SimulatedPoint]) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(point.value)
  }
  result
}

///|
/// Extract latent centers from simulated points.
pub fn simulated_centers(points : Array[SimulatedPoint]) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(point.center)
  }
  result
}

///|
/// Count points by latent cause.
pub fn simulation_causes(
  points : Array[SimulatedPoint],
) -> Array[CategoryCount] {
  let causes : Array[String] = []
  for point in points {
    causes.push(point.cause)
  }
  category_counts(causes)
}

///|
/// Count simulated specification defects.
pub fn simulation_defects(points : Array[SimulatedPoint]) -> Int {
  let mut count = 0
  for point in points {
    if !point.in_spec {
      count += 1
    }
  }
  count
}

///|
/// Count simulated special causes.
pub fn simulation_special_causes(points : Array[SimulatedPoint]) -> Int {
  let mut count = 0
  for point in points {
    if point.cause == "special-cause" {
      count += 1
    }
  }
  count
}

///|
/// Count points beyond three standard deviations from their latent center.
pub fn simulation_alarms(
  points : Array[SimulatedPoint],
  deviation : Double,
) -> Int {
  let mut count = 0
  for point in points {
    if deviation > 0.0 && (point.value - point.center).abs() > 3.0 * deviation {
      count += 1
    }
  }
  count
}

///|
/// Summarize a simulation result.
pub fn summarize_simulation(
  scenario : ProcessScenario,
  points : Array[SimulatedPoint],
) -> SimulationSummary {
  let values = simulated_values(points)
  let mean = if values.length() == 0 { None } else { Some(mean_of(values)) }
  let deviation = if values.length() < 2 {
    None
  } else {
    Some(std_of(values, mean_of(values)))
  }
  {
    scenario: scenario.name,
    points: points.length(),
    mean,
    deviation,
    defects: simulation_defects(points),
    alarms: simulation_alarms(points, scenario.deviation),
  }
}

///|
/// Generate a paired baseline and drifted process for comparison.
pub fn simulate_comparison(
  scenario : ProcessScenario,
  count : Int,
) -> (Array[SimulatedPoint], Array[SimulatedPoint]) {
  let baseline = { ..scenario, drift: 0.0, name: "baseline" }
  let changed = { ..scenario, name: "changed" }
  (simulate_process(baseline, count), simulate_process(changed, count))
}

///|
/// Difference between two simulated sequences.
pub fn simulation_delta(
  first : Array[SimulatedPoint],
  second : Array[SimulatedPoint],
) -> Array[Double]? {
  if first.length() != second.length() {
    None
  } else {
    let result : Array[Double] = []
    for index in 0..<first.length() {
      result.push(second[index].value - first[index].value)
    }
    Some(result)
  }
}

///|
/// Estimate observed drift from latent centers.
pub fn observed_simulation_drift(points : Array[SimulatedPoint]) -> Double? {
  let centers = simulated_centers(points)
  match linear_trend(centers) {
    Some(trend) => Some(trend.slope)
    None => None
  }
}

///|
/// Run a simulation through the streaming monitor.
pub fn simulate_monitor(scenario : ProcessScenario, count : Int) -> Int {
  let points = simulate_process(scenario, count)
  let policy = StreamPolicy::standard(
    lower=scenario.lower,
    upper=scenario.upper,
  )
  replay_stream(
    [
      for point in points => Some(point.value)
    ],
    policy~,
    center=scenario.center,
  )
}

///|
/// Build a synthetic subgroup array for chart examples.
pub fn simulated_subgroups(
  scenario : ProcessScenario,
  count : Int,
  width : Int,
) -> Array[Array[Double]]? {
  if width <= 0 {
    None
  } else {
    match
      subgroup(
        simulated_values(simulate_process(scenario, count * width)),
        width,
      ) {
      Some(groups) => Some(groups)
      None => None
    }
  }
}

///|
/// Generate a deterministic category stream with a controlled defect burst.
pub fn simulated_categories(
  count : Int,
  burst_start : Int,
  burst_length : Int,
) -> Array[String] {
  let result : Array[String] = []
  for index in 0..<count.max(0) {
    if index >= burst_start && index < burst_start + burst_length {
      result.push("special-cause")
    } else {
      result.push("common-cause")
    }
  }
  result
}

///|
/// Compare expected and observed defect counts.
pub fn defect_count_error(expected : Int, observed : Int) -> Int {
  (observed - expected).abs()
}

///|
/// Check whether a simulation met a defect-rate target.
pub fn meets_defect_target(
  points : Array[SimulatedPoint],
  target : Double,
) -> Bool {
  if points.length() == 0 {
    target >= 0.0
  } else {
    simulation_defects(points).to_double() / points.length().to_double() <=
    target
  }
}
