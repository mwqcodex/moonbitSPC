# Development guide

`moonbitSPC` follows a contract-first workflow: observable results are fixed in
tests before implementation details are expanded. The package is deliberately
dependency-light so that manufacturing applications can review the formulas,
data validation, and traceability fields without depending on a database,
plotting engine, or factory protocol.

## Local checks

```text
moon fmt --check
moon check --deny-warn
moon check --target all --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
moon run cmd/demo
moon run cmd/benchmark
```

## Design boundaries

The root package owns deterministic calculations and application-facing result
types. File, database, network, and visualization adapters belong in consuming
applications. New algorithms should document their statistical assumptions,
validate domain inputs, and include empty, singleton, boundary, invalid, and
out-of-spec cases in a dedicated `*_test.mbt` file.

## Contributions

Keep public APIs small and typed, preserve wasm-gc and native compatibility,
run the complete local check sequence before opening a change, and update the
changelog and benchmark record when externally visible behavior changes.
