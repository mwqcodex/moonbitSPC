///|
test "descriptive analytics cover valid and invalid domains" {
  inspect(sum_of([1.0, 2.0, 3.0]), content="6")
  inspect(product_of([2.0, 3.0]), content="6")
  debug_inspect(weighted_mean([1.0, 3.0], [1.0, 3.0]), content="Some(2.5)")
  debug_inspect(weighted_mean([1.0], [0.0]), content="None")
  assert_true(geometric_mean([1.0, 4.0]) is Some(_))
  debug_inspect(harmonic_mean([1.0, 2.0]), content="Some(1.3333333333333333)")
  debug_inspect(
    correlation([1.0, 2.0, 3.0], [2.0, 4.0, 6.0]),
    content="Some(1)",
  )
  debug_inspect(correlation([1.0, 1.0], [2.0, 3.0]), content="None")
}

///|
test "rolling and distribution summaries preserve order" {
  debug_inspect(rolling_min([3.0, 1.0, 2.0], 2), content="Some([1, 1])")
  debug_inspect(rolling_max([3.0, 1.0, 2.0], 2), content="Some([3, 2])")
  debug_inspect(rolling_range([3.0, 1.0, 2.0], 2), content="Some([2, 1])")
  debug_inspect(trimmed([1.0, 2.0, 3.0, 100.0], 0.25), content="Some([2, 3])")
  debug_inspect(
    clipped([-1.0, 0.5, 3.0], 0.0, 1.0),
    content="Some([0, 0.5, 1])",
  )
  assert_true(histogram([0.0, 1.0, 2.0, 3.0], 2) is Some(_))
}

///|
test "run and outlier diagnostics handle ties" {
  inspect(sign_changes([1.0, 2.0, 0.0, -1.0, 1.0], 0.0), content="2")
  inspect(longest_run([1.0, 2.0, 3.0, -1.0], 0.0), content="3")
  inspect(direction_changes([1.0, 2.0, 1.0, 3.0]), content="2")
  assert_true(iqr_outliers([1.0, 1.0, 1.0, 10.0], 1.5) is Some(_))
  debug_inspect(
    percentile_rank([1.0, 2.0, 3.0, 4.0], 2.0),
    content="Some(0.375)",
  )
}
