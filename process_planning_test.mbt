///|
test "capacity planning identifies bottlenecks" {
  let capacity = station_capacity(
    station="CNC",
    available_hours=8.0,
    planned_hours=7.0,
    operators=2,
  )
  inspect(capacity_status(capacity), content="near_limit")
  let stages = [
    stage(name="cut", duration_hours=2.0, required_station="CNC", sequence=1),
    complete_stage(
      stage(
        name="inspect",
        duration_hours=1.0,
        required_station="QA",
        sequence=2,
      ),
    ),
  ]
  inspect(stage_duration(stages), content="3")
  inspect(stage_completion_rate(stages), content="0.5")
}
