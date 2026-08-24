///|
/// A deviation record that connects a quality event to containment and CAPA.
pub(all) struct DeviationCase {
  case_id : String
  lot_id : String
  station : String
  category : String
  description : String
  owner : String
  detected_day : Int
  due_day : Int
  severity : Int
  occurrence : Int
  detection : Int
  status : String
  containment : String
  root_cause : String?
  recurrence : Int
} derive(Debug, ToJson)

///|
/// Create an open deviation case.
pub fn deviation_case(
  case_id~ : String,
  lot_id~ : String,
  station~ : String,
  category~ : String,
  description~ : String,
  owner~ : String,
  detected_day~ : Int,
  due_day~ : Int,
  severity~ : Int,
  occurrence~ : Int,
  detection~ : Int,
) -> DeviationCase {
  {
    case_id,
    lot_id,
    station,
    category,
    description,
    owner,
    detected_day,
    due_day,
    severity: severity.max(1).min(10),
    occurrence: occurrence.max(1).min(10),
    detection: detection.max(1).min(10),
    status: "open",
    containment: "pending",
    root_cause: None,
    recurrence: 0,
  }
}

///|
/// Risk priority number for a deviation.
pub fn deviation_rpn(case : DeviationCase) -> Int {
  case.severity * case.occurrence * case.detection
}

///|
/// Whether the deviation requires immediate containment.
pub fn deviation_is_high_risk(case : DeviationCase, threshold : Int) -> Bool {
  deviation_rpn(case) >= threshold || case.severity >= 9
}

///|
/// Record a containment action and move the case into investigation.
pub fn contain_deviation(
  case : DeviationCase,
  containment : String,
) -> DeviationCase {
  { ..case, containment, status: "investigating" }
}

///|
/// Attach a root-cause statement to a deviation.
pub fn assign_root_cause(
  case : DeviationCase,
  root_cause : String,
) -> DeviationCase {
  { ..case, root_cause: Some(root_cause), status: "corrective_action" }
}

///|
/// Mark a deviation as verified and closed.
pub fn close_deviation(case : DeviationCase) -> DeviationCase {
  match case.root_cause {
    Some(_) => { ..case, status: "closed" }
    None => case
  }
}

///|
/// Reopen a previously closed deviation after recurrence.
pub fn reopen_deviation(case : DeviationCase) -> DeviationCase {
  { ..case, status: "reopened", recurrence: case.recurrence + 1 }
}

///|
/// Whether a deviation is complete.
pub fn deviation_is_closed(case : DeviationCase) -> Bool {
  case.status == "closed"
}

///|
/// Whether a deviation is overdue at the given day.
pub fn deviation_is_overdue(case : DeviationCase, today : Int) -> Bool {
  !deviation_is_closed(case) && today > case.due_day
}

///|
/// Age of an open deviation in days.
pub fn deviation_age(case : DeviationCase, today : Int) -> Int {
  (today - case.detected_day).max(0)
}

///|
/// Remaining days before the due date.
pub fn deviation_days_remaining(case : DeviationCase, today : Int) -> Int {
  case.due_day - today
}

///|
/// Filter cases owned by one person.
pub fn deviations_for_owner(
  cases : Array[DeviationCase],
  owner : String,
) -> Array[DeviationCase] {
  let result : Array[DeviationCase] = []
  for case in cases {
    if case.owner == owner {
      result.push(case)
    }
  }
  result
}

///|
/// Filter cases associated with a lot.
pub fn deviations_for_lot(
  cases : Array[DeviationCase],
  lot_id : String,
) -> Array[DeviationCase] {
  let result : Array[DeviationCase] = []
  for case in cases {
    if case.lot_id == lot_id {
      result.push(case)
    }
  }
  result
}

///|
/// Filter cases by station and category.
pub fn deviations_for_station_category(
  cases : Array[DeviationCase],
  station : String,
  category : String,
) -> Array[DeviationCase] {
  let result : Array[DeviationCase] = []
  for case in cases {
    if case.station == station && case.category == category {
      result.push(case)
    }
  }
  result
}

///|
/// Count cases that are currently open.
pub fn open_deviation_count(cases : Array[DeviationCase]) -> Int {
  let mut count = 0
  for case in cases {
    if !deviation_is_closed(case) {
      count += 1
    }
  }
  count
}

///|
/// Count overdue deviations.
pub fn overdue_deviation_count(
  cases : Array[DeviationCase],
  today : Int,
) -> Int {
  let mut count = 0
  for case in cases {
    if deviation_is_overdue(case, today) {
      count += 1
    }
  }
  count
}

///|
/// Count cases above a risk threshold.
pub fn high_risk_deviation_count(
  cases : Array[DeviationCase],
  threshold : Int,
) -> Int {
  let mut count = 0
  for case in cases {
    if deviation_is_high_risk(case, threshold) {
      count += 1
    }
  }
  count
}

///|
/// Average age of open deviation cases.
pub fn average_deviation_age(
  cases : Array[DeviationCase],
  today : Int,
) -> Double {
  let mut total = 0
  let mut count = 0
  for case in cases {
    if !deviation_is_closed(case) {
      total += deviation_age(case, today)
      count += 1
    }
  }
  if count == 0 {
    0.0
  } else {
    total.to_double() / count.to_double()
  }
}

///|
/// Sort deviations by descending risk and due date.
pub fn sort_deviations(cases : Array[DeviationCase]) -> Array[DeviationCase] {
  let result = cases.copy()
  result.sort_by(fn(a, b) {
    if deviation_rpn(a) != deviation_rpn(b) {
      deviation_rpn(b) - deviation_rpn(a)
    } else {
      a.due_day - b.due_day
    }
  })
  result
}

///|
/// Lifecycle counts for dashboard cards.
pub(all) struct DeviationCounts {
  open : Int
  investigating : Int
  corrective_action : Int
  reopened : Int
  closed : Int
  overdue : Int
} derive(Debug, ToJson)

///|
/// Summarize deviation lifecycle state.
pub fn deviation_counts(
  cases : Array[DeviationCase],
  today : Int,
) -> DeviationCounts {
  let mut open = 0
  let mut investigating = 0
  let mut corrective_action = 0
  let mut reopened = 0
  let mut closed = 0
  let mut overdue = 0
  for case in cases {
    match case.status {
      "closed" => closed += 1
      "investigating" => investigating += 1
      "corrective_action" => corrective_action += 1
      "reopened" => reopened += 1
      _ => open += 1
    }
    if deviation_is_overdue(case, today) {
      overdue += 1
    }
  }
  { open, investigating, corrective_action, reopened, closed, overdue }
}

///|
/// A corrective action linked to one deviation.
pub(all) struct CorrectiveAction {
  action_id : String
  case_id : String
  title : String
  owner : String
  start_day : Int
  due_day : Int
  estimated_hours : Double
  completed_hours : Double
  effectiveness_target : Double
  status : String
  verification : String?
} derive(Debug, ToJson)

///|
/// Create a planned corrective action.
pub fn corrective_action(
  action_id~ : String,
  case_id~ : String,
  title~ : String,
  owner~ : String,
  start_day~ : Int,
  due_day~ : Int,
  estimated_hours~ : Double,
  effectiveness_target~ : Double,
) -> CorrectiveAction {
  {
    action_id,
    case_id,
    title,
    owner,
    start_day,
    due_day,
    estimated_hours: estimated_hours.max(0.0),
    completed_hours: 0.0,
    effectiveness_target: effectiveness_target.max(0.0),
    status: "planned",
    verification: None,
  }
}

///|
/// Start a corrective action.
pub fn start_corrective_action(action : CorrectiveAction) -> CorrectiveAction {
  { ..action, status: "in_progress" }
}

///|
/// Register effort spent on an action.
pub fn record_action_effort(
  action : CorrectiveAction,
  hours : Double,
) -> CorrectiveAction {
  {
    ..action,
    completed_hours: (action.completed_hours + hours.max(0.0)).min(
      action.estimated_hours,
    ),
  }
}

///|
/// Add verification evidence and mark an action complete.
pub fn verify_corrective_action(
  action : CorrectiveAction,
  evidence : String,
  effectiveness : Double,
) -> CorrectiveAction {
  if effectiveness >= action.effectiveness_target {
    { ..action, status: "verified", verification: Some(evidence) }
  } else {
    { ..action, status: "verification_failed", verification: Some(evidence) }
  }
}

///|
/// Whether an action is verified.
pub fn action_is_verified(action : CorrectiveAction) -> Bool {
  action.status == "verified"
}

///|
/// Whether an action is overdue.
pub fn action_is_overdue(action : CorrectiveAction, today : Int) -> Bool {
  !action_is_verified(action) && today > action.due_day
}

///|
/// Progress against the planned effort.
pub fn action_progress(action : CorrectiveAction) -> Double {
  if action.estimated_hours <= 0.0 {
    if action_is_verified(action) {
      1.0
    } else {
      0.0
    }
  } else {
    (action.completed_hours / action.estimated_hours).max(0.0).min(1.0)
  }
}

///|
/// Days available for an action.
pub fn action_duration(action : CorrectiveAction) -> Int {
  (action.due_day - action.start_day).max(0)
}

///|
/// Actions attached to a deviation.
pub fn actions_for_case(
  actions : Array[CorrectiveAction],
  case_id : String,
) -> Array[CorrectiveAction] {
  let result : Array[CorrectiveAction] = []
  for action in actions {
    if action.case_id == case_id {
      result.push(action)
    }
  }
  result
}

///|
/// Actions owned by one person.
pub fn actions_for_owner(
  actions : Array[CorrectiveAction],
  owner : String,
) -> Array[CorrectiveAction] {
  let result : Array[CorrectiveAction] = []
  for action in actions {
    if action.owner == owner {
      result.push(action)
    }
  }
  result
}

///|
/// Count verified actions.
pub fn verified_action_count(actions : Array[CorrectiveAction]) -> Int {
  let mut count = 0
  for action in actions {
    if action_is_verified(action) {
      count += 1
    }
  }
  count
}

///|
/// Count overdue actions.
pub fn overdue_action_count(
  actions : Array[CorrectiveAction],
  today : Int,
) -> Int {
  let mut count = 0
  for action in actions {
    if action_is_overdue(action, today) {
      count += 1
    }
  }
  count
}

///|
/// Average corrective-action progress.
pub fn average_action_progress(actions : Array[CorrectiveAction]) -> Double {
  if actions.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for action in actions {
      total += action_progress(action)
    }
    total / actions.length().to_double()
  }
}

///|
/// Corrective-action completion rate.
pub fn action_completion_rate(actions : Array[CorrectiveAction]) -> Double {
  if actions.length() == 0 {
    0.0
  } else {
    verified_action_count(actions).to_double() / actions.length().to_double()
  }
}

///|
/// Status counts for corrective actions.
pub(all) struct ActionCounts {
  planned : Int
  in_progress : Int
  verified : Int
  verification_failed : Int
} derive(Debug, ToJson)

///|
/// Summarize corrective-action states.
pub fn action_counts(actions : Array[CorrectiveAction]) -> ActionCounts {
  let mut planned = 0
  let mut in_progress = 0
  let mut verified = 0
  let mut verification_failed = 0
  for action in actions {
    match action.status {
      "verified" => verified += 1
      "in_progress" => in_progress += 1
      "verification_failed" => verification_failed += 1
      _ => planned += 1
    }
  }
  { planned, in_progress, verified, verification_failed }
}

///|
/// Evidence attached to an audit-ready quality case.
pub(all) struct EvidenceItem {
  evidence_id : String
  case_id : String
  kind : String
  reference : String
  captured_day : Int
  verified : Bool
  note : String
} derive(Debug, ToJson)

///|
/// Construct an evidence item.
pub fn evidence_item(
  evidence_id~ : String,
  case_id~ : String,
  kind~ : String,
  reference~ : String,
  captured_day~ : Int,
  note~ : String,
) -> EvidenceItem {
  { evidence_id, case_id, kind, reference, captured_day, verified: false, note }
}

///|
/// Mark an evidence item as reviewed.
pub fn verify_evidence(item : EvidenceItem) -> EvidenceItem {
  { ..item, verified: true }
}

///|
/// Evidence belonging to one case.
pub fn evidence_for_case(
  evidence : Array[EvidenceItem],
  case_id : String,
) -> Array[EvidenceItem] {
  let result : Array[EvidenceItem] = []
  for item in evidence {
    if item.case_id == case_id {
      result.push(item)
    }
  }
  result
}

///|
/// Count reviewed evidence items.
pub fn verified_evidence_count(evidence : Array[EvidenceItem]) -> Int {
  let mut count = 0
  for item in evidence {
    if item.verified {
      count += 1
    }
  }
  count
}

///|
/// Evidence completion rate.
pub fn evidence_completion_rate(evidence : Array[EvidenceItem]) -> Double {
  if evidence.length() == 0 {
    0.0
  } else {
    verified_evidence_count(evidence).to_double() /
    evidence.length().to_double()
  }
}

///|
/// Whether a case has enough reviewed evidence to close.
pub fn case_has_verified_evidence(
  case : DeviationCase,
  evidence : Array[EvidenceItem],
  minimum : Int,
) -> Bool {
  if minimum <= 0 {
    true
  } else {
    verified_evidence_count(evidence_for_case(evidence, case.case_id)) >=
    minimum
  }
}

///|
/// A compact QMS portfolio summary.
pub(all) struct QmsSummary {
  cases : Int
  open : Int
  overdue : Int
  high_risk : Int
  actions : Int
  verified_actions : Int
  evidence : Int
  verified_evidence : Int
  closure_rate : Double
} derive(Debug, ToJson)

///|
/// Produce a portfolio summary for dashboards and release meetings.
pub fn qms_summary(
  cases : Array[DeviationCase],
  actions : Array[CorrectiveAction],
  evidence : Array[EvidenceItem],
  today : Int,
  risk_threshold : Int,
) -> QmsSummary {
  let closed = cases.length() - open_deviation_count(cases)
  let closure_rate = if cases.length() == 0 {
    0.0
  } else {
    closed.to_double() / cases.length().to_double()
  }
  {
    cases: cases.length(),
    open: open_deviation_count(cases),
    overdue: overdue_deviation_count(cases, today),
    high_risk: high_risk_deviation_count(cases, risk_threshold),
    actions: actions.length(),
    verified_actions: verified_action_count(actions),
    evidence: evidence.length(),
    verified_evidence: verified_evidence_count(evidence),
    closure_rate,
  }
}

///|
/// Normalize an invalid calendar window without changing case identity.
pub fn normalize_deviation_window(case : DeviationCase) -> DeviationCase {
  let detected = case.detected_day.max(0)
  let due = case.due_day.max(detected)
  { ..case, detected_day: detected, due_day: due }
}

///|
/// A human-readable risk band.
pub fn deviation_risk_band(case : DeviationCase) -> String {
  let score = deviation_rpn(case)
  if score >= 300 || case.severity >= 9 {
    "critical"
  } else if score >= 150 {
    "high"
  } else if score >= 50 {
    "medium"
  } else {
    "low"
  }
}

///|
/// An action priority derived from risk and due date.
pub fn action_priority(
  case : DeviationCase,
  action : CorrectiveAction,
  today : Int,
) -> Int {
  let urgency = if action_is_overdue(action, today) {
    30
  } else if action.due_day - today <= 3 {
    15
  } else {
    0
  }
  deviation_rpn(case) + urgency
}

///|
/// A stable label for the next QMS workflow step.
pub fn next_case_step(case : DeviationCase) -> String {
  match case.status {
    "open" => "contain"
    "investigating" => "identify_root_cause"
    "corrective_action" => "verify_effectiveness"
    "reopened" => "review_recurrence"
    "closed" => "archive"
    _ => "review"
  }
}
