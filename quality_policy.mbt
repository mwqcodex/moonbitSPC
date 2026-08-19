///|
pub struct QualityPolicy {
  name : String
  lower_limit : Double
  upper_limit : Double
  warning_margin : Double
  critical_margin : Double
  required_samples : Int
  enabled : Bool
} derive(Debug, ToJson)

///|
pub struct PolicyDecision {
  accepted : Bool
  warning : Bool
  critical : Bool
  reason : String
  score : Double
} derive(Debug, ToJson)

///|
pub fn quality_policy(
  name~ : String,
  lower_limit~ : Double,
  upper_limit~ : Double,
  warning_margin~ : Double,
  critical_margin~ : Double,
  required_samples~ : Int,
) -> QualityPolicy {
  {
    name,
    lower_limit,
    upper_limit,
    warning_margin: warning_margin.max(0.0),
    critical_margin: critical_margin.max(0.0),
    required_samples: required_samples.max(1),
    enabled: true,
  }
}

///|
pub fn disable_policy(policy : QualityPolicy) -> QualityPolicy {
  { ..policy, enabled: false }
}

///|
pub fn policy_distance(policy : QualityPolicy, value : Double) -> Double {
  if value < policy.lower_limit {
    policy.lower_limit - value
  } else if value > policy.upper_limit {
    value - policy.upper_limit
  } else {
    0.0
  }
}

///|
pub fn evaluate_policy(
  policy : QualityPolicy,
  values : Array[Double],
) -> PolicyDecision {
  if !policy.enabled {
    return {
      accepted: true,
      warning: false,
      critical: false,
      reason: "disabled",
      score: 0.0,
    }
  }
  if values.length() < policy.required_samples {
    return {
      accepted: false,
      warning: false,
      critical: true,
      reason: "insufficient_samples",
      score: 0.0,
    }
  }
  let mut worst = 0.0
  for value in values {
    worst = worst.max(policy_distance(policy, value))
  }
  let critical = worst > policy.critical_margin
  let warning = worst > policy.warning_margin
  {
    accepted: !critical,
    warning,
    critical,
    reason: if critical {
      "critical_out_of_spec"
    } else if warning {
      "warning_margin"
    } else {
      "within_policy"
    },
    score: worst,
  }
}

///|
pub fn policy_defect_count(
  policy : QualityPolicy,
  values : Array[Double],
) -> Int {
  let mut count = 0
  for value in values {
    if policy_distance(policy, value) > 0.0 {
      count += 1
    }
  }
  count
}

///|
pub fn policy_defect_rate(
  policy : QualityPolicy,
  values : Array[Double],
) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    policy_defect_count(policy, values).to_double() /
    values.length().to_double()
  }
}

///|
pub fn policy_yield(policy : QualityPolicy, values : Array[Double]) -> Double {
  1.0 - policy_defect_rate(policy, values)
}

///|
pub fn policy_margin_ok(policy : QualityPolicy, value : Double) -> Bool {
  policy_distance(policy, value) <= policy.warning_margin
}

///|
pub fn policy_summary(policies : Array[QualityPolicy]) -> Array[String] {
  let result : Array[String] = []
  for policy in policies {
    result.push(policy.name)
  }
  result
}

///|
pub fn policies_enabled(policies : Array[QualityPolicy]) -> Int {
  let mut count = 0
  for policy in policies {
    if policy.enabled {
      count += 1
    }
  }
  count
}

///|
pub fn most_restrictive_policy(
  policies : Array[QualityPolicy],
) -> QualityPolicy? {
  if policies.length() == 0 {
    None
  } else {
    let mut result = policies[0]
    for policy in policies[1:] {
      if policy.warning_margin < result.warning_margin {
        result = policy
      }
    }
    Some(result)
  }
}
