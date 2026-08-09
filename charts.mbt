///|
/// One plotted observation and its three-sigma limits.
pub(all) struct ChartPoint {
  value : Double
  center : Double
  upper : Double
  lower : Double
  out_of_control : Bool
} derive(Debug, ToJson)

///|
/// A deterministic control-chart data series.
pub(all) struct ControlChart {
  kind : String
  center : Double
  points : Array[ChartPoint]
} derive(Debug, ToJson)

///|
pub(all) enum ChartResult {
  ChartOk(ControlChart)
  ChartInvalidInput(message~ : String)
} derive(Debug)

///|
fn make_point(
  value : Double,
  center : Double,
  upper : Double,
  lower : Double,
) -> ChartPoint {
  {
    value,
    center,
    upper,
    lower,
    out_of_control: value > upper || value < lower,
  }
}

///|
fn chart_from_values(
  kind : String,
  values : Array[Double],
  center : Double,
  upper : Double,
  lower : Double,
) -> ControlChart {
  let points : Array[ChartPoint] = []
  for value in values {
    points.push(make_point(value, center, upper, lower))
  }
  { kind, center, points }
}

///|
fn mean_of(values : Array[Double]) -> Double {
  let mut total = 0.0
  for value in values {
    total += value
  }
  total / values.length().to_double()
}

///|
fn range_of(values : Array[Double]) -> Double {
  let mut low = values[0]
  let mut high = values[0]
  for value in values {
    if value < low {
      low = value
    }
    if value > high {
      high = value
    }
  }
  high - low
}

///|
fn std_of(values : Array[Double], mean : Double) -> Double {
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
/// X-bar/R chart. Subgroups are expected to have the same size.
pub fn ControlChart::xbar_r(groups : Array[Array[Double]]) -> ChartResult {
  if groups.length() < 2 || groups[0].length() < 2 {
    ChartInvalidInput(message="xbar-r needs at least two subgroups of size two")
  } else {
    let size = groups[0].length()
    let means : Array[Double] = []
    let ranges : Array[Double] = []
    for group in groups {
      if group.length() != size {
        return ChartInvalidInput(message="xbar-r subgroup sizes must match")
      }
      means.push(mean_of(group))
      ranges.push(range_of(group))
    }
    let xbar = mean_of(means)
    let rbar = mean_of(ranges)
    let a2 = match size {
      2 => 1.88
      3 => 1.023
      4 => 0.729
      5 => 0.577
      6 => 0.483
      7 => 0.419
      8 => 0.373
      9 => 0.337
      10 => 0.308
      _ => 0.0
    }
    if a2 == 0.0 {
      ChartInvalidInput(message="xbar-r supports subgroup sizes from 2 to 10")
    } else {
      ChartOk(
        chart_from_values(
          "X-bar/R",
          means,
          xbar,
          xbar + a2 * rbar,
          xbar - a2 * rbar,
        ),
      )
    }
  }
}

///|
/// X-bar/S chart using the average within-subgroup sample deviation.
pub fn ControlChart::xbar_s(groups : Array[Array[Double]]) -> ChartResult {
  if groups.length() < 2 || groups[0].length() < 2 {
    ChartInvalidInput(message="xbar-s needs at least two subgroups of size two")
  } else {
    let size = groups[0].length()
    let means : Array[Double] = []
    let deviations : Array[Double] = []
    for group in groups {
      if group.length() != size {
        return ChartInvalidInput(message="xbar-s subgroup sizes must match")
      }
      let m = mean_of(group)
      means.push(m)
      deviations.push(std_of(group, m))
    }
    let xbar = mean_of(means)
    let sbar = mean_of(deviations)
    let c4 = match size {
      2 => 0.7979
      3 => 0.8862
      4 => 0.9213
      5 => 0.9399
      _ => 0.94
    }
    let a3 = 3.0 / (c4 * size.to_double().sqrt())
    ChartOk(
      chart_from_values(
        "X-bar/S",
        means,
        xbar,
        xbar + a3 * sbar,
        xbar - a3 * sbar,
      ),
    )
  }
}

///|
/// Individuals/moving-range chart.
pub fn ControlChart::imr(values : Array[Double]) -> ChartResult {
  if values.length() < 2 {
    ChartInvalidInput(message="i-mr needs at least two observations")
  } else {
    let moving : Array[Double] = []
    for i in 1..<values.length() {
      moving.push((values[i] - values[i - 1]).abs())
    }
    let center = mean_of(values)
    let mrbar = mean_of(moving)
    let sigma = mrbar / 1.128
    ChartOk(
      chart_from_values(
        "I-MR",
        values,
        center,
        center + 3.0 * sigma,
        center - 3.0 * sigma,
      ),
    )
  }
}

///|
fn counts_chart(
  kind : String,
  counts : Array[Int],
  sizes : Array[Int],
  scale : Double,
) -> ChartResult {
  if counts.length() == 0 || counts.length() != sizes.length() {
    ChartInvalidInput(
      message="counts and sizes must have equal non-zero length",
    )
  } else {
    let rates : Array[Double] = []
    for i in 0..<counts.length() {
      if sizes[i] <= 0 {
        return ChartInvalidInput(message="exposure must be positive")
      }
      rates.push(counts[i].to_double() / sizes[i].to_double())
    }
    let center = mean_of(rates)
    let variance = center * (1.0 - center)
    let upper = center + scale * variance.sqrt()
    let lower = (center - scale * variance.sqrt()).max(0.0)
    ChartOk(chart_from_values(kind, rates, center, upper, lower))
  }
}

///|
/// Fraction defective chart.
pub fn ControlChart::p(counts : Array[Int], sizes : Array[Int]) -> ChartResult {
  counts_chart("P", counts, sizes, 3.0)
}

///|
/// Number defective chart for a constant sample size.
pub fn ControlChart::np(counts : Array[Int], sample_size : Int) -> ChartResult {
  if sample_size <= 0 || counts.length() == 0 {
    ChartInvalidInput(message="sample size and counts must be positive")
  } else {
    let sizes : Array[Int] = []
    for _ in counts {
      sizes.push(sample_size)
    }
    counts_chart("NP", counts, sizes, 3.0)
  }
}

///|
/// Count defects chart for a constant opportunity count.
pub fn ControlChart::c(counts : Array[Int], opportunities : Int) -> ChartResult {
  if opportunities <= 0 || counts.length() == 0 {
    ChartInvalidInput(message="opportunities and counts must be positive")
  } else {
    let sizes : Array[Int] = []
    for _ in counts {
      sizes.push(opportunities)
    }
    counts_chart("C", counts, sizes, 3.0)
  }
}

///|
/// Defects-per-unit chart with varying exposure.
pub fn ControlChart::u(
  counts : Array[Int],
  opportunities : Array[Int],
) -> ChartResult {
  counts_chart("U", counts, opportunities, 3.0)
}
