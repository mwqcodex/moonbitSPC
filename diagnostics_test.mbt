///|
test "diagnostics identify a mean shift and trend" {
  let result = diagnose_process([1.0, 1.1, 1.0, 3.0, 3.1], 1.0, 0.5, 2.0)
  inspect(result.change_index, content="3")
  inspect(trend_direction([1.0, 2.0, 3.0]), content="1")
  inspect(diagnostic_label(result), content="investigate")
}
