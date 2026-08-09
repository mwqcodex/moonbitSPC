///|
test "capability indices describe a centered process" {
  match
    capability(
      [9.0, 10.0, 11.0, 10.0],
      Specification::new(lower=8.0, upper=12.0),
    ) {
    CapabilityOk(result) => {
      inspect(result.mean, content="10")
      inspect(result.cp > 0.0, content="true")
      inspect(result.cpk > 0.0, content="true")
    }
    CapabilityInvalidInput(message~) => fail(message)
  }
}
