///|
/// Human-readable quality report sections.
pub(all) struct ReportSection {
  title : String
  lines : Array[String]
} derive(Debug, ToJson)

///|
/// A report document composed from deterministic sections.
pub(all) struct ReportDocument {
  title : String
  generated_at : String
  sections : Array[ReportSection]
  warnings : Array[String]
} derive(Debug, ToJson)

///|
/// Create an empty report document.
pub fn ReportDocument::new(
  title~ : String,
  generated_at~ : String,
) -> ReportDocument {
  { title, generated_at, sections: [], warnings: [] }
}

///|
/// Append a section while preserving insertion order.
pub fn ReportDocument::add_section(
  self : ReportDocument,
  title~ : String,
  lines~ : Array[String],
) -> Unit {
  self.sections.push({ title, lines })
}

///|
/// Append an audit warning.
pub fn ReportDocument::warn(self : ReportDocument, message : String) -> Unit {
  self.warnings.push(message)
}

///|
/// Render a document as Markdown.
pub fn ReportDocument::to_markdown(self : ReportDocument) -> String {
  let builder = StringBuilder()
  builder.write_string("# ")
  builder.write_string(self.title)
  builder.write_string("\n\n")
  builder.write_string("Generated: ")
  builder.write_string(self.generated_at)
  builder.write_string("\n\n")
  for section in self.sections {
    builder.write_string("## ")
    builder.write_string(section.title)
    builder.write_string("\n\n")
    for line in section.lines {
      builder.write_string("- ")
      builder.write_string(line)
      builder.write_string("\n")
    }
    builder.write_string("\n")
  }
  if self.warnings.length() > 0 {
    builder.write_string("## Warnings\n\n")
    for warning in self.warnings {
      builder.write_string("- ")
      builder.write_string(warning)
      builder.write_string("\n")
    }
  }
  builder.to_string()
}

///|
/// Build a summary section from one statistical summary.
pub fn summary_section(summary : Summary) -> ReportSection {
  {
    title: "Summary",
    lines: [
      "count=\{summary.count}",
      "mean=\{summary.mean}",
      "standard_deviation=\{summary.standard_deviation}",
      "minimum=\{summary.minimum}",
      "maximum=\{summary.maximum}",
      "out_of_spec_rate=\{summary.out_of_spec_rate}",
      "batch=\{summary.batch}",
      "equipment=\{summary.equipment}",
      "tool=\{summary.tool}",
      "operator=\{summary.operator}",
      "window=\{summary.window}",
    ],
  }
}

///|
/// Build a capability section.
pub fn capability_section(capability : Capability) -> ReportSection {
  {
    title: "Capability",
    lines: [
      "mean=\{capability.mean}",
      "standard_deviation=\{capability.standard_deviation}",
      "cp=\{capability.cp}",
      "cpk=\{capability.cpk}",
      "pp=\{capability.pp}",
      "ppk=\{capability.ppk}",
      "out_of_spec_rate=\{capability.out_of_spec_rate}",
    ],
  }
}

///|
/// Build a chart section.
pub fn chart_section(chart : ControlChart) -> ReportSection {
  let lines : Array[String] = [
    "kind=\{chart.kind}",
    "center=\{chart.center}",
    "points=\{chart.points.length()}",
  ]
  for point in chart.points {
    lines.push(
      "value=\{point.value}, lower=\{point.lower}, upper=\{point.upper}, alarm=\{point.out_of_control}",
    )
  }
  { title: "Control chart", lines }
}

///|
/// Build a violation section.
pub fn violation_section(violations : Array[RuleViolation]) -> ReportSection {
  let lines : Array[String] = []
  for violation in violations {
    lines.push(
      "rule=\{violation.rule}, start=\{violation.start_index}, indices=\{Repr(violation.indices)}, message=\{violation.message}",
    )
  }
  { title: "Rule violations", lines }
}

///|
/// Build a quality document from a report result.
pub fn document_quality_report(
  result : ReportResult,
  generated_at : String,
) -> ReportDocument {
  let document = ReportDocument::new(title="Quality report", generated_at~)
  match result {
    ReportOk(report) => {
      let summary = summary_section(report.summary)
      document.add_section(title=summary.title, lines=summary.lines)
      match report.capability {
        Some(capability) => {
          let section = capability_section(capability)
          document.add_section(title=section.title, lines=section.lines)
        }
        None => document.warn("capability indices were not available")
      }
      match report.chart {
        Some(chart) => {
          let section = chart_section(chart)
          document.add_section(title=section.title, lines=section.lines)
        }
        None => ()
      }
      let section = violation_section(report.violations)
      document.add_section(title=section.title, lines=section.lines)
    }
    ReportInvalidInput(message~) => document.warn(message)
  }
  document
}

///|
/// Render a scorecard as a compact Markdown table.
pub fn scorecard_markdown(card : Scorecard) -> String {
  "| Metric | Value |\n|---|---|\n| observations | \{card.observations} |\n| windows | \{card.windows} |\n| alerts | \{card.alerts} |\n| critical | \{card.critical} |\n| defect_rate | \{Repr(card.defect_rate)} |\n| center | \{Repr(card.center)} |\n| deviation | \{Repr(card.deviation)} |\n"
}

///|
/// Render an alert list as JSON-compatible text without external dependencies.
pub fn alerts_text(alerts : Array[QualityAlert]) -> String {
  let builder = StringBuilder()
  builder.write_string("[")
  for index, alert in alerts {
    if index > 0 {
      builder.write_string(",")
    }
    builder.write_string("{code:\"")
    builder.write_string(alert.code)
    builder.write_string("\",message:\"")
    builder.write_string(alert.message)
    builder.write_string("\"}")
  }
  builder.write_string("]")
  builder.to_string()
}

///|
/// Add pipeline alerts to an existing document.
pub fn add_alert_section(
  document : ReportDocument,
  alerts : Array[QualityAlert],
) -> Unit {
  let lines : Array[String] = []
  for alert in alerts {
    lines.push(
      "code=\{alert.code}, message=\{alert.message}, index=\{alert.index}",
    )
  }
  document.add_section(title="Alerts", lines~)
}

///|
/// Add benchmark observations to a report.
pub fn add_benchmark_section(
  document : ReportDocument,
  sample_count : Int,
  elapsed_ms : Double,
) -> Unit {
  document.add_section(title="Benchmark", lines=[
    "sample_count=\{sample_count}",
    "elapsed_ms=\{elapsed_ms}",
  ])
}

///|
/// Add a provenance section.
pub fn add_provenance_section(
  document : ReportDocument,
  source : String,
  version : String,
) -> Unit {
  document.add_section(title="Provenance", lines=[
    "source=\{source}",
    "version=\{version}",
  ])
}

///|
/// Count report warnings.
pub fn report_warning_count(document : ReportDocument) -> Int {
  document.warnings.length()
}

///|
/// Count report sections.
pub fn report_section_count(document : ReportDocument) -> Int {
  document.sections.length()
}

///|
/// Return whether a document has no warnings.
pub fn report_is_clean(document : ReportDocument) -> Bool {
  document.warnings.length() == 0
}

///|
/// Return titles for all sections.
pub fn report_section_titles(document : ReportDocument) -> Array[String] {
  let result : Array[String] = []
  for section in document.sections {
    result.push(section.title)
  }
  result
}
