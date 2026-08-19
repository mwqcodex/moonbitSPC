///|
test "online accumulator matches batch summary" {
  let accumulator = StreamAccumulator::new(lower=Some(0.0), upper=Some(2.0))
  accumulator.push(Some(1.0))
  accumulator.push(Some(2.0))
  accumulator.push(None)
  inspect(accumulator.count, content="2")
  debug_inspect(accumulator.mean(), content="Some(1.5)")
  inspect(accumulator.missing, content="1")
}

///|
test "ring buffer keeps newest values in order" {
  let ring = MeasurementRing::new(2)
  ring.push(1.0)
  ring.push(2.0)
  ring.push(3.0)
  debug_inspect(ring.ordered(), content="[2, 3]")
  debug_inspect(ring.last(), content="Some(3)")
}

///|
test "stream monitor replays missing and numeric values" {
  let policy = StreamPolicy::standard(lower=Some(0.0), upper=Some(10.0))
  inspect(
    replay_stream([Some(1.0), None, Some(1.5)], policy~, center=1.0),
    content="0",
  )
  debug_inspect(
    online_snapshot([1.0, 2.0], lower=Some(0.0), upper=Some(3.0)).mean,
    content="Some(1.5)",
  )
}
