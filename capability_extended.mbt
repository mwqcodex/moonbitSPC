///|
pub struct CapabilityExtended {
  cp : Double
  cpk : Double
  cpu : Double
  cpl : Double
  ppm_upper : Double
  ppm_lower : Double
  yield_rate : Double
  sigma_level : Double
  capable : Bool
} derive(Debug, ToJson)

///|
fn safe_probability(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
pub fn ppm_from_rate(rate : Double) -> Double {
  safe_probability(rate) * 1000000.0
}

///|
pub fn yield_from_ppm(ppm : Double) -> Double {
  safe_probability(1.0 - ppm / 1000000.0)
}

///|
pub fn sigma_from_yield(yield_rate : Double) -> Double {
  let y = safe_probability(yield_rate)
  if y <= 0.0 {
    0.0
  } else if y >= 1.0 {
    6.0
  } else {
    0.5 + 2.0 * y
  }
}

///|
pub fn capability_extended(
  mean~ : Double,
  deviation~ : Double,
  lower~ : Double,
  upper~ : Double,
  target~ : Double,
  threshold~ : Double,
) -> CapabilityExtended {
  if deviation <= 0.0 || upper <= lower {
    return {
      cp: 0.0,
      cpk: 0.0,
      cpu: 0.0,
      cpl: 0.0,
      ppm_upper: 0.0,
      ppm_lower: 0.0,
      yield_rate: 0.0,
      sigma_level: 0.0,
      capable: false,
    }
  }
  let cp = (upper - lower) / (6.0 * deviation)
  let cpu = (upper - mean) / (3.0 * deviation)
  let cpl = (mean - lower) / (3.0 * deviation)
  let cpk = cpu.min(cpl)
  let ppm_upper = ppm_from_rate(
    if mean > upper {
      1.0
    } else {
      (mean - target).max(0.0) / (upper - target).max(0.000001) * 0.001
    },
  )
  let ppm_lower = ppm_from_rate(
    if mean < lower {
      1.0
    } else {
      (target - mean).max(0.0) / (target - lower).max(0.000001) * 0.001
    },
  )
  let yield_rate = safe_probability(1.0 - (ppm_upper + ppm_lower) / 1000000.0)
  {
    cp,
    cpk,
    cpu,
    cpl,
    ppm_upper,
    ppm_lower,
    yield_rate,
    sigma_level: sigma_from_yield(yield_rate),
    capable: cpk >= threshold,
  }
}

///|
pub fn capability_margin(cpk : Double, threshold : Double) -> Double {
  cpk - threshold
}

///|
pub fn capability_status(cpk : Double, threshold : Double) -> String {
  if cpk >= threshold {
    "capable"
  } else if cpk >= threshold * 0.8 {
    "watch"
  } else {
    "incapable"
  }
}

///|
pub fn one_sided_capability(
  mean~ : Double,
  deviation~ : Double,
  limit~ : Double,
  upper~ : Bool,
) -> Double {
  if deviation <= 0.0 {
    0.0
  } else if upper {
    (limit - mean) / (3.0 * deviation)
  } else {
    (mean - limit) / (3.0 * deviation)
  }
}

///|
pub fn capability_confidence_margin(
  deviation : Double,
  sample_count : Int,
) -> Double {
  if sample_count <= 1 {
    0.0
  } else {
    1.96 * deviation / sample_count.to_double().sqrt()
  }
}

///|
pub fn observed_yield(
  values : Array[Double],
  lower : Double,
  upper : Double,
) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let mut good = 0
  for value in values {
    if value >= lower && value <= upper {
      good += 1
    }
  }
  good.to_double() / values.length().to_double()
}

///|
pub fn nonconformance_ppm(
  values : Array[Double],
  lower : Double,
  upper : Double,
) -> Double {
  ppm_from_rate(1.0 - observed_yield(values, lower, upper))
}

///|
pub fn capability_band(cpk : Double) -> Int {
  if cpk < 0.67 {
    0
  } else if cpk < 1.0 {
    1
  } else if cpk < 1.33 {
    2
  } else if cpk < 1.67 {
    3
  } else {
    4
  }
}
