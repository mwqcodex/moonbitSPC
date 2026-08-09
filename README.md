# moonbitSPC

`moonbitSPC` 是一个面向机械加工与实验质量数据的 MoonBit 统计过程控制库。它把原始测量值转换为可复现的统计摘要、控制图数据、异常规则命中和过程能力报告，方便嵌入制造质量平台、实验教学工具和检测软件。

## 能做什么

- 控制图：X-bar/R、X-bar/S、I-MR、P、NP、C、U
- 指标：均值、样本标准差、Cp、Cpk、Pp、Ppk、超差率
- 异常检测：Western Electric 1—4 规则，返回规则编号、起点和影响索引
- 追溯维度：批次、设备、刀具、操作员、时间窗口
- 结果形态：纯数据结构，可由 CLI、WebAssembly 或上层 UI 自行绘图

## 快速开始

```moonbit
let group = @moonbitSPC.Subgroup::new(
  values=[9.8, 10.1, 10.0], batch="B-01", equipment="mill-2",
  tool="T-07", operator="op-a", window="2026-08-09T10:00Z",
)
match @moonbitSPC.quality_report(
  [group], specification=@moonbitSPC.Specification::new(lower=9.0, upper=11.0),
) {
  @moonbitSPC.ReportOk(report) => println(report.summary.mean.to_string())
  @moonbitSPC.ReportInvalidInput(message~) => println(message)
}
```

运行测试：

```text
moon fmt
moon check --deny-warn
moon info
moon test --deny-warn
moon test --target native --deny-warn
```

## 工程边界

当前版本专注于批量、离线、确定性的统计计算，不负责数据库、实时传输、图形绘制或具体工厂协议。后续可在不破坏核心数据结构的前提下增加多变量 SPC、漂移检测、刀具寿命预测、流式输入和 JSON/CSV 适配器。

## 设计说明

库不依赖外部 Mooncakes 包，便于 wasm-gc/native 双目标复现。所有算法都返回结构化结果而非打印文本；错误输入通过结果枚举显式返回。控制图常数与假设写在 API 文档和测试中，使用者可以替换上层估计方法。

## 许可证

MIT License，详见 [LICENSE](LICENSE)。开发过程与取舍记录见 [DEVELOPMENT.md](DEVELOPMENT.md)，申报材料见 [申报书.md](申报书.md)。
