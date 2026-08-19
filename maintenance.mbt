///|
/// Maintenance record for a machine or cutting tool.
pub(all) struct MaintenanceRecord {
  asset : String
  event : String
  timestamp : String
  runtime_hours : Double
  severity : Int
  note : String
} derive(Debug, ToJson)

///|
/// Tool-life observation linked to a production run.
pub(all) struct ToolLifePoint {
  tool : String
  runtime_hours : Double
  wear : Double
  threshold : Double
  exceeded : Bool
} derive(Debug, ToJson)

///|
/// Create a maintenance record.
pub fn MaintenanceRecord::new(
  asset~ : String,
  event~ : String,
  timestamp~ : String,
  runtime_hours~ : Double,
  severity~ : Int,
  note~ : String,
) -> MaintenanceRecord {
  {
    asset,
    event,
    timestamp,
    runtime_hours,
    severity: severity.max(0).min(5),
    note,
  }
}

///|
/// Create a tool-life observation.
pub fn ToolLifePoint::new(
  tool~ : String,
  runtime_hours~ : Double,
  wear~ : Double,
  threshold~ : Double,
) -> ToolLifePoint {
  { tool, runtime_hours, wear, threshold, exceeded: wear >= threshold }
}

///|
/// Return maintenance records for one asset.
pub fn asset_records(
  records : Array[MaintenanceRecord],
  asset : String,
) -> Array[MaintenanceRecord] {
  let result : Array[MaintenanceRecord] = []
  for record in records {
    if record.asset == asset {
      result.push(record)
    }
  }
  result
}

///|
/// Return records above a severity threshold.
pub fn severe_records(
  records : Array[MaintenanceRecord],
  threshold : Int,
) -> Array[MaintenanceRecord] {
  let result : Array[MaintenanceRecord] = []
  for record in records {
    if record.severity >= threshold {
      result.push(record)
    }
  }
  result
}

///|
/// Count records by event name.
pub fn maintenance_event_counts(
  records : Array[MaintenanceRecord],
) -> Array[CategoryCount] {
  let names : Array[String] = []
  for record in records {
    names.push(record.event)
  }
  category_counts(names)
}

///|
/// Sum runtime recorded for an asset.
pub fn asset_runtime(
  records : Array[MaintenanceRecord],
  asset : String,
) -> Double {
  let mut total = 0.0
  for record in records {
    if record.asset == asset {
      total += record.runtime_hours.max(0.0)
    }
  }
  total
}

///|
/// Average repair severity for an asset.
pub fn average_severity(
  records : Array[MaintenanceRecord],
  asset : String,
) -> Double? {
  let selected = asset_records(records, asset)
  if selected.length() == 0 {
    None
  } else {
    let mut total = 0
    for record in selected {
      total += record.severity
    }
    Some(total.to_double() / selected.length().to_double())
  }
}

///|
/// Mean time between recorded maintenance events.
pub fn mean_time_between_events(
  records : Array[MaintenanceRecord],
  asset : String,
) -> Double? {
  let selected = asset_records(records, asset)
  if selected.length() < 2 {
    None
  } else {
    let mut total = 0.0
    for index in 1..<selected.length() {
      total += (selected[index].runtime_hours -
      selected[index - 1].runtime_hours).abs()
    }
    Some(total / (selected.length() - 1).to_double())
  }
}

///|
/// A reliability summary for one asset.
pub(all) struct ReliabilitySummary {
  asset : String
  events : Int
  runtime_hours : Double
  mean_between_events : Double?
  severe_events : Int
  risk_score : Double
} derive(Debug, ToJson)

///|
/// Build a reliability summary using event frequency and severity.
pub fn reliability_summary(
  records : Array[MaintenanceRecord],
  asset : String,
  severe_threshold~ : Int,
) -> ReliabilitySummary {
  let selected = asset_records(records, asset)
  let severe = severe_records(selected, severe_threshold).length()
  let severity = average_severity(selected, asset).unwrap_or(0.0)
  let runtime = asset_runtime(selected, asset)
  let risk = if runtime <= 0.0 {
    severity
  } else {
    severity * (1.0 + severe.to_double() / runtime)
  }
  {
    asset,
    events: selected.length(),
    runtime_hours: runtime,
    mean_between_events: mean_time_between_events(selected, asset),
    severe_events: severe,
    risk_score: risk,
  }
}

///|
/// Fit a linear wear trend against runtime.
pub fn wear_trend(points : Array[ToolLifePoint]) -> Trend? {
  let runtime : Array[Double] = []
  let wear : Array[Double] = []
  for point in points {
    runtime.push(point.runtime_hours)
    wear.push(point.wear)
  }
  if runtime.length() < 2 {
    None
  } else {
    let matrix : Array[Double] = []
    for index in 0..<runtime.length() {
      matrix.push(wear[index])
    }
    linear_trend(matrix)
  }
}

///|
/// Predict runtime at which a wear threshold will be exceeded.
pub fn predicted_tool_limit(points : Array[ToolLifePoint]) -> Double? {
  if points.length() < 2 {
    None
  } else {
    let values : Array[Double] = []
    let runtime : Array[Double] = []
    for point in points {
      values.push(point.wear)
      runtime.push(point.runtime_hours)
    }
    match linear_trend(values) {
      Some(trend) =>
        if trend.slope <= 0.0 {
          None
        } else {
          Some((points[0].threshold - trend.intercept) / trend.slope)
        }
      None => None
    }
  }
}

///|
/// Count tools that have exceeded their wear threshold.
pub fn exceeded_tool_count(points : Array[ToolLifePoint]) -> Int {
  let mut count = 0
  for point in points {
    if point.exceeded {
      count += 1
    }
  }
  count
}

///|
/// Return tools with the highest current wear.
pub fn highest_wear(
  points : Array[ToolLifePoint],
  limit : Int,
) -> Array[ToolLifePoint] {
  let sorted = points.copy()
  for index in 1..<sorted.length() {
    let value = sorted[index]
    let mut cursor = index
    while cursor > 0 && sorted[cursor - 1].wear < value.wear {
      sorted[cursor] = sorted[cursor - 1]
      cursor -= 1
    }
    sorted[cursor] = value
  }
  let output : Array[ToolLifePoint] = []
  for index in 0..<limit.min(sorted.length()) {
    output.push(sorted[index])
  }
  output
}

///|
/// Estimate remaining wear margin.
pub fn remaining_wear(point : ToolLifePoint) -> Double {
  (point.threshold - point.wear).max(0.0)
}

///|
/// Estimate a normalized wear percentage.
pub fn wear_percentage(point : ToolLifePoint) -> Double {
  if point.threshold <= 0.0 {
    1.0
  } else {
    (point.wear / point.threshold).max(0.0)
  }
}

///|
/// Return a warning when wear reaches a configurable fraction.
pub fn wear_warning(point : ToolLifePoint, fraction : Double) -> Bool {
  wear_percentage(point) >= fraction
}

///|
/// Group wear observations by tool identifier.
pub fn group_tool_life(points : Array[ToolLifePoint]) -> Array[String] {
  let result : Array[String] = []
  for point in points {
    let mut found = false
    for tool in result {
      if tool == point.tool {
        found = true
      }
    }
    if !found {
      result.push(point.tool)
    }
  }
  result
}

///|
/// Average wear for one tool.
pub fn average_tool_wear(
  points : Array[ToolLifePoint],
  tool : String,
) -> Double? {
  let mut total = 0.0
  let mut count = 0
  for point in points {
    if point.tool == tool {
      total += point.wear
      count += 1
    }
  }
  if count == 0 {
    None
  } else {
    Some(total / count.to_double())
  }
}

///|
/// Maximum runtime observed for one tool.
pub fn maximum_tool_runtime(
  points : Array[ToolLifePoint],
  tool : String,
) -> Double? {
  let mut result : Double? = None
  for point in points {
    if point.tool == tool {
      result = match result {
        None => Some(point.runtime_hours)
        Some(value) => Some(value.max(point.runtime_hours))
      }
    }
  }
  result
}

///|
/// Normalize runtime/wear points to a common interval.
pub fn normalize_wear_points(points : Array[ToolLifePoint]) -> Array[Double] {
  let values : Array[Double] = []
  for point in points {
    values.push(wear_percentage(point))
  }
  values
}
