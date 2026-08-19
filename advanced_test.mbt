///|
test "quantiles handle empty, singleton, and interpolation boundaries" {
  debug_inspect(quantile([], 0.5), content="None")
  debug_inspect(quantile([7.0], 0.0), content="Some(7)")
  debug_inspect(quantile([1.0, 2.0, 3.0, 4.0], 0.5), content="Some(2.5)")
  debug_inspect(quantile([1.0, 2.0, 3.0, 4.0], 1.0), content="Some(4)")
}

///|
test "robust statistics reject invalid parameters" {
  debug_inspect(median([]), content="None")
  debug_inspect(quantile([1.0, 2.0], -0.1), content="None")
  debug_inspect(quantile([1.0, 2.0], 1.1), content="None")
  debug_inspect(mad([1.0, 1.0, 1.0]), content="Some(0)")
}

///|
test "ewma and cusum preserve deterministic sequence length" {
  debug_inspect(ewma([], lambda=0.2, initial=0.0), content="[]")
  debug_inspect(
    ewma([1.0, 2.0, 3.0], lambda=0.5, initial=0.0),
    content="[0.5, 1.25, 2.125]",
  )
  inspect(
    cusum([0.0, 1.0, 2.0], target=0.0, allowance=0.0, decision=1.0).length(),
    content="3",
  )
}

///|
test "validation catches manufacturing input faults" {
  let bad = Subgroup::new(
    values=[],
    batch="",
    equipment="e",
    tool="t",
    operator="o",
    window="w",
  )
  let result = validate_subgroups([bad])
  inspect(result.length(), content="2")
  inspect(validate_counts([1, -1], [10, 10]).length(), content="1")
  inspect(validate_counts([0], [0]).length(), content="1")
}

///|
test "moving windows reject zero and oversized windows" {
  debug_inspect(moving_mean([1.0, 2.0], 0), content="None")
  debug_inspect(moving_mean([1.0, 2.0], 3), content="None")
  debug_inspect(moving_mean([1.0, 2.0, 3.0], 2), content="Some([1.5, 2.5])")
}
