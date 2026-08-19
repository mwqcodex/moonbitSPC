///|
test "inventory reservations remain bounded" {
  let lot = material_lot(
    material_id="steel",
    lot_id="L1",
    quantity=10.0,
    lower_limit=0.0,
    upper_limit=20.0,
  )
  let reserved = reserve_material(lot, 12.0)
  inspect(available_quantity(reserved), content="0")
  inspect(reserved.status, content="reserved")
  inspect(reorder_needed([reserved], 1.0), content="true")
}
