///|
test "western electric rules find sustained shift" {
  let points = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
  let violations = detect_western_electric(points, mean=0.0, sigma=1.0)
  inspect(violations.length() > 0, content="true")
  inspect(violations[0].rule, content="4")
}
