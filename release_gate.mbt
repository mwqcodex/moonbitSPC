///|
pub struct ReleaseGate {
  name : String
  required_checks : Int
  passed_checks : Int
  open_alerts : Int
  critical_alerts : Int
  evidence_count : Int
  minimum_score : Double
} derive(Debug, ToJson)

///|
pub struct GateDecision {
  released : Bool
  score : Double
  blockers : Array[String]
  recommendation : String
} derive(Debug, ToJson)

///|
pub fn release_gate(
  name~ : String,
  required_checks~ : Int,
  passed_checks~ : Int,
  open_alerts~ : Int,
  critical_alerts~ : Int,
  evidence_count~ : Int,
  minimum_score~ : Double,
) -> ReleaseGate {
  {
    name,
    required_checks: required_checks.max(0),
    passed_checks: passed_checks.max(0),
    open_alerts: open_alerts.max(0),
    critical_alerts: critical_alerts.max(0),
    evidence_count: evidence_count.max(0),
    minimum_score: minimum_score.max(0.0).min(100.0),
  }
}

///|
pub fn release_check_rate(gate : ReleaseGate) -> Double {
  if gate.required_checks <= 0 {
    1.0
  } else {
    gate.passed_checks.to_double() / gate.required_checks.to_double()
  }
}

///|
pub fn release_score(gate : ReleaseGate) -> Double {
  let check = release_check_rate(gate) * 60.0
  let evidence = gate.evidence_count.to_double().min(10.0) / 10.0 * 20.0
  let alert = (1.0 - gate.open_alerts.to_double().min(10.0) / 10.0) * 20.0
  check + evidence + alert
}

///|
pub fn release_blockers(gate : ReleaseGate) -> Array[String] {
  let result : Array[String] = []
  if gate.passed_checks < gate.required_checks {
    result.push("checks")
  }
  if gate.critical_alerts > 0 {
    result.push("critical_alerts")
  }
  if gate.evidence_count == 0 {
    result.push("evidence")
  }
  if release_score(gate) < gate.minimum_score {
    result.push("score")
  }
  result
}

///|
pub fn evaluate_release(gate : ReleaseGate) -> GateDecision {
  let blockers = release_blockers(gate)
  let released = blockers.length() == 0
  {
    released,
    score: release_score(gate),
    blockers,
    recommendation: if released {
      "release"
    } else if gate.critical_alerts > 0 {
      "hold_and_investigate"
    } else {
      "complete_open_actions"
    },
  }
}

///|
pub fn release_ready(gate : ReleaseGate) -> Bool {
  evaluate_release(gate).released
}

///|
pub fn release_gap(gate : ReleaseGate) -> Double {
  (gate.minimum_score - release_score(gate)).max(0.0)
}

///|
pub fn release_evidence_required(gate : ReleaseGate) -> Int {
  if gate.evidence_count >= 10 {
    0
  } else {
    10 - gate.evidence_count
  }
}

///|
pub fn release_alert_burden(gate : ReleaseGate) -> Double {
  gate.open_alerts.to_double() + gate.critical_alerts.to_double() * 3.0
}

///|
pub fn merge_release_gates(
  left : ReleaseGate,
  right : ReleaseGate,
) -> ReleaseGate {
  release_gate(
    name=left.name + "+" + right.name,
    required_checks=left.required_checks + right.required_checks,
    passed_checks=left.passed_checks + right.passed_checks,
    open_alerts=left.open_alerts + right.open_alerts,
    critical_alerts=left.critical_alerts + right.critical_alerts,
    evidence_count=left.evidence_count + right.evidence_count,
    minimum_score=left.minimum_score.max(right.minimum_score),
  )
}

///|
pub fn release_audit_lines(gate : ReleaseGate) -> Array[String] {
  let decision = evaluate_release(gate)
  [
    "name=\{gate.name}",
    "score=\{decision.score}",
    "released=\{decision.released}",
    "blocker_count=\{decision.blockers.length()}",
  ]
}
