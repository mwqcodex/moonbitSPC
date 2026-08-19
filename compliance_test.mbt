///|
test "traceability audit detects missing evidence" {
  let events = [
    audit_event(
      event_id="1",
      lot_id="L1",
      actor="qa",
      action="release",
      timestamp="01",
      passed=true,
      evidence="a.pdf",
    ),
    audit_event(
      event_id="2",
      lot_id="L1",
      actor="qa",
      action="review",
      timestamp="02",
      passed=true,
      evidence="",
    ),
  ]
  let result = traceability_check(events)
  inspect(result.event_count, content="2")
  inspect(result.missing_evidence, content="1")
  inspect(result.complete, content="false")
}
