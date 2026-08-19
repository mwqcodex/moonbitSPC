///|
/// Severity used by an application-facing quality alert.
pub(all) enum AlertSeverity {
  Info
  Warning
  Critical
} derive(Debug, Eq, ToJson)

///|
/// A structured alert that can be handed to a dashboard or work-order system.
pub(all) struct QualityAlert {
  severity : AlertSeverity
  code : String
  message : String
  index : Int
  value : Double?
} derive(Debug, ToJson)

///|
/// A bounded observation window for repeatable batch reviews.
pub(all) struct QualityWindow {
  id : String
  values : Array[Double]
  specification : Specification?
} derive(Debug, ToJson)

///|
pub fn QualityWindow::new(
  id~ : String,
  values~ : Array[Double],
  specification~ : Specification?,
) -> QualityWindow {
  { id, values, specification }
}

///|
/// Create a window from a subgroup collection while preserving the first batch id.
pub fn window_from_groups(
  groups : Array[Subgroup],
  specification? : Specification,
) -> QualityWindow? {
  if groups.length() == 0 {
    None
  } else {
    Some({ id: groups[0].batch, values: flatten(groups), specification })
  }
}

///|
/// Evaluate one window using limits, robust outliers, and specification defects.
pub fn evaluate_window(window : QualityWindow) -> Array[QualityAlert] {
  let alerts : Array[QualityAlert] = []
  if window.values.length() == 0 {
    alerts.push({
      severity: Critical,
      code: "EMPTY_WINDOW",
      message: "quality window has no measurements",
      index: -1,
      value: None,
    })
    return alerts
  }
  let center = mean_of(window.values)
  let deviation = std_of(window.values, center)
  for index, value in window.values {
    if deviation > 0.0 && (value - center).abs() > 3.0 * deviation {
      alerts.push({
        severity: Critical,
        code: "THREE_SIGMA",
        message: "measurement exceeds three-sigma limit",
        index,
        value: Some(value),
      })
    }
  }
  match window.specification {
    Some(spec) =>
      for index, value in window.values {
        if value < spec.lower || value > spec.upper {
          alerts.push({
            severity: Critical,
            code: "OUT_OF_SPEC",
            message: "measurement is outside specification",
            index,
            value: Some(value),
          })
        }
      }
    None => ()
  }
  match iqr_outliers(window.values, 1.5) {
    Some(flags) =>
      for index, flag in flags {
        if flag {
          alerts.push({
            severity: Warning,
            code: "IQR_OUTLIER",
            message: "measurement is an interquartile-range outlier",
            index,
            value: Some(window.values[index]),
          })
        }
      }
    None => ()
  }
  let run = longest_run(window.values, center)
  if run >= 8 {
    alerts.push({
      severity: Warning,
      code: "LONG_RUN",
      message: "eight measurements remain on one side of center",
      index: window.values.length() - run,
      value: None,
    })
  }
  alerts
}

///|
/// Compare two windows and return a change alert when the center shifts.
pub fn compare_windows(
  previous : QualityWindow,
  current : QualityWindow,
  threshold : Double,
) -> QualityAlert? {
  if previous.values.length() == 0 ||
    current.values.length() == 0 ||
    threshold < 0.0 {
    None
  } else {
    let old_center = mean_of(previous.values)
    let new_center = mean_of(current.values)
    let old_deviation = std_of(previous.values, old_center)
    let score = if old_deviation == 0.0 {
      if old_center == new_center {
        0.0
      } else {
        threshold + 1.0
      }
    } else {
      (new_center - old_center).abs() / old_deviation
    }
    if score >= threshold {
      Some({
        severity: if score >= threshold * 2.0 {
          Critical
        } else {
          Warning
        },
        code: "CENTER_SHIFT",
        message: "window center shifted from baseline",
        index: -1,
        value: Some(new_center),
      })
    } else {
      None
    }
  }
}

///|
/// Summarize multiple windows into their means.
pub fn window_means(windows : Array[QualityWindow]) -> Array[Double] {
  let result : Array[Double] = []
  for window in windows {
    if window.values.length() > 0 {
      result.push(mean_of(window.values))
    }
  }
  result
}

///|
/// Summarize multiple windows into their sample deviations.
pub fn window_deviations(windows : Array[QualityWindow]) -> Array[Double] {
  let result : Array[Double] = []
  for window in windows {
    if window.values.length() > 1 {
      result.push(std_of(window.values, mean_of(window.values)))
    }
  }
  result
}

///|
/// Return a deterministic count of critical alerts.
pub fn critical_alert_count(alerts : Array[QualityAlert]) -> Int {
  let mut count = 0
  for alert in alerts {
    if alert.severity == Critical {
      count += 1
    }
  }
  count
}

///|
/// Return a deterministic count of warnings and critical alerts.
pub fn actionable_alert_count(alerts : Array[QualityAlert]) -> Int {
  let mut count = 0
  for alert in alerts {
    if alert.severity != Info {
      count += 1
    }
  }
  count
}

///|
/// Group alerts by their stable machine-readable code.
pub fn alert_codes(alerts : Array[QualityAlert]) -> Array[String] {
  let result : Array[String] = []
  for alert in alerts {
    let mut exists = false
    for code in result {
      if code == alert.code {
        exists = true
      }
    }
    if !exists {
      result.push(alert.code)
    }
  }
  result
}

///|
/// Build independent windows from a flat sequence.
pub fn windows_from_values(
  values : Array[Double],
  width : Int,
  specification? : Specification,
) -> Array[QualityWindow]? {
  match subgroup(values, width) {
    None => None
    Some(groups) => {
      let result : Array[QualityWindow] = []
      for group in groups {
        result.push({ id: "window", values: group, specification })
      }
      Some(result)
    }
  }
}

///|
/// Evaluate all windows and attach their local index to generated alerts.
pub fn evaluate_windows(windows : Array[QualityWindow]) -> Array[QualityAlert] {
  let result : Array[QualityAlert] = []
  for window in windows {
    for alert in evaluate_window(window) {
      result.push(alert)
    }
  }
  result
}

///|
/// A compact scorecard useful for a status badge or release report.
pub(all) struct Scorecard {
  observations : Int
  windows : Int
  alerts : Int
  critical : Int
  defect_rate : Double?
  center : Double?
  deviation : Double?
} derive(Debug, ToJson)

///|
pub fn scorecard(windows : Array[QualityWindow]) -> Scorecard {
  let values : Array[Double] = []
  let mut specification : Specification? = None
  for window in windows {
    for value in window.values {
      values.push(value)
    }
    match (specification, window.specification) {
      (None, Some(spec)) => specification = Some(spec)
      _ => ()
    }
  }
  let alerts = evaluate_windows(windows)
  let center = if values.length() == 0 { None } else { Some(mean_of(values)) }
  let deviation = if values.length() < 2 {
    None
  } else {
    Some(std_of(values, mean_of(values)))
  }
  let defect_rate = match specification {
    Some(spec) => defect_rate(values, spec)
    None => None
  }
  {
    observations: values.length(),
    windows: windows.length(),
    alerts: alerts.length(),
    critical: critical_alert_count(alerts),
    defect_rate,
    center,
    deviation,
  }
}

///|
/// Return only windows whose mean is outside the supplied engineering band.
pub fn filter_shifted_windows(
  windows : Array[QualityWindow],
  lower : Double,
  upper : Double,
) -> Array[QualityWindow] {
  let result : Array[QualityWindow] = []
  if lower <= upper {
    for window in windows {
      if window.values.length() > 0 {
        let center = mean_of(window.values)
        if center < lower || center > upper {
          result.push(window)
        }
      }
    }
  }
  result
}

///|
/// Return the first window with an actionable alert.
pub fn first_actionable_window(windows : Array[QualityWindow]) -> Int? {
  for index, window in windows {
    if actionable_alert_count(evaluate_window(window)) > 0 {
      return Some(index)
    }
  }
  None
}
