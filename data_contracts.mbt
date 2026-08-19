///|
pub struct DataContract {
  name : String
  required_fields : Array[String]
  minimum_rows : Int
  maximum_missing_rate : Double
  unique_key : String
  version : String
} derive(Debug, ToJson)

///|
pub struct ContractResult {
  valid : Bool
  row_count : Int
  missing_fields : Array[String]
  missing_rate : Double
  duplicate_keys : Int
  reasons : Array[String]
} derive(Debug, ToJson)

///|
pub fn data_contract(
  name~ : String,
  required_fields~ : Array[String],
  minimum_rows~ : Int,
  maximum_missing_rate~ : Double,
  unique_key~ : String,
  version~ : String,
) -> DataContract {
  {
    name,
    required_fields,
    minimum_rows: minimum_rows.max(0),
    maximum_missing_rate: maximum_missing_rate.max(0.0).min(1.0),
    unique_key,
    version,
  }
}

///|
pub fn contract_missing_fields(
  contract : DataContract,
  fields : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for required in contract.required_fields {
    if !fields.contains(required) {
      result.push(required)
    }
  }
  result
}

///|
pub fn contract_duplicate_count(keys : Array[String]) -> Int {
  let mut count = 0
  let seen : Array[String] = []
  for key in keys {
    if seen.contains(key) {
      count += 1
    } else {
      seen.push(key)
    }
  }
  count
}

///|
pub fn validate_contract(
  contract : DataContract,
  fields : Array[String],
  row_count : Int,
  missing_cells : Int,
  total_cells : Int,
  keys : Array[String],
) -> ContractResult {
  let missing = contract_missing_fields(contract, fields)
  let rate = if total_cells <= 0 {
    0.0
  } else {
    missing_cells.max(0).to_double() / total_cells.to_double()
  }
  let duplicates = contract_duplicate_count(keys)
  let reasons : Array[String] = []
  if missing.length() > 0 {
    reasons.push("missing_fields")
  }
  if row_count < contract.minimum_rows {
    reasons.push("minimum_rows")
  }
  if rate > contract.maximum_missing_rate {
    reasons.push("missing_rate")
  }
  if duplicates > 0 && contract.unique_key.length() > 0 {
    reasons.push("duplicate_key")
  }
  {
    valid: reasons.length() == 0,
    row_count,
    missing_fields: missing,
    missing_rate: rate,
    duplicate_keys: duplicates,
    reasons,
  }
}

///|
pub fn contract_quality_score(result : ContractResult) -> Double {
  let score = 100.0 -
    result.reasons.length().to_double() * 20.0 -
    result.missing_rate * 100.0
  score.max(0.0)
}

///|
pub fn contract_reason_count(result : ContractResult) -> Int {
  result.reasons.length()
}

///|
pub fn contract_has_reason(result : ContractResult, reason : String) -> Bool {
  result.reasons.contains(reason)
}

///|
pub fn contract_schema_signature(fields : Array[String]) -> String {
  let sorted = fields.copy()
  sorted.sort()
  let builder = StringBuilder()
  for i, field in sorted {
    if i > 0 {
      builder.write_string("|")
    }
    builder.write_string(field)
  }
  builder.to_string()
}

///|
pub fn contract_is_backward_compatible(
  old_fields : Array[String],
  new_fields : Array[String],
) -> Bool {
  for field in old_fields {
    if !new_fields.contains(field) {
      return false
    }
  }
  true
}

///|
pub fn contract_field_count(contract : DataContract) -> Int {
  contract.required_fields.length()
}

///|
pub fn contract_version_major(version : String) -> Int {
  if version.length() == 0 {
    0
  } else {
    1
  }
}

///|
pub fn contract_version_compatible(
  old_version : String,
  new_version : String,
) -> Bool {
  contract_version_major(old_version) == contract_version_major(new_version)
}

///|
pub fn contract_merge_fields(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let result = left.copy()
  for field in right {
    if !result.contains(field) {
      result.push(field)
    }
  }
  result
}
