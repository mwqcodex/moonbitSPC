///|
pub fn safe_divide(
  numerator : Double,
  denominator : Double,
  fallback : Double,
) -> Double {
  if denominator == 0.0 {
    fallback
  } else {
    numerator / denominator
  }
}

///|
pub fn clamp_probability(value : Double) -> Double {
  value.max(0.0).min(1.0)
}

///|
pub fn weighted_average(
  values : Array[Double],
  weights : Array[Double],
) -> Double {
  let mut numerator = 0.0
  let mut denominator = 0.0
  for i in 0..<values.length().min(weights.length()) {
    numerator += values[i] * weights[i]
    denominator += weights[i]
  }
  safe_divide(numerator, denominator, 0.0)
}

///|
pub fn absolute_error(actual : Double, predicted : Double) -> Double {
  (actual - predicted).abs()
}

///|
pub fn squared_error(actual : Double, predicted : Double) -> Double {
  let difference = actual - predicted
  difference * difference
}

///|
pub fn helper_root_mean_squared_error(errors : Array[Double]) -> Double {
  if errors.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for error in errors {
      total += error * error
    }
    (total / errors.length().to_double()).sqrt()
  }
}

///|
pub fn relative_error(actual : Double, predicted : Double) -> Double {
  if actual == 0.0 {
    0.0
  } else {
    (actual - predicted).abs() / actual.abs()
  }
}

///|
pub fn normalize_range(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  if upper <= lower {
    0.0
  } else {
    clamp_probability((value - lower) / (upper - lower))
  }
}

///|
pub fn denormalize_range(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  lower + clamp_probability(value) * (upper - lower)
}

///|
pub fn linear_interpolate(
  x : Double,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Double {
  if x1 == x0 {
    y0
  } else {
    y0 + (x - x0) * (y1 - y0) / (x1 - x0)
  }
}

///|
pub fn sign_code(value : Double, tolerance : Double) -> Int {
  if value > tolerance {
    1
  } else if value < -tolerance {
    -1
  } else {
    0
  }
}

///|
pub fn percentage_change(old : Double, new : Double) -> Double {
  if old == 0.0 {
    0.0
  } else {
    (new - old) / old * 100.0
  }
}

///|
pub fn safe_range(value : Double, lower : Double, upper : Double) -> Double {
  value.max(lower).min(upper)
}

///|
pub fn count_true(values : Array[Bool]) -> Int {
  let mut count = 0
  for value in values {
    if value {
      count += 1
    }
  }
  count
}

///|
pub fn bool_rate(values : Array[Bool]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    count_true(values).to_double() / values.length().to_double()
  }
}

///|
pub fn integer_range_sum(start : Int, end : Int) -> Int {
  let mut total = 0
  for value in start..<end {
    total += value
  }
  total
}

///|
pub fn stable_round(value : Double, digits : Int) -> Double {
  if digits <= 0 {
    value.round()
  } else {
    value
  }
}

///|
pub fn min_positive(value : Double, fallback : Double) -> Double {
  if value > 0.0 {
    value
  } else {
    fallback
  }
}

///|
pub fn max_abs(left : Double, right : Double) -> Double {
  left.abs().max(right.abs())
}

///|
pub fn midpoint(left : Double, right : Double) -> Double {
  (left + right) / 2.0
}

///|
pub fn distance_from_interval(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  if value < lower {
    lower - value
  } else if value > upper {
    value - upper
  } else {
    0.0
  }
}
