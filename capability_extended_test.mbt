///|
test "extended capability reports yield and status" {
  let result = capability_extended(
    mean=10.0,
    deviation=1.0,
    lower=7.0,
    upper=13.0,
    target=10.0,
    threshold=1.0,
  )
  inspect(result.capable, content="true")
  inspect(capability_status(result.cpk, 1.0), content="capable")
  inspect(capability_band(result.cpk), content="2")
  inspect(
    observed_yield([9.0, 10.0, 14.0], 8.0, 12.0),
    content="0.6666666666666666",
  )
}
