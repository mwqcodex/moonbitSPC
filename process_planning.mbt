///|
pub struct StationCapacity {
  station : String
  available_hours : Double
  planned_hours : Double
  operators : Int
  utilization : Double
  overloaded : Bool
} derive(Debug, ToJson)

///|
pub struct ProductionStage {
  name : String
  duration_hours : Double
  required_station : String
  sequence : Int
  completed : Bool
} derive(Debug, ToJson)

///|
pub fn station_capacity(
  station~ : String,
  available_hours~ : Double,
  planned_hours~ : Double,
  operators~ : Int,
) -> StationCapacity {
  let utilization = if available_hours <= 0.0 {
    0.0
  } else {
    planned_hours / available_hours
  }
  {
    station,
    available_hours,
    planned_hours,
    operators,
    utilization,
    overloaded: utilization > 1.0,
  }
}

///|
pub fn stage(
  name~ : String,
  duration_hours~ : Double,
  required_station~ : String,
  sequence~ : Int,
) -> ProductionStage {
  { name, duration_hours, required_station, sequence, completed: false }
}

///|
pub fn complete_stage(value : ProductionStage) -> ProductionStage {
  { ..value, completed: true }
}

///|
pub fn capacity_remaining(capacity : StationCapacity) -> Double {
  capacity.available_hours - capacity.planned_hours
}

///|
pub fn capacity_headroom(capacity : StationCapacity) -> Double {
  if capacity.available_hours <= 0.0 {
    0.0
  } else {
    capacity_remaining(capacity) / capacity.available_hours
  }
}

///|
pub fn capacity_status(capacity : StationCapacity) -> String {
  if capacity.overloaded {
    "overloaded"
  } else if capacity.utilization >= 0.85 {
    "near_limit"
  } else {
    "available"
  }
}

///|
pub fn add_planned_hours(
  capacity : StationCapacity,
  hours : Double,
) -> StationCapacity {
  station_capacity(
    station=capacity.station,
    available_hours=capacity.available_hours,
    planned_hours=capacity.planned_hours + hours,
    operators=capacity.operators,
  )
}

///|
pub fn stage_duration(stages : Array[ProductionStage]) -> Double {
  let mut total = 0.0
  for value in stages {
    total += value.duration_hours
  }
  total
}

///|
pub fn completed_stage_count(stages : Array[ProductionStage]) -> Int {
  let mut count = 0
  for value in stages {
    if value.completed {
      count += 1
    }
  }
  count
}

///|
pub fn stage_completion_rate(stages : Array[ProductionStage]) -> Double {
  if stages.length() == 0 {
    0.0
  } else {
    completed_stage_count(stages).to_double() / stages.length().to_double()
  }
}

///|
pub fn stages_for_station(
  stages : Array[ProductionStage],
  station : String,
) -> Array[ProductionStage] {
  let result : Array[ProductionStage] = []
  for value in stages {
    if value.required_station == station {
      result.push(value)
    }
  }
  result
}

///|
pub fn sort_stages(stages : Array[ProductionStage]) -> Array[ProductionStage] {
  let result = stages.copy()
  result.sort_by(fn(a, b) { a.sequence - b.sequence })
  result
}

///|
pub fn invalid_stage_sequence(stages : Array[ProductionStage]) -> Int {
  let sorted = sort_stages(stages)
  for i in 1..<sorted.length() {
    if sorted[i].sequence <= sorted[i - 1].sequence {
      return i
    }
  }
  -1
}

///|
pub fn balance_capacity(capacities : Array[StationCapacity]) -> Double {
  if capacities.length() == 0 {
    0.0
  } else {
    let mut high = capacities[0].utilization
    let mut low = high
    for value in capacities {
      high = high.max(value.utilization)
      low = low.min(value.utilization)
    }
    high - low
  }
}

///|
pub fn total_available_hours(capacities : Array[StationCapacity]) -> Double {
  let mut total = 0.0
  for value in capacities {
    total += value.available_hours
  }
  total
}

///|
pub fn total_planned_hours(capacities : Array[StationCapacity]) -> Double {
  let mut total = 0.0
  for value in capacities {
    total += value.planned_hours
  }
  total
}

///|
pub fn plan_utilization(capacities : Array[StationCapacity]) -> Double {
  let available = total_available_hours(capacities)
  if available <= 0.0 {
    0.0
  } else {
    total_planned_hours(capacities) / available
  }
}
