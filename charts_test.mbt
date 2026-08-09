///|
test "xbar r chart returns limits and flags" {
  let groups = [[10.0, 11.0, 9.0], [10.0, 10.0, 10.0], [11.0, 12.0, 10.0]]
  match ControlChart::xbar_r(groups) {
    ChartOk(chart) => {
      inspect(chart.points.length(), content="3")
      inspect(chart.points[0].value, content="10")
      inspect(chart.points[1].out_of_control, content="false")
      inspect(chart.points[0].upper > chart.points[0].lower, content="true")
    }
    ChartInvalidInput(message~) => fail(message)
  }
}

///|
test "attribute charts accept exposure" {
  match ControlChart::p([2, 1, 4], [20, 20, 20]) {
    ChartOk(chart) => inspect(chart.points.length(), content="3")
    ChartInvalidInput(message~) => fail(message)
  }
  match ControlChart::u([2, 3, 4], [10, 10, 20]) {
    ChartOk(chart) => inspect(chart.points[2].value, content="0.2")
    ChartInvalidInput(message~) => fail(message)
  }
}
