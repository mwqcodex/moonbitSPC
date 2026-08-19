///|
test "quality policy separates warning and critical values" {
  let policy = quality_policy(
    name="diameter",
    lower_limit=9.0,
    upper_limit=11.0,
    warning_margin=0.2,
    critical_margin=1.0,
    required_samples=2,
  )
  let decision = evaluate_policy(policy, [10.0, 11.3])
  inspect(decision.accepted, content="true")
  inspect(decision.warning, content="true")
  inspect(policy_defect_count(policy, [8.0, 10.0]), content="1")
}
