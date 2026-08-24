///|
test "production KPI operations" {
  let record = production_kpi(
    period="D1",
    planned_units=100,
    started_units=90,
    good_units=80,
    rework_units=5,
    scrap_units=5,
    planned_hours=8.0,
    run_hours=6.0,
    downtime_hours=2.0,
    ideal_cycle_seconds=240.0,
    total_cost=900.0,
    quality_cost=60.0,
  )
  ignore(non_first_pass_units(record))
  ignore(unaccounted_units(record))
  ignore(first_pass_yield(record))
  ignore(total_yield(record))
  ignore(rework_rate(record))
  ignore(scrap_rate(record))
  ignore(plan_attainment(record))
  ignore(availability(record))
  ignore(performance(record))
  ignore(quality_rate(record))
  ignore(oee(record))
  ignore(downtime_rate(record))
  ignore(throughput_per_hour(record))
  ignore(defects_per_million(record))
  ignore(cost_per_output(record))
  ignore(quality_cost_rate(record))
  ignore(plan_gap(record))
  ignore(kpi_has_invalid_quantity(record))
  ignore(kpi_has_reconciliation_gap(record))
  ignore(validate_kpi(record))
  ignore(normalize_kpi_time(record))
  ignore(oee_band(oee(record)))
  ignore(yield_band(first_pass_yield(record)))
  let invalid = { ..record, good_units: 200, run_hours: 9.0 }
  ignore(validate_kpi(invalid))
  let aggregate = sum_kpis([record, invalid])
  ignore(aggregate)
  ignore(kpis_for_period([record, invalid], "D1"))
  ignore(low_oee_records([record, invalid], 0.8))
  ignore(high_scrap_records([record, invalid], 0.01))
  let observations = [
    kpi_observation(
      period="D1",
      metric="oee",
      value=0.5,
      target=Some(0.7),
      lower=Some(0.4),
      upper=Some(1.0),
    ),
    kpi_observation(
      period="D2",
      metric="oee",
      value=0.8,
      target=Some(0.7),
      lower=Some(0.4),
      upper=Some(1.0),
    ),
    kpi_observation(
      period="D3",
      metric="oee",
      value=0.3,
      target=Some(0.7),
      lower=Some(0.4),
      upper=Some(1.0),
    ),
  ]
  for observation in observations {
    ignore(observation_gap(observation))
    ignore(observation_out_of_bounds(observation))
    ignore(observation_status(observation))
    ignore(observation_alert(observation))
  }
  ignore(observations_for_metric(observations, "oee"))
  ignore(out_of_bound_count(observations))
  ignore(target_compliance_rate(observations))
  ignore(rolling_observation_average(observations, 2))
  ignore(rolling_observation_minimum(observations, 2))
  ignore(rolling_observation_maximum(observations, 2))
  ignore(summarize_kpi_trend(observations))
  ignore(consecutive_status_count(observations, "below_target"))
  ignore(sustained_below_target(observations, 2))
  let alerts = kpi_alerts(observations)
  ignore(alert_count_at_least(alerts, 2))
  ignore(sort_kpi_alerts(alerts))
  let costs = [
    quality_cost(
      period="D1",
      prevention=10.0,
      appraisal=20.0,
      internal_failure=30.0,
      external_failure=5.0,
    ),
    quality_cost(
      period="D2",
      prevention=5.0,
      appraisal=10.0,
      internal_failure=15.0,
      external_failure=2.0,
    ),
  ]
  for cost in costs {
    ignore(total_quality_cost(cost))
    ignore(prevention_appraisal_cost(cost))
    ignore(failure_cost(cost))
    ignore(failure_cost_rate(cost))
  }
  ignore(sum_quality_costs(costs))
}

///|
test "QMS and traceability operations" {
  let case = deviation_case(
    case_id="C1",
    lot_id="L1",
    station="S1",
    category="dimension",
    description="high",
    owner="qa",
    detected_day=2,
    due_day=5,
    severity=8,
    occurrence=4,
    detection=3,
  )
  ignore(deviation_rpn(case))
  ignore(deviation_is_high_risk(case, 100))
  ignore(deviation_is_overdue(case, 10))
  ignore(deviation_age(case, 10))
  ignore(deviation_days_remaining(case, 3))
  ignore(next_case_step(case))
  ignore(deviation_risk_band(case))
  let contained = contain_deviation(case, "hold lot")
  let investigated = assign_root_cause(contained, "tool wear")
  let closed = close_deviation(investigated)
  let reopened = reopen_deviation(closed)
  ignore(deviation_is_closed(closed))
  ignore(
    normalize_deviation_window({ ..reopened, detected_day: -1, due_day: -2 }),
  )
  let second = deviation_case(
    case_id="C2",
    lot_id="L2",
    station="S2",
    category="material",
    description="low",
    owner="ops",
    detected_day=1,
    due_day=20,
    severity=2,
    occurrence=2,
    detection=2,
  )
  let cases = [case, reopened, second]
  ignore(deviations_for_owner(cases, "qa"))
  ignore(deviations_for_lot(cases, "L1"))
  ignore(deviations_for_station_category(cases, "S1", "dimension"))
  ignore(open_deviation_count(cases))
  ignore(overdue_deviation_count(cases, 10))
  ignore(high_risk_deviation_count(cases, 50))
  ignore(average_deviation_age(cases, 10))
  ignore(sort_deviations(cases))
  ignore(deviation_counts(cases, 10))
  let action = corrective_action(
    action_id="A1",
    case_id="C1",
    title="replace tool",
    owner="eng",
    start_day=3,
    due_day=8,
    estimated_hours=4.0,
    effectiveness_target=0.8,
  )
  let started = start_corrective_action(action)
  let effort = record_action_effort(started, 2.0)
  let verified = verify_corrective_action(effort, "run chart", 0.9)
  ignore(action_is_verified(verified))
  ignore(action_is_overdue(action, 10))
  ignore(action_progress(verified))
  ignore(action_duration(action))
  let actions = [action, verified]
  ignore(actions_for_case(actions, "C1"))
  ignore(actions_for_owner(actions, "eng"))
  ignore(verified_action_count(actions))
  ignore(overdue_action_count(actions, 10))
  ignore(average_action_progress(actions))
  ignore(action_completion_rate(actions))
  ignore(action_counts(actions))
  ignore(action_priority(case, verified, 10))
  let item = evidence_item(
    evidence_id="E1",
    case_id="C1",
    kind="chart",
    reference="report-1",
    captured_day=4,
    note="review",
  )
  let reviewed = verify_evidence(item)
  let evidence = [item, reviewed]
  ignore(evidence_for_case(evidence, "C1"))
  ignore(verified_evidence_count(evidence))
  ignore(evidence_completion_rate(evidence))
  ignore(case_has_verified_evidence(case, evidence, 1))
  ignore(qms_summary(cases, actions, evidence, 10, 50))
  let event1 = trace_event(
    event_id="E-1",
    lot_id="L1",
    parent_lot=Some("RAW"),
    product="P",
    station="S1",
    operation="cut",
    operator="op",
    timestamp="1",
    sequence=0,
    quantity=10.0,
    note="",
  )
  let event2 = accept_trace_event(
    trace_event(
      event_id="E-2",
      lot_id="L1",
      parent_lot=None,
      product="P",
      station="S2",
      operation="inspect",
      operator="op",
      timestamp="2",
      sequence=1,
      quantity=9.0,
      note="",
    ),
  )
  let event3 = reject_trace_event(event2, "out of spec")
  let events = [event1, event3]
  for event in events {
    ignore(trace_event_is_accepted(event))
    ignore(events_for_lot(events, event.lot_id))
    ignore(events_for_station(events, event.station))
    ignore(events_for_operation(events, event.lot_id, event.operation))
    ignore(find_trace_event(events, event.event_id))
  }
  ignore(sort_trace_events(events))
  ignore(trace_quantity(events))
  ignore(accepted_trace_quantity(events))
  ignore(trace_acceptance_rate(events))
  ignore(trace_stations(events))
  ignore(trace_operations(events))
  ignore(trace_disposition_count(events, "rejected"))
  ignore(trace_has_sequences(events, 2))
  ignore(trace_has_duplicate_ids(events))
  ignore(trace_identity_is_complete(events))
  ignore(incomplete_trace_events(events))
  ignore(trace_quality_score(events))
  ignore(normalize_trace_quantities(events))
  ignore(trace_lot_ids(events))
  ignore(trace_latest_sequence(events))
  ignore(trace_completion_rate(events, 3))
  let links = [
    genealogy_link(
      parent_lot="RAW",
      child_lot="L1",
      quantity=10.0,
      event_id="E-1",
      sequence=0,
    ),
    genealogy_link(
      parent_lot="L1",
      child_lot="FG",
      quantity=9.0,
      event_id="E-2",
      sequence=1,
    ),
  ]
  ignore(child_links(links, "RAW"))
  ignore(parent_links(links, "L1"))
  ignore(child_lots(links, "RAW"))
  ignore(parent_lots(links, "L1"))
  ignore(descendants(links, "RAW", 3))
  ignore(ancestors(links, "FG", 3))
  ignore(genealogy_has_cycle(links))
  ignore(summarize_genealogy(links, "L1"))
  ignore(trace_link_quantity(links))
  ignore(sort_genealogy_links(links))
  let checklist = release_checklist(
    "L1",
    [accept_trace_event(event1), accept_trace_event(event2)],
    2,
    1,
    1,
    0,
    1,
    [reviewed],
  )
  assert_true(checklist.ready)
}
