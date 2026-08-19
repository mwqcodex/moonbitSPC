///|
/// A reason why a measurement was changed or rejected during preprocessing.
pub(all) struct CleanIssue {
  index : Int
  code : String
  message : String
  original : Double?
  replacement : Double?
} derive(Debug, ToJson)

///|
/// Result of a deterministic measurement-cleaning pass.
pub(all) struct CleanResult {
  values : Array[Double]
  original_count : Int
  removed : Int
  replaced : Int
  issues : Array[CleanIssue]
} derive(Debug, ToJson)

///|
/// A nullable series is useful when an upstream sensor reports missing values.
pub type MaybeMeasurement = Double?

///|
/// Filter values outside an engineering interval and retain an audit trail.
pub fn clean_values(
  values : Array[Double],
  lower~ : Double,
  upper~ : Double,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  let mut removed = 0
  if lower > upper {
    issues.push({
      index: -1,
      code: "INVALID_LIMITS",
      message: "lower limit exceeds upper limit",
      original: None,
      replacement: None,
    })
    {
      values: output,
      original_count: values.length(),
      removed: values.length(),
      replaced: 0,
      issues,
    }
  } else {
    for index, value in values {
      if value < lower || value > upper {
        removed += 1
        issues.push({
          index,
          code: "OUT_OF_RANGE",
          message: "measurement removed outside engineering interval",
          original: Some(value),
          replacement: None,
        })
      } else {
        output.push(value)
      }
    }
    {
      values: output,
      original_count: values.length(),
      removed,
      replaced: 0,
      issues,
    }
  }
}

///|
/// Replace out-of-range values with a boundary instead of dropping them.
pub fn clamp_values(
  values : Array[Double],
  lower~ : Double,
  upper~ : Double,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  let mut replaced = 0
  if lower > upper {
    issues.push({
      index: -1,
      code: "INVALID_LIMITS",
      message: "lower limit exceeds upper limit",
      original: None,
      replacement: None,
    })
    {
      values: [],
      original_count: values.length(),
      removed: values.length(),
      replaced: 0,
      issues,
    }
  } else {
    for index, value in values {
      let replacement = value.max(lower).min(upper)
      if replacement != value {
        replaced += 1
        issues.push({
          index,
          code: "CLAMPED",
          message: "measurement replaced by nearest boundary",
          original: Some(value),
          replacement: Some(replacement),
        })
      }
      output.push(replacement)
    }
    {
      values: output,
      original_count: values.length(),
      removed: 0,
      replaced,
      issues,
    }
  }
}

///|
/// Replace missing interior points by linear interpolation.
pub fn interpolate_missing(
  values : Array[MaybeMeasurement],
) -> Array[MaybeMeasurement] {
  let output = values.copy()
  for index in 0..<output.length() {
    if output[index] is None {
      match surrounding_values(values, index) {
        Some((left, right, distance)) =>
          output[index] = Some(left + (right - left) / distance.to_double())
        None => ()
      }
    }
  }
  output
}

///|
fn surrounding_values(
  values : Array[MaybeMeasurement],
  index : Int,
) -> (Double, Double, Int)? {
  let mut left_index = index - 1
  let mut left : Double? = None
  while left_index >= 0 {
    match values[left_index] {
      Some(value) => {
        left = Some(value)
        break
      }
      None => left_index -= 1
    }
  }
  let mut right_index = index + 1
  let mut right : Double? = None
  while right_index < values.length() {
    match values[right_index] {
      Some(value) => {
        right = Some(value)
        break
      }
      None => right_index += 1
    }
  }
  match (left, right) {
    (Some(first), Some(second)) =>
      Some((first, second, right_index - left_index))
    _ => None
  }
}

///|
/// Replace every missing point with a caller-supplied process center.
pub fn fill_missing(
  values : Array[MaybeMeasurement],
  replacement : Double,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  let mut replaced = 0
  for index, value in values {
    match value {
      Some(number) => output.push(number)
      None => {
        replaced += 1
        output.push(replacement)
        issues.push({
          index,
          code: "MISSING_FILLED",
          message: "missing measurement filled by policy",
          original: None,
          replacement: Some(replacement),
        })
      }
    }
  }
  {
    values: output,
    original_count: values.length(),
    removed: 0,
    replaced,
    issues,
  }
}

///|
/// Return the first difference of a series, preserving time order.
pub fn first_difference(values : Array[Double]) -> Array[Double] {
  let output : Array[Double] = []
  if values.length() >= 2 {
    for index in 1..<values.length() {
      output.push(values[index] - values[index - 1])
    }
  }
  output
}

///|
/// Return the second difference for acceleration and tool-wear diagnostics.
pub fn second_difference(values : Array[Double]) -> Array[Double] {
  first_difference(first_difference(values))
}

///|
/// Cumulative sum for material balance and defect accumulation charts.
pub fn cumulative_sum(values : Array[Double]) -> Array[Double] {
  let output : Array[Double] = []
  let mut total = 0.0
  for value in values {
    total += value
    output.push(total)
  }
  output
}

///|
/// Cumulative product for multiplicative reliability factors.
pub fn cumulative_product(values : Array[Double]) -> Array[Double] {
  let output : Array[Double] = []
  let mut total = 1.0
  for value in values {
    total *= value
    output.push(total)
  }
  output
}

///|
/// Shift a series by a non-negative lag; the leading positions retain source values.
pub fn lag_values(values : Array[Double], lag : Int) -> Array[Double] {
  let output : Array[Double] = []
  if lag <= 0 || lag >= values.length() {
    for value in values {
      output.push(value)
    }
  } else {
    for index in 0..<values.length() {
      output.push(if index < lag { values[0] } else { values[index - lag] })
    }
  }
  output
}

///|
/// Shift a series forward and fill its tail with the final value.
pub fn lead_values(values : Array[Double], lead : Int) -> Array[Double] {
  let output : Array[Double] = []
  if values.length() == 0 || lead <= 0 || lead >= values.length() {
    for value in values {
      output.push(value)
    }
  } else {
    let final_value = values[values.length() - 1]
    for index in 0..<values.length() {
      output.push(
        if index + lead < values.length() {
          values[index + lead]
        } else {
          final_value
        },
      )
    }
  }
  output
}

///|
/// Normalize a series by its first observation.
pub fn relative_to_first(values : Array[Double]) -> Array[Double]? {
  if values.length() == 0 || values[0] == 0.0 {
    None
  } else {
    let output : Array[Double] = []
    for value in values {
      output.push(value / values[0])
    }
    Some(output)
  }
}

///|
/// Normalize a series by its last observation.
pub fn relative_to_last(values : Array[Double]) -> Array[Double]? {
  if values.length() == 0 || values[values.length() - 1] == 0.0 {
    None
  } else {
    let output : Array[Double] = []
    let final_value = values[values.length() - 1]
    for value in values {
      output.push(value / final_value)
    }
    Some(output)
  }
}

///|
/// Center values around a supplied reference.
pub fn center_values(values : Array[Double], center : Double) -> Array[Double] {
  let output : Array[Double] = []
  for value in values {
    output.push(value - center)
  }
  output
}

///|
/// Scale values by a positive engineering scale.
pub fn scale_values(values : Array[Double], scale : Double) -> Array[Double]? {
  if scale == 0.0 {
    None
  } else {
    let output : Array[Double] = []
    for value in values {
      output.push(value / scale)
    }
    Some(output)
  }
}

///|
/// Apply a center and scale transformation.
pub fn standardize_values(
  values : Array[Double],
  center : Double,
  scale : Double,
) -> Array[Double]? {
  match scale_values(center_values(values, center), scale) {
    Some(output) => Some(output)
    None => None
  }
}

///|
/// Remove adjacent duplicate sensor readings.
pub fn deduplicate_adjacent(values : Array[Double]) -> Array[Double] {
  let output : Array[Double] = []
  for value in values {
    match output.last() {
      Some(previous) => if previous != value { output.push(value) }
      None => output.push(value)
    }
  }
  output
}

///|
/// Remove values that repeat more than a configured run length.
pub fn limit_repeated_runs(
  values : Array[Double],
  maximum : Int,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  let mut removed = 0
  if maximum <= 0 {
    for index, value in values {
      issues.push({
        index,
        code: "RUN_REMOVED",
        message: "all values rejected by non-positive run limit",
        original: Some(value),
        replacement: None,
      })
      removed += 1
    }
    {
      values: output,
      original_count: values.length(),
      removed,
      replaced: 0,
      issues,
    }
  } else {
    let mut previous : Double? = None
    let mut run = 0
    for index, value in values {
      if previous is Some(_) {
        run += 1
      } else {
        run = 1
      }
      if run <= maximum {
        output.push(value)
      } else {
        removed += 1
        issues.push({
          index,
          code: "RUN_TRIMMED",
          message: "repeated sensor run exceeded policy",
          original: Some(value),
          replacement: None,
        })
      }
      previous = Some(value)
    }
    {
      values: output,
      original_count: values.length(),
      removed,
      replaced: 0,
      issues,
    }
  }
}

///|
/// Remove values with a robust IQR fence and return an audit trail.
pub fn remove_iqr_outliers(
  values : Array[Double],
  multiplier~ : Double,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  match (quantile(values, 0.25), quantile(values, 0.75)) {
    (Some(first), Some(third)) => {
      let low = first - multiplier * (third - first)
      let high = third + multiplier * (third - first)
      let mut removed = 0
      for index, value in values {
        if value < low || value > high {
          removed += 1
          issues.push({
            index,
            code: "IQR_OUTLIER",
            message: "measurement outside robust IQR fence",
            original: Some(value),
            replacement: None,
          })
        } else {
          output.push(value)
        }
      }
      {
        values: output,
        original_count: values.length(),
        removed,
        replaced: 0,
        issues,
      }
    }
    _ =>
      {
        values: values.copy(),
        original_count: values.length(),
        removed: 0,
        replaced: 0,
        issues,
      }
  }
}

///|
/// Replace robust outliers with the nearest fence boundary.
pub fn winsorize_values(
  values : Array[Double],
  multiplier~ : Double,
) -> CleanResult {
  let output : Array[Double] = []
  let issues : Array[CleanIssue] = []
  match (quantile(values, 0.25), quantile(values, 0.75)) {
    (Some(first), Some(third)) => {
      let low = first - multiplier * (third - first)
      let high = third + multiplier * (third - first)
      let mut replaced = 0
      for index, value in values {
        let replacement = value.max(low).min(high)
        if replacement != value {
          replaced += 1
          issues.push({
            index,
            code: "IQR_WINSORIZED",
            message: "outlier replaced by robust fence",
            original: Some(value),
            replacement: Some(replacement),
          })
        }
        output.push(replacement)
      }
      {
        values: output,
        original_count: values.length(),
        removed: 0,
        replaced,
        issues,
      }
    }
    _ =>
      {
        values: values.copy(),
        original_count: values.length(),
        removed: 0,
        replaced: 0,
        issues,
      }
  }
}

///|
/// Return a moving average with an explicit partial-window policy.
pub fn centered_moving_average(
  values : Array[Double],
  radius : Int,
) -> Array[Double]? {
  if radius < 0 {
    None
  } else {
    let output : Array[Double] = []
    for index in 0..<values.length() {
      let lower = (index - radius).max(0)
      let upper = (index + radius + 1).min(values.length())
      let mut total = 0.0
      for cursor in lower..<upper {
        total += values[cursor]
      }
      output.push(total / (upper - lower).to_double())
    }
    Some(output)
  }
}

///|
/// Exponentially decay a prior value into each current measurement.
pub fn exponential_smooth(
  values : Array[Double],
  alpha~ : Double,
  initial~ : Double,
) -> Array[Double] {
  let output : Array[Double] = []
  if alpha < 0.0 || alpha > 1.0 {
    output
  } else {
    let mut state = initial
    for value in values {
      state = alpha * value + (1.0 - alpha) * state
      output.push(state)
    }
    output
  }
}

///|
/// Compute a stable rolling sum without allocating one array per window.
pub fn rolling_sum(values : Array[Double], width : Int) -> Array[Double]? {
  if width <= 0 || width > values.length() {
    None
  } else {
    let output : Array[Double] = []
    let mut total = 0.0
    for index in 0..<width {
      total += values[index]
    }
    output.push(total)
    for start in 1..<(values.length() - width + 1) {
      total += values[start + width - 1] - values[start - 1]
      output.push(total)
    }
    Some(output)
  }
}

///|
/// Return the index of the largest absolute change.
pub fn largest_change_index(values : Array[Double]) -> Int? {
  if values.length() < 2 {
    None
  } else {
    let mut best_index = 1
    let mut best = (values[1] - values[0]).abs()
    for index in 2..<values.length() {
      let change = (values[index] - values[index - 1]).abs()
      if change > best {
        best = change
        best_index = index
      }
    }
    Some(best_index)
  }
}

///|
/// Return a boolean mask for values within a closed interval.
pub fn within_mask(
  values : Array[Double],
  lower : Double,
  upper : Double,
) -> Array[Bool] {
  let output : Array[Bool] = []
  for value in values {
    output.push(value >= lower && value <= upper)
  }
  output
}

///|
/// Return a boolean mask for values outside a closed interval.
pub fn outside_mask(
  values : Array[Double],
  lower : Double,
  upper : Double,
) -> Array[Bool] {
  let output : Array[Bool] = []
  for value in values {
    output.push(value < lower || value > upper)
  }
  output
}

///|
/// Count true entries in a mask.
pub fn count_mask(mask : Array[Bool]) -> Int {
  let mut count = 0
  for value in mask {
    if value {
      count += 1
    }
  }
  count
}

///|
/// Apply a boolean mask to a measurement series.
pub fn select_mask(values : Array[Double], mask : Array[Bool]) -> Array[Double] {
  let output : Array[Double] = []
  let length = values.length().min(mask.length())
  for index in 0..<length {
    if mask[index] {
      output.push(values[index])
    }
  }
  output
}

///|
/// Split a series at a change-point index.
pub fn split_at(
  values : Array[Double],
  index : Int,
) -> (Array[Double], Array[Double]) {
  let left : Array[Double] = []
  let right : Array[Double] = []
  let pivot = index.max(0).min(values.length())
  for cursor in 0..<values.length() {
    if cursor < pivot {
      left.push(values[cursor])
    } else {
      right.push(values[cursor])
    }
  }
  (left, right)
}

///|
/// Concatenate two measurement windows.
pub fn concatenate_values(
  first : Array[Double],
  second : Array[Double],
) -> Array[Double] {
  let output = first.copy()
  for value in second {
    output.push(value)
  }
  output
}

///|
/// Reverse a series without mutating the caller's array.
pub fn reverse_values(values : Array[Double]) -> Array[Double] {
  let output : Array[Double] = []
  let mut index = values.length()
  while index > 0 {
    index -= 1
    output.push(values[index])
  }
  output
}

///|
/// Rotate a series left by a normalized offset.
pub fn rotate_values(values : Array[Double], offset : Int) -> Array[Double] {
  if values.length() == 0 {
    []
  } else {
    let normalized = (offset % values.length() + values.length()) %
      values.length()
    let output : Array[Double] = []
    for index in 0..<values.length() {
      output.push(values[(index + normalized) % values.length()])
    }
    output
  }
}

///|
/// Check whether a series is non-decreasing.
pub fn is_non_decreasing(values : Array[Double]) -> Bool {
  let mut valid = true
  for index in 1..<values.length() {
    if values[index] < values[index - 1] {
      valid = false
    }
  }
  valid
}

///|
/// Check whether a series is non-increasing.
pub fn is_non_increasing(values : Array[Double]) -> Bool {
  let mut valid = true
  for index in 1..<values.length() {
    if values[index] > values[index - 1] {
      valid = false
    }
  }
  valid
}

///|
/// Count missing entries in a nullable series.
pub fn count_missing(values : Array[MaybeMeasurement]) -> Int {
  let mut count = 0
  for value in values {
    if value is None {
      count += 1
    }
  }
  count
}

///|
/// Convert a nullable series to a compact series by dropping missing entries.
pub fn drop_missing(values : Array[MaybeMeasurement]) -> Array[Double] {
  let output : Array[Double] = []
  for value in values {
    match value {
      Some(number) => output.push(number)
      None => ()
    }
  }
  output
}

///|
/// Return a nullable series' occupied index range.
pub fn occupied_range(values : Array[MaybeMeasurement]) -> (Int, Int)? {
  let mut first : Int? = None
  let mut last : Int? = None
  for index, value in values {
    if value is Some(_) {
      if first is None {
        first = Some(index)
      }
      last = Some(index)
    }
  }
  match (first, last) {
    (Some(left), Some(right)) => Some((left, right))
    _ => None
  }
}

///|
/// Calculate the fraction of missing sensor readings.
pub fn missing_rate(values : Array[MaybeMeasurement]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    count_missing(values).to_double() / values.length().to_double()
  }
}

///|
/// A compact quality score combining coverage and specification compliance.
pub fn data_quality_score(
  values : Array[MaybeMeasurement],
  lower : Double,
  upper : Double,
) -> Double {
  let available = drop_missing(values)
  if values.length() == 0 || lower > upper {
    0.0
  } else {
    let coverage = available.length().to_double() / values.length().to_double()
    let in_spec = count_mask(within_mask(available, lower, upper)).to_double() /
      values.length().to_double()
    0.5 * coverage + 0.5 * in_spec
  }
}
