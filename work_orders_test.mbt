///|
test "quality work orders track closure and urgency" {
  let order = quality_work_order(
    order_id="Q1",
    lot_id="L1",
    title="review",
    owner="qa",
    priority=5,
    due_day=3,
    estimated_hours=2.0,
  )
  inspect(work_order_is_overdue(order, 4), content="true")
  let done = complete_work_order(start_work_order(order), 1.0, 2)
  inspect(done.status, content="completed")
  inspect(completion_rate([done]), content="1")
}
