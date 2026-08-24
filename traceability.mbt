///|
/// A production event that can be joined to lot genealogy and release review.
pub(all) struct TraceEvent {
  event_id : String
  lot_id : String
  parent_lot : String?
  product : String
  station : String
  operation : String
  operator : String
  timestamp : String
  sequence : Int
  quantity : Double
  disposition : String
  note : String
} derive(Debug, ToJson)

///|
/// Construct a trace event with a neutral disposition.
pub fn trace_event(
  event_id~ : String,
  lot_id~ : String,
  parent_lot~ : String?,
  product~ : String,
  station~ : String,
  operation~ : String,
  operator~ : String,
  timestamp~ : String,
  sequence~ : Int,
  quantity~ : Double,
  note~ : String,
) -> TraceEvent {
  {
    event_id,
    lot_id,
    parent_lot,
    product,
    station,
    operation,
    operator,
    timestamp,
    sequence,
    quantity: quantity.max(0.0),
    disposition: "pending",
    note,
  }
}

///|
/// Mark a trace event as accepted.
pub fn accept_trace_event(event : TraceEvent) -> TraceEvent {
  { ..event, disposition: "accepted" }
}

///|
/// Mark a trace event as rejected while retaining its data.
pub fn reject_trace_event(event : TraceEvent, note : String) -> TraceEvent {
  { ..event, disposition: "rejected", note }
}

///|
/// Whether an event can be used as release evidence.
pub fn trace_event_is_accepted(event : TraceEvent) -> Bool {
  event.disposition == "accepted"
}

///|
/// Events associated with a lot.
pub fn events_for_lot(
  events : Array[TraceEvent],
  lot_id : String,
) -> Array[TraceEvent] {
  let result : Array[TraceEvent] = []
  for event in events {
    if event.lot_id == lot_id {
      result.push(event)
    }
  }
  result
}

///|
/// Events produced by one station.
pub fn events_for_station(
  events : Array[TraceEvent],
  station : String,
) -> Array[TraceEvent] {
  let result : Array[TraceEvent] = []
  for event in events {
    if event.station == station {
      result.push(event)
    }
  }
  result
}

///|
/// Events for a lot and operation.
pub fn events_for_operation(
  events : Array[TraceEvent],
  lot_id : String,
  operation : String,
) -> Array[TraceEvent] {
  let result : Array[TraceEvent] = []
  for event in events {
    if event.lot_id == lot_id && event.operation == operation {
      result.push(event)
    }
  }
  result
}

///|
/// Find a trace event by its stable identifier.
pub fn find_trace_event(
  events : Array[TraceEvent],
  event_id : String,
) -> TraceEvent? {
  for event in events {
    if event.event_id == event_id {
      return Some(event)
    }
  }
  None
}

///|
/// Sort a trace by process sequence and timestamp.
pub fn sort_trace_events(events : Array[TraceEvent]) -> Array[TraceEvent] {
  let result = events.copy()
  result.sort_by(fn(a, b) {
    if a.sequence != b.sequence {
      a.sequence - b.sequence
    } else if a.timestamp < b.timestamp {
      -1
    } else if a.timestamp == b.timestamp {
      0
    } else {
      1
    }
  })
  result
}

///|
/// Sum the material quantity represented by trace events.
pub fn trace_quantity(events : Array[TraceEvent]) -> Double {
  let mut total = 0.0
  for event in events {
    total += event.quantity
  }
  total
}

///|
/// Quantity accepted by a station or lot.
pub fn accepted_trace_quantity(events : Array[TraceEvent]) -> Double {
  let mut total = 0.0
  for event in events {
    if trace_event_is_accepted(event) {
      total += event.quantity
    }
  }
  total
}

///|
/// Fraction of events accepted by a process.
pub fn trace_acceptance_rate(events : Array[TraceEvent]) -> Double {
  if events.length() == 0 {
    0.0
  } else {
    let mut accepted = 0
    for event in events {
      if trace_event_is_accepted(event) {
        accepted += 1
      }
    }
    accepted.to_double() / events.length().to_double()
  }
}

///|
/// Unique station names in first-seen order.
pub fn trace_stations(events : Array[TraceEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let mut found = false
    for station in result {
      if station == event.station {
        found = true
      }
    }
    if !found {
      result.push(event.station)
    }
  }
  result
}

///|
/// Unique operation names in first-seen order.
pub fn trace_operations(events : Array[TraceEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let mut found = false
    for operation in result {
      if operation == event.operation {
        found = true
      }
    }
    if !found {
      result.push(event.operation)
    }
  }
  result
}

///|
/// Count events with a given disposition.
pub fn trace_disposition_count(
  events : Array[TraceEvent],
  disposition : String,
) -> Int {
  let mut count = 0
  for event in events {
    if event.disposition == disposition {
      count += 1
    }
  }
  count
}

///|
/// Whether a lot has an event at every expected sequence position.
pub fn trace_has_sequences(events : Array[TraceEvent], expected : Int) -> Bool {
  if expected <= 0 {
    true
  } else {
    for sequence in 0..<expected {
      let mut found = false
      for event in events {
        if event.sequence == sequence {
          found = true
        }
      }
      if !found {
        return false
      }
    }
    true
  }
}

///|
/// Whether a lot has duplicate event identifiers.
pub fn trace_has_duplicate_ids(events : Array[TraceEvent]) -> Bool {
  for left in 0..<events.length() {
    for right in (left + 1)..<events.length() {
      if events[left].event_id == events[right].event_id {
        return true
      }
    }
  }
  false
}

///|
/// A material genealogy edge from a parent lot to a child lot.
pub(all) struct GenealogyLink {
  parent_lot : String
  child_lot : String
  quantity : Double
  event_id : String
  sequence : Int
} derive(Debug, ToJson)

///|
/// Construct a genealogy link.
pub fn genealogy_link(
  parent_lot~ : String,
  child_lot~ : String,
  quantity~ : Double,
  event_id~ : String,
  sequence~ : Int,
) -> GenealogyLink {
  { parent_lot, child_lot, quantity: quantity.max(0.0), event_id, sequence }
}

///|
/// Links whose parent is a given lot.
pub fn child_links(
  links : Array[GenealogyLink],
  parent_lot : String,
) -> Array[GenealogyLink] {
  let result : Array[GenealogyLink] = []
  for link in links {
    if link.parent_lot == parent_lot {
      result.push(link)
    }
  }
  result
}

///|
/// Links whose child is a given lot.
pub fn parent_links(
  links : Array[GenealogyLink],
  child_lot : String,
) -> Array[GenealogyLink] {
  let result : Array[GenealogyLink] = []
  for link in links {
    if link.child_lot == child_lot {
      result.push(link)
    }
  }
  result
}

///|
/// Direct child lot identifiers.
pub fn child_lots(
  links : Array[GenealogyLink],
  parent_lot : String,
) -> Array[String] {
  let result : Array[String] = []
  for link in child_links(links, parent_lot) {
    let mut found = false
    for lot in result {
      if lot == link.child_lot {
        found = true
      }
    }
    if !found {
      result.push(link.child_lot)
    }
  }
  result
}

///|
/// Direct parent lot identifiers.
pub fn parent_lots(
  links : Array[GenealogyLink],
  child_lot : String,
) -> Array[String] {
  let result : Array[String] = []
  for link in parent_links(links, child_lot) {
    let mut found = false
    for lot in result {
      if lot == link.parent_lot {
        found = true
      }
    }
    if !found {
      result.push(link.parent_lot)
    }
  }
  result
}

///|
/// Recursively collect descendants with a bounded traversal depth.
pub fn descendants(
  links : Array[GenealogyLink],
  parent_lot : String,
  depth : Int,
) -> Array[String] {
  let result : Array[String] = []
  if depth <= 0 {
    return result
  }
  let mut frontier = child_lots(links, parent_lot)
  let mut level = 0
  while level < depth && frontier.length() > 0 {
    let next : Array[String] = []
    for lot in frontier {
      let mut known = false
      for existing in result {
        if existing == lot {
          known = true
        }
      }
      if !known {
        result.push(lot)
        for child in child_lots(links, lot) {
          next.push(child)
        }
      }
    }
    frontier = next
    level += 1
  }
  result
}

///|
/// Recursively collect ancestors with a bounded traversal depth.
pub fn ancestors(
  links : Array[GenealogyLink],
  child_lot : String,
  depth : Int,
) -> Array[String] {
  let result : Array[String] = []
  if depth <= 0 {
    return result
  }
  let mut frontier = parent_lots(links, child_lot)
  let mut level = 0
  while level < depth && frontier.length() > 0 {
    let next : Array[String] = []
    for lot in frontier {
      let mut known = false
      for existing in result {
        if existing == lot {
          known = true
        }
      }
      if !known {
        result.push(lot)
        for parent in parent_lots(links, lot) {
          next.push(parent)
        }
      }
    }
    frontier = next
    level += 1
  }
  result
}

///|
/// Detect a cycle in the supplied parent-child links.
pub fn genealogy_has_cycle(links : Array[GenealogyLink]) -> Bool {
  for link in links {
    for ancestor in ancestors(links, link.parent_lot, links.length() + 1) {
      if ancestor == link.child_lot {
        return true
      }
    }
  }
  false
}

///|
/// A genealogy summary for one lot.
pub(all) struct GenealogySummary {
  lot_id : String
  parents : Int
  children : Int
  ancestor_count : Int
  descendant_count : Int
  incoming_quantity : Double
  outgoing_quantity : Double
  cycle : Bool
} derive(Debug, ToJson)

///|
/// Summarize lineage around one lot.
pub fn summarize_genealogy(
  links : Array[GenealogyLink],
  lot_id : String,
) -> GenealogySummary {
  let incoming = parent_links(links, lot_id)
  let outgoing = child_links(links, lot_id)
  {
    lot_id,
    parents: parent_lots(links, lot_id).length(),
    children: child_lots(links, lot_id).length(),
    ancestor_count: ancestors(links, lot_id, links.length() + 1).length(),
    descendant_count: descendants(links, lot_id, links.length() + 1).length(),
    incoming_quantity: trace_link_quantity(incoming),
    outgoing_quantity: trace_link_quantity(outgoing),
    cycle: genealogy_has_cycle(links),
  }
}

///|
/// Sum quantities in genealogy links.
pub fn trace_link_quantity(links : Array[GenealogyLink]) -> Double {
  let mut total = 0.0
  for link in links {
    total += link.quantity
  }
  total
}

///|
/// Sort genealogy links by sequence.
pub fn sort_genealogy_links(
  links : Array[GenealogyLink],
) -> Array[GenealogyLink] {
  let result = links.copy()
  result.sort_by(fn(a, b) { a.sequence - b.sequence })
  result
}

///|
/// A release checklist assembled from process evidence.
pub(all) struct ReleaseChecklist {
  lot_id : String
  required_events : Int
  observed_events : Int
  accepted_events : Int
  required_features : Int
  measured_features : Int
  open_deviations : Int
  verified_actions : Int
  evidence_items : Int
  verified_evidence : Int
  ready : Bool
  reasons : Array[String]
} derive(Debug, ToJson)

///|
/// Build a release checklist from trace, QMS, and evidence inputs.
pub fn release_checklist(
  lot_id : String,
  events : Array[TraceEvent],
  required_events : Int,
  required_features : Int,
  measured_features : Int,
  open_deviations : Int,
  verified_actions : Int,
  evidence : Array[EvidenceItem],
) -> ReleaseChecklist {
  let lot_events = events_for_lot(events, lot_id)
  let reasons : Array[String] = []
  if lot_events.length() < required_events {
    reasons.push("required process events are missing")
  }
  if trace_disposition_count(lot_events, "rejected") > 0 {
    reasons.push("a process event is rejected")
  }
  if measured_features < required_features {
    reasons.push("required measurements are missing")
  }
  if open_deviations > 0 {
    reasons.push("open deviations remain")
  }
  if verified_actions <= 0 && open_deviations > 0 {
    reasons.push("no verified corrective action is linked")
  }
  if evidence_completion_rate(evidence) < 1.0 {
    reasons.push("evidence review is incomplete")
  }
  {
    lot_id,
    required_events,
    observed_events: lot_events.length(),
    accepted_events: trace_disposition_count(lot_events, "accepted"),
    required_features,
    measured_features,
    open_deviations,
    verified_actions,
    evidence_items: evidence.length(),
    verified_evidence: verified_evidence_count(evidence),
    ready: reasons.length() == 0,
    reasons,
  }
}

///|
/// Whether all trace events have non-empty identifiers and lot IDs.
pub fn trace_identity_is_complete(events : Array[TraceEvent]) -> Bool {
  for event in events {
    if event.event_id == "" || event.lot_id == "" {
      return false
    }
  }
  true
}

///|
/// Return events that have incomplete trace identity.
pub fn incomplete_trace_events(events : Array[TraceEvent]) -> Array[TraceEvent] {
  let result : Array[TraceEvent] = []
  for event in events {
    if event.event_id == "" || event.lot_id == "" || event.station == "" {
      result.push(event)
    }
  }
  result
}

///|
/// A compact data-quality score for a trace.
pub fn trace_quality_score(events : Array[TraceEvent]) -> Double {
  if events.length() == 0 {
    0.0
  } else {
    let mut complete = 0
    for event in events {
      if event.event_id != "" &&
        event.lot_id != "" &&
        event.station != "" &&
        event.operator != "" {
        complete += 1
      }
    }
    complete.to_double() / events.length().to_double()
  }
}

///|
/// Return a normalized non-negative quantity for each trace event.
pub fn normalize_trace_quantities(
  events : Array[TraceEvent],
) -> Array[TraceEvent] {
  let result : Array[TraceEvent] = []
  for event in events {
    result.push({ ..event, quantity: event.quantity.max(0.0) })
  }
  result
}

///|
/// Return unique lots that occur in the trace.
pub fn trace_lot_ids(events : Array[TraceEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let mut found = false
    for lot in result {
      if lot == event.lot_id {
        found = true
      }
    }
    if !found {
      result.push(event.lot_id)
    }
  }
  result
}

///|
/// Return the latest sequence number in a trace.
pub fn trace_latest_sequence(events : Array[TraceEvent]) -> Int {
  let mut latest = -1
  for event in events {
    latest = latest.max(event.sequence)
  }
  latest
}

///|
/// Return a trace completion ratio against an expected process length.
pub fn trace_completion_rate(
  events : Array[TraceEvent],
  expected : Int,
) -> Double {
  if expected <= 0 {
    0.0
  } else {
    (trace_latest_sequence(events) + 1).to_double() / expected.to_double()
  }
}
