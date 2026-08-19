///|
test "cleaning filters measurements by engineering limits" {
  let result = clean_values([1.0, 2.0, 99.0, 3.0], lower=0.0, upper=10.0)
  inspect(result.values.length(), content="3")
  inspect(result.removed, content="1")
  inspect(result.values[2], content="3")
}

///|
test "cleaning rejects inverted limits and preserves empty input" {
  let result = clean_values([], lower=10.0, upper=0.0)
  inspect(result.values.length(), content="0")
  inspect(result.issues.length(), content="1")
  let empty = clean_values([], lower=0.0, upper=1.0)
  inspect(empty.removed, content="0")
}

///|
test "interpolation fills interior gaps but not edge gaps" {
  debug_inspect(
    interpolate_missing([Some(1.0), None, Some(3.0)]),
    content="[Some(1), Some(2), Some(3)]",
  )
  debug_inspect(
    interpolate_missing([None, Some(2.0), None]),
    content="[None, Some(2), None]",
  )
}

///|
test "differences and cumulative sums preserve sequence semantics" {
  debug_inspect(first_difference([1.0, 3.0, 6.0]), content="[2, 3]")
  debug_inspect(cumulative_sum([1.0, -1.0, 2.0]), content="[1, 0, 2]")
  debug_inspect(lag_values([1.0, 2.0, 3.0], 2), content="[1, 1, 1]")
}
