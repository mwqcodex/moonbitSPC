///|
/// Ordinary-least-squares trend metadata for a sequence ordered in time.
pub(all) struct Trend {
  slope : Double
  intercept : Double
  r_squared : Double
} derive(Debug, ToJson)

///|
pub fn linear_trend(values : Array[Double]) -> Trend? {
  if values.length() < 2 {
    None
  } else {
    let n = values.length().to_double()
    let mut sum_x = 0.0
    let mut sum_y = 0.0
    let mut sum_xx = 0.0
    let mut sum_xy = 0.0
    for index, value in values {
      let x = index.to_double()
      sum_x += x
      sum_y += value
      sum_xx += x * x
      sum_xy += x * value
    }
    let denominator = n * sum_xx - sum_x * sum_x
    if denominator == 0.0 {
      None
    } else {
      let slope = (n * sum_xy - sum_x * sum_y) / denominator
      let intercept = (sum_y - slope * sum_x) / n
      let mean = sum_y / n
      let mut total = 0.0
      let mut residual = 0.0
      for index, value in values {
        let fitted = intercept + slope * index.to_double()
        let difference = value - mean
        total += difference * difference
        let error = value - fitted
        residual += error * error
      }
      let r_squared = if total == 0.0 { 1.0 } else { 1.0 - residual / total }
      Some({ slope, intercept, r_squared })
    }
  }
}

///|
/// Forecast future points from an ordinary-least-squares trend.
pub fn forecast(values : Array[Double], periods : Int) -> Array[Double]? {
  if periods < 0 {
    None
  } else {
    match linear_trend(values) {
      None => None
      Some(trend) => {
        let result : Array[Double] = []
        for offset in 0..<periods {
          let x = values.length().to_double() + offset.to_double()
          result.push(trend.intercept + trend.slope * x)
        }
        Some(result)
      }
    }
  }
}

///|
/// A baseline used to compare later production windows.
pub(all) struct Baseline {
  center : Double
  deviation : Double
  lower : Double
  upper : Double
  count : Int
} derive(Debug, ToJson)

///|
pub fn baseline_from(values : Array[Double]) -> Baseline {
  let center = if values.length() == 0 { 0.0 } else { mean_of(values) }
  let deviation = if values.length() < 2 { 0.0 } else { std_of(values, center) }
  {
    center,
    deviation,
    lower: center - 3.0 * deviation,
    upper: center + 3.0 * deviation,
    count: values.length(),
  }
}

///|
/// Per-point drift score relative to a baseline.
pub(all) struct DriftPoint {
  index : Int
  value : Double
  score : Double
  alarm : Bool
} derive(Debug, ToJson)

///|
pub fn drift_score(
  values : Array[Double],
  baseline : Baseline,
  threshold~ : Double,
) -> Array[DriftPoint] {
  let result : Array[DriftPoint] = []
  for index, value in values {
    let score = if baseline.deviation == 0.0 {
      if value == baseline.center {
        0.0
      } else {
        threshold + 1.0
      }
    } else {
      (value - baseline.center).abs() / baseline.deviation
    }
    result.push({
      index,
      value,
      score,
      alarm: threshold >= 0.0 && score >= threshold,
    })
  }
  result
}

///|
/// Deterministic pseudo-random samples for repeatable examples and benchmarks.
pub fn sample_uniform(
  count : Int,
  seed~ : Int,
  lower~ : Double,
  upper~ : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if count <= 0 || lower >= upper {
    result
  } else {
    let mut state = if seed <= 0 { 1 } else { seed % 1000003 }
    for _ in 0..<count {
      state = state * 517 % 1000003
      let unit = state.to_double() / 1000003.0
      result.push(lower + unit * (upper - lower))
    }
    result
  }
}

///|
/// Create a CUSUM chart from the cumulative statistics.
pub fn ControlChart::cusum(
  values : Array[Double],
  target~ : Double,
  allowance~ : Double,
  decision~ : Double,
) -> ChartResult {
  if values.length() == 0 || allowance < 0.0 || decision <= 0.0 {
    ChartInvalidInput(
      message="cusum needs values, non-negative allowance, and positive decision",
    )
  } else {
    let statistics = cusum(values, target~, allowance~, decision~)
    ChartOk(chart_from_values("CUSUM", statistics, 0.0, decision, -decision))
  }
}

///|
/// Create an EWMA chart with a fixed three-sigma limit.
pub fn ControlChart::ewma(
  values : Array[Double],
  lambda~ : Double,
  initial~ : Double,
  sigma~ : Double,
) -> ChartResult {
  if values.length() == 0 || lambda <= 0.0 || lambda > 1.0 || sigma <= 0.0 {
    ChartInvalidInput(
      message="ewma needs values, lambda in (0,1], and positive sigma",
    )
  } else {
    let statistics = ewma(values, lambda~, initial~)
    let limit = 3.0 * sigma * (lambda / (2.0 - lambda)).sqrt()
    ChartOk(
      chart_from_values(
        "EWMA",
        statistics,
        initial,
        initial + limit,
        initial - limit,
      ),
    )
  }
}

///|
/// Calculate the percentage of observations outside a bilateral specification.
pub fn defect_rate(
  values : Array[Double],
  specification : Specification,
) -> Double? {
  if values.length() == 0 || specification.lower >= specification.upper {
    None
  } else {
    let mut defects = 0
    for value in values {
      if value < specification.lower || value > specification.upper {
        defects += 1
      }
    }
    Some(defects.to_double() / values.length().to_double())
  }
}

///|
/// Return residuals after removing a fitted linear trend.
pub fn detrend(values : Array[Double]) -> Array[Double]? {
  match linear_trend(values) {
    None => None
    Some(trend) => {
      let result : Array[Double] = []
      for index, value in values {
        result.push(value - trend.intercept - trend.slope * index.to_double())
      }
      Some(result)
    }
  }
}
