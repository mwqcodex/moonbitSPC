///|
test "time series transforms preserve operational signals" {
  debug_inspect(ts_difference([1.0, 3.0, 6.0], 1), content="[2, 3]")
  inspect(ts_peak_index([2.0, 5.0, 1.0]), content="1")
  inspect(ts_count_crossings([0.0, 2.0, 0.0], 1.0), content="2")
  inspect(ts_range([2.0, 5.0, 1.0]), content="4")
}
