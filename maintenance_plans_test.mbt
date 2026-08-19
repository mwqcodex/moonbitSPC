///|
test "maintenance planning tracks service risk" {
  let plan = maintenance_plan(
    asset_id="M1",
    interval_days=10,
    last_service_day=1,
    runtime_hours=95.0,
    runtime_limit=100.0,
    open_actions=0,
  )
  inspect(maintenance_due(plan, 11), content="true")
  inspect(maintenance_risk(plan), content="watch")
  inspect(maintenance_runtime_utilization(plan), content="0.95")
}
