///|
/// A small deterministic command-line demonstration.
fn main {
  let group = @spc.Subgroup::new(
    values=[9.8, 10.1, 10.0],
    batch="B-01",
    equipment="mill-2",
    tool="T-07",
    operator="op-a",
    window="2026-08-09T10:00Z",
  )
  match
    @spc.quality_report(
      [group],
      specification=@spc.Specification::new(lower=9.0, upper=11.0),
    ) {
    @spc.ReportOk(report) =>
      println("mean=\{report.summary.mean}, count=\{report.summary.count}")
    @spc.ReportInvalidInput(message~) => println("invalid input: \{message}")
  }
}
