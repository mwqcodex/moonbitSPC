///|
pub(all) enum SamplingMethod {
  SimpleRandom
  Systematic
  Stratified
  Cluster
} derive(Debug, Eq)

///|
pub struct SamplingPlan {
  sampling_method : SamplingMethod
  population : Int
  requested : Int
  seed : Int
  strata : Array[Int]
} derive(Debug)

///|
pub struct SampleResult {
  indices : Array[Int]
  expected_fraction : Double
  valid : Bool
} derive(Debug, ToJson)

///|
pub fn sampling_plan(
  sampling_method~ : SamplingMethod,
  population~ : Int,
  requested~ : Int,
  seed~ : Int,
) -> SamplingPlan {
  { sampling_method, population, requested, seed, strata: [] }
}

///|
/// Return the supported strategies for configuration UIs.
pub fn supported_sampling_methods() -> Array[SamplingMethod] {
  [
    SamplingMethod::SimpleRandom,
    SamplingMethod::Systematic,
    SamplingMethod::Stratified,
    SamplingMethod::Cluster,
  ]
}

///|
pub fn SamplingPlan::with_strata(
  self : SamplingPlan,
  strata : Array[Int],
) -> SamplingPlan {
  { ..self, strata, }
}

///|
fn bounded_count(population : Int, requested : Int) -> Int {
  if population <= 0 || requested <= 0 {
    0
  } else if requested > population {
    population
  } else {
    requested
  }
}

///|
fn lcg(seed : Int) -> Int {
  let value = (seed * 1103515245 + 12345) % 2147483647
  if value < 0 {
    value + 2147483647
  } else {
    value
  }
}

///|
pub fn simple_random_indices(
  population~ : Int,
  requested~ : Int,
  seed~ : Int,
) -> Array[Int] {
  let count = bounded_count(population, requested)
  let result : Array[Int] = []
  let mut state = seed
  while result.length() < count {
    state = lcg(state)
    let index = state % population
    if !result.contains(index) {
      result.push(index)
    }
  }
  result.sort()
  result
}

///|
pub fn systematic_indices(
  population~ : Int,
  requested~ : Int,
  offset~ : Int,
) -> Array[Int] {
  let count = bounded_count(population, requested)
  if count == 0 {
    return []
  }
  let step = if population / count <= 0 { 1 } else { population / count }
  let start = (offset % step + step) % step
  let result : Array[Int] = []
  for i in 0..<count {
    result.push((start + i * step) % population)
  }
  result
}

///|
pub fn proportional_allocation(total~ : Int, strata : Array[Int]) -> Array[Int] {
  let result : Array[Int] = []
  let mut population = 0
  for value in strata {
    population += value
  }
  if population <= 0 || total <= 0 {
    return strata.map(fn(_) { 0 })
  }
  let mut assigned = 0
  for size in strata {
    let value = total * size / population
    result.push(value)
    assigned += value
  }
  let remainder = total - assigned
  if result.length() > 0 && remainder > 0 {
    result[0] += remainder
  }
  result
}

///|
pub fn stratified_indices(
  strata~ : Array[Int],
  requested~ : Int,
  seed~ : Int,
) -> Array[Int] {
  let allocations = proportional_allocation(strata, total=requested)
  let result : Array[Int] = []
  let mut base = 0
  for i, size in strata {
    let selected = simple_random_indices(
      population=size,
      requested=allocations[i],
      seed=seed + i,
    )
    for index in selected {
      result.push(base + index)
    }
    base += size
  }
  result.sort()
  result
}

///|
pub fn sample(plan : SamplingPlan) -> SampleResult {
  let indices = match plan.sampling_method {
    SimpleRandom =>
      simple_random_indices(
        population=plan.population,
        requested=plan.requested,
        seed=plan.seed,
      )
    Systematic =>
      systematic_indices(
        population=plan.population,
        requested=plan.requested,
        offset=plan.seed,
      )
    Stratified =>
      stratified_indices(
        strata=plan.strata,
        requested=plan.requested,
        seed=plan.seed,
      )
    Cluster =>
      systematic_indices(
        population=plan.population,
        requested=plan.requested,
        offset=plan.seed,
      )
  }
  {
    indices,
    expected_fraction: if plan.population <= 0 {
      0.0
    } else {
      indices.length().to_double() / plan.population.to_double()
    },
    valid: indices.length() > 0,
  }
}

///|
pub fn required_sample_size(
  confidence_z~ : Double,
  proportion~ : Double,
  margin~ : Double,
) -> Int {
  if margin <= 0 {
    return 0
  }
  let p = if proportion < 0 {
    0.0
  } else if proportion > 1.0 {
    1.0
  } else {
    proportion
  }
  let raw = confidence_z * confidence_z * p * (1.0 - p) / (margin * margin)
  raw.ceil().to_int()
}

///|
pub fn finite_population_sample(
  population~ : Int,
  confidence_z~ : Double,
  proportion~ : Double,
  margin~ : Double,
) -> Int {
  let base = required_sample_size(confidence_z~, proportion~, margin~)
  if population <= 0 || base <= 0 {
    0
  } else {
    (base * population / (base + population - 1)).min(population)
  }
}

///|
pub fn sampling_coverage(indices : Array[Int], population : Int) -> Double {
  if population <= 0 {
    0.0
  } else {
    indices.length().to_double() / population.to_double()
  }
}

///|
pub fn has_duplicate_indices(indices : Array[Int]) -> Bool {
  for i, value in indices {
    if indices[0:i].contains(value) {
      return true
    }
  }
  false
}

///|
pub fn valid_indices(indices : Array[Int], population : Int) -> Bool {
  for index in indices {
    if index < 0 || index >= population {
      return false
    }
  }
  !has_duplicate_indices(indices)
}

///|
pub fn sampling_interval(population~ : Int, requested~ : Int) -> Double {
  if requested <= 0 {
    0.0
  } else {
    population.to_double() / requested.to_double()
  }
}

///|
pub fn allocation_total(allocation : Array[Int]) -> Int {
  let mut total = 0
  for value in allocation {
    total += value
  }
  total
}
