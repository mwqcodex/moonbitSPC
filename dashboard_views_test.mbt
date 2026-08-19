///|
test "dashboard snapshot aggregates operational cards" {
  let snapshot = dashboard_snapshot(name="line", generated_at="now")
  snapshot.add_card(
    dashboard_card(
      key="cpk",
      title="Capability",
      value=1.5,
      target=1.33,
      unit="index",
      trend=1,
      status="good",
    ),
  )
  snapshot.add_card(
    dashboard_card(
      key="ppm",
      title="Defects",
      value=80.0,
      target=50.0,
      unit="ppm",
      trend=-1,
      status="warning",
    ),
  )
  snapshot.set_alerts(0)
  inspect(snapshot_card_count(snapshot), content="2")
  inspect(snapshot_health(snapshot), content="warning")
  inspect(snapshot_trending_up(snapshot), content="1")
}
