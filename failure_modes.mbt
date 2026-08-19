///|
pub struct FailureMode {
  id : String
  process : String
  cause : String
  effect : String
  severity : Int
  occurrence : Int
  detection : Int
  owner : String
  mitigation : String
  closed : Bool
} derive(Debug, ToJson)

///|
pub fn failure_mode(
  id~ : String,
  process~ : String,
  cause~ : String,
  effect~ : String,
  severity~ : Int,
  occurrence~ : Int,
  detection~ : Int,
  owner~ : String,
  mitigation~ : String,
) -> FailureMode {
  {
    id,
    process,
    cause,
    effect,
    severity: severity.max(1).min(10),
    occurrence: occurrence.max(1).min(10),
    detection: detection.max(1).min(10),
    owner,
    mitigation,
    closed: false,
  }
}

///|
pub fn FailureMode::rpn(self : FailureMode) -> Int {
  self.severity * self.occurrence * self.detection
}

///|
pub fn FailureMode::risk_level(self : FailureMode) -> String {
  let score = self.rpn()
  if score >= 200 {
    "critical"
  } else if score >= 100 {
    "high"
  } else if score >= 50 {
    "medium"
  } else {
    "low"
  }
}

///|
pub fn close_failure_mode(mode : FailureMode) -> FailureMode {
  { ..mode, closed: true }
}

///|
pub fn sort_failure_modes(modes : Array[FailureMode]) -> Array[FailureMode] {
  let result = modes.copy()
  result.sort_by(fn(a, b) { b.rpn() - a.rpn() })
  result
}

///|
pub fn critical_failure_modes(modes : Array[FailureMode]) -> Array[FailureMode] {
  let result : Array[FailureMode] = []
  for mode in modes {
    if mode.rpn() >= 200 {
      result.push(mode)
    }
  }
  result
}

///|
pub fn open_failure_modes(modes : Array[FailureMode]) -> Int {
  let mut count = 0
  for mode in modes {
    if !mode.closed {
      count += 1
    }
  }
  count
}

///|
pub fn average_rpn(modes : Array[FailureMode]) -> Double {
  if modes.length() == 0 {
    0.0
  } else {
    let mut total = 0
    for mode in modes {
      total += mode.rpn()
    }
    total.to_double() / modes.length().to_double()
  }
}

///|
pub fn mitigation_coverage(modes : Array[FailureMode]) -> Double {
  if modes.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for mode in modes {
      if mode.mitigation.length() > 0 {
        count += 1
      }
    }
    count.to_double() / modes.length().to_double()
  }
}

///|
pub fn risk_reduction(before : FailureMode, after : FailureMode) -> Double {
  let old = before.rpn().to_double()
  if old <= 0.0 {
    0.0
  } else {
    (old - after.rpn().to_double()) / old
  }
}

///|
pub fn failure_modes_by_process(
  modes : Array[FailureMode],
  process : String,
) -> Array[FailureMode] {
  let result : Array[FailureMode] = []
  for mode in modes {
    if mode.process == process {
      result.push(mode)
    }
  }
  result
}
