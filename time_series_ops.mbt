///|
pub fn ts_mean(values : Array[Double]) -> Double {
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
pub fn ts_difference(values : Array[Double], lag : Int) -> Array[Double] {
  let result : Array[Double] = []
  if lag <= 0 || lag >= values.length() {
    return result
  }
  for i in lag..<values.length() {
    result.push(values[i] - values[i - lag])
  }
  result
}

///|
pub fn ts_seasonal_difference(
  values : Array[Double],
  period : Int,
) -> Array[Double] {
  ts_difference(values, period)
}

///|
pub fn ts_moving_min(values : Array[Double], window : Int) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  let mut i = window - 1
  while i < values.length() {
    let mut low = values[i - window + 1]
    let mut j = i - window + 2
    while j <= i {
      low = low.min(values[j])
      j += 1
    }
    result.push(low)
    i += 1
  }
  result
}

///|
pub fn ts_moving_max(values : Array[Double], window : Int) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  let mut i = window - 1
  while i < values.length() {
    let mut high = values[i - window + 1]
    let mut j = i - window + 2
    while j <= i {
      high = high.max(values[j])
      j += 1
    }
    result.push(high)
    i += 1
  }
  result
}

///|
pub fn ts_moving_range(values : Array[Double], window : Int) -> Array[Double] {
  let lows = ts_moving_min(values, window)
  let highs = ts_moving_max(values, window)
  let result : Array[Double] = []
  for i in 0..<lows.length() {
    result.push(highs[i] - lows[i])
  }
  result
}

///|
pub fn ts_centered(values : Array[Double], window : Int) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 || values.length() < window {
    return result
  }
  let mut i = 0
  while i < values.length() - window + 1 {
    result.push(ts_mean(values[i:i + window].to_owned()))
    i += 1
  }
  result
}

///|
pub fn ts_detrend(values : Array[Double]) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() == 0 {
    return result
  }
  let mean = ts_mean(values)
  for i, value in values {
    let trend = if values.length() <= 1 {
      mean
    } else {
      values[0] +
      (values[values.length() - 1] - values[0]) *
      i.to_double() /
      (values.length() - 1).to_double()
    }
    result.push(value - trend)
  }
  result
}

///|
pub fn ts_autocovariance(values : Array[Double], lag : Int) -> Double {
  if lag < 0 || lag >= values.length() {
    0.0
  } else {
    let mean = ts_mean(values)
    let mut total = 0.0
    for i in lag..<values.length() {
      total += (values[i] - mean) * (values[i - lag] - mean)
    }
    total / (values.length() - lag).to_double()
  }
}

///|
pub fn ts_autocorrelation(values : Array[Double], lag : Int) -> Double {
  let base = ts_autocovariance(values, 0)
  if base <= 0.0 {
    0.0
  } else {
    ts_autocovariance(values, lag) / base
  }
}

///|
pub fn ts_peak_index(values : Array[Double]) -> Int {
  if values.length() == 0 {
    -1
  } else {
    let mut index = 0
    for i in 1..<values.length() {
      if values[i] > values[index] {
        index = i
      }
    }
    index
  }
}

///|
pub fn ts_trough_index(values : Array[Double]) -> Int {
  if values.length() == 0 {
    -1
  } else {
    let mut index = 0
    for i in 1..<values.length() {
      if values[i] < values[index] {
        index = i
      }
    }
    index
  }
}

///|
pub fn ts_range(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    values[ts_peak_index(values)] - values[ts_trough_index(values)]
  }
}

///|
pub fn ts_count_crossings(values : Array[Double], level : Double) -> Int {
  if values.length() < 2 {
    0
  } else {
    let mut count = 0
    for i in 1..<values.length() {
      if (values[i] >= level) != (values[i - 1] >= level) {
        count += 1
      }
    }
    count
  }
}

///|
pub fn ts_downsample(values : Array[Double], step : Int) -> Array[Double] {
  let result : Array[Double] = []
  if step <= 0 {
    return result
  }
  for i in 0..<values.length() {
    if i % step == 0 {
      result.push(values[i])
    }
  }
  result
}

///|
pub fn ts_pad(
  values : Array[Double],
  length : Int,
  fill : Double,
) -> Array[Double] {
  let result = values.copy()
  while result.length() < length {
    result.push(fill)
  }
  result
}

///|
pub fn ts_last(values : Array[Double], fallback : Double) -> Double {
  values.last().unwrap_or(fallback)
}

///|
pub fn ts_first(values : Array[Double], fallback : Double) -> Double {
  if values.length() == 0 {
    fallback
  } else {
    values[0]
  }
}
