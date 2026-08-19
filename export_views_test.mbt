///|
test "export views produce stable text" {
  inspect(csv_row(["a", "b,c"]), content="a,\"b,c\"")
  inspect(score_band(92.0), content="excellent")
  inspect(truncate_text("abcdef", 5), content="ab...")
  inspect(line_count("a\nb"), content="2")
}
