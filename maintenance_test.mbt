///|
test "maintenance summaries identify high-risk assets" {
  let records = [
    MaintenanceRecord::new(
      asset="mill-1",
      event="repair",
      timestamp="1",
      runtime_hours=10.0,
      severity=4,
      note="bearing",
    ),
    MaintenanceRecord::new(
      asset="mill-1",
      event="inspection",
      timestamp="2",
      runtime_hours=20.0,
      severity=1,
      note="ok",
    ),
  ]
  let summary = reliability_summary(records, "mill-1", severe_threshold=3)
  inspect(summary.events, content="2")
  inspect(summary.severe_events, content="1")
  assert_true(summary.risk_score > 0.0)
}

///|
test "tool life helpers calculate remaining margin" {
  let point = ToolLifePoint::new(
    tool="T1",
    runtime_hours=10.0,
    wear=4.0,
    threshold=8.0,
  )
  inspect(remaining_wear(point), content="4")
  inspect(wear_warning(point, 0.5), content="true")
  inspect(exceeded_tool_count([point]), content="0")
}
