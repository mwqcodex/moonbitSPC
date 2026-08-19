///|
/// Deterministic forecasting strategy for production planning.
pub(all) enum ForecastStrategy {
  LastValue
  MeanValue
  MovingAverage(Int)
  TrendLine
  ExponentialAverage(Double)
} derive(Debug, Eq, ToJson)

///|
/// A forecast plus uncertainty bands and evaluation metadata.
pub(all) struct ForecastResult {
  strategy_name : String
  horizon : Int
  values : Array[Double]
  baseline : Double
  deviation : Double?
  lower : Array[Double]
  upper : Array[Double]
} derive(Debug, ToJson)

///|
/// Produce a deterministic forecast for a future horizon.
pub fn forecast_with(
  values : Array[Double],
  strategy : ForecastStrategy,
  horizon : Int,
) -> ForecastResult? {
  if values.length() == 0 || horizon < 0 {
    None
  } else {
    let future : Array[Double]? = match strategy {
      LastValue => Some(repeat_forecast(values[values.length() - 1], horizon))
      MeanValue => Some(repeat_forecast(mean_of(values), horizon))
      MovingAverage(width) =>
        match moving_mean(values, width) {
          Some(result) =>
            if result.length() == 0 {
              None
            } else {
              Some(repeat_forecast(result[result.length() - 1], horizon))
            }
          None => None
        }
      TrendLine => forecast(values, horizon)
      ExponentialAverage(lambda) => {
        let result = ewma(values, lambda~, initial=values[0])
        if result.length() == 0 {
          None
        } else {
          Some(repeat_forecast(result[result.length() - 1], horizon))
        }
      }
    }
    match future {
      None => None
      Some(predictions) => {
        let errors = fitted_errors(values, strategy)
        let deviation = if errors.length() < 2 {
          None
        } else {
          Some(std_of(errors, mean_of(errors)))
        }
        let lower : Array[Double] = []
        let upper : Array[Double] = []
        for value in predictions {
          let margin = match deviation {
            Some(error) => 1.96 * error
            None => 0.0
          }
          lower.push(value - margin)
          upper.push(value + margin)
        }
        Some({
          strategy_name: strategy_name(strategy),
          horizon,
          values: predictions,
          baseline: values[values.length() - 1],
          deviation,
          lower,
          upper,
        })
      }
    }
  }
}

///|
fn repeat_forecast(value : Double, count : Int) -> Array[Double] {
  let result : Array[Double] = []
  for _ in 0..<count {
    result.push(value)
  }
  result
}

///|
fn strategy_name(strategy : ForecastStrategy) -> String {
  match strategy {
    LastValue => "last-value"
    MeanValue => "mean"
    MovingAverage(_) => "moving-average"
    TrendLine => "trend"
    ExponentialAverage(_) => "exponential"
  }
}

///|
/// Fitted residuals for a strategy.
pub fn fitted_errors(
  values : Array[Double],
  strategy : ForecastStrategy,
) -> Array[Double] {
  let fitted : Array[Double] = []
  match strategy {
    LastValue =>
      for index in 0..<values.length() {
        fitted.push(if index == 0 { values[0] } else { values[index - 1] })
      }
    MeanValue =>
      for _ in values {
        fitted.push(mean_of(values))
      }
    MovingAverage(width) =>
      if width > 0 {
        for index in 0..<values.length() {
          let start = (index - width + 1).max(0)
          let mut total = 0.0
          let mut count = 0
          for cursor in start..<=index {
            total += values[cursor]
            count += 1
          }
          fitted.push(total / count.to_double())
        }
      }
    TrendLine =>
      match linear_trend(values) {
        Some(trend) =>
          for index in 0..<values.length() {
            fitted.push(trend.intercept + trend.slope * index.to_double())
          }
        None => ()
      }
    ExponentialAverage(lambda) =>
      for value in ewma(values, lambda~, initial=values[0]) {
        fitted.push(value)
      }
  }
  let errors : Array[Double] = []
  for index in 0..<values.length().min(fitted.length()) {
    errors.push(values[index] - fitted[index])
  }
  errors
}

///|
/// Mean absolute forecast error.
pub fn mean_absolute_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Double? {
  match paired_errors(actual, predicted) {
    None => None
    Some(errors) =>
      if errors.length() == 0 {
        None
      } else {
        let mut total = 0.0
        for error in errors {
          total += error.abs()
        }
        Some(total / errors.length().to_double())
      }
  }
}

///|
/// Mean squared forecast error.
pub fn mean_squared_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Double? {
  match paired_errors(actual, predicted) {
    None => None
    Some(errors) =>
      if errors.length() == 0 {
        None
      } else {
        let mut total = 0.0
        for error in errors {
          total += error * error
        }
        Some(total / errors.length().to_double())
      }
  }
}

///|
/// Root mean squared forecast error.
pub fn root_mean_squared_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Double? {
  match mean_squared_error(actual, predicted) {
    Some(value) => Some(value.sqrt())
    None => None
  }
}

///|
fn paired_errors(
  actual : Array[Double],
  predicted : Array[Double],
) -> Array[Double]? {
  if actual.length() != predicted.length() {
    None
  } else {
    let errors : Array[Double] = []
    for index in 0..<actual.length() {
      errors.push(actual[index] - predicted[index])
    }
    Some(errors)
  }
}

///|
/// Symmetric mean absolute percentage error.
pub fn symmetric_percentage_error(
  actual : Array[Double],
  predicted : Array[Double],
) -> Double? {
  match paired_errors(actual, predicted) {
    None => None
    Some(errors) => {
      let mut total = 0.0
      let mut count = 0
      for index in 0..<errors.length() {
        let denominator = actual[index].abs() + predicted[index].abs()
        if denominator > 0.0 {
          total += 2.0 * errors[index].abs() / denominator
          count += 1
        }
      }
      if count == 0 {
        None
      } else {
        Some(total / count.to_double())
      }
    }
  }
}

///|
/// One-step historical backtest result.
pub(all) struct BacktestPoint {
  index : Int
  actual : Double
  predicted : Double
  error : Double
} derive(Debug, ToJson)

///|
/// Evaluate one-step forecasts using expanding history.
pub fn backtest_forecast(
  values : Array[Double],
  strategy : ForecastStrategy,
  minimum_history : Int,
) -> Array[BacktestPoint] {
  let result : Array[BacktestPoint] = []
  if minimum_history > 0 {
    for index in minimum_history..<values.length() {
      let history : Array[Double] = []
      for cursor in 0..<index {
        history.push(values[cursor])
      }
      match forecast_with(history, strategy, 1) {
        Some(prediction) => {
          let error = values[index] - prediction.values[0]
          result.push({
            index,
            actual: values[index],
            predicted: prediction.values[0],
            error,
          })
        }
        None => ()
      }
    }
  }
  result
}

///|
/// Aggregate backtest errors into MAE and deviation.
pub fn backtest_metrics(points : Array[BacktestPoint]) -> (Double, Double)? {
  if points.length() == 0 {
    None
  } else {
    let errors : Array[Double] = []
    for point in points {
      errors.push(point.error)
    }
    Some((mean_of(errors), std_of(errors, mean_of(errors))))
  }
}

///|
/// Pick the lowest-MAE strategy from a candidate list.
pub fn choose_forecast_strategy(
  values : Array[Double],
  strategies : Array[ForecastStrategy],
  minimum_history : Int,
) -> ForecastStrategy? {
  let mut best : ForecastStrategy? = None
  let mut best_error = 0.0
  for strategy in strategies {
    let points = backtest_forecast(values, strategy, minimum_history)
    match backtest_metrics(points) {
      Some((mean, _)) => {
        let error = mean.abs()
        match best {
          None => {
            best = Some(strategy)
            best_error = error
          }
          Some(_) =>
            if error < best_error {
              best = Some(strategy)
              best_error = error
            }
        }
      }
      None => ()
    }
  }
  best
}

///|
/// Generate multiple uncertainty levels around one forecast.
pub fn forecast_bands(
  values : Array[Double],
  deviation : Double,
  levels : Array[Double],
) -> Array[(Array[Double], Array[Double])] {
  let result : Array[(Array[Double], Array[Double])] = []
  for level in levels {
    let lower : Array[Double] = []
    let upper : Array[Double] = []
    for value in values {
      let margin = level.abs() * deviation
      lower.push(value - margin)
      upper.push(value + margin)
    }
    result.push((lower, upper))
  }
  result
}
