# Benchmark record

This record is intentionally small and reproducible. It measures the executable benchmark workload, including the first-run MoonBit build/run path, on the local Windows workstation used for validation.

Command:

```text
moon run cmd/benchmark
```

Correctness output from the workload:

```text
sample=10000 windows=1000 alerts=141 critical=0
```

Three consecutive wall-clock measurements using PowerShell `Measure-Command` were 188.002 ms, 164.004 ms, and 164.174 ms. The first run includes additional cache/build work; the steady-state median of the latter two runs was 164.089 ms. These numbers are an observed local baseline, not a cross-machine performance promise. Re-run the command on the deployment target when comparing changes.
