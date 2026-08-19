///|
pub struct QualityWorkOrder {
  order_id : String
  lot_id : String
  title : String
  owner : String
  priority : Int
  due_day : Int
  status : String
  estimated_hours : Double
  actual_hours : Double
  evidence_count : Int
} derive(Debug, ToJson)

///|
pub fn quality_work_order(
  order_id~ : String,
  lot_id~ : String,
  title~ : String,
  owner~ : String,
  priority~ : Int,
  due_day~ : Int,
  estimated_hours~ : Double,
) -> QualityWorkOrder {
  {
    order_id,
    lot_id,
    title,
    owner,
    priority: priority.max(1).min(5),
    due_day,
    status: "open",
    estimated_hours,
    actual_hours: 0.0,
    evidence_count: 0,
  }
}

///|
pub fn start_work_order(order : QualityWorkOrder) -> QualityWorkOrder {
  { ..order, status: "in_progress" }
}

///|
pub fn complete_work_order(
  order : QualityWorkOrder,
  actual_hours : Double,
  evidence_count : Int,
) -> QualityWorkOrder {
  { ..order, status: "completed", actual_hours, evidence_count }
}

///|
pub fn block_work_order(order : QualityWorkOrder) -> QualityWorkOrder {
  { ..order, status: "blocked" }
}

///|
pub fn work_order_is_overdue(
  order : QualityWorkOrder,
  current_day : Int,
) -> Bool {
  order.status != "completed" && current_day > order.due_day
}

///|
pub fn work_order_efficiency(order : QualityWorkOrder) -> Double {
  if order.actual_hours <= 0.0 {
    0.0
  } else {
    order.estimated_hours / order.actual_hours
  }
}

///|
pub fn work_order_score(order : QualityWorkOrder, current_day : Int) -> Double {
  let urgency = if order.due_day - current_day <= 0 {
    2.0
  } else {
    1.0 / (order.due_day - current_day).to_double()
  }
  order.priority.to_double() * urgency
}

///|
pub fn sort_work_orders(
  orders : Array[QualityWorkOrder],
  current_day : Int,
) -> Array[QualityWorkOrder] {
  let result = orders.copy()
  result.sort_by(fn(a, b) {
    if work_order_score(a, current_day) > work_order_score(b, current_day) {
      -1
    } else {
      1
    }
  })
  result
}

///|
pub fn open_work_order_count(orders : Array[QualityWorkOrder]) -> Int {
  let mut count = 0
  for order in orders {
    if order.status != "completed" {
      count += 1
    }
  }
  count
}

///|
pub fn overdue_work_order_count(
  orders : Array[QualityWorkOrder],
  current_day : Int,
) -> Int {
  let mut count = 0
  for order in orders {
    if work_order_is_overdue(order, current_day) {
      count += 1
    }
  }
  count
}

///|
pub fn completion_rate(orders : Array[QualityWorkOrder]) -> Double {
  if orders.length() == 0 {
    0.0
  } else {
    (orders.length() - open_work_order_count(orders)).to_double() /
    orders.length().to_double()
  }
}

///|
pub fn work_orders_for_lot(
  orders : Array[QualityWorkOrder],
  lot_id : String,
) -> Array[QualityWorkOrder] {
  let result : Array[QualityWorkOrder] = []
  for order in orders {
    if order.lot_id == lot_id {
      result.push(order)
    }
  }
  result
}

///|
pub fn evidence_coverage(orders : Array[QualityWorkOrder]) -> Double {
  if orders.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for order in orders {
      if order.evidence_count > 0 {
        count += 1
      }
    }
    count.to_double() / orders.length().to_double()
  }
}
