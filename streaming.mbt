///|
/// Mutable online state for a long-running measurement stream.
pub(all) struct StreamAccumulator {
  mut count : Int
  mut sum : Double
  mut sum_squared : Double
  mut minimum : Double?
  mut maximum : Double?
  mut last : Double?
  mut missing : Int
  mut out_of_spec : Int
  lower : Double?
  upper : Double?
} derive(Debug, ToJson)

///|
/// Create an empty online accumulator.
pub fn StreamAccumulator::new(
  lower~ : Double?,
  upper~ : Double?,
) -> StreamAccumulator {
  {
    count: 0,
    sum: 0.0,
    sum_squared: 0.0,
    minimum: None,
    maximum: None,
    last: None,
    missing: 0,
    out_of_spec: 0,
    lower,
    upper,
  }
}

///|
/// Add one optional measurement and update all online counters.
pub fn StreamAccumulator::push(
  self : StreamAccumulator,
  value : Double?,
) -> Unit {
  match value {
    None => self.missing += 1
    Some(number) => {
      self.count += 1
      self.sum += number
      self.sum_squared += number * number
      self.minimum = match self.minimum {
        None => Some(number)
        Some(old) => Some(old.min(number))
      }
      self.maximum = match self.maximum {
        None => Some(number)
        Some(old) => Some(old.max(number))
      }
      self.last = Some(number)
      match (self.lower, self.upper) {
        (Some(lower), Some(upper)) =>
          if number < lower || number > upper {
            self.out_of_spec += 1
          }
        _ => ()
      }
    }
  }
}

///|
/// Add every item in an optional series.
pub fn StreamAccumulator::push_all(
  self : StreamAccumulator,
  values : Array[MaybeMeasurement],
) -> Unit {
  for value in values {
    self.push(value)
  }
}

///|
/// Online arithmetic mean.
pub fn StreamAccumulator::mean(self : StreamAccumulator) -> Double? {
  if self.count == 0 {
    None
  } else {
    Some(self.sum / self.count.to_double())
  }
}

///|
/// Online population variance with cancellation protection.
pub fn StreamAccumulator::variance(self : StreamAccumulator) -> Double? {
  if self.count == 0 {
    None
  } else {
    let mean = self.sum / self.count.to_double()
    Some((self.sum_squared / self.count.to_double() - mean * mean).max(0.0))
  }
}

///|
/// Online sample deviation.
pub fn StreamAccumulator::deviation(self : StreamAccumulator) -> Double? {
  if self.count < 2 {
    None
  } else {
    Some(
      ((self.sum_squared - self.sum * self.sum / self.count.to_double()).max(
        0.0,
      ) /
      (self.count - 1).to_double()).sqrt(),
    )
  }
}

///|
/// Observed defect rate when a specification was configured.
pub fn StreamAccumulator::defect_rate(self : StreamAccumulator) -> Double? {
  if self.count == 0 || self.lower is None || self.upper is None {
    None
  } else {
    Some(self.out_of_spec.to_double() / self.count.to_double())
  }
}

///|
/// Current span if at least one value has arrived.
pub fn StreamAccumulator::span(self : StreamAccumulator) -> Double? {
  match (self.minimum, self.maximum) {
    (Some(low), Some(high)) => Some(high - low)
    _ => None
  }
}

///|
/// Merge another stream accumulator into this one.
pub fn StreamAccumulator::merge(
  self : StreamAccumulator,
  other : StreamAccumulator,
) -> Unit {
  self.count += other.count
  self.sum += other.sum
  self.sum_squared += other.sum_squared
  self.missing += other.missing
  self.out_of_spec += other.out_of_spec
  self.minimum = match (self.minimum, other.minimum) {
    (None, value) => value
    (value, None) => value
    (Some(first), Some(second)) => Some(first.min(second))
  }
  self.maximum = match (self.maximum, other.maximum) {
    (None, value) => value
    (value, None) => value
    (Some(first), Some(second)) => Some(first.max(second))
  }
  self.last = other.last
}

///|
/// Snapshot useful for a dashboard card.
pub(all) struct StreamSnapshot {
  count : Int
  missing : Int
  mean : Double?
  deviation : Double?
  minimum : Double?
  maximum : Double?
  defect_rate : Double?
  last : Double?
} derive(Debug, ToJson)

///|
pub fn StreamAccumulator::snapshot(self : StreamAccumulator) -> StreamSnapshot {
  {
    count: self.count,
    missing: self.missing,
    mean: self.mean(),
    deviation: self.deviation(),
    minimum: self.minimum,
    maximum: self.maximum,
    defect_rate: self.defect_rate(),
    last: self.last,
  }
}

///|
/// A fixed-size ring buffer for recent measurements.
pub(all) struct MeasurementRing {
  capacity : Int
  values : Array[Double]
  mut next : Int
} derive(Debug, ToJson)

///|
pub fn MeasurementRing::new(capacity : Int) -> MeasurementRing {
  { capacity: capacity.max(0), values: [], next: 0 }
}

///|
/// Push into a ring, dropping the oldest value when full.
pub fn MeasurementRing::push(self : MeasurementRing, value : Double) -> Unit {
  if self.capacity > 0 {
    if self.values.length() < self.capacity {
      self.values.push(value)
    } else {
      self.values[self.next] = value
      self.next = (self.next + 1) % self.capacity
    }
  }
}

///|
/// Number of retained values.
pub fn MeasurementRing::length(self : MeasurementRing) -> Int {
  self.values.length()
}

///|
/// Return values ordered oldest to newest.
pub fn MeasurementRing::ordered(self : MeasurementRing) -> Array[Double] {
  if self.values.length() < self.capacity || self.capacity == 0 {
    self.values.copy()
  } else {
    let output : Array[Double] = []
    for index in 0..<self.capacity {
      output.push(self.values[(self.next + index) % self.capacity])
    }
    output
  }
}

///|
/// Mean of the retained ring window.
pub fn MeasurementRing::mean(self : MeasurementRing) -> Double? {
  let values = self.ordered()
  if values.length() == 0 {
    None
  } else {
    Some(mean_of(values))
  }
}

///|
/// Deviation of the retained ring window.
pub fn MeasurementRing::deviation(self : MeasurementRing) -> Double? {
  let values = self.ordered()
  if values.length() < 2 {
    None
  } else {
    Some(std_of(values, mean_of(values)))
  }
}

///|
/// Return the newest retained measurement.
pub fn MeasurementRing::last(self : MeasurementRing) -> Double? {
  if self.values.length() == 0 {
    None
  } else {
    let values = self.ordered()
    Some(values[values.length() - 1])
  }
}

///|
/// Online EWMA state.
pub(all) struct EWMAStep {
  value : Double
  center : Double
  alarm : Bool
} derive(Debug, ToJson)

///|
pub(all) struct EWMAStream {
  lambda : Double
  mut state : Double
  center : Double
  limit : Double
  mut steps : Int
} derive(Debug, ToJson)

///|
pub fn EWMAStream::new(
  lambda~ : Double,
  center~ : Double,
  limit~ : Double,
) -> EWMAStream {
  {
    lambda: lambda.max(0.0).min(1.0),
    state: center,
    center,
    limit: limit.abs(),
    steps: 0,
  }
}

///|
/// Update EWMA and return the point-level alarm decision.
pub fn EWMAStream::push(self : EWMAStream, value : Double) -> EWMAStep {
  self.state = self.lambda * value + (1.0 - self.lambda) * self.state
  self.steps += 1
  {
    value,
    center: self.state,
    alarm: (self.state - self.center).abs() > self.limit,
  }
}

///|
/// Reset EWMA state without changing its policy.
pub fn EWMAStream::reset(self : EWMAStream) -> Unit {
  self.state = self.center
  self.steps = 0
}

///|
/// Online CUSUM state.
pub(all) struct CUSUMStream {
  target : Double
  allowance : Double
  decision : Double
  mut positive : Double
  mut negative : Double
  mut steps : Int
} derive(Debug, ToJson)

///|
pub fn CUSUMStream::new(
  target~ : Double,
  allowance~ : Double,
  decision~ : Double,
) -> CUSUMStream {
  {
    target,
    allowance: allowance.max(0.0),
    decision: decision.abs(),
    positive: 0.0,
    negative: 0.0,
    steps: 0,
  }
}

///|
/// Update two-sided CUSUM state.
pub fn CUSUMStream::push(self : CUSUMStream, value : Double) -> Bool {
  self.positive = (self.positive + value - self.target - self.allowance).max(
    0.0,
  )
  self.negative = (self.negative + self.target - self.allowance - value).max(
    0.0,
  )
  self.steps += 1
  self.positive >= self.decision || self.negative >= self.decision
}

///|
/// Clear accumulated evidence after an operator acknowledgement.
pub fn CUSUMStream::acknowledge(self : CUSUMStream) -> Unit {
  self.positive = 0.0
  self.negative = 0.0
}

///|
/// Current signed CUSUM statistic.
pub fn CUSUMStream::score(self : CUSUMStream) -> Double {
  if self.positive >= self.negative {
    self.positive
  } else {
    -self.negative
  }
}

///|
/// A stream policy combines recent-window and cumulative alarms.
pub(all) struct StreamPolicy {
  lower : Double?
  upper : Double?
  ring_capacity : Int
  ewma_lambda : Double
  ewma_limit : Double
  cusum_allowance : Double
  cusum_decision : Double
} derive(Debug, ToJson)

///|
/// Create a conservative production policy.
pub fn StreamPolicy::standard(
  lower~ : Double?,
  upper~ : Double?,
) -> StreamPolicy {
  {
    lower,
    upper,
    ring_capacity: 25,
    ewma_lambda: 0.2,
    ewma_limit: 3.0,
    cusum_allowance: 0.5,
    cusum_decision: 5.0,
  }
}

///|
/// Change the retained-window capacity.
pub fn StreamPolicy::with_capacity(
  self : StreamPolicy,
  capacity : Int,
) -> StreamPolicy {
  { ..self, ring_capacity: capacity.max(0) }
}

///|
/// Change EWMA smoothing and limit policy.
pub fn StreamPolicy::with_ewma(
  self : StreamPolicy,
  lambda : Double,
  limit : Double,
) -> StreamPolicy {
  { ..self, ewma_lambda: lambda, ewma_limit: limit }
}

///|
/// Change CUSUM sensitivity.
pub fn StreamPolicy::with_cusum(
  self : StreamPolicy,
  allowance : Double,
  decision : Double,
) -> StreamPolicy {
  { ..self, cusum_allowance: allowance, cusum_decision: decision }
}

///|
/// Full state for a running policy evaluation.
pub(all) struct StreamMonitor {
  policy : StreamPolicy
  accumulator : StreamAccumulator
  recent : MeasurementRing
  ewma : EWMAStream
  cusum : CUSUMStream
} derive(Debug, ToJson)

///|
/// Create a monitor from a policy and process center.
pub fn StreamMonitor::new(
  policy~ : StreamPolicy,
  center~ : Double,
) -> StreamMonitor {
  {
    policy,
    accumulator: StreamAccumulator::new(lower=policy.lower, upper=policy.upper),
    recent: MeasurementRing::new(policy.ring_capacity),
    ewma: EWMAStream::new(
      lambda=policy.ewma_lambda,
      center~,
      limit=policy.ewma_limit,
    ),
    cusum: CUSUMStream::new(
      target=center,
      allowance=policy.cusum_allowance,
      decision=policy.cusum_decision,
    ),
  }
}

///|
/// Push a value and return whether any monitor alarm fired.
pub fn StreamMonitor::push(self : StreamMonitor, value : Double?) -> Bool {
  self.accumulator.push(value)
  match value {
    None => false
    Some(number) => {
      self.recent.push(number)
      let ewma_alarm = self.ewma.push(number).alarm
      let cusum_alarm = self.cusum.push(number)
      ewma_alarm || cusum_alarm
    }
  }
}

///|
/// Current stream snapshot.
pub fn StreamMonitor::snapshot(self : StreamMonitor) -> StreamSnapshot {
  self.accumulator.snapshot()
}

///|
/// Current recent-window chart.
pub fn StreamMonitor::recent_chart(self : StreamMonitor) -> ChartResult {
  let values = self.recent.ordered()
  if values.length() < 2 {
    ChartInvalidInput(message="recent window needs two values")
  } else {
    ControlChart::imr(values)
  }
}

///|
/// Reset cumulative alarm state while keeping measurements.
pub fn StreamMonitor::acknowledge(self : StreamMonitor) -> Unit {
  self.cusum.acknowledge()
  self.ewma.reset()
}

///|
/// Count alarms in a deterministic stream replay.
pub fn replay_stream(
  values : Array[MaybeMeasurement],
  policy~ : StreamPolicy,
  center~ : Double,
) -> Int {
  let monitor = StreamMonitor::new(policy~, center~)
  let mut alarms = 0
  for value in values {
    if monitor.push(value) {
      alarms += 1
    }
  }
  alarms
}

///|
/// Compute a batch snapshot through the online path.
pub fn online_snapshot(
  values : Array[Double],
  lower~ : Double?,
  upper~ : Double?,
) -> StreamSnapshot {
  let accumulator = StreamAccumulator::new(lower~, upper~)
  for value in values {
    accumulator.push(Some(value))
  }
  accumulator.snapshot()
}
