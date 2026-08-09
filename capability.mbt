///|
/// Process capability indices for a bilateral specification.
pub(all) struct Capability {
  mean : Double
  standard_deviation : Double
  cp : Double
  cpk : Double
  pp : Double
  ppk : Double
  out_of_spec_rate : Double
} derive(Debug, ToJson)

///|
pub(all) enum CapabilityResult {
  CapabilityOk(Capability)
  CapabilityInvalidInput(message~ : String)
} derive(Debug)

///|
/// Calculate short-term and overall capability indices.
pub fn capability(
  values : Array[Double],
  specification : Specification,
) -> CapabilityResult {
  if values.length() < 2 || specification.lower >= specification.upper {
    CapabilityInvalidInput(
      message="capability needs two observations and lower < upper",
    )
  } else {
    let mean = mean_of(values)
    let standard_deviation = std_of(values, mean)
    if standard_deviation <= 0.0 {
      CapabilityInvalidInput(message="capability needs non-zero variation")
    } else {
      let spread = specification.upper - specification.lower
      let cp = spread / (6.0 * standard_deviation)
      let cpk = ((specification.upper - mean) / (3.0 * standard_deviation)).min(
        (mean - specification.lower) / (3.0 * standard_deviation),
      )
      let pp = cp
      let ppk = cpk
      let mut defects = 0
      for value in values {
        if value < specification.lower || value > specification.upper {
          defects += 1
        }
      }
      CapabilityOk({
        mean,
        standard_deviation,
        cp,
        cpk,
        pp,
        ppk,
        out_of_spec_rate: defects.to_double() / values.length().to_double(),
      })
    }
  }
}
