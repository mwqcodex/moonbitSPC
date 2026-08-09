///|
/// A complete deterministic quality analysis result.
pub(all) struct QualityReport {
  summary : Summary
  capability : Capability?
  chart : ControlChart?
  violations : Array[RuleViolation]
} derive(Debug, ToJson)

///|
pub(all) enum ReportResult {
  ReportOk(QualityReport)
  ReportInvalidInput(message~ : String)
} derive(Debug)

///|
/// Assemble descriptive statistics, optional capability, chart, and rules.
pub fn quality_report(
  groups : Array[Subgroup],
  specification? : Specification,
) -> ReportResult {
  let summary_result = match specification {
    Some(spec) => summarize(groups, specification=spec)
    None => summarize(groups)
  }
  match summary_result {
    InvalidInput(message~) => ReportInvalidInput(message~)
    Ok(summary) => {
      let values = flatten(groups)
      let capability_result = match specification {
        Some(spec) =>
          match capability(values, spec) {
            CapabilityOk(result) => Some(result)
            CapabilityInvalidInput(_) => None
          }
        None => None
      }
      let violations = detect_western_electric(
        values,
        mean=summary.mean,
        sigma=summary.standard_deviation,
      )
      ReportOk({
        summary,
        capability: capability_result,
        chart: None,
        violations,
      })
    }
  }
}
