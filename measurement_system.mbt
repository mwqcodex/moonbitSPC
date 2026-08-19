///|
pub struct GaugeStudy {
  readings : Array[Double]
  reference : Double
  repeatability : Double
  bias : Double
  resolution : Double
  percent_tolerance : Double
  adequate : Bool
} derive(Debug, ToJson)

///|
fn ms_mean(values : Array[Double]) -> Double {
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
fn ms_sd(values : Array[Double], mean : Double) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      let d = value - mean
      total += d * d
    }
    (total / (values.length() - 1).to_double()).sqrt()
  }
}

///|
pub fn gauge_study(
  readings~ : Array[Double],
  reference~ : Double,
  tolerance~ : Double,
  resolution~ : Double,
) -> GaugeStudy {
  let mean = ms_mean(readings)
  let sd = ms_sd(readings, mean)
  let bias = mean - reference
  {
    readings,
    reference,
    repeatability: sd,
    bias,
    resolution,
    percent_tolerance: if tolerance <= 0.0 {
      0.0
    } else {
      100.0 * sd / tolerance
    },
    adequate: tolerance > 0.0 &&
    sd <= tolerance * 0.1 &&
    resolution <= tolerance * 0.1,
  }
}

///|
pub fn gauge_bias_percent(study : GaugeStudy, tolerance : Double) -> Double {
  if tolerance <= 0.0 {
    0.0
  } else {
    study.bias.abs() / tolerance * 100.0
  }
}

///|
pub fn gauge_resolution_ratio(study : GaugeStudy, tolerance : Double) -> Double {
  if tolerance <= 0.0 {
    0.0
  } else {
    study.resolution / tolerance
  }
}

///|
pub fn gauge_repeatability_ratio(
  study : GaugeStudy,
  tolerance : Double,
) -> Double {
  if tolerance <= 0.0 {
    0.0
  } else {
    study.repeatability / tolerance
  }
}

///|
pub fn gauge_status(study : GaugeStudy) -> String {
  if study.adequate {
    "adequate"
  } else {
    "review"
  }
}

///|
pub fn operator_average(
  readings : Array[Double],
  operators : Int,
) -> Array[Double] {
  if operators <= 0 {
    return []
  }
  let result : Array[Double] = []
  let per = readings.length() / operators
  for operator in 0..<operators {
    let start = operator * per
    let finish = if operator == operators - 1 {
      readings.length()
    } else {
      start + per
    }
    result.push(ms_mean(readings[start:finish].to_owned()))
  }
  result
}

///|
pub fn reproducibility(values : Array[Double]) -> Double {
  ms_sd(values, ms_mean(values))
}

///|
pub fn repeatability_by_group(groups : Array[Array[Double]]) -> Double {
  if groups.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for group in groups {
      total += ms_sd(group, ms_mean(group))
    }
    total / groups.length().to_double()
  }
}

///|
pub fn ndc(process_sd : Double, gauge_sd : Double) -> Double {
  if gauge_sd <= 0.0 {
    0.0
  } else {
    1.41 * process_sd / gauge_sd
  }
}

///|
pub fn grr_percent(gauge_sd : Double, tolerance : Double) -> Double {
  if tolerance <= 0.0 {
    0.0
  } else {
    5.15 * gauge_sd / tolerance * 100.0
  }
}

///|
pub fn measurement_system_rating(ndc_value : Double, grr : Double) -> String {
  if ndc_value >= 5.0 && grr <= 10.0 {
    "good"
  } else if ndc_value >= 2.0 && grr <= 30.0 {
    "conditional"
  } else {
    "poor"
  }
}

///|
pub fn linearity_slope(
  references : Array[Double],
  readings : Array[Double],
) -> Double {
  if references.length() < 2 || references.length() != readings.length() {
    0.0
  } else {
    let x = ms_mean(references)
    let y = ms_mean(readings)
    let mut num = 0.0
    let mut den = 0.0
    for i in 0..<references.length() {
      num += (references[i] - x) * (readings[i] - y)
      den += (references[i] - x) * (references[i] - x)
    }
    if den <= 0.0 {
      0.0
    } else {
      num / den
    }
  }
}

///|
pub fn linearity_bias(
  references : Array[Double],
  readings : Array[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<references.length().min(readings.length()) {
    result.push(readings[i] - references[i])
  }
  result
}

///|
pub fn stability_range(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut low = values[0]
    let mut high = values[0]
    for value in values {
      low = low.min(value)
      high = high.max(value)
    }
    high - low
  }
}
