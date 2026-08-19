///|
pub struct TrendAlert {
  metric : String
  direction : Int
  slope : Double
  confidence : Double
  start_index : Int
  end_index : Int
  message : String
} derive(Debug, ToJson)

///|
pub fn trend_slope(values : Array[Double]) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      total += value
    }
    let mean = total / values.length().to_double()
    let mut numerator = 0.0
    let mut denominator = 0.0
    for i, value in values {
      let x = i.to_double()
      numerator += (x - (values.length() - 1).to_double() / 2.0) *
        (value - mean)
      denominator += (x - (values.length() - 1).to_double() / 2.0) *
        (x - (values.length() - 1).to_double() / 2.0)
    }
    if denominator <= 0.0 {
      0.0
    } else {
      numerator / denominator
    }
  }
}

///|
pub fn trend_direction_code(slope : Double, tolerance : Double) -> Int {
  if slope > tolerance {
    1
  } else if slope < -tolerance {
    -1
  } else {
    0
  }
}

///|
pub fn trend_confidence(values : Array[Double], slope : Double) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut residual = 0.0
    let mean = if values.length() == 0 {
      0.0
    } else {
      let mut total = 0.0
      for value in values {
        total += value
      }
      total / values.length().to_double()
    }
    for value in values {
      let d = value - mean
      residual += d * d
    }
    let scale = residual.sqrt()
    if scale <= 0.0 {
      1.0
    } else {
      (slope.abs() * values.length().to_double() / scale).min(1.0)
    }
  }
}

///|
pub fn detect_trend(
  metric~ : String,
  values~ : Array[Double],
  tolerance~ : Double,
) -> TrendAlert? {
  let slope = trend_slope(values)
  let direction = trend_direction_code(slope, tolerance)
  if direction == 0 {
    None
  } else {
    Some({
      metric,
      direction,
      slope,
      confidence: trend_confidence(values, slope),
      start_index: 0,
      end_index: values.length() - 1,
      message: if direction > 0 {
        "upward trend"
      } else {
        "downward trend"
      },
    })
  }
}

///|
pub fn trend_severity(alert : TrendAlert) -> String {
  if alert.confidence >= 0.8 {
    "high"
  } else if alert.confidence >= 0.5 {
    "medium"
  } else {
    "low"
  }
}

///|
pub fn trend_alert_count(alerts : Array[TrendAlert]) -> Int {
  alerts.length()
}

///|
pub fn high_severity_trends(alerts : Array[TrendAlert]) -> Int {
  let mut count = 0
  for alert in alerts {
    if trend_severity(alert) == "high" {
      count += 1
    }
  }
  count
}

///|
pub fn trend_direction_name(direction : Int) -> String {
  if direction > 0 {
    "up"
  } else if direction < 0 {
    "down"
  } else {
    "flat"
  }
}

///|
pub fn trend_total_change(values : Array[Double]) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    values[values.length() - 1] - values[0]
  }
}

///|
pub fn trend_relative_change(values : Array[Double]) -> Double {
  if values.length() < 2 || values[0] == 0.0 {
    0.0
  } else {
    trend_total_change(values) / values[0]
  }
}

///|
pub fn trend_turning_points(values : Array[Double]) -> Int {
  if values.length() < 3 {
    0
  } else {
    let mut count = 0
    let mut i = 1
    while i < values.length() - 1 {
      let left = values[i] - values[i - 1]
      let right = values[i + 1] - values[i]
      if (left > 0.0 && right < 0.0) || (left < 0.0 && right > 0.0) {
        count += 1
      }
      i += 1
    }
    count
  }
}
