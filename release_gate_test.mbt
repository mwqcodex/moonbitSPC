///|
test "release gate exposes actionable blockers" {
  let gate = release_gate(
    name="lot",
    required_checks=3,
    passed_checks=3,
    open_alerts=0,
    critical_alerts=0,
    evidence_count=10,
    minimum_score=90.0,
  )
  let decision = evaluate_release(gate)
  inspect(decision.released, content="true")
  inspect(release_ready(gate), content="true")
  inspect(release_evidence_required(gate), content="0")
}
