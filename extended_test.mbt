///|
test "linear trend estimates slope and intercept" {
  match linear_trend([1.0, 3.0, 5.0, 7.0]) {
    Some(trend) => {
      inspect(trend.slope, content="2")
      inspect(trend.intercept, content="1")
      inspect(trend.r_squared, content="1")
    }
    None => fail("expected a trend")
  }
}

///|
test "trend rejects constant and undersized input" {
  match linear_trend([]) {
    None => ()
    Some(_) => fail("empty trend must be rejected")
  }
  match linear_trend([1.0]) {
    None => ()
    Some(_) => fail("single point trend must be rejected")
  }
  match linear_trend([1.0, 1.0, 1.0]) {
    Some(trend) => {
      inspect(trend.slope, content="0")
      inspect(trend.intercept, content="1")
      inspect(trend.r_squared, content="1")
    }
    None => fail("constant trend should be representable")
  }
}

///|
test "cusum chart returns limits and alarms" {
  match
    ControlChart::cusum(
      [0.0, 0.0, 10.0],
      target=0.0,
      allowance=0.0,
      decision=2.0,
    ) {
    ChartOk(chart) => {
      inspect(chart.kind, content="CUSUM")
      inspect(chart.points.length(), content="3")
      inspect(chart.points[2].out_of_control, content="true")
    }
    ChartInvalidInput(message~) => fail(message)
  }
}

///|
test "deterministic sampling is reproducible and bounded" {
  let first = sample_uniform(8, seed=42, lower=9.0, upper=11.0)
  let second = sample_uniform(8, seed=42, lower=9.0, upper=11.0)
  assert_true(first == second)
  for value in first {
    assert_true(value >= 9.0 && value <= 11.0)
  }
  debug_inspect(sample_uniform(2, seed=1, lower=2.0, upper=1.0), content="[]")
}

///|
test "quality baseline flags mean drift" {
  let baseline = baseline_from([10.0, 10.1, 9.9, 10.0])
  let result = drift_score([10.0, 10.2, 10.4], baseline, threshold=2.0)
  inspect(result.length(), content="3")
  assert_true(result[2].alarm)
}
