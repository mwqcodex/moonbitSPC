///|
test "matrix validation and feature statistics" {
  let matrix = MeasurementMatrix::new(
    rows=[[1.0, 10.0], [2.0, 20.0], [3.0, 30.0]],
    feature_names=["size", "force"],
  )
  inspect(matrix.validate().valid, content="true")
  debug_inspect(column_means(matrix), content="Some([2, 20])")
  debug_inspect(column(matrix, 1), content="Some([10, 20, 30])")
  debug_inspect(dominant_feature(matrix), content="Some(1)")
}

///|
test "matrix alarms and profile deltas" {
  let matrix = MeasurementMatrix::new(
    rows=[[0.0, 0.0], [1.0, 1.0], [5.0, 5.0]],
    feature_names=[],
  )
  let alarms = distance_alarms(matrix, [0.0, 0.0], threshold=2.0)
  assert_true(alarms is Some(_))
  debug_inspect(profile_delta([1.0, 2.0], [2.0, 4.0]), content="Some([1, 2])")
  debug_inspect(weighted_row_score([1.0, 2.0], [2.0, 3.0]), content="Some(8)")
}
