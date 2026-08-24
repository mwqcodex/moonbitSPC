# moonbitSPC

`moonbitSPC` is a dependency-light MoonBit library for statistical process
control and manufacturing quality workflows. It provides deterministic,
typed calculations that can be embedded in CLI programs, services, and
WebAssembly applications.

## Included capabilities

- Classical variable and attribute control charts, EWMA, and CUSUM.
- Robust statistics, capability indices, forecasting, trend diagnostics, and
  multivariate checks.
- Streaming monitors, batch and lot aggregation, deterministic simulation,
  sampling plans, and data-quality contracts.
- Maintenance planning, measurement-system studies, FMEA, quality policies,
  release gates, audit evidence, dashboard snapshots, and CSV/Markdown output.
- Production KPI/OEE, quality-cost analysis, deviation/CAPA workflows, batch
  genealogy, and release checklists.

## Checked example

```mbt check
///|
test "package readme example" {
  let group = @moonbitSPC.Subgroup::new(
    values=[9.8, 10.1, 10.0],
    batch="B-01",
    equipment="mill-2",
    tool="T-07",
    operator="op-a",
    window="2026-08-09T10:00Z",
  )
  match
    @moonbitSPC.quality_report(
      [group],
      specification=@moonbitSPC.Specification::new(lower=9.0, upper=11.0),
    ) {
    ReportOk(report) => assert_eq(report.summary.count, 3)
    ReportInvalidInput(message~) => fail(message)
  }
}
```

See [README.md](README.md) for installation, architecture, assumptions,
benchmark details, and the complete local validation commands.
