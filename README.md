# 衣柜管家 MVP

基于 PRD v1.1 实现的 iOS 17+ SwiftUI 初版工程，聚焦三条核心闭环：

- 添加衣物：拍照或导入图片，自动抠图，录入结构化信息后保存
- 搜配评分：选择 2-5 件单品，本地生成拼图预览和规则评分
- 记录回看：保存搜配方案，并在记录页查看历史与得分详情

## 技术方案

- UI: SwiftUI
- 数据: SwiftData
- 图片处理: Vision 前景分割 + UIKit 渲染拼图
- 架构: Feature + Service + Model 分层

## MVP 范围

- `衣柜` 页：筛选、网格浏览、遗忘标签、详情查看
- `搜配` 页：分区选品、预览合成、本地评分、保存记录
- `记录` 页：历史浏览、得分概览、详情分析

## 保守决策

- iCloud/CloudKit 在架构上预留，但当前默认使用本地 `ModelContainer`
- `Outfit` 同时保存关联衣物与展示快照，避免后续单品变化影响历史记录展示
- 若抠图失败，自动回退为原图，避免阻断添加流程

## 当前环境限制

当前工作机未安装完整 Xcode，仅有 Command Line Tools，因此无法执行 `xcodebuild` 级别的真机构建验证。源码和工程描述已按标准 iOS 工程方式组织，建议在安装 Xcode 后运行：

```bash
xcodegen generate
open WardrobeManager.xcodeproj
```
