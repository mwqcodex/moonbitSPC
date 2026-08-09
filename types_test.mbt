///|
test "summary rejects empty observations" {
  match summarize([]) {
    InvalidInput(message~) =>
      inspect(message, content="observations must not be empty")
    _ => fail("expected empty input to be rejected")
  }
}

///|
test "summary exposes manufacturing dimensions" {
  let subgroup = Subgroup::new(
    values=[10.0, 11.0, 9.0],
    batch="B-01",
    equipment="mill-2",
    tool="T-07",
    operator="op-a",
    window="2026-08-09T10:00Z",
  )
  let result = summarize([subgroup])
  match result {
    Ok(summary) => {
      inspect(summary.count, content="3")
      inspect(summary.mean, content="10")
      inspect(summary.batch, content="B-01")
    }
    InvalidInput(message~) => fail(message)
  }
}
