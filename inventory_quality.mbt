///|
pub struct MaterialLot {
  material_id : String
  lot_id : String
  quantity : Double
  reserved : Double
  lower_limit : Double
  upper_limit : Double
  status : String
} derive(Debug, ToJson)

///|
pub fn material_lot(
  material_id~ : String,
  lot_id~ : String,
  quantity~ : Double,
  lower_limit~ : Double,
  upper_limit~ : Double,
) -> MaterialLot {
  {
    material_id,
    lot_id,
    quantity,
    reserved: 0.0,
    lower_limit,
    upper_limit,
    status: "available",
  }
}

///|
pub fn available_quantity(lot : MaterialLot) -> Double {
  (lot.quantity - lot.reserved).max(0.0)
}

///|
pub fn reserve_material(lot : MaterialLot, amount : Double) -> MaterialLot {
  let reserved = (lot.reserved + amount.max(0.0)).min(lot.quantity)
  {
    ..lot,
    reserved,
    status: if reserved >= lot.quantity {
      "reserved"
    } else {
      "available"
    },
  }
}

///|
pub fn consume_material(lot : MaterialLot, amount : Double) -> MaterialLot {
  let quantity = (lot.quantity - amount.max(0.0)).max(0.0)
  let reserved = lot.reserved.min(quantity)
  {
    ..lot,
    quantity,
    reserved,
    status: if quantity <= 0.0 {
      "depleted"
    } else {
      "available"
    },
  }
}

///|
pub fn material_is_in_range(lot : MaterialLot, value : Double) -> Bool {
  value >= lot.lower_limit && value <= lot.upper_limit
}

///|
pub fn stock_total(lots : Array[MaterialLot]) -> Double {
  let mut total = 0.0
  for lot in lots {
    total += lot.quantity
  }
  total
}

///|
pub fn stock_available(lots : Array[MaterialLot]) -> Double {
  let mut total = 0.0
  for lot in lots {
    total += available_quantity(lot)
  }
  total
}

///|
pub fn stock_reserved(lots : Array[MaterialLot]) -> Double {
  let mut total = 0.0
  for lot in lots {
    total += lot.reserved
  }
  total
}

///|
pub fn lots_for_material(
  lots : Array[MaterialLot],
  material_id : String,
) -> Array[MaterialLot] {
  let result : Array[MaterialLot] = []
  for lot in lots {
    if lot.material_id == material_id {
      result.push(lot)
    }
  }
  result
}

///|
pub fn depleted_lot_count(lots : Array[MaterialLot]) -> Int {
  let mut count = 0
  for lot in lots {
    if lot.status == "depleted" {
      count += 1
    }
  }
  count
}

///|
pub fn inventory_utilization(lots : Array[MaterialLot]) -> Double {
  let total = stock_total(lots)
  if total <= 0.0 {
    0.0
  } else {
    stock_reserved(lots) / total
  }
}

///|
pub fn reorder_needed(
  lots : Array[MaterialLot],
  reorder_point : Double,
) -> Bool {
  stock_available(lots) < reorder_point
}

///|
pub fn lot_age_bucket(days : Int) -> String {
  if days < 0 {
    "invalid"
  } else if days <= 7 {
    "fresh"
  } else if days <= 30 {
    "standard"
  } else {
    "aged"
  }
}

///|
pub fn fifo_lots(lots : Array[MaterialLot]) -> Array[MaterialLot] {
  let result = lots.copy()
  result.sort_by(fn(a, b) { if a.lot_id < b.lot_id { -1 } else { 1 } })
  result
}
