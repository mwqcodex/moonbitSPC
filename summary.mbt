///|
fn flatten(groups : Array[Subgroup]) -> Array[Double] {
  let values : Array[Double] = []
  for group in groups {
    for value in group.values {
      values.push(value)
    }
  }
  values
}

///|
fn sample_standard_deviation(values : Array[Double], mean : Double) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut sum = 0.0
    for value in values {
      let delta = value - mean
      sum += delta * delta
    }
    (sum / (values.length() - 1).to_double()).sqrt()
  }
}

///|
/// Summarize manufacturing observations across one or more subgroups.
pub fn summarize(
  groups : Array[Subgroup],
  specification? : Specification,
) -> SummaryResult {
  let values = flatten(groups)
  if values.length() == 0 {
    InvalidInput(message="observations must not be empty")
  } else {
    let mut total = 0.0
    let mut minimum = values[0]
    let mut maximum = values[0]
    for value in values {
      total += value
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
    }
    let mean = total / values.length().to_double()
    let mut out_of_spec = 0
    match specification {
      Some(spec) =>
        for value in values {
          if value < spec.lower || value > spec.upper {
            out_of_spec += 1
          }
        }
      None => ()
    }
    let first = groups[0]
    Ok({
      count: values.length(),
      mean,
      standard_deviation: sample_standard_deviation(values, mean),
      minimum,
      maximum,
      out_of_spec_rate: out_of_spec.to_double() / values.length().to_double(),
      batch: first.batch,
      equipment: first.equipment,
      tool: first.tool,
      operator: first.operator,
      window: first.window,
    })
  }
}
