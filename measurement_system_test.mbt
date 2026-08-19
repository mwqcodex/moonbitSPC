///|
test "measurement system metrics" {
  let study = gauge_study(
    readings=[10.0, 10.1, 9.9],
    reference=10.0,
    tolerance=1.0,
    resolution=0.05,
  )
  inspect(study.adequate, content="true")
  inspect(gauge_status(study), content="adequate")
  inspect(stability_range([1.0, 4.0, 2.0]), content="3")
}
