///|
test "attribute charts expose defect and opportunity rates" {
  match attribute_rate([2, 4], [10, 10]) {
    Some(rates) => debug_inspect(rates, content="[0.2, 0.4]")
    None => fail("valid counts should produce rates")
  }
  debug_inspect(attribute_rate([1, -1], [10, 10]), content="None")
}

///|
test "defect categories aggregate in stable order" {
  let result = category_counts(["scratch", "dent", "scratch", "scratch", "dent"])
  inspect(result.length(), content="2")
  inspect(result[0].category, content="scratch")
  inspect(result[0].count, content="3")
}

///|
test "pareto ranking returns cumulative proportions" {
  let result = pareto_categories(["a", "b", "a", "c", "a"])
  inspect(result[0].category, content="a")
  inspect(result[0].count, content="3")
  inspect(result[0].cumulative, content="0.6")
}
