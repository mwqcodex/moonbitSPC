///|
pub struct DiagnosticResult {
  sample_count : Int
  mean : Double
  deviation : Double
  runs : Int
  increasing_pairs : Int
  decreasing_pairs : Int
  change_index : Int
  shift : Double
  variance_ratio : Double
  autocorrelation : Double
  stable : Bool
} derive(Debug, ToJson)

///|
fn diag_mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      total += value
    }
    total / values.length().to_double()
  }
}

///|
fn diag_variance(values : Array[Double], mean : Double) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      let d = value - mean
      total += d * d
    }
    total / (values.length() - 1).to_double()
  }
}

///|
pub fn runs_count(values : Array[Double], center : Double) -> Int {
  if values.length() == 0 {
    return 0
  }
  let mut runs = 1
  let mut previous = values[0] >= center
  for value in values[1:] {
    let current = value >= center
    if current != previous {
      runs += 1
    }
    previous = current
  }
  runs
}

///|
pub fn increasing_pair_count(values : Array[Double]) -> Int {
  let mut count = 0
  for i in 1..<values.length() {
    if values[i] > values[i - 1] {
      count += 1
    }
  }
  count
}

///|
pub fn decreasing_pair_count(values : Array[Double]) -> Int {
  let mut count = 0
  for i in 1..<values.length() {
    if values[i] < values[i - 1] {
      count += 1
    }
  }
  count
}

///|
pub fn first_mean_shift(
  values : Array[Double],
  baseline : Double,
  tolerance : Double,
) -> Int {
  for i, value in values {
    if (value - baseline).abs() > tolerance {
      return i
    }
  }
  -1
}

///|
pub fn variance_ratio(values : Array[Double], split : Int) -> Double {
  if split <= 0 || split >= values.length() {
    return 0.0
  }
  let left = values[0:split].to_owned()
  let right = values[split:].to_owned()
  let left_var = diag_variance(left, diag_mean(left))
  let right_var = diag_variance(right, diag_mean(right))
  if left_var <= 0.0 {
    if right_var <= 0.0 {
      1.0
    } else {
      999999.0
    }
  } else {
    right_var / left_var
  }
}

///|
pub fn lag_autocorrelation(values : Array[Double], lag : Int) -> Double {
  if lag <= 0 || lag >= values.length() {
    return 0.0
  }
  let mean = diag_mean(values)
  let mut numerator = 0.0
  let mut denominator = 0.0
  for value in values {
    let d = value - mean
    denominator += d * d
  }
  for i in lag..<values.length() {
    numerator += (values[i] - mean) * (values[i - lag] - mean)
  }
  if denominator <= 0.0 {
    0.0
  } else {
    numerator / denominator
  }
}

///|
pub fn diagnose_process(
  values : Array[Double],
  baseline : Double,
  shift_tolerance : Double,
  variance_limit : Double,
) -> DiagnosticResult {
  let mean = diag_mean(values)
  let deviation = diag_variance(values, mean).sqrt()
  let split = values.length() / 2
  let ratio = variance_ratio(values, split)
  let shift = mean - baseline
  {
    sample_count: values.length(),
    mean,
    deviation,
    runs: runs_count(values, baseline),
    increasing_pairs: increasing_pair_count(values),
    decreasing_pairs: decreasing_pair_count(values),
    change_index: first_mean_shift(values, baseline, shift_tolerance),
    shift,
    variance_ratio: ratio,
    autocorrelation: lag_autocorrelation(values, 1),
    stable: shift.abs() <= shift_tolerance &&
    ratio <= variance_limit &&
    ratio >= 1.0 / variance_limit,
  }
}

///|
pub fn diagnostic_alarm_count(result : DiagnosticResult) -> Int {
  let mut count = 0
  if result.change_index >= 0 {
    count += 1
  }
  if result.variance_ratio > 2.0 || result.variance_ratio < 0.5 {
    count += 1
  }
  if result.autocorrelation.abs() > 0.8 {
    count += 1
  }
  count
}

///|
pub fn trend_direction(values : Array[Double]) -> Int {
  let up = increasing_pair_count(values)
  let down = decreasing_pair_count(values)
  if up > down {
    1
  } else if down > up {
    -1
  } else {
    0
  }
}

///|
pub fn plateau_count(values : Array[Double], tolerance : Double) -> Int {
  let mut count = 0
  for i in 1..<values.length() {
    if (values[i] - values[i - 1]).abs() <= tolerance {
      count += 1
    }
  }
  count
}

///|
pub fn outlier_indices(
  values : Array[Double],
  center : Double,
  limit : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i, value in values {
    if (value - center).abs() > limit {
      result.push(i)
    }
  }
  result
}

///|
pub fn diagnostic_score(result : DiagnosticResult) -> Double {
  let shift_score = result.shift.abs()
  let variance_score = if result.variance_ratio <= 0.0 {
    10.0
  } else {
    (result.variance_ratio - 1.0).abs()
  }
  shift_score + variance_score + result.autocorrelation.abs()
}

///|
pub fn diagnostic_label(result : DiagnosticResult) -> String {
  if result.stable {
    "stable"
  } else if diagnostic_alarm_count(result) > 1 {
    "investigate"
  } else {
    "watch"
  }
}
