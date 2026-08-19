///|
test "lot events group into feature summaries" {
  let identity = LotIdentity::new(
    lot="L1",
    product="P",
    revision="R1",
    line="A",
    shift="1",
    start_window="s",
    end_window="e",
  )
  let events = [
    MeasurementEvent::new(
      identity~,
      station="S1",
      feature="diameter",
      value=Some(10.0),
      sequence=2,
    ),
    MeasurementEvent::new(
      identity~,
      station="S2",
      feature="diameter",
      value=None,
      sequence=1,
    ),
    MeasurementEvent::new(
      identity~,
      station="S1",
      feature="diameter",
      value=Some(10.2),
      sequence=3,
    ),
  ]
  let groups = group_events(events)
  inspect(groups.length(), content="1")
  inspect(groups[0].missing, content="1")
  inspect(groups[0].stations.length(), content="2")
}

///|
test "release decision reports insufficient coverage" {
  let identity = LotIdentity::new(
    lot="L1",
    product="P",
    revision="R1",
    line="A",
    shift="1",
    start_window="s",
    end_window="e",
  )
  let event = MeasurementEvent::new(
    identity~,
    station="S1",
    feature="x",
    value=None,
    sequence=0,
  ).reject()
  let decision = release_decision(
    [event],
    minimum_features=2,
    minimum_measurements=1,
  )
  inspect(decision.released, content="false")
  inspect(decision.reason_codes.length(), content="3")
}
