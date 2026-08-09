///|
/// A measured subgroup together with the manufacturing dimensions that produced it.
pub(all) struct Subgroup {
  values : Array[Double]
  batch : String
  equipment : String
  tool : String
  operator : String
  window : String
} derive(Debug, ToJson)

///|
/// Build a measured subgroup with stable traceability dimensions.
pub fn Subgroup::new(
  values~ : Array[Double],
  batch~ : String,
  equipment~ : String,
  tool~ : String,
  operator~ : String,
  window~ : String,
) -> Subgroup {
  { values, batch, equipment, tool, operator, window }
}

///|
/// A specification window used by capability analysis.
pub(all) struct Specification {
  lower : Double
  upper : Double
} derive(Debug, ToJson)

///|
/// Construct a bilateral specification window.
pub fn Specification::new(lower~ : Double, upper~ : Double) -> Specification {
  { lower, upper }
}

///|
/// Descriptive statistics for a set of measurements.
pub(all) struct Summary {
  count : Int
  mean : Double
  standard_deviation : Double
  minimum : Double
  maximum : Double
  out_of_spec_rate : Double
  batch : String
  equipment : String
  tool : String
  operator : String
  window : String
} derive(Debug, ToJson)

///|
/// The result of summarizing one or more subgroups.
pub(all) enum SummaryResult {
  Ok(Summary)
  InvalidInput(message~ : String)
} derive(Debug)
