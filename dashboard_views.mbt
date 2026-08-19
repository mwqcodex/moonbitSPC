///|
pub struct DashboardCard {
  key : String
  title : String
  value : Double
  target : Double
  unit : String
  trend : Int
  status : String
} derive(Debug, ToJson)

///|
pub struct DashboardSnapshot {
  name : String
  generated_at : String
  cards : Array[DashboardCard]
  mut alerts : Int
  mut score : Double
} derive(Debug, ToJson)

///|
pub fn dashboard_card(
  key~ : String,
  title~ : String,
  value~ : Double,
  target~ : Double,
  unit~ : String,
  trend~ : Int,
  status~ : String,
) -> DashboardCard {
  { key, title, value, target, unit, trend, status }
}

///|
pub fn dashboard_snapshot(
  name~ : String,
  generated_at~ : String,
) -> DashboardSnapshot {
  { name, generated_at, cards: [], alerts: 0, score: 0.0 }
}

///|
pub fn DashboardSnapshot::add_card(
  self : DashboardSnapshot,
  card : DashboardCard,
) -> Unit {
  self.cards.push(card)
}

///|
pub fn DashboardSnapshot::set_alerts(
  self : DashboardSnapshot,
  alerts : Int,
) -> Unit {
  self.alerts = alerts.max(0)
}

///|
pub fn DashboardSnapshot::set_score(
  self : DashboardSnapshot,
  score : Double,
) -> Unit {
  self.score = score.max(0.0).min(100.0)
}

///|
pub fn card_gap(card : DashboardCard) -> Double {
  (card.value - card.target).abs()
}

///|
pub fn card_meets_target(card : DashboardCard) -> Bool {
  card.status == "good" || card_gap(card) <= 0.0
}

///|
pub fn card_status_from_gap(
  gap : Double,
  warning : Double,
  critical : Double,
) -> String {
  if gap >= critical {
    "critical"
  } else if gap >= warning {
    "warning"
  } else {
    "good"
  }
}

///|
pub fn snapshot_card_count(snapshot : DashboardSnapshot) -> Int {
  snapshot.cards.length()
}

///|
pub fn snapshot_failed_cards(snapshot : DashboardSnapshot) -> Int {
  let mut count = 0
  for card in snapshot.cards {
    if !card_meets_target(card) {
      count += 1
    }
  }
  count
}

///|
pub fn snapshot_good_cards(snapshot : DashboardSnapshot) -> Int {
  snapshot.cards.length() - snapshot_failed_cards(snapshot)
}

///|
pub fn snapshot_completion(snapshot : DashboardSnapshot) -> Double {
  if snapshot.cards.length() == 0 {
    0.0
  } else {
    snapshot_good_cards(snapshot).to_double() /
    snapshot.cards.length().to_double()
  }
}

///|
pub fn snapshot_card(
  snapshot : DashboardSnapshot,
  key : String,
) -> DashboardCard? {
  for card in snapshot.cards {
    if card.key == key {
      return Some(card)
    }
  }
  None
}

///|
pub fn snapshot_keys(snapshot : DashboardSnapshot) -> Array[String] {
  let result : Array[String] = []
  for card in snapshot.cards {
    result.push(card.key)
  }
  result
}

///|
pub fn snapshot_units(snapshot : DashboardSnapshot) -> Array[String] {
  let result : Array[String] = []
  for card in snapshot.cards {
    if !result.contains(card.unit) {
      result.push(card.unit)
    }
  }
  result
}

///|
pub fn snapshot_trending_up(snapshot : DashboardSnapshot) -> Int {
  let mut count = 0
  for card in snapshot.cards {
    if card.trend > 0 {
      count += 1
    }
  }
  count
}

///|
pub fn snapshot_trending_down(snapshot : DashboardSnapshot) -> Int {
  let mut count = 0
  for card in snapshot.cards {
    if card.trend < 0 {
      count += 1
    }
  }
  count
}

///|
pub fn snapshot_critical_count(snapshot : DashboardSnapshot) -> Int {
  let mut count = 0
  for card in snapshot.cards {
    if card.status == "critical" {
      count += 1
    }
  }
  count
}

///|
pub fn snapshot_warning_count(snapshot : DashboardSnapshot) -> Int {
  let mut count = 0
  for card in snapshot.cards {
    if card.status == "warning" {
      count += 1
    }
  }
  count
}

///|
pub fn snapshot_health(snapshot : DashboardSnapshot) -> String {
  if snapshot_critical_count(snapshot) > 0 || snapshot.alerts > 0 {
    "critical"
  } else if snapshot_warning_count(snapshot) > 0 {
    "warning"
  } else {
    "healthy"
  }
}

///|
pub fn sort_cards_by_gap(snapshot : DashboardSnapshot) -> Array[DashboardCard] {
  let result = snapshot.cards.copy()
  result.sort_by(fn(a, b) { if card_gap(a) > card_gap(b) { -1 } else { 1 } })
  result
}

///|
pub fn card_trend_name(trend : Int) -> String {
  if trend > 0 {
    "up"
  } else if trend < 0 {
    "down"
  } else {
    "flat"
  }
}

///|
pub fn snapshot_target_rate(snapshot : DashboardSnapshot) -> Double {
  if snapshot.cards.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for card in snapshot.cards {
      if card.target != 0.0 {
        total += card.value / card.target
      }
    }
    total / snapshot.cards.length().to_double()
  }
}

///|
pub fn snapshot_alert_density(snapshot : DashboardSnapshot) -> Double {
  if snapshot.cards.length() == 0 {
    0.0
  } else {
    snapshot.alerts.to_double() / snapshot.cards.length().to_double()
  }
}

///|
pub fn snapshot_card_values(snapshot : DashboardSnapshot) -> Array[Double] {
  let result : Array[Double] = []
  for card in snapshot.cards {
    result.push(card.value)
  }
  result
}

///|
pub fn snapshot_card_targets(snapshot : DashboardSnapshot) -> Array[Double] {
  let result : Array[Double] = []
  for card in snapshot.cards {
    result.push(card.target)
  }
  result
}

///|
pub fn snapshot_average_gap(snapshot : DashboardSnapshot) -> Double {
  if snapshot.cards.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for card in snapshot.cards {
      total += card_gap(card)
    }
    total / snapshot.cards.length().to_double()
  }
}

///|
pub fn snapshot_max_gap(snapshot : DashboardSnapshot) -> Double {
  let mut high = 0.0
  for card in snapshot.cards {
    high = high.max(card_gap(card))
  }
  high
}

///|
pub fn snapshot_has_key(snapshot : DashboardSnapshot, key : String) -> Bool {
  snapshot_card(snapshot, key) is Some(_)
}

///|
pub fn snapshot_is_empty(snapshot : DashboardSnapshot) -> Bool {
  snapshot.cards.length() == 0
}

///|
pub fn snapshot_quality_score(snapshot : DashboardSnapshot) -> Double {
  snapshot_completion(snapshot) * 100.0 - snapshot.alerts.to_double().min(100.0)
}

///|
pub fn snapshot_summary_line(snapshot : DashboardSnapshot) -> String {
  "name=\{snapshot.name}; cards=\{snapshot.cards.length()}; health=\{snapshot_health(snapshot)}; score=\{snapshot_quality_score(snapshot)}"
}

///|
pub fn snapshot_card_statuses(snapshot : DashboardSnapshot) -> Array[String] {
  let result : Array[String] = []
  for card in snapshot.cards {
    result.push(card.status)
  }
  result
}

///|
pub fn snapshot_filter_status(
  snapshot : DashboardSnapshot,
  status : String,
) -> Array[DashboardCard] {
  let result : Array[DashboardCard] = []
  for card in snapshot.cards {
    if card.status == status {
      result.push(card)
    }
  }
  result
}

///|
pub fn snapshot_filter_unit(
  snapshot : DashboardSnapshot,
  unit : String,
) -> Array[DashboardCard] {
  let result : Array[DashboardCard] = []
  for card in snapshot.cards {
    if card.unit == unit {
      result.push(card)
    }
  }
  result
}

///|
pub fn snapshot_merge(
  left : DashboardSnapshot,
  right : DashboardSnapshot,
) -> DashboardSnapshot {
  let result = dashboard_snapshot(
    name=left.name + "+" + right.name,
    generated_at=right.generated_at,
  )
  for card in left.cards {
    result.add_card(card)
  }
  for card in right.cards {
    result.add_card(card)
  }
  result.set_alerts(left.alerts + right.alerts)
  result.set_score((left.score + right.score) / 2.0)
  result
}
