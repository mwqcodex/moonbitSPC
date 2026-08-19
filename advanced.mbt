///|
/// Robust location and spread estimators used by offline quality reviews.
pub fn sorted_copy(values : Array[Double]) -> Array[Double] {
  let output = values.copy()
  for i in 1..<output.length() {
    let value = output[i]
    let mut j = i
    while j > 0 && output[j - 1] > value {
      output[j] = output[j - 1]
      j -= 1
    }
    output[j] = value
  }
  output
}

///|
/// Linearly interpolated quantile in the closed probability interval.
pub fn quantile(values : Array[Double], probability : Double) -> Double? {
  if values.length() == 0 || probability < 0.0 || probability > 1.0 {
    None
  } else {
    let ordered = sorted_copy(values)
    if ordered.length() == 1 {
      Some(ordered[0])
    } else {
      let position = probability * (ordered.length() - 1).to_double()
      let lower = position.to_int()
      let upper = if lower + 1 >= ordered.length() { lower } else { lower + 1 }
      let fraction = position - lower.to_double()
      Some(ordered[lower] + (ordered[upper] - ordered[lower]) * fraction)
    }
  }
}

///|
pub fn median(values : Array[Double]) -> Double? {
  quantile(values, 0.5)
}

///|
/// Median absolute deviation, a robust estimate of process spread.
pub fn mad(values : Array[Double]) -> Double? {
  match median(values) {
    None => None
    Some(center) => {
      let distances : Array[Double] = []
      for value in values {
        distances.push((value - center).abs())
      }
      median(distances)
    }
  }
}

///|
/// Interquartile range.
pub fn iqr(values : Array[Double]) -> Double? {
  match (quantile(values, 0.25), quantile(values, 0.75)) {
    (Some(low), Some(high)) => Some(high - low)
    _ => None
  }
}

///|
/// Population z-scores using the supplied baseline center and deviation.
pub fn z_scores(
  values : Array[Double],
  center : Double,
  deviation : Double,
) -> Array[Double]? {
  if deviation <= 0.0 {
    None
  } else {
    let result : Array[Double] = []
    for value in values {
      result.push((value - center) / deviation)
    }
    Some(result)
  }
}

///|
/// Exponentially weighted moving average. Invalid smoothing factors return None.
pub fn ewma(
  values : Array[Double],
  lambda~ : Double,
  initial~ : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if lambda < 0.0 || lambda > 1.0 {
    result
  } else {
    let mut previous = initial
    for value in values {
      previous = lambda * value + (1.0 - lambda) * previous
      result.push(previous)
    }
    result
  }
}

///|
/// Two-sided cumulative-sum chart statistic.
pub fn cusum(
  values : Array[Double],
  target~ : Double,
  allowance~ : Double,
  decision~ : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if allowance < 0.0 || decision <= 0.0 {
    result
  } else {
    let mut positive = 0.0
    let mut negative = 0.0
    for value in values {
      positive = (positive + value - target - allowance).max(0.0)
      negative = (negative + target - allowance - value).max(0.0)
      if positive >= decision || negative >= decision {
        result.push(if positive >= negative { positive } else { -negative })
      } else {
        result.push(if positive > 0.0 { positive } else { -negative })
      }
    }
    result
  }
}

///|
/// Arithmetic means for all contiguous windows of a fixed width.
pub fn moving_mean(values : Array[Double], width : Int) -> Array[Double]? {
  if width <= 0 || width > values.length() {
    None
  } else {
    let result : Array[Double] = []
    let mut sum = 0.0
    for i in 0..<width {
      sum += values[i]
    }
    result.push(sum / width.to_double())
    for start in 1..<(values.length() - width + 1) {
      sum += values[start + width - 1] - values[start - 1]
      result.push(sum / width.to_double())
    }
    Some(result)
  }
}

///|
/// Moving sample deviations for a fixed-width window.
pub fn moving_std(values : Array[Double], width : Int) -> Array[Double]? {
  if width <= 1 || width > values.length() {
    None
  } else {
    let result : Array[Double] = []
    for start in 0..<(values.length() - width + 1) {
      let window : Array[Double] = []
      for i in start..<(start + width) {
        window.push(values[i])
      }
      result.push(std_of(window, mean_of(window)))
    }
    Some(result)
  }
}

///|
/// A deterministic validation message attached to a source index.
pub(all) struct ValidationIssue {
  index : Int
  field : String
  message : String
} derive(Debug, ToJson)

///|
/// Validate traceability fields and measurement cardinality.
pub fn validate_subgroups(groups : Array[Subgroup]) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  for index, group in groups {
    if group.values.length() == 0 {
      issues.push({
        index,
        field: "values",
        message: "subgroup must contain a measurement",
      })
    }
    if group.batch.length() == 0 {
      issues.push({
        index,
        field: "batch",
        message: "batch identifier must not be empty",
      })
    }
    if group.equipment.length() == 0 {
      issues.push({
        index,
        field: "equipment",
        message: "equipment identifier must not be empty",
      })
    }
    if group.tool.length() == 0 {
      issues.push({
        index,
        field: "tool",
        message: "tool identifier must not be empty",
      })
    }
    if group.operator.length() == 0 {
      issues.push({
        index,
        field: "operator",
        message: "operator identifier must not be empty",
      })
    }
    if group.window.length() == 0 {
      issues.push({
        index,
        field: "window",
        message: "time window must not be empty",
      })
    }
  }
  issues
}

///|
/// Validate non-negative counts and positive exposure values.
pub fn validate_counts(
  counts : Array[Int],
  exposures : Array[Int],
) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if counts.length() != exposures.length() {
    issues.push({
      index: -1,
      field: "length",
      message: "counts and exposures must have equal length",
    })
  } else {
    for index in 0..<counts.length() {
      if counts[index] < 0 {
        issues.push({
          index,
          field: "count",
          message: "count must be non-negative",
        })
      }
      if exposures[index] <= 0 {
        issues.push({
          index,
          field: "exposure",
          message: "exposure must be positive",
        })
      }
      if counts[index] > exposures[index] {
        issues.push({
          index,
          field: "count",
          message: "count must not exceed exposure",
        })
      }
    }
  }
  issues
}

///|
/// Validate a specification before capability analysis.
pub fn validate_specification(
  specification : Specification,
) -> Array[ValidationIssue] {
  if specification.lower < specification.upper {
    []
  } else {
    [
      {
        index: -1,
        field: "specification",
        message: "lower bound must be below upper bound",
      },
    ]
  }
}

///|
/// Split measurements into fixed-size groups without silently dropping a tail.
pub fn subgroup(values : Array[Double], width : Int) -> Array[Array[Double]]? {
  if width <= 0 || values.length() == 0 || values.length() % width != 0 {
    None
  } else {
    let groups : Array[Array[Double]] = []
    let mut start = 0
    while start < values.length() {
      let group : Array[Double] = []
      for index in start..<(start + width) {
        group.push(values[index])
      }
      groups.push(group)
      start += width
    }
    Some(groups)
  }
}

///|
/// Normalize values to a unit interval; constant inputs are rejected.
pub fn min_max_scale(values : Array[Double]) -> Array[Double]? {
  if values.length() == 0 {
    None
  } else {
    let mut low = values[0]
    let mut high = values[0]
    for value in values {
      low = low.min(value)
      high = high.max(value)
    }
    if high == low {
      None
    } else {
      let result : Array[Double] = []
      for value in values {
        result.push((value - low) / (high - low))
      }
      Some(result)
    }
  }
}
