///|
test "data contracts validate schema and quality" {
  let contract = data_contract(
    name="measurements",
    required_fields=["lot", "value"],
    minimum_rows=2,
    maximum_missing_rate=0.1,
    unique_key="lot",
    version="1.0",
  )
  let result = validate_contract(contract, ["lot", "value"], 2, 0, 4, ["A", "A"])
  inspect(result.valid, content="false")
  inspect(contract_has_reason(result, "duplicate_key"), content="true")
  inspect(contract_schema_signature(["value", "lot"]), content="lot|value")
}
