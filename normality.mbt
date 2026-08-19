///|
pub struct DistributionSummary {
  count : Int
  mean : Double
  deviation : Double
  median : Double
  mad : Double
  skewness : Double
  kurtosis : Double
  normality_score : Double
  approximately_normal : Bool
} derive(Debug, ToJson)

///|
fn ns_mean(values : Array[Double]) -> Double {
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
fn ns_sorted(values : Array[Double]) -> Array[Double] {
  let result = values.copy()
  result.sort()
  result
}

///|
pub fn median_value(values : Array[Double]) -> Double {
  let sorted = ns_sorted(values)
  if sorted.length() == 0 {
    0.0
  } else {
    let middle = sorted.length() / 2
    if sorted.length() % 2 == 1 {
      sorted[middle]
    } else {
      (sorted[middle - 1] + sorted[middle]) / 2.0
    }
  }
}

///|
pub fn median_absolute_deviation(values : Array[Double]) -> Double {
  let median = median_value(values)
  let deviations : Array[Double] = []
  for value in values {
    deviations.push((value - median).abs())
  }
  median_value(deviations)
}

///|
pub fn central_moment(values : Array[Double], order : Int) -> Double {
  if values.length() == 0 || order <= 0 {
    0.0
  } else {
    let mean = ns_mean(values)
    let mut total = 0.0
    for value in values {
      let delta = value - mean
      let powered = if order == 1 {
        delta
      } else if order == 2 {
        delta * delta
      } else if order == 3 {
        delta * delta * delta
      } else {
        delta * delta * delta * delta
      }
      total += powered
    }
    total / values.length().to_double()
  }
}

///|
pub fn skewness_value(values : Array[Double]) -> Double {
  let sd = central_moment(values, 2).sqrt()
  if sd <= 0.0 {
    0.0
  } else {
    central_moment(values, 3) / (sd * sd * sd)
  }
}

///|
pub fn kurtosis_value(values : Array[Double]) -> Double {
  let variance = central_moment(values, 2)
  if variance <= 0.0 {
    0.0
  } else {
    central_moment(values, 4) / (variance * variance) - 3.0
  }
}

///|
pub fn distribution_summary(values : Array[Double]) -> DistributionSummary {
  let mean = ns_mean(values)
  let sd = central_moment(values, 2).sqrt()
  let skew = skewness_value(values)
  let kurt = kurtosis_value(values)
  let score = skew.abs() + kurt.abs() / 2.0
  {
    count: values.length(),
    mean,
    deviation: sd,
    median: median_value(values),
    mad: median_absolute_deviation(values),
    skewness: skew,
    kurtosis: kurt,
    normality_score: score,
    approximately_normal: score < 1.0,
  }
}

///|
pub fn normality_label(summary : DistributionSummary) -> String {
  if summary.approximately_normal {
    "approximately_normal"
  } else {
    "non_normal"
  }
}

///|
pub fn robust_z_score(value : Double, median : Double, mad : Double) -> Double {
  if mad <= 0.0 {
    0.0
  } else {
    0.6745 * (value - median) / mad
  }
}

///|
pub fn robust_outlier_indices(
  values : Array[Double],
  threshold : Double,
) -> Array[Int] {
  let median = median_value(values)
  let mad = median_absolute_deviation(values)
  let result : Array[Int] = []
  for i, value in values {
    if robust_z_score(value, median, mad).abs() > threshold {
      result.push(i)
    }
  }
  result
}

///|
pub fn quantile_value(values : Array[Double], probability : Double) -> Double {
  let sorted = ns_sorted(values)
  if sorted.length() == 0 {
    0.0
  } else {
    let p = probability.max(0.0).min(1.0)
    let index = (p * (sorted.length() - 1).to_double()).round().to_int()
    sorted[index]
  }
}

///|
pub fn interquartile_range(values : Array[Double]) -> Double {
  quantile_value(values, 0.75) - quantile_value(values, 0.25)
}

///|
pub fn normality_distance(summary : DistributionSummary) -> Double {
  summary.normality_score
}
