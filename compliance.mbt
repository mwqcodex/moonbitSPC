///|
pub struct AuditEvent {
  event_id : String
  lot_id : String
  actor : String
  action : String
  timestamp : String
  passed : Bool
  evidence : String
} derive(Debug, ToJson)

///|
pub struct TraceabilityResult {
  event_count : Int
  unique_lots : Int
  missing_evidence : Int
  failed_events : Int
  chronological : Bool
  complete : Bool
} derive(Debug, ToJson)

///|
pub fn audit_event(
  event_id~ : String,
  lot_id~ : String,
  actor~ : String,
  action~ : String,
  timestamp~ : String,
  passed~ : Bool,
  evidence~ : String,
) -> AuditEvent {
  { event_id, lot_id, actor, action, timestamp, passed, evidence }
}

///|
pub fn audit_missing_evidence(events : Array[AuditEvent]) -> Int {
  let mut count = 0
  for event in events {
    if event.evidence.length() == 0 {
      count += 1
    }
  }
  count
}

///|
pub fn audit_failed_count(events : Array[AuditEvent]) -> Int {
  let mut count = 0
  for event in events {
    if !event.passed {
      count += 1
    }
  }
  count
}

///|
pub fn audit_unique_lots(events : Array[AuditEvent]) -> Int {
  let lots : Array[String] = []
  for event in events {
    if !lots.contains(event.lot_id) {
      lots.push(event.lot_id)
    }
  }
  lots.length()
}

///|
pub fn audit_is_chronological(events : Array[AuditEvent]) -> Bool {
  for i in 1..<events.length() {
    if events[i].timestamp < events[i - 1].timestamp {
      return false
    }
  }
  true
}

///|
pub fn traceability_check(events : Array[AuditEvent]) -> TraceabilityResult {
  let missing = audit_missing_evidence(events)
  let failed = audit_failed_count(events)
  let chronological = audit_is_chronological(events)
  {
    event_count: events.length(),
    unique_lots: audit_unique_lots(events),
    missing_evidence: missing,
    failed_events: failed,
    chronological,
    complete: missing == 0 && failed == 0 && chronological,
  }
}

///|
pub fn audit_events_for_lot(
  events : Array[AuditEvent],
  lot_id : String,
) -> Array[AuditEvent] {
  let result : Array[AuditEvent] = []
  for event in events {
    if event.lot_id == lot_id {
      result.push(event)
    }
  }
  result
}

///|
pub fn audit_action_count(events : Array[AuditEvent], action : String) -> Int {
  let mut count = 0
  for event in events {
    if event.action == action {
      count += 1
    }
  }
  count
}

///|
pub fn audit_pass_rate(events : Array[AuditEvent]) -> Double {
  if events.length() == 0 {
    0.0
  } else {
    (events.length() - audit_failed_count(events)).to_double() /
    events.length().to_double()
  }
}

///|
pub fn audit_score(result : TraceabilityResult) -> Double {
  let total = result.event_count.max(1).to_double()
  100.0 *
  (1.0 - (result.missing_evidence + result.failed_events).to_double() / total)
}

///|
pub fn evidence_types(events : Array[AuditEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let suffix = event.evidence.split(".").last().unwrap_or("").to_owned()
    if !result.contains(suffix) {
      result.push(suffix)
    }
  }
  result
}
