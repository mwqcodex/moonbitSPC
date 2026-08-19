# moonbitSPC

`moonbitSPC` is a dependency-light MoonBit library for statistical process control (SPC) in manufacturing and laboratory measurement software. It turns measured values into deterministic summaries, control-chart points, anomaly rules, capability indices, drift signals, and application-facing quality alerts.

## Core capabilities

- Descriptive statistics: mean, sample deviation, quantiles, median, MAD, IQR, covariance, correlation, rolling windows, histograms, and confidence intervals.
- Control charts: X-bar/R, X-bar/S, I-MR, P, NP, C, U, EWMA, and CUSUM.
- Quality rules: Western Electric rules 1–4, IQR outliers, run length, sign changes, trend and drift scores.
- Process capability: Cp, Cpk, Pp, Ppk, defect rate, specification validation, and pooled deviation.
- Production pipeline helpers: traceable subgroups, input validation, window scorecards, structured alerts, deterministic simulation samples, and forecast baselines.
- Portable output: public data structures with `Debug`/`ToJson` support; no database, plotting, or factory-protocol dependency.

## Quick start

```moonbit
let subgroup = @moonbitSPC.Subgroup::new(
  values=[9.8, 10.1, 10.0], batch="B-01", equipment="mill-2",
  tool="T-07", operator="op-a", window="2026-08-09T10:00Z",
)
match @moonbitSPC.quality_report(
  [subgroup], specification=@moonbitSPC.Specification::new(lower=9.0, upper=11.0),
) {
  @moonbitSPC.ReportOk(report) => println("mean=\{report.summary.mean}")
  @moonbitSPC.ReportInvalidInput(message~) => println(message)
}
```

The repository contains an executable example in `cmd/demo`.

## CLI

```text
moon run cmd/demo
moon check --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
```

The library is intended to be embedded in a MoonBit CLI, service, WebAssembly module, or teaching notebook. It does not read files or print analysis results from the core API; callers own transport and presentation.

## Architecture

The root package is organized by responsibility:

| Area | Files | Responsibility |
| --- | --- | --- |
| Data model | `types.mbt`, `summary.mbt` | Traceability dimensions and descriptive summaries |
| Charts | `charts.mbt`, `extended.mbt` | Classical, EWMA, and CUSUM chart points |
| Rules | `rules.mbt`, `advanced.mbt`, `analytics.mbt` | Western Electric and robust/run diagnostics |
| Capability | `capability.mbt` | Specification-based process indices |
| Pipeline | `pipeline.mbt`, `report.mbt` | Window evaluation, alerts, and reports |

All algorithms are deterministic and operate on owned arrays. Invalid domain inputs return explicit `Option` or result values rather than silently producing a chart.

## Statistical assumptions

Control limits use classical three-sigma formulas and documented subgroup-size constants. Capability indices use sample standard deviation for the current implementation. Attribute charts require non-negative counts and positive exposure; X-bar charts require consistent subgroup sizes. These assumptions are deliberately visible in the API and should be reviewed against the process measurement system before production use.

## Benchmarks

The benchmark command processes a deterministic 10,000-observation sample and reports the computed summary. An observed local timing record and reproducibility notes are in [docs/benchmarks.md](docs/benchmarks.md); hosted-runner wall time is not treated as a performance guarantee.

## Testing and CI

The test suite covers empty and singleton inputs, zero variation, invalid specifications, mismatched lengths, changing exposure, subgroup tails, boundary probabilities, constant trends, outliers, run rules, native execution, and wasm-gc execution.

GitHub Actions runs formatting, strict type checking, generated-interface drift detection, wasm-gc tests, native tests, and coverage analysis on Ubuntu, macOS, and Windows. The workflow installs the latest stable MoonBit toolchain through the official installer.

## License

MIT. See [LICENSE](LICENSE).
