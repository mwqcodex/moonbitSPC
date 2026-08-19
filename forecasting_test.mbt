///|
test "forecast strategies produce deterministic horizons" {
  match forecast_with([1.0, 2.0, 3.0], LastValue, 2) {
    Some(result) => debug_inspect(result.values, content="[3, 3]")
    None => fail("last value forecast should succeed")
  }
  match forecast_with([1.0, 2.0, 3.0], TrendLine, 2) {
    Some(result) => debug_inspect(result.values, content="[4, 5]")
    None => fail("trend forecast should succeed")
  }
}

///|
test "forecast error metrics reject mismatched lengths" {
  debug_inspect(mean_absolute_error([1.0], []), content="None")
  debug_inspect(
    root_mean_squared_error([1.0, 2.0], [1.0, 2.5]),
    content="Some(0.3535533905932738)",
  )
  inspect(
    backtest_forecast([1.0, 2.0, 3.0], MeanValue, 2).length(),
    content="1",
  )
}
