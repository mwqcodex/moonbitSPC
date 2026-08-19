///|
test "distribution summary supports robust screening" {
  let summary = distribution_summary([1.0, 2.0, 3.0, 4.0, 5.0])
  inspect(summary.median, content="3")
  inspect(interquartile_range([1.0, 2.0, 3.0, 4.0, 5.0]), content="2")
  inspect(normality_label(summary), content="approximately_normal")
}
