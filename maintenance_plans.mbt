///|
pub struct MaintenancePlan {
  asset_id : String
  interval_days : Int
  last_service_day : Int
  next_service_day : Int
  runtime_hours : Double
  runtime_limit : Double
  open_actions : Int
  status : String
} derive(Debug, ToJson)

///|
pub fn maintenance_plan(
  asset_id~ : String,
  interval_days~ : Int,
  last_service_day~ : Int,
  runtime_hours~ : Double,
  runtime_limit~ : Double,
  open_actions~ : Int,
) -> MaintenancePlan {
  {
    asset_id,
    interval_days: interval_days.max(1),
    last_service_day,
    next_service_day: last_service_day + interval_days.max(1),
    runtime_hours,
    runtime_limit,
    open_actions: open_actions.max(0),
    status: "scheduled",
  }
}

///|
pub fn maintenance_due(plan : MaintenancePlan, current_day : Int) -> Bool {
  current_day >= plan.next_service_day ||
  plan.runtime_hours >= plan.runtime_limit
}

///|
pub fn maintenance_overdue_days(
  plan : MaintenancePlan,
  current_day : Int,
) -> Int {
  (current_day - plan.next_service_day).max(0)
}

///|
pub fn maintenance_runtime_margin(plan : MaintenancePlan) -> Double {
  plan.runtime_limit - plan.runtime_hours
}

///|
pub fn maintenance_risk(plan : MaintenancePlan) -> String {
  if plan.open_actions > 0 || maintenance_runtime_margin(plan) <= 0.0 {
    "critical"
  } else if maintenance_runtime_margin(plan) < plan.runtime_limit * 0.2 {
    "watch"
  } else {
    "normal"
  }
}

///|
pub fn record_service(
  plan : MaintenancePlan,
  service_day : Int,
  runtime_hours : Double,
) -> MaintenancePlan {
  {
    ..plan,
    last_service_day: service_day,
    next_service_day: service_day + plan.interval_days,
    runtime_hours,
    open_actions: 0,
    status: "scheduled",
  }
}

///|
pub fn add_maintenance_action(plan : MaintenancePlan) -> MaintenancePlan {
  { ..plan, open_actions: plan.open_actions + 1, status: "action_required" }
}

///|
pub fn maintenance_action_count(plans : Array[MaintenancePlan]) -> Int {
  let mut count = 0
  for plan in plans {
    count += plan.open_actions
  }
  count
}

///|
pub fn due_maintenance_count(
  plans : Array[MaintenancePlan],
  current_day : Int,
) -> Int {
  let mut count = 0
  for plan in plans {
    if maintenance_due(plan, current_day) {
      count += 1
    }
  }
  count
}

///|
pub fn critical_maintenance_count(plans : Array[MaintenancePlan]) -> Int {
  let mut count = 0
  for plan in plans {
    if maintenance_risk(plan) == "critical" {
      count += 1
    }
  }
  count
}

///|
pub fn plans_for_asset(
  plans : Array[MaintenancePlan],
  asset_id : String,
) -> Array[MaintenancePlan] {
  let result : Array[MaintenancePlan] = []
  for plan in plans {
    if plan.asset_id == asset_id {
      result.push(plan)
    }
  }
  result
}

///|
pub fn maintenance_compliance(
  plans : Array[MaintenancePlan],
  current_day : Int,
) -> Double {
  if plans.length() == 0 {
    1.0
  } else {
    (plans.length() - due_maintenance_count(plans, current_day)).to_double() /
    plans.length().to_double()
  }
}

///|
pub fn maintenance_runtime_utilization(plan : MaintenancePlan) -> Double {
  if plan.runtime_limit <= 0.0 {
    0.0
  } else {
    plan.runtime_hours / plan.runtime_limit
  }
}

///|
pub fn maintenance_priority(
  plan : MaintenancePlan,
  current_day : Int,
) -> Double {
  let overdue = maintenance_overdue_days(plan, current_day).to_double()
  overdue +
  plan.open_actions.to_double() * 2.0 +
  maintenance_runtime_utilization(plan)
}

///|
pub fn sort_maintenance_plans(
  plans : Array[MaintenancePlan],
  current_day : Int,
) -> Array[MaintenancePlan] {
  let result = plans.copy()
  result.sort_by(fn(a, b) {
    if maintenance_priority(a, current_day) >
      maintenance_priority(b, current_day) {
      -1
    } else {
      1
    }
  })
  result
}

///|
pub fn maintenance_status_counts(plans : Array[MaintenancePlan]) -> Array[Int] {
  let scheduled = 0
  let action = 0
  let critical = 0
  let mut s = scheduled
  let mut a = action
  let mut c = critical
  for plan in plans {
    if plan.status == "scheduled" {
      s += 1
    }
    if plan.status == "action_required" {
      a += 1
    }
    if maintenance_risk(plan) == "critical" {
      c += 1
    }
  }
  [s, a, c]
}

///|
pub fn planned_service_days(plans : Array[MaintenancePlan]) -> Array[Int] {
  let result : Array[Int] = []
  for plan in plans {
    result.push(plan.next_service_day)
  }
  result
}
