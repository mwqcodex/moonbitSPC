///|
test "pipeline scorecard exposes actionable quality state" {
  let spec = Specification::new(lower=9.0, upper=11.0)
  let windows = [
    QualityWindow::new(
      id="B-01",
      values=[10.0, 10.1, 9.9],
      specification=Some(spec),
    ),
    QualityWindow::new(
      id="B-02",
      values=[12.0, 12.1, 11.9],
      specification=Some(spec),
    ),
  ]
  let card = scorecard(windows)
  inspect(card.observations, content="6")
  inspect(card.windows, content="2")
  assert_true(card.alerts > 0)
  assert_true(card.critical > 0)
}

///|
test "pipeline handles empty windows and stable filtering" {
  let empty = QualityWindow::new(id="empty", values=[], specification=None)
  let alerts = evaluate_window(empty)
  inspect(alerts.length(), content="1")
  debug_inspect(first_actionable_window([empty]), content="Some(0)")
  inspect(filter_shifted_windows([empty], 0.0, 1.0).length(), content="0")
}
