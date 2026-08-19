///|
/// Production lot identity used to join measurements from several stations.
pub(all) struct LotIdentity {
  lot : String
  product : String
  revision : String
  line : String
  shift : String
  start_window : String
  end_window : String
} derive(Debug, ToJson)

///|
/// One observation event with source and routing metadata.
pub(all) struct MeasurementEvent {
  identity : LotIdentity
  station : String
  feature : String
  value : Double?
  sequence : Int
  accepted : Bool
} derive(Debug, ToJson)

///|
/// A grouped measurement stream for one lot and feature.
pub(all) struct LotFeature {
  identity : LotIdentity
  feature : String
  values : Array[Double]
  mut missing : Int
  stations : Array[String]
} derive(Debug, ToJson)

///|
/// Create a stable lot identity.
pub fn LotIdentity::new(
  lot~ : String,
  product~ : String,
  revision~ : String,
  line~ : String,
  shift~ : String,
  start_window~ : String,
  end_window~ : String,
) -> LotIdentity {
  { lot, product, revision, line, shift, start_window, end_window }
}

///|
/// Construct an event from an optional measurement.
pub fn MeasurementEvent::new(
  identity~ : LotIdentity,
  station~ : String,
  feature~ : String,
  value~ : Double?,
  sequence~ : Int,
) -> MeasurementEvent {
  { identity, station, feature, value, sequence, accepted: true }
}

///|
/// Mark an event as rejected without discarding its traceability.
pub fn MeasurementEvent::reject(self : MeasurementEvent) -> MeasurementEvent {
  { ..self, accepted: false }
}

///|
/// Group events by feature and preserve source station order.
pub fn group_events(events : Array[MeasurementEvent]) -> Array[LotFeature] {
  let result : Array[LotFeature] = []
  for event in events {
    let mut target : Int? = None
    for index, group in result {
      if group.feature == event.feature &&
        group.identity.lot == event.identity.lot {
        target = Some(index)
      }
    }
    match target {
      Some(index) => {
        match event.value {
          Some(value) => result[index].values.push(value)
          None => result[index].missing += 1
        }
        let mut station_seen = false
        for station in result[index].stations {
          if station == event.station {
            station_seen = true
          }
        }
        if !station_seen {
          result[index].stations.push(event.station)
        }
      }
      None => {
        let values : Array[Double] = []
        let missing = match event.value {
          Some(value) => {
            values.push(value)
            0
          }
          None => 1
        }
        result.push({
          identity: event.identity,
          feature: event.feature,
          values,
          missing,
          stations: [event.station],
        })
      }
    }
  }
  result
}

///|
/// Aggregate one lot feature into a quality summary.
pub(all) struct LotFeatureSummary {
  lot : String
  feature : String
  count : Int
  missing : Int
  mean : Double?
  deviation : Double?
  minimum : Double?
  maximum : Double?
  defect_rate : Double?
  station_count : Int
} derive(Debug, ToJson)

///|
/// Summarize a grouped lot feature against an optional specification.
pub fn summarize_lot_feature(
  feature : LotFeature,
  specification : Specification?,
) -> LotFeatureSummary {
  let mean = if feature.values.length() == 0 {
    None
  } else {
    Some(mean_of(feature.values))
  }
  let deviation = if feature.values.length() < 2 {
    None
  } else {
    Some(std_of(feature.values, mean_of(feature.values)))
  }
  let minimum = if feature.values.length() == 0 {
    None
  } else {
    let mut value = feature.values[0]
    for item in feature.values {
      value = value.min(item)
    }
    Some(value)
  }
  let maximum = if feature.values.length() == 0 {
    None
  } else {
    let mut value = feature.values[0]
    for item in feature.values {
      value = value.max(item)
    }
    Some(value)
  }
  let defect_rate = match specification {
    Some(spec) => defect_rate(feature.values, spec)
    None => None
  }
  {
    lot: feature.identity.lot,
    feature: feature.feature,
    count: feature.values.length(),
    missing: feature.missing,
    mean,
    deviation,
    minimum,
    maximum,
    defect_rate,
    station_count: feature.stations.length(),
  }
}

///|
/// Summarize every lot feature in a deterministic order.
pub fn summarize_lot_features(
  features : Array[LotFeature],
  specification : Specification?,
) -> Array[LotFeatureSummary] {
  let result : Array[LotFeatureSummary] = []
  for feature in features {
    result.push(summarize_lot_feature(feature, specification))
  }
  result
}

///|
/// A station-to-station comparison result.
pub(all) struct StationComparison {
  station : String
  count : Int
  mean : Double?
  deviation : Double?
  delta_from_lot : Double?
  alarm : Bool
} derive(Debug, ToJson)

///|
/// Compare each station's values with a lot center.
pub fn compare_stations(
  events : Array[MeasurementEvent],
  feature : String,
  threshold~ : Double,
) -> Array[StationComparison] {
  let values : Array[Double] = []
  let station_names : Array[String] = []
  let station_values : Array[Array[Double]] = []
  for event in events {
    if event.feature == feature && event.accepted {
      match event.value {
        Some(value) => {
          values.push(value)
          let mut index : Int? = None
          for current, station in station_names {
            if station == event.station {
              index = Some(current)
            }
          }
          match index {
            Some(current) => station_values[current].push(value)
            None => {
              station_names.push(event.station)
              station_values.push([value])
            }
          }
        }
        None => ()
      }
    }
  }
  let center = if values.length() == 0 { 0.0 } else { mean_of(values) }
  let output : Array[StationComparison] = []
  for index, station in station_names {
    let data = station_values[index]
    let station_mean = mean_of(data)
    output.push({
      station,
      count: data.length(),
      mean: Some(station_mean),
      deviation: if data.length() < 2 {
        None
      } else {
        Some(std_of(data, station_mean))
      },
      delta_from_lot: Some(station_mean - center),
      alarm: (station_mean - center).abs() > threshold,
    })
  }
  output
}

///|
/// A lot-level release decision with reasons for review.
pub(all) struct ReleaseDecision {
  released : Bool
  reason_codes : Array[String]
  measured_features : Int
  rejected_events : Int
  missing_measurements : Int
} derive(Debug, ToJson)

///|
/// Decide whether a lot can be released under minimum coverage rules.
pub fn release_decision(
  events : Array[MeasurementEvent],
  minimum_features~ : Int,
  minimum_measurements~ : Int,
) -> ReleaseDecision {
  let features : Array[String] = []
  let mut rejected = 0
  let mut missing = 0
  let mut accepted_measurements = 0
  for event in events {
    if !event.accepted {
      rejected += 1
    }
    let mut seen = false
    for feature in features {
      if feature == event.feature {
        seen = true
      }
    }
    if !seen {
      features.push(event.feature)
    }
    match event.value {
      Some(_) => if event.accepted { accepted_measurements += 1 }
      None => missing += 1
    }
  }
  let reasons : Array[String] = []
  if features.length() < minimum_features {
    reasons.push("INSUFFICIENT_FEATURES")
  }
  if accepted_measurements < minimum_measurements {
    reasons.push("INSUFFICIENT_MEASUREMENTS")
  }
  if rejected > 0 {
    reasons.push("REJECTED_EVENTS_PRESENT")
  }
  {
    released: reasons.length() == 0,
    reason_codes: reasons,
    measured_features: features.length(),
    rejected_events: rejected,
    missing_measurements: missing,
  }
}

///|
/// Sort events by sequence number for deterministic replay.
pub fn sort_events(events : Array[MeasurementEvent]) -> Array[MeasurementEvent] {
  let output = events.copy()
  for index in 1..<output.length() {
    let event = output[index]
    let mut cursor = index
    while cursor > 0 && output[cursor - 1].sequence > event.sequence {
      output[cursor] = output[cursor - 1]
      cursor -= 1
    }
    output[cursor] = event
  }
  output
}

///|
/// Return events from one station.
pub fn station_events(
  events : Array[MeasurementEvent],
  station : String,
) -> Array[MeasurementEvent] {
  let result : Array[MeasurementEvent] = []
  for event in events {
    if event.station == station {
      result.push(event)
    }
  }
  result
}

///|
/// Return events for one feature.
pub fn feature_events(
  events : Array[MeasurementEvent],
  feature : String,
) -> Array[MeasurementEvent] {
  let result : Array[MeasurementEvent] = []
  for event in events {
    if event.feature == feature {
      result.push(event)
    }
  }
  result
}

///|
/// Count accepted events.
pub fn accepted_event_count(events : Array[MeasurementEvent]) -> Int {
  let mut count = 0
  for event in events {
    if event.accepted {
      count += 1
    }
  }
  count
}

///|
/// Count rejected events.
pub fn rejected_event_count(events : Array[MeasurementEvent]) -> Int {
  let mut count = 0
  for event in events {
    if !event.accepted {
      count += 1
    }
  }
  count
}

///|
/// Count non-missing events.
pub fn measured_event_count(events : Array[MeasurementEvent]) -> Int {
  let mut count = 0
  for event in events {
    if event.value is Some(_) {
      count += 1
    }
  }
  count
}

///|
/// Count events missing a value.
pub fn missing_event_count(events : Array[MeasurementEvent]) -> Int {
  let mut count = 0
  for event in events {
    if event.value is None {
      count += 1
    }
  }
  count
}

///|
/// Return unique station identifiers.
pub fn unique_stations(events : Array[MeasurementEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let mut seen = false
    for station in result {
      if station == event.station {
        seen = true
      }
    }
    if !seen {
      result.push(event.station)
    }
  }
  result
}

///|
/// Return unique feature identifiers.
pub fn unique_features(events : Array[MeasurementEvent]) -> Array[String] {
  let result : Array[String] = []
  for event in events {
    let mut seen = false
    for feature in result {
      if feature == event.feature {
        seen = true
      }
    }
    if !seen {
      result.push(event.feature)
    }
  }
  result
}

///|
/// Coverage rate for accepted numeric observations.
pub fn measurement_coverage(events : Array[MeasurementEvent]) -> Double {
  if events.length() == 0 {
    0.0
  } else {
    measured_event_count(events).to_double() / events.length().to_double()
  }
}

///|
/// Acceptance rate for routed events.
pub fn event_acceptance_rate(events : Array[MeasurementEvent]) -> Double {
  if events.length() == 0 {
    0.0
  } else {
    accepted_event_count(events).to_double() / events.length().to_double()
  }
}

///|
/// Filter events belonging to one lot.
pub fn lot_events(
  events : Array[MeasurementEvent],
  lot : String,
) -> Array[MeasurementEvent] {
  let result : Array[MeasurementEvent] = []
  for event in events {
    if event.identity.lot == lot {
      result.push(event)
    }
  }
  result
}

///|
/// Build a feature's values from event records.
pub fn values_from_events(events : Array[MeasurementEvent]) -> Array[Double] {
  let result : Array[Double] = []
  for event in sort_events(events) {
    match event.value {
      Some(value) => result.push(value)
      None => ()
    }
  }
  result
}

///|
/// Run a quality report for every lot feature.
pub fn lot_feature_reports(
  events : Array[MeasurementEvent],
  specification : Specification?,
) -> Array[LotFeatureSummary] {
  summarize_lot_features(group_events(events), specification)
}

///|
/// Merge events from multiple lots into a single chronological stream.
pub fn merge_event_streams(
  first : Array[MeasurementEvent],
  second : Array[MeasurementEvent],
) -> Array[MeasurementEvent] {
  sort_events(concatenate_events(first, second))
}

///|
fn concatenate_events(
  first : Array[MeasurementEvent],
  second : Array[MeasurementEvent],
) -> Array[MeasurementEvent] {
  let result = first.copy()
  for event in second {
    result.push(event)
  }
  result
}

///|
/// Validate event sequences for duplicate or negative sequence numbers.
pub fn validate_event_sequences(
  events : Array[MeasurementEvent],
) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  for index, event in events {
    if event.sequence < 0 {
      issues.push({
        index,
        field: "sequence",
        message: "sequence must be non-negative",
      })
    }
    for previous_index in 0..<index {
      if events[previous_index].sequence == event.sequence &&
        events[previous_index].identity.lot == event.identity.lot {
        issues.push({
          index,
          field: "sequence",
          message: "sequence is duplicated within lot",
        })
      }
    }
  }
  issues
}
