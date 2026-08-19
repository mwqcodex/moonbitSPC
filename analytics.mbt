///|
/// Additional descriptive statistics for quality engineers.
pub fn sum_of(values : Array[Double]) -> Double {
  let mut result = 0.0
  for value in values {
    result += value
  }
  result
}

///|
pub fn product_of(values : Array[Double]) -> Double {
  let mut result = 1.0
  for value in values {
    result *= value
  }
  result
}

///|
pub fn weighted_mean(
  values : Array[Double],
  weights : Array[Double],
) -> Double? {
  if values.length() == 0 || values.length() != weights.length() {
    None
  } else {
    let mut numerator = 0.0
    let mut denominator = 0.0
    for index in 0..<values.length() {
      if weights[index] < 0.0 {
        return None
      }
      numerator += values[index] * weights[index]
      denominator += weights[index]
    }
    if denominator == 0.0 {
      None
    } else {
      Some(numerator / denominator)
    }
  }
}

///|
pub fn geometric_mean(values : Array[Double]) -> Double? {
  if values.length() == 0 {
    None
  } else {
    let mut total = 1.0
    for value in values {
      if value <= 0.0 {
        return None
      }
      total *= value
    }
    Some(nth_root(total, values.length()))
  }
}

///|
/// Binary-search an integer-degree root using only multiplication.
fn nth_root(value : Double, degree : Int) -> Double {
  let mut low = 0.0
  let mut high = value.max(1.0)
  for _ in 0..<48 {
    let middle = (low + high) / 2.0
    let mut power = 1.0
    for _ in 0..<degree {
      power *= middle
    }
    if power < value {
      low = middle
    } else {
      high = middle
    }
  }
  (low + high) / 2.0
}

///|
pub fn harmonic_mean(values : Array[Double]) -> Double? {
  if values.length() == 0 {
    None
  } else {
    let mut reciprocal = 0.0
    for value in values {
      if value <= 0.0 {
        return None
      }
      reciprocal += 1.0 / value
    }
    Some(values.length().to_double() / reciprocal)
  }
}

///|
pub fn covariance(first : Array[Double], second : Array[Double]) -> Double? {
  if first.length() < 2 || first.length() != second.length() {
    None
  } else {
    let first_mean = mean_of(first)
    let second_mean = mean_of(second)
    let mut total = 0.0
    for index in 0..<first.length() {
      total += (first[index] - first_mean) * (second[index] - second_mean)
    }
    Some(total / (first.length() - 1).to_double())
  }
}

///|
pub fn correlation(first : Array[Double], second : Array[Double]) -> Double? {
  match
    (
      covariance(first, second),
      covariance(first, first),
      covariance(second, second),
    ) {
    (Some(cross), Some(first_var), Some(second_var)) =>
      if first_var <= 0.0 || second_var <= 0.0 {
        None
      } else {
        Some(cross / (first_var * second_var).sqrt())
      }
    _ => None
  }
}

///|
pub fn autocorrelation(values : Array[Double], lag : Int) -> Double? {
  if lag < 0 || lag >= values.length() || values.length() - lag < 2 {
    None
  } else {
    let first : Array[Double] = []
    let second : Array[Double] = []
    for index in lag..<values.length() {
      first.push(values[index])
      second.push(values[index - lag])
    }
    correlation(first, second)
  }
}

///|
/// A compact count/frequency table for integer-coded quality states.
pub(all) struct Frequency {
  value : Int
  count : Int
  proportion : Double
} derive(Debug, ToJson)

///|
pub fn frequencies(values : Array[Int]) -> Array[Frequency] {
  let result : Array[Frequency] = []
  for value in values {
    let mut found = false
    for entry in result {
      if entry.value == value {
        found = true
      }
    }
    if !found {
      result.push({ value, count: 0, proportion: 0.0 })
    }
  }
  for index in 0..<result.length() {
    let mut count = 0
    for value in values {
      if value == result[index].value {
        count += 1
      }
    }
    result[index] = {
      value: result[index].value,
      count,
      proportion: if values.length() == 0 {
        0.0
      } else {
        count.to_double() / values.length().to_double()
      },
    }
  }
  result
}

///|
/// Minimum of each rolling window.
pub fn rolling_min(values : Array[Double], width : Int) -> Array[Double]? {
  rolling_extreme(values, width, true)
}

///|
/// Maximum of each rolling window.
pub fn rolling_max(values : Array[Double], width : Int) -> Array[Double]? {
  rolling_extreme(values, width, false)
}

///|
fn rolling_extreme(
  values : Array[Double],
  width : Int,
  minimum : Bool,
) -> Array[Double]? {
  if width <= 0 || width > values.length() {
    None
  } else {
    let result : Array[Double] = []
    for start in 0..<(values.length() - width + 1) {
      let mut extreme = values[start]
      for index in (start + 1)..<(start + width) {
        if minimum {
          extreme = extreme.min(values[index])
        } else {
          extreme = extreme.max(values[index])
        }
      }
      result.push(extreme)
    }
    Some(result)
  }
}

///|
/// Range of each rolling window.
pub fn rolling_range(values : Array[Double], width : Int) -> Array[Double]? {
  match (rolling_min(values, width), rolling_max(values, width)) {
    (Some(low), Some(high)) => {
      let result : Array[Double] = []
      for index in 0..<low.length() {
        result.push(high[index] - low[index])
      }
      Some(result)
    }
    _ => None
  }
}

///|
/// Remove a symmetric fraction of the smallest and largest observations.
pub fn trimmed(values : Array[Double], fraction : Double) -> Array[Double]? {
  if fraction < 0.0 || fraction >= 0.5 || values.length() == 0 {
    None
  } else {
    let ordered = sorted_copy(values)
    let remove = (fraction * values.length().to_double()).to_int()
    let result : Array[Double] = []
    for index in remove..<(ordered.length() - remove) {
      result.push(ordered[index])
    }
    Some(result)
  }
}

///|
/// Replace tail observations with the nearest retained quantile.
pub fn winsorized(values : Array[Double], fraction : Double) -> Array[Double]? {
  if fraction < 0.0 || fraction >= 0.5 || values.length() == 0 {
    None
  } else {
    let ordered = sorted_copy(values)
    let amount = (fraction * values.length().to_double()).to_int()
    let low = ordered[amount]
    let high = ordered[ordered.length() - amount - 1]
    let result : Array[Double] = []
    for value in values {
      result.push(value.max(low).min(high))
    }
    Some(result)
  }
}

///|
/// Clamp every measurement to a trusted engineering interval.
pub fn clipped(
  values : Array[Double],
  lower : Double,
  upper : Double,
) -> Array[Double]? {
  if lower > upper {
    None
  } else {
    let result : Array[Double] = []
    for value in values {
      result.push(value.max(lower).min(upper))
    }
    Some(result)
  }
}

///|
/// Histogram bin with an inclusive lower and exclusive upper edge.
pub(all) struct HistogramBin {
  lower : Double
  upper : Double
  count : Int
  proportion : Double
} derive(Debug, ToJson)

///|
pub fn histogram(values : Array[Double], bins : Int) -> Array[HistogramBin]? {
  if values.length() == 0 || bins <= 0 {
    None
  } else {
    let mut low = values[0]
    let mut high = values[0]
    for value in values {
      low = low.min(value)
      high = high.max(value)
    }
    if low == high {
      None
    } else {
      let width = (high - low) / bins.to_double()
      let counts : Array[Int] = []
      for _ in 0..<bins {
        counts.push(0)
      }
      for value in values {
        let mut index = ((value - low) / width).to_int()
        if index >= bins {
          index = bins - 1
        }
        counts[index] += 1
      }
      let result : Array[HistogramBin] = []
      for index in 0..<bins {
        result.push({
          lower: low + index.to_double() * width,
          upper: low + (index + 1).to_double() * width,
          count: counts[index],
          proportion: counts[index].to_double() / values.length().to_double(),
        })
      }
      Some(result)
    }
  }
}

///|
/// Percentile rank of a measurement, with ties counted as half.
pub fn percentile_rank(values : Array[Double], value : Double) -> Double? {
  if values.length() == 0 {
    None
  } else {
    let mut below = 0
    let mut equal = 0
    for candidate in values {
      if candidate < value {
        below += 1
      }
      if candidate == value {
        equal += 1
      }
    }
    Some(
      (below.to_double() + 0.5 * equal.to_double()) /
      values.length().to_double(),
    )
  }
}

///|
/// Standard error of the sample mean.
pub fn standard_error(values : Array[Double]) -> Double? {
  if values.length() < 2 {
    None
  } else {
    Some(std_of(values, mean_of(values)) / values.length().to_double().sqrt())
  }
}

///|
/// Approximate 95 percent confidence interval for a mean.
pub fn confidence_interval_95(values : Array[Double]) -> (Double, Double)? {
  match standard_error(values) {
    None => None
    Some(error) => {
      let center = mean_of(values)
      Some((center - 1.96 * error, center + 1.96 * error))
    }
  }
}

///|
/// Pooled sample deviation for independent subgroups.
pub fn pooled_standard_deviation(groups : Array[Array[Double]]) -> Double? {
  let mut degrees = 0
  let mut total = 0.0
  for group in groups {
    if group.length() < 2 {
      return None
    }
    let mean = mean_of(group)
    for value in group {
      let delta = value - mean
      total += delta * delta
    }
    degrees += group.length() - 1
  }
  if degrees <= 0 {
    None
  } else {
    Some((total / degrees.to_double()).sqrt())
  }
}

///|
/// Boolean outlier markers using the interquartile range fence.
pub fn iqr_outliers(
  values : Array[Double],
  multiplier : Double,
) -> Array[Bool]? {
  if multiplier < 0.0 {
    None
  } else {
    match (quantile(values, 0.25), quantile(values, 0.75)) {
      (Some(first), Some(third)) => {
        let spread = third - first
        let low = first - multiplier * spread
        let high = third + multiplier * spread
        let result : Array[Bool] = []
        for value in values {
          result.push(value < low || value > high)
        }
        Some(result)
      }
      _ => None
    }
  }
}

///|
/// Count sign changes around a center line.
pub fn sign_changes(values : Array[Double], center : Double) -> Int {
  let mut changes = 0
  let mut previous : Int? = None
  for value in values {
    let sign = if value > center { 1 } else if value < center { -1 } else { 0 }
    if sign != 0 {
      match previous {
        Some(old) => if old != sign { changes += 1 }
        None => ()
      }
      previous = Some(sign)
    }
  }
  changes
}

///|
/// Longest consecutive run on either side of a center line.
pub fn longest_run(values : Array[Double], center : Double) -> Int {
  let mut longest = 0
  let mut current = 0
  let mut side = 0
  for value in values {
    let next = if value > center { 1 } else if value < center { -1 } else { 0 }
    if next == 0 {
      current = 0
      side = 0
    } else if next == side {
      current += 1
    } else {
      current = 1
      side = next
    }
    longest = longest.max(current)
  }
  longest
}

///|
/// Count monotonic direction changes, useful for tool-wear review.
pub fn direction_changes(values : Array[Double]) -> Int {
  if values.length() < 3 {
    0
  } else {
    let mut changes = 0
    let mut previous = values[1] - values[0]
    for index in 2..<values.length() {
      let current = values[index] - values[index - 1]
      if current != 0.0 &&
        previous != 0.0 &&
        (current > 0.0) != (previous > 0.0) {
        changes += 1
      }
      if current != 0.0 {
        previous = current
      }
    }
    changes
  }
}
