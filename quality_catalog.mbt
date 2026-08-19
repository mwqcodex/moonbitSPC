///|
pub struct QualityMetric {
  key : String
  value : Double
  unit : String
  target : Double
  lower_is_better : Bool
} derive(Debug, ToJson)

///|
pub struct MetricCatalog {
  metrics : Array[QualityMetric]
  version : String
} derive(Debug, ToJson)

///|
pub fn quality_metric(
  key~ : String,
  value~ : Double,
  unit~ : String,
  target~ : Double,
  lower_is_better~ : Bool,
) -> QualityMetric {
  { key, value, unit, target, lower_is_better }
}

///|
pub fn metric_catalog(version~ : String) -> MetricCatalog {
  { metrics: [], version }
}

///|
pub fn MetricCatalog::add(self : MetricCatalog, metric : QualityMetric) -> Unit {
  self.metrics.push(metric)
}

///|
pub fn metric_gap(metric : QualityMetric) -> Double {
  if metric.lower_is_better {
    (metric.value - metric.target).max(0.0)
  } else {
    (metric.target - metric.value).max(0.0)
  }
}

///|
pub fn metric_meets_target(metric : QualityMetric) -> Bool {
  metric_gap(metric) <= 0.0
}

///|
pub fn catalog_score(catalog : MetricCatalog) -> Double {
  if catalog.metrics.length() == 0 {
    100.0
  } else {
    let mut passed = 0
    for metric in catalog.metrics {
      if metric_meets_target(metric) {
        passed += 1
      }
    }
    passed.to_double() / catalog.metrics.length().to_double() * 100.0
  }
}

///|
pub fn catalog_failed(catalog : MetricCatalog) -> Array[QualityMetric] {
  let result : Array[QualityMetric] = []
  for metric in catalog.metrics {
    if !metric_meets_target(metric) {
      result.push(metric)
    }
  }
  result
}

///|
pub fn catalog_keys(catalog : MetricCatalog) -> Array[String] {
  let result : Array[String] = []
  for metric in catalog.metrics {
    result.push(metric.key)
  }
  result
}

///|
pub fn catalog_units(catalog : MetricCatalog) -> Array[String] {
  let result : Array[String] = []
  for metric in catalog.metrics {
    if !result.contains(metric.unit) {
      result.push(metric.unit)
    }
  }
  result
}

///|
pub fn catalog_metric(catalog : MetricCatalog, key : String) -> QualityMetric? {
  for metric in catalog.metrics {
    if metric.key == key {
      return Some(metric)
    }
  }
  None
}

///|
pub fn normalized_metric(metric : QualityMetric) -> Double {
  if metric.target == 0.0 {
    0.0
  } else if metric.lower_is_better {
    metric.target / metric.value.max(0.000001)
  } else {
    metric.value / metric.target
  }
}

///|
pub fn catalog_average_normalized(catalog : MetricCatalog) -> Double {
  if catalog.metrics.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for metric in catalog.metrics {
      total += normalized_metric(metric)
    }
    total / catalog.metrics.length().to_double()
  }
}
