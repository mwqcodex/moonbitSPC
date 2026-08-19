///|
test "trend alerts classify drift" {
  let alert = detect_trend(
    metric="diameter",
    values=[1.0, 2.0, 3.0, 4.0],
    tolerance=0.1,
  ).unwrap()
  inspect(alert.direction, content="1")
  inspect(trend_severity(alert), content="high")
  inspect(trend_turning_points([1.0, 3.0, 2.0]), content="1")
}
