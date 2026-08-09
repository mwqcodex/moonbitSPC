///|
test "quality report combines capability and rules" {
  let group = Subgroup::new(
    values=[9.0, 10.0, 11.0],
    batch="B",
    equipment="E",
    tool="T",
    operator="O",
    window="W",
  )
  match
    quality_report(
      [group],
      specification=Specification::new(lower=8.0, upper=12.0),
    ) {
    ReportOk(report) => {
      inspect(report.summary.count, content="3")
      inspect(report.capability is Some(_), content="true")
    }
    ReportInvalidInput(message~) => fail(message)
  }
}
