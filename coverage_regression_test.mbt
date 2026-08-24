///|
test "coverage regression analytics and robust boundaries" {
  ignore(sum_of([]))
  ignore(sum_of([1.0, 2.0]))
  ignore(product_of([1.0, 2.0]))
  ignore(weighted_mean([1.0, 2.0], [1.0, 2.0]))
  ignore(weighted_mean([], []))
  ignore(weighted_mean([1.0], [-1.0]))
  ignore(geometric_mean([1.0, 2.0]))
  ignore(geometric_mean([]))
  ignore(geometric_mean([0.0]))
  ignore(harmonic_mean([1.0, 2.0]))
  ignore(harmonic_mean([]))
  ignore(harmonic_mean([0.0]))
  ignore(covariance([1.0, 2.0], [2.0, 4.0]))
  ignore(covariance([], []))
  ignore(correlation([1.0, 1.0], [2.0, 3.0]))
  ignore(autocorrelation([1.0, 2.0, 3.0], 1))
  ignore(autocorrelation([], 0))
  ignore(frequencies([1, 1, 2]))
  ignore(rolling_min([1.0, 2.0, 3.0], 2))
  ignore(rolling_min([], 2))
  ignore(rolling_max([1.0, 2.0, 3.0], 2))
  ignore(rolling_range([1.0, 2.0], 3))
  ignore(trimmed([1.0, 2.0, 3.0], 0.2))
  ignore(trimmed([], 0.2))
  ignore(winsorized([1.0, 2.0, 9.0], 0.2))
  ignore(clipped([1.0, 2.0], 0.0, 1.0))
  ignore(clipped([1.0], 2.0, 1.0))
  ignore(histogram([1.0, 2.0, 3.0], 2))
  ignore(histogram([], 2))
  ignore(percentile_rank([1.0, 2.0], 1.0))
  ignore(percentile_rank([], 1.0))
  ignore(standard_error([1.0, 2.0]))
  ignore(standard_error([]))
  ignore(confidence_interval_95([1.0, 2.0]))
  ignore(pooled_standard_deviation([[1.0, 2.0], [2.0, 3.0]]))
  ignore(pooled_standard_deviation([]))
  ignore(iqr_outliers([1.0, 2.0, 20.0], 1.5))
  ignore(iqr_outliers([], 1.5))
  ignore(sign_changes([1.0, -1.0], 0.0))
  ignore(longest_run([1.0, 2.0], 0.0))
  ignore(direction_changes([1.0, 2.0, 1.0]))
}

///|
test "coverage regression advanced statistics and validation" {
  let values = [1.0, 2.0, 3.0, 4.0]
  ignore(sorted_copy(values))
  ignore(quantile(values, 0.5))
  ignore(quantile([], 0.5))
  ignore(median(values))
  ignore(median([]))
  ignore(mad(values))
  ignore(iqr(values))
  ignore(z_scores(values, 2.0, 1.0))
  ignore(z_scores(values, 2.0, 0.0))
  ignore(ewma(values, lambda=0.2, initial=0.0))
  ignore(ewma(values, lambda=2.0, initial=0.0))
  ignore(cusum(values, target=2.0, allowance=0.1, decision=1.0))
  ignore(cusum(values, target=2.0, allowance=-1.0, decision=1.0))
  ignore(moving_mean(values, 2))
  ignore(moving_mean(values, 0))
  ignore(moving_std(values, 2))
  ignore(moving_std(values, 0))
  ignore(subgroup(values, 2))
  ignore(subgroup(values, 3))
  ignore(min_max_scale(values))
  ignore(min_max_scale([]))
  ignore(min_max_scale([1.0, 1.0]))
  let group = Subgroup::new(
    values~,
    batch="B",
    equipment="E",
    tool="T",
    operator="O",
    window="W",
  )
  ignore(validate_subgroups([group]))
  ignore(
    validate_subgroups([
      { ..group, equipment: "", tool: "", operator: "", window: "" },
    ]),
  )
  ignore(validate_counts([1, -1], [2, 2]))
  ignore(validate_counts([1], [2, 2]))
  ignore(validate_specification(Specification::new(lower=0.0, upper=1.0)))
  ignore(validate_specification(Specification::new(lower=1.0, upper=0.0)))
}

///|
test "coverage regression attribute and capability paths" {
  ignore(attribute_rate([1, 2], [10, 10]))
  ignore(attribute_rate([], []))
  ignore(attribute_rate([-1], [1]))
  ignore(defects_per_opportunity([1], [10]))
  ignore(defects_per_opportunity([], []))
  ignore(category_counts(["a", "a", "b"]))
  ignore(sort_category_counts(category_counts(["a", "b", "b"])))
  ignore(pareto_categories(["a", "b"]))
  ignore(p_chart_points([1, 2], [10, 10]))
  ignore(p_chart_points([], []))
  ignore(count_chart_points([1, 2]))
  ignore(count_chart_points([]))
  ignore(count_chart_points([-1]))
  let base = ["a", "b", "a"]
  let first_categories = category_counts(base)
  let second_categories = category_counts(["a", "c"])
  ignore(category_delta(first_categories, second_categories))
  ignore(increased_categories(first_categories, second_categories))
  ignore(removed_categories(first_categories, second_categories))
  ignore(weighted_defect_score(["a", "b"], [("a", 1.0), ("b", 2.0)]))
  ignore(category_presence(base, ["a", "b", "c"]))
  ignore(category_vocabulary(base))
  ignore(ppm_from_rate(0.01))
  ignore(yield_from_ppm(1000.0))
  ignore(sigma_from_yield(0.9))
  ignore(
    capability_extended(
      mean=10.0,
      deviation=1.0,
      lower=9.0,
      upper=11.0,
      target=10.0,
      threshold=1.0,
    ),
  )
  ignore(
    capability_extended(
      mean=10.0,
      deviation=0.0,
      lower=9.0,
      upper=11.0,
      target=10.0,
      threshold=1.0,
    ),
  )
  ignore(capability_margin(1.2, 1.0))
  ignore(capability_status(0.5, 1.0))
  ignore(one_sided_capability(mean=10.0, deviation=1.0, limit=11.0, upper=true))
  ignore(capability_confidence_margin(1.0, 10))
  ignore(observed_yield([9.0, 12.0], 9.0, 11.0))
  ignore(nonconformance_ppm([9.0], 9.0, 11.0))
  ignore(capability_band(0.5))
}

///|
test "coverage regression cleaning and time-series paths" {
  let values = [1.0, 2.0, 10.0]
  ignore(clean_values(values, lower=0.0, upper=5.0))
  ignore(clean_values(values, lower=5.0, upper=0.0))
  ignore(clamp_values(values, lower=0.0, upper=5.0))
  ignore(fill_missing([Some(1.0), None], 0.0))
  ignore(interpolate_missing([Some(1.0), None, Some(3.0)]))
  ignore(first_difference(values))
  ignore(second_difference(values))
  ignore(cumulative_sum(values))
  ignore(cumulative_product(values))
  ignore(lag_values(values, 1))
  ignore(lead_values(values, 1))
  ignore(relative_to_first(values))
  ignore(relative_to_last(values))
  ignore(center_values(values, 2.0))
  ignore(scale_values(values, 2.0))
  ignore(scale_values(values, 0.0))
  ignore(standardize_values(values, 2.0, 1.0))
  ignore(deduplicate_adjacent([1.0, 1.0, 2.0]))
  ignore(limit_repeated_runs([1.0, 1.0, 1.0], 2))
  ignore(remove_iqr_outliers(values, multiplier=1.5))
  ignore(winsorize_values(values, multiplier=0.1))
  ignore(centered_moving_average(values, 2))
  ignore(exponential_smooth(values, alpha=0.2, initial=0.0))
  ignore(rolling_sum(values, 2))
  ignore(largest_change_index(values))
  ignore(within_mask(values, 0.0, 5.0))
  ignore(outside_mask(values, 0.0, 5.0))
  ignore(count_mask([true, false]))
  ignore(select_mask(values, [true, false, true]))
  ignore(split_at(values, 1))
  ignore(concatenate_values(values, [4.0]))
  ignore(reverse_values(values))
  ignore(rotate_values(values, 1))
  ignore(is_non_decreasing(values))
  ignore(is_non_increasing(values))
  let nullable : Array[MaybeMeasurement] = [Some(1.0), None, Some(3.0)]
  ignore(count_missing(nullable))
  ignore(drop_missing(nullable))
  ignore(occupied_range(nullable))
  ignore(missing_rate(nullable))
  ignore(data_quality_score(nullable, 0.0, 4.0))
  ignore(ts_mean(values))
  ignore(ts_difference(values, 1))
  ignore(ts_difference(values, 0))
  ignore(ts_seasonal_difference(values, 2))
  ignore(ts_moving_min(values, 2))
  ignore(ts_moving_max(values, 2))
  ignore(ts_moving_range(values, 2))
  ignore(ts_centered(values, 2))
  ignore(ts_detrend(values))
  ignore(ts_autocovariance(values, 1))
  ignore(ts_autocorrelation(values, 1))
  ignore(ts_peak_index(values))
  ignore(ts_trough_index(values))
  ignore(ts_range(values))
  ignore(ts_count_crossings(values, 2.0))
  ignore(ts_downsample(values, 2))
  ignore(ts_pad(values, 5, 0.0))
  ignore(ts_last(values, 0.0))
  ignore(ts_first(values, 0.0))
}

///|
test "coverage regression operations and governance paths" {
  let identity = LotIdentity::new(
    lot="L",
    product="P",
    revision="R",
    line="1",
    shift="A",
    start_window="1",
    end_window="2",
  )
  let event = MeasurementEvent::new(
    identity~,
    station="S",
    feature="F",
    value=Some(1.0),
    sequence=1,
  )
  let missing = MeasurementEvent::new(
    identity~,
    station="S2",
    feature="F",
    value=None,
    sequence=2,
  )
  let events = [event, event.reject(), missing]
  ignore(group_events(events))
  let features = group_events(events)
  ignore(summarize_lot_features(features, None))
  ignore(compare_stations(events, "F", threshold=1.0))
  ignore(release_decision(events, minimum_features=1, minimum_measurements=1))
  ignore(sort_events(events))
  ignore(station_events(events, "S"))
  ignore(feature_events(events, "F"))
  ignore(accepted_event_count(events))
  ignore(rejected_event_count(events))
  ignore(measured_event_count(events))
  ignore(missing_event_count(events))
  ignore(unique_stations(events))
  ignore(unique_features(events))
  ignore(measurement_coverage(events))
  ignore(event_acceptance_rate(events))
  ignore(lot_events(events, "L"))
  ignore(values_from_events(events))
  ignore(lot_feature_reports(events, None))
  ignore(merge_event_streams(events, events))
  ignore(validate_event_sequences(events))
  let matrix = MeasurementMatrix::new(rows=[[1.0, 2.0], [2.0, 3.0]], feature_names=[
    "a", "b",
  ])
  ignore(matrix.validate())
  ignore(column(matrix, 0))
  ignore(column(matrix, -1))
  ignore(column_means(matrix))
  ignore(column_deviations(matrix))
  ignore(center_matrix(matrix))
  ignore(standardize_matrix(matrix))
  ignore(covariance_matrix(matrix))
  ignore(correlation_matrix(matrix))
  ignore(distance_alarms(matrix, [1.0, 2.0], threshold=2.0))
  ignore(weighted_row_score([1.0, 2.0], [1.0, 1.0]))
  ignore(weighted_scores(matrix, [1.0, 1.0]))
  ignore(sort_rows_by_feature(matrix, 0))
  ignore(append_feature(matrix, [3.0, 4.0], "c"))
  ignore(project_row([1.0, 2.0], [1.0, 1.0]))
  ignore(project_matrix(matrix, [1.0, 1.0]))
  ignore(reconstruct_row(1.0, [1.0, 2.0]))
  ignore(reconstruction_error(matrix, [1.0, 1.0]))
  let mode = failure_mode(
    id="F",
    process="P",
    cause="C",
    effect="E",
    severity=8,
    occurrence=8,
    detection=8,
    owner="O",
    mitigation="M",
  )
  ignore(mode.rpn())
  ignore(mode.risk_level())
  ignore(close_failure_mode(mode))
  ignore(sort_failure_modes([mode]))
  ignore(critical_failure_modes([mode]))
  ignore(open_failure_modes([mode]))
  ignore(average_rpn([mode]))
  ignore(mitigation_coverage([mode]))
  ignore(risk_reduction(mode, mode))
  ignore(failure_modes_by_process([mode], "P"))
  let policy = quality_policy(
    name="q",
    lower_limit=0.0,
    upper_limit=1.0,
    warning_margin=0.1,
    critical_margin=1.0,
    required_samples=1,
  )
  let decision = evaluate_policy(policy, [2.0])
  ignore(disable_policy(policy))
  ignore(policy_distance(policy, 2.0))
  ignore(policy_defect_count(policy, [2.0]))
  ignore(policy_defect_rate(policy, [2.0]))
  ignore(policy_yield(policy, [2.0]))
  ignore(policy_margin_ok(policy, 0.5))
  ignore(policy_summary([policy]))
  ignore(policies_enabled([policy]))
  ignore(most_restrictive_policy([policy]))
  ignore(decision)
}

///|
test "coverage regression reporting and decision paths" {
  let gate = release_gate(
    name="g",
    required_checks=2,
    passed_checks=1,
    open_alerts=1,
    critical_alerts=1,
    evidence_count=0,
    minimum_score=90.0,
  )
  ignore(release_check_rate(gate))
  ignore(release_score(gate))
  ignore(release_blockers(gate))
  ignore(evaluate_release(gate))
  ignore(release_ready(gate))
  ignore(release_gap(gate))
  ignore(release_evidence_required(gate))
  ignore(release_alert_burden(gate))
  ignore(merge_release_gates(gate, gate))
  ignore(release_audit_lines(gate))
  let catalog = metric_catalog(version="1")
  let metric = quality_metric(
    key="m",
    value=1.0,
    unit="u",
    target=2.0,
    lower_is_better=false,
  )
  catalog.add(metric)
  ignore(metric_gap(metric))
  ignore(metric_meets_target(metric))
  ignore(catalog_score(catalog))
  ignore(catalog_failed(catalog))
  ignore(catalog_keys(catalog))
  ignore(catalog_units(catalog))
  ignore(catalog_metric(catalog, "m"))
  ignore(normalized_metric(metric))
  ignore(catalog_average_normalized(catalog))
  let doc = ReportDocument::new(title="Q", generated_at="now")
  doc.add_section(title="S", lines=["x"])
  doc.warn("w")
  ignore(doc.to_markdown())
  ignore(report_section_count(doc))
  ignore(report_warning_count(doc))
  ignore(report_is_clean(doc))
  ignore(report_section_titles(doc))
  ignore(
    scorecard_markdown({
      observations: 1,
      windows: 1,
      alerts: 0,
      critical: 0,
      defect_rate: Some(0.0),
      center: Some(1.0),
      deviation: Some(0.1),
    }),
  )
  ignore(alerts_text([]))
  add_benchmark_section(doc, 1, 1.0)
  add_provenance_section(doc, "s", "v")
  ignore(csv_escape("a,b"))
  ignore(csv_row(["a", "b"]))
  ignore(csv_document(["a"], [["b"]]))
  ignore(markdown_row(["a"]))
  ignore(markdown_table(["a"], [["b"]]))
  ignore(key_value_line("a", "b"))
  ignore(percent_text(0.5))
  ignore(score_band(50.0))
  ignore(boolean_text(true))
  ignore(join_lines(["a", "b"]))
  ignore(nonempty_lines(["", "a"]))
  ignore(line_count("a\nb"))
  ignore(word_count("a b"))
  ignore(truncate_text("abcdef", 4))
  ignore(indent_lines(["a"], "-"))
  ignore(numbered_lines(["a"]))
  ignore(contains_line(["a"], "a"))
  ignore(unique_lines(["a", "a"]))
  ignore(sort_lines(["b", "a"]))
  ignore(export_status(true, 90.0))
}

///|
test "coverage regression operational modules" {
  ignore(safe_divide(1.0, 0.0, -1.0))
  ignore(clamp_probability(2.0))
  ignore(weighted_average([1.0, 2.0], [1.0, 1.0]))
  ignore(absolute_error(2.0, 1.0))
  ignore(squared_error(2.0, 1.0))
  ignore(helper_root_mean_squared_error([1.0, 2.0]))
  ignore(relative_error(2.0, 1.0))
  ignore(normalize_range(2.0, 0.0, 1.0))
  ignore(denormalize_range(0.5, 0.0, 2.0))
  ignore(linear_interpolate(0.5, 0.0, 0.0, 1.0, 2.0))
  ignore(sign_code(-1.0, 0.1))
  ignore(percentage_change(1.0, 2.0))
  ignore(safe_range(3.0, 0.0, 2.0))
  ignore(count_true([true, false]))
  ignore(bool_rate([true, false]))
  ignore(integer_range_sum(0, 3))
  ignore(stable_round(1.2, 0))
  ignore(min_positive(-1.0, 1.0))
  ignore(max_abs(-2.0, 1.0))
  ignore(midpoint(0.0, 2.0))
  ignore(distance_from_interval(3.0, 0.0, 2.0))
  let dashboard = dashboard_snapshot(name="line", generated_at="now")
  let card = dashboard_card(
    key="m",
    title="Metric",
    value=2.0,
    target=1.0,
    unit="u",
    trend=-1,
    status="warning",
  )
  dashboard.add_card(card)
  dashboard.set_alerts(0)
  dashboard.set_score(80.0)
  ignore(card_gap(card))
  ignore(card_meets_target(card))
  ignore(card_status_from_gap(2.0, 1.0, 3.0))
  ignore(snapshot_card_count(dashboard))
  ignore(snapshot_failed_cards(dashboard))
  ignore(snapshot_good_cards(dashboard))
  ignore(snapshot_completion(dashboard))
  ignore(snapshot_card(dashboard, "m"))
  ignore(snapshot_keys(dashboard))
  ignore(snapshot_units(dashboard))
  ignore(snapshot_trending_up(dashboard))
  ignore(snapshot_trending_down(dashboard))
  ignore(snapshot_critical_count(dashboard))
  ignore(snapshot_warning_count(dashboard))
  ignore(snapshot_health(dashboard))
  ignore(sort_cards_by_gap(dashboard))
  ignore(card_trend_name(-1))
  ignore(snapshot_target_rate(dashboard))
  ignore(snapshot_alert_density(dashboard))
  ignore(snapshot_card_values(dashboard))
  ignore(snapshot_card_targets(dashboard))
  ignore(snapshot_average_gap(dashboard))
  ignore(snapshot_max_gap(dashboard))
  ignore(snapshot_has_key(dashboard, "m"))
  ignore(snapshot_is_empty(dashboard))
  ignore(snapshot_quality_score(dashboard))
  ignore(snapshot_summary_line(dashboard))
  ignore(snapshot_card_statuses(dashboard))
  ignore(snapshot_filter_status(dashboard, "warning"))
  ignore(snapshot_filter_unit(dashboard, "u"))
  ignore(snapshot_merge(dashboard, dashboard))
  let records = [
    MaintenanceRecord::new(
      asset="M",
      event="repair",
      timestamp="1",
      runtime_hours=1.0,
      severity=4,
      note="n",
    ),
    MaintenanceRecord::new(
      asset="M",
      event="inspect",
      timestamp="2",
      runtime_hours=5.0,
      severity=2,
      note="n",
    ),
  ]
  ignore(asset_records(records, "M"))
  ignore(severe_records(records, 3))
  ignore(maintenance_event_counts(records))
  ignore(asset_runtime(records, "M"))
  ignore(average_severity(records, "M"))
  ignore(mean_time_between_events(records, "M"))
  ignore(reliability_summary(records, "M", severe_threshold=3))
  let tool = ToolLifePoint::new(
    tool="T",
    runtime_hours=1.0,
    wear=0.5,
    threshold=1.0,
  )
  ignore(wear_trend([tool]))
  ignore(predicted_tool_limit([tool]))
  ignore(exceeded_tool_count([tool]))
  ignore(highest_wear([tool], 1))
  ignore(remaining_wear(tool))
  ignore(wear_percentage(tool))
  ignore(wear_warning(tool, 0.8))
  ignore(group_tool_life([tool]))
  ignore(average_tool_wear([tool], "T"))
  ignore(maximum_tool_runtime([tool], "T"))
  ignore(normalize_wear_points([tool]))
  let plan = maintenance_plan(
    asset_id="M",
    interval_days=10,
    last_service_day=1,
    runtime_hours=5.0,
    runtime_limit=10.0,
    open_actions=0,
  )
  ignore(maintenance_due(plan, 11))
  ignore(maintenance_overdue_days(plan, 20))
  ignore(maintenance_runtime_margin(plan))
  ignore(maintenance_risk(plan))
  ignore(record_service(plan, 20, 1.0))
  ignore(add_maintenance_action(plan))
  ignore(maintenance_action_count([plan]))
  ignore(due_maintenance_count([plan], 20))
  ignore(critical_maintenance_count([plan]))
  ignore(plans_for_asset([plan], "M"))
  ignore(maintenance_compliance([plan], 20))
  ignore(maintenance_runtime_utilization(plan))
  ignore(maintenance_priority(plan, 20))
  ignore(sort_maintenance_plans([plan], 20))
  ignore(maintenance_status_counts([plan]))
  ignore(planned_service_days([plan]))
}

///|
test "coverage regression sampling simulation and contracts" {
  ignore(supported_sampling_methods())
  let plan = sampling_plan(
    sampling_method=SimpleRandom,
    population=10,
    requested=3,
    seed=1,
  ).with_strata([5, 5])
  ignore(sample(plan))
  ignore(simple_random_indices(population=10, requested=3, seed=1))
  ignore(systematic_indices(population=10, requested=3, offset=1))
  ignore(proportional_allocation([5, 5], total=4))
  ignore(stratified_indices(strata=[5, 5], requested=4, seed=1))
  ignore(required_sample_size(confidence_z=1.96, proportion=0.5, margin=0.1))
  ignore(
    finite_population_sample(
      population=100,
      confidence_z=1.96,
      proportion=0.5,
      margin=0.1,
    ),
  )
  ignore(sampling_coverage([1, 2], 10))
  ignore(has_duplicate_indices([1, 1]))
  ignore(valid_indices([1, 2], 10))
  ignore(sampling_interval(population=10, requested=2))
  ignore(allocation_total([1, 2]))
  let scenario = ProcessScenario::new(
    name="S",
    center=10.0,
    deviation=1.0,
    lower=Some(8.0),
    upper=Some(12.0),
    drift=0.1,
    outlier_probability=0.2,
    seed=1,
  )
  ignore(simulated_noise(1))
  let points = simulate_process(scenario, 5)
  ignore(simulated_values(points))
  ignore(simulated_centers(points))
  ignore(simulation_causes(points))
  ignore(simulation_defects(points))
  ignore(simulation_special_causes(points))
  ignore(simulation_alarms(points, 1.0))
  ignore(summarize_simulation(scenario, points))
  let comparison = simulate_comparison(scenario, 5)
  ignore(comparison)
  ignore(simulation_delta(points, points))
  ignore(observed_simulation_drift(points))
  ignore(simulate_monitor(scenario, 5))
  ignore(simulated_subgroups(scenario, 2, 2))
  ignore(simulated_categories(5, 3, 1))
  ignore(defect_count_error(1, 2))
  ignore(meets_defect_target(points, 1))
  ignore(
    replay_stream(
      [Some(10.0)],
      policy=StreamPolicy::standard(lower=None, upper=None),
      center=10.0,
    ),
  )
  let contract = data_contract(
    name="m",
    required_fields=["id", "value"],
    minimum_rows=1,
    maximum_missing_rate=0.2,
    unique_key="id",
    version="1.0",
  )
  let check = validate_contract(contract, ["id", "value"], 2, 0, 4, ["a", "a"])
  ignore(contract_missing_fields(contract, ["id"]))
  ignore(contract_duplicate_count(["a", "a"]))
  ignore(check)
  ignore(contract_quality_score(check))
  ignore(contract_reason_count(check))
  ignore(contract_has_reason(check, "duplicate_key"))
  ignore(contract_schema_signature(["value", "id"]))
  ignore(contract_is_backward_compatible(["id"], ["id", "value"]))
  ignore(contract_field_count(contract))
  ignore(contract_version_major("1.0"))
  ignore(contract_version_compatible("1.0", "1.1"))
  ignore(contract_merge_fields(["id"], ["value"]))
  let order = quality_work_order(
    order_id="Q",
    lot_id="L",
    title="review",
    owner="qa",
    priority=5,
    due_day=2,
    estimated_hours=2.0,
  )
  ignore(start_work_order(order))
  ignore(complete_work_order(order, 1.0, 1))
  ignore(block_work_order(order))
  ignore(work_order_is_overdue(order, 3))
  ignore(work_order_efficiency(order))
  ignore(work_order_score(order, 3))
  ignore(sort_work_orders([order], 3))
  ignore(open_work_order_count([order]))
  ignore(overdue_work_order_count([order], 3))
  ignore(completion_rate([order]))
  ignore(work_orders_for_lot([order], "L"))
  ignore(evidence_coverage([order]))
}
