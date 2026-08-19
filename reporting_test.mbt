///|
test "report document records sections and warnings" {
  let document = ReportDocument::new(title="Quality", generated_at="today")
  document.add_section(title="Summary", lines=["count=3"])
  document.warn("missing capability")
  inspect(report_section_count(document), content="1")
  inspect(report_warning_count(document), content="1")
  inspect(report_is_clean(document), content="false")
  debug_inspect(report_section_titles(document), content="[\"Summary\"]")
}

///|
test "report markdown contains deterministic headings" {
  let document = ReportDocument::new(title="Quality", generated_at="today")
  add_benchmark_section(document, 100, 2.5)
  add_provenance_section(document, "test", "1")
  let markdown = document.to_markdown()
  inspect(markdown.contains("# Quality"), content="true")
  inspect(markdown.contains("## Benchmark"), content="true")
  inspect(markdown.contains("sample_count=100"), content="true")
}
