# moonbitSPC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task with verification checkpoints.

**Goal:** Build a reusable, dependency-light MoonBit statistical process control library for manufacturing quality data, with reproducible tests, documentation, CI, and competition-ready repository metadata.

**Architecture:** Keep the public facade in the root package. Separate data summaries, control-chart calculations, Western Electric rules, capability indices, and report assembly into focused files. Use deterministic arrays and explicit result types so the library works for wasm-gc and native targets without external runtime services.

**Tech Stack:** MoonBit 0.10.3-compatible syntax, Moon toolchain, GitHub Actions, MIT License, Markdown.

---

### Task 1: Establish module metadata and test skeleton

**Files:** Create `moon.mod`, `moon.pkg`, `types.mbt`, `types_test.mbt`, `.gitignore`.

- [ ] Add the module metadata for `mwqcodex/moonbitSPC` and a root package with no third-party dependencies.
- [ ] Write failing tests for summary statistics and invalid empty input.
- [ ] Run `moon test` and confirm the tests fail because the API is not implemented.
- [ ] Commit the test skeleton as the first real development commit.

### Task 2: Implement descriptive statistics and manufacturing dimensions

**Files:** Modify `types.mbt`, `types_test.mbt`; create `summary.mbt`, `summary_test.mbt`.

- [ ] Implement `Observation`, `Subgroup`, `Specification`, `Summary`, and `summarize` with mean, sample standard deviation, min, max, and out-of-spec rate.
- [ ] Add subgroup dimensions for batch, equipment, tool, operator, and time window without coupling them to storage.
- [ ] Run targeted tests, then the complete test suite.
- [ ] Commit the tested statistics core.

### Task 3: Implement control-chart engines

**Files:** Create `charts.mbt`, `charts_test.mbt`.

- [ ] Add chart kinds XBarR, XBarS, IMR, P, NP, C, and U.
- [ ] Implement a common `ChartPoint`/`ControlChart` result shape with center line, upper/lower limits, and out-of-control flags.
- [ ] Use standard constants and document assumptions for subgroup size and count/exposure inputs.
- [ ] Add tests covering nominal limits, varying subgroup sizes, and invalid inputs.
- [ ] Run format, check, and tests; commit the chart engine.

### Task 4: Implement Western Electric rules

**Files:** Create `rules.mbt`, `rules_test.mbt`.

- [ ] Implement rules for one point beyond 3 sigma, two of three beyond 2 sigma, four of five beyond 1 sigma, and eight consecutive points on one side.
- [ ] Return structured violations with rule number, start index, and affected indices.
- [ ] Add focused tests for positive and negative-side detections and short sequences.
- [ ] Commit the anomaly rule engine.

### Task 5: Implement process capability and quality reports

**Files:** Create `capability.mbt`, `capability_test.mbt`, `report.mbt`, `report_test.mbt`.

- [ ] Implement Cp, Cpk, Pp, Ppk, mean, standard deviation, and defect rate against bilateral specifications.
- [ ] Assemble deterministic `QualityReport` values combining summary, capability, chart points, and rule violations.
- [ ] Add tests for centered, shifted, and specification-free cases.
- [ ] Commit reporting and capability analysis.

### Task 6: Add examples, documentation, license, and competition materials

**Files:** Create `README.md`, `README.mbt.md`, `LICENSE`, `CHANGELOG.md`, `DEVELOPMENT.md`, `申报书.md`, `examples/basic.mbt`, `examples/moon.pkg`.

- [ ] Document installation, API examples, supported chart types, assumptions, reproducibility, and extension roadmap.
- [ ] Add a short human-readable development history explaining design choices and AI-assisted workflow transparently.
- [ ] Add exactly one-page Markdown proposal in `申报书.md`.
- [ ] Add an executable example and checked Markdown snippets.
- [ ] Commit documentation and examples.

### Task 7: Add CI and toolchain checks

**Files:** Create `.github/workflows/test.yml`, `.github/workflows/ci.yml`.

- [ ] Add GitHub Actions for Ubuntu, macOS, and Windows setup using the official Moon installer and run `moon fmt --deny-warn`, `moon check --deny-warn`, `moon info --deny-warn`, `moon test --deny-warn`, and native tests.
- [ ] Make generated interface files and formatting drift fail the workflow.
- [ ] Add a lightweight CLI check matching the referenced workflow.
- [ ] Commit CI configuration.

### Task 8: Quality gate, scale audit, and remote publication

- [ ] Run fresh local verification for format, check, info, wasm-gc tests, native tests, example execution, and CLI checks.
- [ ] Count effective MoonBit source lines and report the actual value; do not inflate counts with generated or blank lines.
- [ ] Create at least 10 meaningful commits per remote history while keeping one author identity.
- [ ] Create and push GitHub and Gitlink repositories using the explicitly authorized credentials, set the default branch, and verify remotes, branches, commit authors, and repository contents.
- [ ] Generate a final self-audit covering structure, README, license, history, branch, source scale, source attribution, and unresolved risks.
