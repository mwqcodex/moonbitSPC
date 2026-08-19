///|
/// A row-major matrix of measurements, with rows as parts and columns as features.
pub(all) struct MeasurementMatrix {
  rows : Array[Array[Double]]
  feature_names : Array[String]
} derive(Debug, ToJson)

///|
/// A result of validating a matrix before multivariate analysis.
pub(all) struct MatrixValidation {
  valid : Bool
  rows : Int
  columns : Int
  issues : Array[String]
} derive(Debug, ToJson)

///|
/// Construct a matrix and copy rows so callers retain ownership of inputs.
pub fn MeasurementMatrix::new(
  rows~ : Array[Array[Double]],
  feature_names~ : Array[String],
) -> MeasurementMatrix {
  let copied : Array[Array[Double]] = []
  for row in rows {
    copied.push(row.copy())
  }
  { rows: copied, feature_names: feature_names.copy() }
}

///|
/// Validate rectangular shape and feature labels.
pub fn MeasurementMatrix::validate(
  matrix : MeasurementMatrix,
) -> MatrixValidation {
  let issues : Array[String] = []
  let columns = if matrix.rows.length() == 0 {
    matrix.feature_names.length()
  } else {
    matrix.rows[0].length()
  }
  for row in matrix.rows {
    if row.length() != columns {
      issues.push("rows have inconsistent feature counts")
    }
  }
  if matrix.feature_names.length() != 0 &&
    matrix.feature_names.length() != columns {
    issues.push("feature label count does not match columns")
  }
  { valid: issues.length() == 0, rows: matrix.rows.length(), columns, issues }
}

///|
/// Return one feature column.
pub fn column(matrix : MeasurementMatrix, index : Int) -> Array[Double]? {
  if index < 0 || matrix.rows.length() == 0 || index >= matrix.rows[0].length() {
    None
  } else {
    let output : Array[Double] = []
    for row in matrix.rows {
      output.push(row[index])
    }
    Some(output)
  }
}

///|
/// Return all feature means.
pub fn column_means(matrix : MeasurementMatrix) -> Array[Double]? {
  let check = matrix.validate()
  if !check.valid {
    None
  } else {
    let result : Array[Double] = []
    for index in 0..<check.columns {
      match column(matrix, index) {
        Some(values) => result.push(mean_of(values))
        None => ()
      }
    }
    Some(result)
  }
}

///|
/// Return all feature sample deviations.
pub fn column_deviations(matrix : MeasurementMatrix) -> Array[Double]? {
  let check = matrix.validate()
  if !check.valid {
    None
  } else {
    let result : Array[Double] = []
    for index in 0..<check.columns {
      match column(matrix, index) {
        Some(values) => result.push(std_of(values, mean_of(values)))
        None => ()
      }
    }
    Some(result)
  }
}

///|
/// Center each feature by its sample mean.
pub fn center_matrix(matrix : MeasurementMatrix) -> MeasurementMatrix? {
  match column_means(matrix) {
    None => None
    Some(means) => {
      let result : Array[Array[Double]] = []
      for row in matrix.rows {
        let centered : Array[Double] = []
        for index, value in row {
          centered.push(value - means[index])
        }
        result.push(centered)
      }
      Some(
        MeasurementMatrix::new(rows=result, feature_names=matrix.feature_names),
      )
    }
  }
}

///|
/// Standardize each feature independently.
pub fn standardize_matrix(matrix : MeasurementMatrix) -> MeasurementMatrix? {
  match (column_means(matrix), column_deviations(matrix)) {
    (Some(means), Some(deviations)) => {
      let result : Array[Array[Double]] = []
      for row in matrix.rows {
        let normalized : Array[Double] = []
        for index, value in row {
          normalized.push(
            if deviations[index] == 0.0 {
              0.0
            } else {
              (value - means[index]) / deviations[index]
            },
          )
        }
        result.push(normalized)
      }
      Some(
        MeasurementMatrix::new(rows=result, feature_names=matrix.feature_names),
      )
    }
    _ => None
  }
}

///|
/// Feature-by-feature covariance matrix.
pub fn covariance_matrix(matrix : MeasurementMatrix) -> Array[Array[Double]]? {
  let check = matrix.validate()
  if !check.valid {
    None
  } else {
    let columns : Array[Array[Double]] = []
    for index in 0..<check.columns {
      match column(matrix, index) {
        Some(values) => columns.push(values)
        None => ()
      }
    }
    let result : Array[Array[Double]] = []
    for first in columns {
      let row : Array[Double] = []
      for second in columns {
        row.push(covariance(first, second).unwrap_or(0.0))
      }
      result.push(row)
    }
    Some(result)
  }
}

///|
/// Feature-by-feature correlation matrix.
pub fn correlation_matrix(matrix : MeasurementMatrix) -> Array[Array[Double]]? {
  let check = matrix.validate()
  if !check.valid {
    None
  } else {
    let columns : Array[Array[Double]] = []
    for index in 0..<check.columns {
      match column(matrix, index) {
        Some(values) => columns.push(values)
        None => ()
      }
    }
    let result : Array[Array[Double]] = []
    for first in columns {
      let row : Array[Double] = []
      for second in columns {
        row.push(correlation(first, second).unwrap_or(0.0))
      }
      result.push(row)
    }
    Some(result)
  }
}

///|
/// Squared Euclidean distance from a row to a center vector.
pub fn squared_distance(row : Array[Double], center : Array[Double]) -> Double? {
  if row.length() != center.length() {
    None
  } else {
    let mut total = 0.0
    for index in 0..<row.length() {
      let delta = row[index] - center[index]
      total += delta * delta
    }
    Some(total)
  }
}

///|
/// Euclidean distances from each row to a reference profile.
pub fn row_distances(
  matrix : MeasurementMatrix,
  center : Array[Double],
) -> Array[Double]? {
  let result : Array[Double] = []
  for row in matrix.rows {
    match squared_distance(row, center) {
      Some(value) => result.push(value.sqrt())
      None => return None
    }
  }
  Some(result)
}

///|
/// A multivariate alarm with row and score information.
pub(all) struct MultivariateAlarm {
  row : Int
  score : Double
  threshold : Double
  alarm : Bool
} derive(Debug, ToJson)

///|
/// Score rows against a profile using a distance threshold.
pub fn distance_alarms(
  matrix : MeasurementMatrix,
  center : Array[Double],
  threshold~ : Double,
) -> Array[MultivariateAlarm]? {
  match row_distances(matrix, center) {
    None => None
    Some(distances) => {
      let result : Array[MultivariateAlarm] = []
      for row, score in distances {
        result.push({ row, score, threshold, alarm: score >= threshold })
      }
      Some(result)
    }
  }
}

///|
/// Select rows that remain in a multivariate acceptance region.
pub fn select_rows(
  matrix : MeasurementMatrix,
  alarms : Array[MultivariateAlarm],
  keep_alarms : Bool,
) -> MeasurementMatrix {
  let rows : Array[Array[Double]] = []
  for row, alarm in alarms {
    if alarm.alarm == keep_alarms && row < matrix.rows.length() {
      rows.push(matrix.rows[row].copy())
    }
  }
  MeasurementMatrix::new(rows~, feature_names=matrix.feature_names)
}

///|
/// Weighted linear combination of features for a scorecard.
pub fn weighted_row_score(
  row : Array[Double],
  weights : Array[Double],
) -> Double? {
  if row.length() != weights.length() {
    None
  } else {
    let mut total = 0.0
    for index in 0..<row.length() {
      total += row[index] * weights[index]
    }
    Some(total)
  }
}

///|
/// Scores for every row under a weighted feature model.
pub fn weighted_scores(
  matrix : MeasurementMatrix,
  weights : Array[Double],
) -> Array[Double]? {
  let result : Array[Double] = []
  for row in matrix.rows {
    match weighted_row_score(row, weights) {
      Some(score) => result.push(score)
      None => return None
    }
  }
  Some(result)
}

///|
/// Normalize a weight vector to unit absolute sum.
pub fn normalize_weights(weights : Array[Double]) -> Array[Double]? {
  let mut total = 0.0
  for value in weights {
    total += value.abs()
  }
  if total == 0.0 {
    None
  } else {
    let result : Array[Double] = []
    for value in weights {
      result.push(value / total)
    }
    Some(result)
  }
}

///|
/// Return the feature index with the largest variance.
pub fn dominant_feature(matrix : MeasurementMatrix) -> Int? {
  match column_deviations(matrix) {
    None => None
    Some(values) =>
      if values.length() == 0 {
        None
      } else {
        let mut best = 0
        for index in 1..<values.length() {
          if values[index] > values[best] {
            best = index
          }
        }
        Some(best)
      }
  }
}

///|
/// Return a copy of a matrix with rows sorted by a selected feature.
pub fn sort_rows_by_feature(
  matrix : MeasurementMatrix,
  feature : Int,
) -> MeasurementMatrix? {
  let check = matrix.validate()
  if !check.valid || feature < 0 || feature >= check.columns {
    None
  } else {
    let rows = matrix.rows.copy()
    for index in 1..<rows.length() {
      let value = rows[index]
      let mut cursor = index
      while cursor > 0 && rows[cursor - 1][feature] > value[feature] {
        rows[cursor] = rows[cursor - 1]
        cursor -= 1
      }
      rows[cursor] = value
    }
    Some(MeasurementMatrix::new(rows~, feature_names=matrix.feature_names))
  }
}

///|
/// Add a derived feature to every row.
pub fn append_feature(
  matrix : MeasurementMatrix,
  values : Array[Double],
  name : String,
) -> MeasurementMatrix? {
  if values.length() != matrix.rows.length() {
    None
  } else {
    let rows : Array[Array[Double]] = []
    for index, row in matrix.rows {
      let extended = row.copy()
      extended.push(values[index])
      rows.push(extended)
    }
    let names = matrix.feature_names.copy()
    names.push(name)
    Some(MeasurementMatrix::new(rows~, feature_names=names))
  }
}

///|
/// Difference between two profiles, useful for revision-to-revision comparison.
pub fn profile_delta(
  first : Array[Double],
  second : Array[Double],
) -> Array[Double]? {
  if first.length() != second.length() {
    None
  } else {
    let result : Array[Double] = []
    for index in 0..<first.length() {
      result.push(second[index] - first[index])
    }
    Some(result)
  }
}

///|
/// Maximum absolute coordinate difference between profiles.
pub fn profile_max_delta(
  first : Array[Double],
  second : Array[Double],
) -> Double? {
  match profile_delta(first, second) {
    None => None
    Some(values) => {
      let mut best = 0.0
      for value in values {
        best = best.max(value.abs())
      }
      Some(best)
    }
  }
}

///|
/// Count rows with any feature outside a component-wise specification.
pub fn count_component_failures(
  matrix : MeasurementMatrix,
  lower : Array[Double],
  upper : Array[Double],
) -> Int {
  let mut count = 0
  for row in matrix.rows {
    let mut failed = row.length() != lower.length() ||
      row.length() != upper.length()
    if !failed {
      for index in 0..<row.length() {
        if row[index] < lower[index] || row[index] > upper[index] {
          failed = true
        }
      }
    }
    if failed {
      count += 1
    }
  }
  count
}

///|
/// Project a row onto a principal direction.
pub fn project_row(row : Array[Double], direction : Array[Double]) -> Double? {
  weighted_row_score(row, direction)
}

///|
/// Project every row onto a principal direction.
pub fn project_matrix(
  matrix : MeasurementMatrix,
  direction : Array[Double],
) -> Array[Double]? {
  let result : Array[Double] = []
  for row in matrix.rows {
    match project_row(row, direction) {
      Some(value) => result.push(value)
      None => return None
    }
  }
  Some(result)
}

///|
/// Reconstruct a row from a scalar score and direction.
pub fn reconstruct_row(
  score : Double,
  direction : Array[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for value in direction {
    result.push(score * value)
  }
  result
}

///|
/// Sum squared reconstruction errors for a one-component model.
pub fn reconstruction_error(
  matrix : MeasurementMatrix,
  direction : Array[Double],
) -> Double? {
  match project_matrix(matrix, direction) {
    None => None
    Some(scores) => {
      let mut total = 0.0
      for index, row in matrix.rows {
        match squared_distance(row, reconstruct_row(scores[index], direction)) {
          Some(value) => total += value
          None => return None
        }
      }
      Some(total)
    }
  }
}
