///|
test "metric catalog scores targets" {
  let catalog = metric_catalog(version="1")
  catalog.add(
    quality_metric(
      key="cpk",
      value=1.5,
      unit="index",
      target=1.33,
      lower_is_better=false,
    ),
  )
  catalog.add(
    quality_metric(
      key="ppm",
      value=20.0,
      unit="ppm",
      target=50.0,
      lower_is_better=true,
    ),
  )
  inspect(catalog_score(catalog), content="100")
  inspect(catalog_metric(catalog, "cpk").unwrap().key, content="cpk")
}
