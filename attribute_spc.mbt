///|
/// A categorical defect count with a stable category label.
pub(all) struct CategoryCount {
  category : String
  count : Int
  proportion : Double
} derive(Debug, ToJson)

///|
/// Pareto row with cumulative contribution.
pub(all) struct ParetoRow {
  category : String
  count : Int
  proportion : Double
  cumulative : Double
} derive(Debug, ToJson)

///|
/// Calculate defect rates from counts and exposure values.
pub fn attribute_rate(
  counts : Array[Int],
  exposure : Array[Int],
) -> Array[Double]? {
  if counts.length() == 0 || counts.length() != exposure.length() {
    None
  } else {
    let result : Array[Double] = []
    for index in 0..<counts.length() {
      if counts[index] < 0 ||
        exposure[index] <= 0 ||
        counts[index] > exposure[index] {
        return None
      }
      result.push(counts[index].to_double() / exposure[index].to_double())
    }
    Some(result)
  }
}

///|
/// Calculate average defects per opportunity with varying exposure.
pub fn defects_per_opportunity(
  defects : Array[Int],
  opportunities : Array[Int],
) -> Double? {
  if defects.length() == 0 || defects.length() != opportunities.length() {
    None
  } else {
    let mut total_defects = 0
    let mut total_opportunities = 0
    for index in 0..<defects.length() {
      if defects[index] < 0 || opportunities[index] <= 0 {
        return None
      }
      total_defects += defects[index]
      total_opportunities += opportunities[index]
    }
    Some(total_defects.to_double() / total_opportunities.to_double())
  }
}

///|
/// Aggregate a categorical defect stream in first-seen order.
pub fn category_counts(categories : Array[String]) -> Array[CategoryCount] {
  let result : Array[CategoryCount] = []
  for category in categories {
    let mut found : Int? = None
    for index, row in result {
      if row.category == category {
        found = Some(index)
      }
    }
    match found {
      Some(index) =>
        result[index] = {
          category: result[index].category,
          count: result[index].count + 1,
          proportion: 0.0,
        }
      None => result.push({ category, count: 1, proportion: 0.0 })
    }
  }
  let total = categories.length().to_double()
  for index in 0..<result.length() {
    result[index] = {
      category: result[index].category,
      count: result[index].count,
      proportion: if total == 0.0 {
        0.0
      } else {
        result[index].count.to_double() / total
      },
    }
  }
  result
}

///|
/// Sort category rows by descending contribution.
pub fn sort_category_counts(
  rows : Array[CategoryCount],
) -> Array[CategoryCount] {
  let result = rows.copy()
  for index in 1..<result.length() {
    let value = result[index]
    let mut cursor = index
    while cursor > 0 && result[cursor - 1].count < value.count {
      result[cursor] = result[cursor - 1]
      cursor -= 1
    }
    result[cursor] = value
  }
  result
}

///|
/// Build a Pareto ranking from categorical observations.
pub fn pareto_categories(categories : Array[String]) -> Array[ParetoRow] {
  let sorted = sort_category_counts(category_counts(categories))
  let result : Array[ParetoRow] = []
  let mut cumulative = 0.0
  for row in sorted {
    cumulative += row.proportion
    result.push({
      category: row.category,
      count: row.count,
      proportion: row.proportion,
      cumulative,
    })
  }
  result
}

///|
/// A binomial attribute-chart point.
pub(all) struct AttributePoint {
  index : Int
  rate : Double
  center : Double
  lower : Double
  upper : Double
  alarm : Bool
} derive(Debug, ToJson)

///|
/// Create a p-chart series from variable exposures.
pub fn p_chart_points(
  counts : Array[Int],
  exposure : Array[Int],
) -> Array[AttributePoint]? {
  match attribute_rate(counts, exposure) {
    None => None
    Some(rates) => {
      let center = mean_of(rates)
      let result : Array[AttributePoint] = []
      for index, rate in rates {
        let variance = center * (1.0 - center) / exposure[index].to_double()
        let margin = 3.0 * variance.max(0.0).sqrt()
        let lower = (center - margin).max(0.0)
        let upper = (center + margin).min(1.0)
        result.push({
          index,
          rate,
          center,
          lower,
          upper,
          alarm: rate < lower || rate > upper,
        })
      }
      Some(result)
    }
  }
}

///|
/// A c-chart point for counts at a constant opportunity count.
pub(all) struct CountPoint {
  index : Int
  count : Int
  center : Double
  lower : Double
  upper : Double
  alarm : Bool
} derive(Debug, ToJson)

///|
/// Create a count chart with Poisson three-sigma limits.
pub fn count_chart_points(counts : Array[Int]) -> Array[CountPoint]? {
  if counts.length() == 0 {
    None
  } else {
    let mut total = 0
    for count in counts {
      if count < 0 {
        return None
      }
      total += count
    }
    let center = total.to_double() / counts.length().to_double()
    let margin = 3.0 * center.sqrt()
    let lower = (center - margin).max(0.0)
    let upper = center + margin
    let result : Array[CountPoint] = []
    for index, count in counts {
      result.push({
        index,
        count,
        center,
        lower,
        upper,
        alarm: count.to_double() < lower || count.to_double() > upper,
      })
    }
    Some(result)
  }
}

///|
/// Return the number of attribute alarms.
pub fn attribute_alarm_count(points : Array[AttributePoint]) -> Int {
  let mut count = 0
  for point in points {
    if point.alarm {
      count += 1
    }
  }
  count
}

///|
/// Return the number of count-chart alarms.
pub fn count_alarm_count(points : Array[CountPoint]) -> Int {
  let mut count = 0
  for point in points {
    if point.alarm {
      count += 1
    }
  }
  count
}

///|
/// Compare two categorical defect distributions.
pub fn category_delta(
  first : Array[CategoryCount],
  second : Array[CategoryCount],
) -> Array[CategoryCount] {
  let result : Array[CategoryCount] = []
  for row in second {
    let mut old = 0
    for previous in first {
      if previous.category == row.category {
        old = previous.count
      }
    }
    result.push({
      category: row.category,
      count: row.count - old,
      proportion: row.proportion,
    })
  }
  result
}

///|
/// Return categories whose counts increased.
pub fn increased_categories(
  first : Array[CategoryCount],
  second : Array[CategoryCount],
) -> Array[CategoryCount] {
  let result : Array[CategoryCount] = []
  for row in category_delta(first, second) {
    if row.count > 0 {
      result.push(row)
    }
  }
  result
}

///|
/// Return categories whose counts disappeared from the second sample.
pub fn removed_categories(
  first : Array[CategoryCount],
  second : Array[CategoryCount],
) -> Array[String] {
  let result : Array[String] = []
  for row in first {
    let mut exists = false
    for current in second {
      if current.category == row.category {
        exists = true
      }
    }
    if !exists {
      result.push(row.category)
    }
  }
  result
}

///|
/// Weighted severity score for defect categories.
pub fn weighted_defect_score(
  categories : Array[String],
  weights : Array[(String, Double)],
) -> Double {
  let mut total = 0.0
  for category in categories {
    for pair in weights {
      if pair.0 == category {
        total += pair.1
      }
    }
  }
  total
}

///|
/// Convert defect categories to a binary presence vector.
pub fn category_presence(
  categories : Array[String],
  vocabulary : Array[String],
) -> Array[Int] {
  let result : Array[Int] = []
  for word in vocabulary {
    let mut present = 0
    for category in categories {
      if category == word {
        present = 1
      }
    }
    result.push(present)
  }
  result
}

///|
/// Stable category vocabulary with first-seen order.
pub fn category_vocabulary(categories : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for category in categories {
    let mut found = false
    for current in result {
      if current == category {
        found = true
      }
    }
    if !found {
      result.push(category)
    }
  }
  result
}
