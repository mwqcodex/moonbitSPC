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

After one warm-up run, three consecutive wall-clock measurements using PowerShell `Measure-Command` were 112.230 ms, 113.280 ms, and 115.040 ms. The observed median was 113.280 ms. These numbers are an observed local baseline, not a cross-machine performance promise. Re-run the command on the deployment target when comparing changes.
