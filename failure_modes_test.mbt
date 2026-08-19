///|
test "fmea ranks and closes risks" {
  let mode = failure_mode(
    id="F1",
    process="cut",
    cause="wear",
    effect="oversize",
    severity=8,
    occurrence=6,
    detection=5,
    owner="qa",
    mitigation="replace",
  )
  inspect(mode.rpn(), content="240")
  inspect(mode.risk_level(), content="critical")
  inspect(close_failure_mode(mode).closed, content="true")
}
