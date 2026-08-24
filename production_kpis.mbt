///|
/// A period-level production record used for OEE and quality reporting.
pub(all) struct ProductionKpi {
  period : String
  planned_units : Int
  started_units : Int
  good_units : Int
  rework_units : Int
  scrap_units : Int
  planned_hours : Double
  run_hours : Double
  downtime_hours : Double
  ideal_cycle_seconds : Double
  total_cost : Double
  quality_cost : Double
} derive(Debug, ToJson)

///|
/// Construct a production record while retaining raw operational quantities.
pub fn production_kpi(
  period~ : String,
  planned_units~ : Int,
  started_units~ : Int,
  good_units~ : Int,
  rework_units~ : Int,
  scrap_units~ : Int,
  planned_hours~ : Double,
  run_hours~ : Double,
  downtime_hours~ : Double,
  ideal_cycle_seconds~ : Double,
  total_cost~ : Double,
  quality_cost~ : Double,
) -> ProductionKpi {
  {
    period,
    planned_units,
    started_units,
    good_units,
    rework_units,
    scrap_units,
    planned_hours,
    run_hours,
    downtime_hours,
    ideal_cycle_seconds,
    total_cost,
    quality_cost,
  }
}

///|
/// Units that entered production but did not become first-pass-good.
pub fn non_first_pass_units(record : ProductionKpi) -> Int {
  (record.started_units - record.good_units).max(0)
}

///|
/// Units not released as good or rework output.
pub fn unaccounted_units(record : ProductionKpi) -> Int {
  (record.started_units -
  record.good_units -
  record.rework_units -
  record.scrap_units).max(0)
}

///|
/// First-pass yield for one period.
pub fn first_pass_yield(record : ProductionKpi) -> Double {
  if record.started_units <= 0 {
    0.0
  } else {
    record.good_units.to_double() / record.started_units.to_double()
  }
}

///|
/// Total output yield including rework output.
pub fn total_yield(record : ProductionKpi) -> Double {
  if record.started_units <= 0 {
    0.0
  } else {
    (record.good_units + record.rework_units).to_double() /
    record.started_units.to_double()
  }
}

///|
/// Rework fraction of started units.
pub fn rework_rate(record : ProductionKpi) -> Double {
  if record.started_units <= 0 {
    0.0
  } else {
    record.rework_units.to_double() / record.started_units.to_double()
  }
}

///|
/// Scrap fraction of started units.
pub fn scrap_rate(record : ProductionKpi) -> Double {
  if record.started_units <= 0 {
    0.0
  } else {
    record.scrap_units.to_double() / record.started_units.to_double()
  }
}

///|
/// Planned production attainment.
pub fn plan_attainment(record : ProductionKpi) -> Double {
  if record.planned_units <= 0 {
    0.0
  } else {
    (record.good_units + record.rework_units).to_double() /
    record.planned_units.to_double()
  }
}

///|
/// Fraction of planned time spent running.
pub fn availability(record : ProductionKpi) -> Double {
  if record.planned_hours <= 0.0 {
    0.0
  } else {
    (record.run_hours / record.planned_hours).max(0.0).min(1.0)
  }
}

///|
/// Performance against the ideal cycle time.
pub fn performance(record : ProductionKpi) -> Double {
  if record.run_hours <= 0.0 || record.ideal_cycle_seconds <= 0.0 {
    0.0
  } else {
    let ideal_hours = (record.good_units + record.rework_units).to_double() *
      record.ideal_cycle_seconds /
      3600.0
    (ideal_hours / record.run_hours).max(0.0).min(1.0)
  }
}

///|
/// Quality component used by the OEE product.
pub fn quality_rate(record : ProductionKpi) -> Double {
  if record.good_units + record.rework_units <= 0 {
    0.0
  } else {
    record.good_units.to_double() /
    (record.good_units + record.rework_units).to_double()
  }
}

///|
/// Overall equipment effectiveness from availability, performance, and quality.
pub fn oee(record : ProductionKpi) -> Double {
  availability(record) * performance(record) * quality_rate(record)
}

///|
/// Hours lost to downtime as a fraction of planned time.
pub fn downtime_rate(record : ProductionKpi) -> Double {
  if record.planned_hours <= 0.0 {
    0.0
  } else {
    (record.downtime_hours / record.planned_hours).max(0.0).min(1.0)
  }
}

///|
/// Units produced per running hour.
pub fn throughput_per_hour(record : ProductionKpi) -> Double {
  if record.run_hours <= 0.0 {
    0.0
  } else {
    (record.good_units + record.rework_units).to_double() / record.run_hours
  }
}

///|
/// Defects per million started units.
pub fn defects_per_million(record : ProductionKpi) -> Double {
  if record.started_units <= 0 {
    0.0
  } else {
    (record.rework_units + record.scrap_units).to_double() *
    1_000_000.0 /
    record.started_units.to_double()
  }
}

///|
/// Cost per released good or rework unit.
pub fn cost_per_output(record : ProductionKpi) -> Double {
  let output = record.good_units + record.rework_units
  if output <= 0 {
    0.0
  } else {
    record.total_cost / output.to_double()
  }
}

///|
/// Quality cost as a fraction of total production cost.
pub fn quality_cost_rate(record : ProductionKpi) -> Double {
  if record.total_cost <= 0.0 {
    0.0
  } else {
    (record.quality_cost / record.total_cost).max(0.0)
  }
}

///|
/// Difference between planned and released output.
pub fn plan_gap(record : ProductionKpi) -> Int {
  record.planned_units - record.good_units - record.rework_units
}

///|
/// Whether the record contains a negative operational quantity.
pub fn kpi_has_invalid_quantity(record : ProductionKpi) -> Bool {
  record.planned_units < 0 ||
  record.started_units < 0 ||
  record.good_units < 0 ||
  record.rework_units < 0 ||
  record.scrap_units < 0
}

///|
/// Whether a period has an impossible output reconciliation.
pub fn kpi_has_reconciliation_gap(record : ProductionKpi) -> Bool {
  unaccounted_units(record) > 0
}

///|
/// A typed validation result for one production record.
pub(all) struct KpiValidation {
  valid : Bool
  issues : Array[String]
  utilization : Double
  quality : Double
  oee_value : Double
} derive(Debug, ToJson)

///|
/// Validate quantities and derive the most important KPI components.
pub fn validate_kpi(record : ProductionKpi) -> KpiValidation {
  let issues : Array[String] = []
  if kpi_has_invalid_quantity(record) {
    issues.push("negative quantity")
  }
  if record.planned_hours < 0.0 ||
    record.run_hours < 0.0 ||
    record.downtime_hours < 0.0 {
    issues.push("negative time")
  }
  if record.run_hours > record.planned_hours && record.planned_hours > 0.0 {
    issues.push("run time exceeds planned time")
  }
  if record.good_units + record.rework_units + record.scrap_units >
    record.started_units {
    issues.push("output exceeds started units")
  }
  {
    valid: issues.length() == 0,
    issues,
    utilization: availability(record),
    quality: quality_rate(record),
    oee_value: oee(record),
  }
}

///|
/// Aggregate period records by summing additive quantities.
pub fn sum_kpis(records : Array[ProductionKpi]) -> ProductionKpi {
  let mut planned = 0
  let mut started = 0
  let mut good = 0
  let mut rework = 0
  let mut scrap = 0
  let mut planned_hours = 0.0
  let mut run_hours = 0.0
  let mut downtime = 0.0
  let mut cost = 0.0
  let mut quality_cost = 0.0
  let mut ideal_cycle = 0.0
  let mut cycle_weight = 0
  for record in records {
    planned += record.planned_units
    started += record.started_units
    good += record.good_units
    rework += record.rework_units
    scrap += record.scrap_units
    planned_hours += record.planned_hours
    run_hours += record.run_hours
    downtime += record.downtime_hours
    cost += record.total_cost
    quality_cost += record.quality_cost
    if record.ideal_cycle_seconds > 0.0 {
      ideal_cycle += record.ideal_cycle_seconds *
        record.started_units.to_double()
      cycle_weight += record.started_units
    }
  }
  let weighted_cycle = if cycle_weight <= 0 {
    0.0
  } else {
    ideal_cycle / cycle_weight.to_double()
  }
  production_kpi(
    period="aggregate",
    planned_units=planned,
    started_units=started,
    good_units=good,
    rework_units=rework,
    scrap_units=scrap,
    planned_hours~,
    run_hours~,
    downtime_hours=downtime,
    ideal_cycle_seconds=weighted_cycle,
    total_cost=cost,
    quality_cost~,
  )
}

///|
/// Return records associated with one production period.
pub fn kpis_for_period(
  records : Array[ProductionKpi],
  period : String,
) -> Array[ProductionKpi] {
  let result : Array[ProductionKpi] = []
  for record in records {
    if record.period == period {
      result.push(record)
    }
  }
  result
}

///|
/// Return all records whose OEE is below a threshold.
pub fn low_oee_records(
  records : Array[ProductionKpi],
  threshold : Double,
) -> Array[ProductionKpi] {
  let result : Array[ProductionKpi] = []
  for record in records {
    if oee(record) < threshold {
      result.push(record)
    }
  }
  result
}

///|
/// Return all records whose scrap rate is above a threshold.
pub fn high_scrap_records(
  records : Array[ProductionKpi],
  threshold : Double,
) -> Array[ProductionKpi] {
  let result : Array[ProductionKpi] = []
  for record in records {
    if scrap_rate(record) > threshold {
      result.push(record)
    }
  }
  result
}

///|
/// A named KPI observation suitable for a dashboard or alert stream.
pub(all) struct KpiObservation {
  period : String
  metric : String
  value : Double
  target : Double?
  lower : Double?
  upper : Double?
} derive(Debug, ToJson)

///|
/// Construct a named KPI observation.
pub fn kpi_observation(
  period~ : String,
  metric~ : String,
  value~ : Double,
  target~ : Double?,
  lower~ : Double?,
  upper~ : Double?,
) -> KpiObservation {
  { period, metric, value, target, lower, upper }
}

///|
/// Signed distance from a target, or zero when no target exists.
pub fn observation_gap(observation : KpiObservation) -> Double {
  match observation.target {
    Some(target) => observation.value - target
    None => 0.0
  }
}

///|
/// Whether an observation violates either configured bound.
pub fn observation_out_of_bounds(observation : KpiObservation) -> Bool {
  match observation.lower {
    Some(lower) => if observation.value < lower { return true }
    None => ()
  }
  match observation.upper {
    Some(upper) => observation.value > upper
    None => false
  }
}

///|
/// Stable status label for an observation.
pub fn observation_status(observation : KpiObservation) -> String {
  if observation_out_of_bounds(observation) {
    "out_of_bounds"
  } else {
    match observation.target {
      Some(target) =>
        if observation.value >= target {
          "on_target"
        } else {
          "below_target"
        }
      None => "informational"
    }
  }
}

///|
/// Observations for one named metric.
pub fn observations_for_metric(
  observations : Array[KpiObservation],
  metric : String,
) -> Array[KpiObservation] {
  let result : Array[KpiObservation] = []
  for observation in observations {
    if observation.metric == metric {
      result.push(observation)
    }
  }
  result
}

///|
/// Count observations outside their configured bounds.
pub fn out_of_bound_count(observations : Array[KpiObservation]) -> Int {
  let mut count = 0
  for observation in observations {
    if observation_out_of_bounds(observation) {
      count += 1
    }
  }
  count
}

///|
/// Fraction of observations meeting their configured target.
pub fn target_compliance_rate(observations : Array[KpiObservation]) -> Double {
  if observations.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for observation in observations {
      if observation_status(observation) == "on_target" {
        count += 1
      }
    }
    count.to_double() / observations.length().to_double()
  }
}

///|
/// Moving averages over an ordered observation sequence.
pub fn rolling_observation_average(
  observations : Array[KpiObservation],
  window : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  for index in 0..<observations.length() {
    let start = (index + 1 - window).max(0)
    let mut total = 0.0
    let mut count = 0
    for cursor in start..<=index {
      total += observations[cursor].value
      count += 1
    }
    result.push(total / count.to_double())
  }
  result
}

///|
/// Moving minimum values over an ordered observation sequence.
pub fn rolling_observation_minimum(
  observations : Array[KpiObservation],
  window : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  for index in 0..<observations.length() {
    let start = (index + 1 - window).max(0)
    let mut value = observations[start].value
    for cursor in start..<=index {
      value = value.min(observations[cursor].value)
    }
    result.push(value)
  }
  result
}

///|
/// Moving maximum values over an ordered observation sequence.
pub fn rolling_observation_maximum(
  observations : Array[KpiObservation],
  window : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  for index in 0..<observations.length() {
    let start = (index + 1 - window).max(0)
    let mut value = observations[start].value
    for cursor in start..<=index {
      value = value.max(observations[cursor].value)
    }
    result.push(value)
  }
  result
}

///|
/// A simple trend summary for a metric series.
pub(all) struct KpiTrend {
  metric : String
  points : Int
  first : Double?
  last : Double?
  slope : Double?
  direction : String
  change : Double?
} derive(Debug, ToJson)

///|
/// Estimate a least-squares trend from observation values.
pub fn summarize_kpi_trend(observations : Array[KpiObservation]) -> KpiTrend {
  let metric = if observations.length() == 0 {
    ""
  } else {
    observations[0].metric
  }
  let first = if observations.length() == 0 {
    None
  } else {
    Some(observations[0].value)
  }
  let last = if observations.length() == 0 {
    None
  } else {
    Some(observations[observations.length() - 1].value)
  }
  let change = match (first, last) {
    (Some(a), Some(b)) => Some(b - a)
    _ => None
  }
  let slope = if observations.length() < 2 {
    None
  } else {
    let mut x_total = 0.0
    let mut y_total = 0.0
    for index, observation in observations {
      x_total += index.to_double()
      y_total += observation.value
    }
    let x_mean = x_total / observations.length().to_double()
    let y_mean = y_total / observations.length().to_double()
    let mut numerator = 0.0
    let mut denominator = 0.0
    for index, observation in observations {
      let x = index.to_double() - x_mean
      numerator += x * (observation.value - y_mean)
      denominator += x * x
    }
    if denominator <= 0.0 {
      None
    } else {
      Some(numerator / denominator)
    }
  }
  let direction = match slope {
    None => "insufficient_data"
    Some(value) =>
      if value > 0.000001 {
        "increasing"
      } else if value < -0.000001 {
        "decreasing"
      } else {
        "stable"
      }
  }
  {
    metric,
    points: observations.length(),
    first,
    last,
    slope,
    direction,
    change,
  }
}

///|
/// Count consecutive observations in the same status.
pub fn consecutive_status_count(
  observations : Array[KpiObservation],
  status : String,
) -> Int {
  let mut count = 0
  let mut index = observations.length() - 1
  while index >= 0 {
    if observation_status(observations[index]) == status {
      count += 1
    } else {
      break
    }
    index -= 1
  }
  count
}

///|
/// Whether the latest observation has persisted below target.
pub fn sustained_below_target(
  observations : Array[KpiObservation],
  periods : Int,
) -> Bool {
  periods > 0 &&
  consecutive_status_count(observations, "below_target") >= periods
}

///|
/// Cost components for one quality event.
pub(all) struct QualityCost {
  period : String
  prevention : Double
  appraisal : Double
  internal_failure : Double
  external_failure : Double
} derive(Debug, ToJson)

///|
/// Construct a cost-of-quality record.
pub fn quality_cost(
  period~ : String,
  prevention~ : Double,
  appraisal~ : Double,
  internal_failure~ : Double,
  external_failure~ : Double,
) -> QualityCost {
  { period, prevention, appraisal, internal_failure, external_failure }
}

///|
/// Total cost of quality.
pub fn total_quality_cost(cost : QualityCost) -> Double {
  cost.prevention +
  cost.appraisal +
  cost.internal_failure +
  cost.external_failure
}

///|
/// Cost invested before a defect occurs.
pub fn prevention_appraisal_cost(cost : QualityCost) -> Double {
  cost.prevention + cost.appraisal
}

///|
/// Failure cost that can be used for Pareto prioritization.
pub fn failure_cost(cost : QualityCost) -> Double {
  cost.internal_failure + cost.external_failure
}

///|
/// Fraction of quality cost spent on failure recovery.
pub fn failure_cost_rate(cost : QualityCost) -> Double {
  let total = total_quality_cost(cost)
  if total <= 0.0 {
    0.0
  } else {
    failure_cost(cost) / total
  }
}

///|
/// Aggregate cost-of-quality records.
pub fn sum_quality_costs(costs : Array[QualityCost]) -> QualityCost {
  let mut prevention = 0.0
  let mut appraisal = 0.0
  let mut internal_failure = 0.0
  let mut external_failure = 0.0
  for cost in costs {
    prevention += cost.prevention
    appraisal += cost.appraisal
    internal_failure += cost.internal_failure
    external_failure += cost.external_failure
  }
  quality_cost(
    period="aggregate",
    prevention~,
    appraisal~,
    internal_failure~,
    external_failure~,
  )
}

///|
/// A threshold alert derived from KPI observations.
pub(all) struct KpiAlert {
  metric : String
  period : String
  status : String
  severity : Int
  gap : Double
  message : String
} derive(Debug, ToJson)

///|
/// Create an alert only when an observation is not on target.
pub fn observation_alert(observation : KpiObservation) -> KpiAlert? {
  let status = observation_status(observation)
  if status == "on_target" || status == "informational" {
    None
  } else {
    let severity = if status == "out_of_bounds" { 3 } else { 2 }
    Some({
      metric: observation.metric,
      period: observation.period,
      status,
      severity,
      gap: observation_gap(observation),
      message: observation.metric + " is " + status,
    })
  }
}

///|
/// Build alerts for a sequence of observations.
pub fn kpi_alerts(observations : Array[KpiObservation]) -> Array[KpiAlert] {
  let result : Array[KpiAlert] = []
  for observation in observations {
    match observation_alert(observation) {
      Some(alert) => result.push(alert)
      None => ()
    }
  }
  result
}

///|
/// Count alerts by severity.
pub fn alert_count_at_least(alerts : Array[KpiAlert], severity : Int) -> Int {
  let mut count = 0
  for alert in alerts {
    if alert.severity >= severity {
      count += 1
    }
  }
  count
}

///|
/// Sort alerts by severity and then period.
pub fn sort_kpi_alerts(alerts : Array[KpiAlert]) -> Array[KpiAlert] {
  let result = alerts.copy()
  result.sort_by(fn(a, b) {
    if a.severity != b.severity {
      b.severity - a.severity
    } else if a.period < b.period {
      -1
    } else if a.period == b.period {
      0
    } else {
      1
    }
  })
  result
}

///|
/// Return a KPI record with a bounded non-negative time budget.
pub fn normalize_kpi_time(record : ProductionKpi) -> ProductionKpi {
  let planned = record.planned_hours.max(0.0)
  let run = record.run_hours.max(0.0).min(planned)
  let downtime = record.downtime_hours.max(0.0).min(planned)
  { ..record, planned_hours: planned, run_hours: run, downtime_hours: downtime }
}

///|
/// Return an efficiency label for operational dashboards.
pub fn oee_band(value : Double) -> String {
  if value >= 0.85 {
    "excellent"
  } else if value >= 0.65 {
    "healthy"
  } else if value >= 0.45 {
    "watch"
  } else {
    "critical"
  }
}

///|
/// Return a yield label for release dashboards.
pub fn yield_band(value : Double) -> String {
  if value >= 0.99 {
    "excellent"
  } else if value >= 0.95 {
    "healthy"
  } else if value >= 0.90 {
    "watch"
  } else {
    "critical"
  }
}
