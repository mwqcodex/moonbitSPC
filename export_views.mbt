///|
pub fn csv_escape(value : String) -> String {
  if value.contains(",") || value.contains("\"") || value.contains("\n") {
    "\"" + value.replace(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
pub fn csv_row(values : Array[String]) -> String {
  let builder = StringBuilder()
  for i, value in values {
    if i > 0 {
      builder.write_string(",")
    }
    builder.write_string(csv_escape(value))
  }
  builder.to_string()
}

///|
pub fn csv_document(
  headers : Array[String],
  rows : Array[Array[String]],
) -> String {
  let builder = StringBuilder()
  builder.write_string(csv_row(headers))
  builder.write_string("\n")
  for row in rows {
    builder.write_string(csv_row(row))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
pub fn markdown_row(values : Array[String]) -> String {
  "| " + values.join(" | ") + " |"
}

///|
pub fn markdown_table(
  headers : Array[String],
  rows : Array[Array[String]],
) -> String {
  let builder = StringBuilder()
  builder.write_string(markdown_row(headers))
  builder.write_string("\n")
  let separators : Array[String] = []
  for _ in headers {
    separators.push("---")
  }
  builder.write_string(markdown_row(separators))
  builder.write_string("\n")
  for row in rows {
    builder.write_string(markdown_row(row))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
pub fn key_value_line(key : String, value : String) -> String {
  key + ": " + value
}

///|
pub fn percent_text(value : Double) -> String {
  "\{value*100.0}%"
}

///|
pub fn score_band(score : Double) -> String {
  if score >= 90.0 {
    "excellent"
  } else if score >= 75.0 {
    "good"
  } else if score >= 60.0 {
    "watch"
  } else {
    "critical"
  }
}

///|
pub fn boolean_text(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
pub fn join_lines(lines : Array[String]) -> String {
  lines.join("\n")
}

///|
pub fn nonempty_lines(lines : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for line in lines {
    if line.length() > 0 {
      result.push(line)
    }
  }
  result
}

///|
pub fn line_count(text : String) -> Int {
  text.split("\n").count()
}

///|
pub fn word_count(text : String) -> Int {
  let mut count = 0
  for word in text.split(" ") {
    if word.length() > 0 {
      count += 1
    }
  }
  count
}

///|
pub fn truncate_text(text : String, limit : Int) -> String {
  if limit <= 0 {
    ""
  } else if text.length() <= limit {
    text
  } else {
    text[0:limit - 3].to_owned() + "..."
  }
}

///|
pub fn indent_lines(lines : Array[String], prefix : String) -> Array[String] {
  let result : Array[String] = []
  for line in lines {
    result.push(prefix + line)
  }
  result
}

///|
pub fn numbered_lines(lines : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for i, line in lines {
    result.push("\{i+1}. " + line)
  }
  result
}

///|
pub fn contains_line(lines : Array[String], value : String) -> Bool {
  lines.contains(value)
}

///|
pub fn unique_lines(lines : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for line in lines {
    if !result.contains(line) {
      result.push(line)
    }
  }
  result
}

///|
pub fn sort_lines(lines : Array[String]) -> Array[String] {
  let result = lines.copy()
  result.sort()
  result
}

///|
pub fn export_status(valid : Bool, score : Double) -> String {
  if !valid {
    "invalid"
  } else {
    score_band(score)
  }
}
