///|
/// Deterministic benchmark workload for release notes and local comparisons.
fn main {
  let values = @spc.sample_uniform(10000, seed=20260820, lower=9.0, upper=11.0)
  let windows = match
    @spc.windows_from_values(
      values,
      10,
      specification=@spc.Specification::new(lower=9.0, upper=11.0),
    ) {
    Some(result) => result
    None => []
  }
  let card = @spc.scorecard(windows)
  println(
    "sample=\{card.observations} windows=\{card.windows} alerts=\{card.alerts} critical=\{card.critical}",
  )
}
