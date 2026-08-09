///|
/// A detected Western Electric rule violation.
pub(all) struct RuleViolation {
  rule : Int
  start_index : Int
  indices : Array[Int]
  message : String
} derive(Debug, ToJson)

///|
fn same_side(
  values : Array[Double],
  mean : Double,
  start : Int,
  length : Int,
  threshold : Double,
) -> Bool {
  let first = values[start] - mean
  if first == 0.0 {
    false
  } else {
    let positive = first > 0.0
    let mut valid = true
    for i in start..<(start + length) {
      let delta = values[i] - mean
      if delta.abs() <= threshold || (delta > 0.0) != positive {
        valid = false
      }
    }
    valid
  }
}

///|
/// Detect the four commonly used Western Electric rules.
pub fn detect_western_electric(
  values : Array[Double],
  mean~ : Double,
  sigma~ : Double,
) -> Array[RuleViolation] {
  let violations : Array[RuleViolation] = []
  if sigma <= 0.0 {
    violations
  } else {
    for i in 0..<values.length() {
      if (values[i] - mean).abs() > 3.0 * sigma {
        violations.push({
          rule: 1,
          start_index: i,
          indices: [i],
          message: "one point beyond three sigma",
        })
      }
    }
    if values.length() >= 3 {
      for i in 0..<(values.length() - 2) {
        let mut positive = 0
        let mut negative = 0
        for j in i..<(i + 3) {
          let delta = values[j] - mean
          if delta > 2.0 * sigma {
            positive += 1
          }
          if delta < -2.0 * sigma {
            negative += 1
          }
        }
        if positive >= 2 || negative >= 2 {
          violations.push({
            rule: 2,
            start_index: i,
            indices: [i, i + 1, i + 2],
            message: "two of three beyond two sigma",
          })
        }
      }
    }
    if values.length() >= 5 {
      for i in 0..<(values.length() - 4) {
        let mut positive = 0
        let mut negative = 0
        for j in i..<(i + 5) {
          let delta = values[j] - mean
          if delta > sigma {
            positive += 1
          }
          if delta < -sigma {
            negative += 1
          }
        }
        if positive >= 4 || negative >= 4 {
          violations.push({
            rule: 3,
            start_index: i,
            indices: [i, i + 1, i + 2, i + 3, i + 4],
            message: "four of five beyond one sigma",
          })
        }
      }
    }
    if values.length() >= 8 {
      for i in 0..<(values.length() - 7) {
        if same_side(values, mean, i, 8, 0.0) {
          let indices : Array[Int] = []
          for j in i..<(i + 8) {
            indices.push(j)
          }
          violations.push({
            rule: 4,
            start_index: i,
            indices,
            message: "eight consecutive points on one side",
          })
        }
      }
    }
    violations
  }
}
