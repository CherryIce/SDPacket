# 搬家箱 / Moving Box

Flutter 实现的本地优先搬家箱登记与定位应用。产品规格见
[`Docs/搬家箱快速登记与定位App_设计开发文档.md`](Docs/搬家箱快速登记与定位App_设计开发文档.md)，当前实现状态见
[`Docs/Flutter_MVP_开发进度.md`](Docs/Flutter_MVP_开发进度.md)。

## 当前能力

- 本地项目创建、编辑、归档、恢复和删除。
- 自动分配项目内唯一箱号；删除后不回退序号。
- 手动、批量照片和语音三种登记入口，权限不可用时可回到文字登记。
- 离线搜索箱号、标题、备注、结构化物品、房间、位置和标签。
- 搬运状态、异常标记、实体标记状态和项目进度统计。
- 稳定 UUID 二维码、高清 PNG、单个 PDF、A4 批量标签、系统分享和打印。
- CSV 导出、带版本号的 JSON 本地备份及校验后恢复。
- 简体中文和英文界面；权限用途文案随 iOS 系统语言本地化。

## 系统要求

- Flutter 3.35.7 / Dart 3.9.2（当前验证工具链）
- iOS 15+
- Android 14+（`minSdk = 34`）

当前 Bundle ID / Application ID 为开发期占位值：

- iOS：`com.starburst.movingBox`
- Android：`com.starburst.moving_box`

正式上架前必须替换为已确认的生产标识，并配置独立的 Release 签名；当前 Android Release 配置仍沿用 Flutter 模板的 Debug 签名，不可用于发布。

## 本地运行

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## 验证

```bash
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
flutter build apk --debug
```

构建和自动化测试不能替代真机相机、语音、照片选择、扫码、系统分享、打印、飞行模式及 Android 14 设备验收。

## 代码结构

```text
lib/
├── data/       # JSON 快照、原子写入、备份校验、应用状态
├── models/     # 项目、箱子、物品与状态模型
├── screens/    # 项目、箱子、搜索、扫码、语音、标签与设置页面
├── services/   # 照片持久化、QR 载荷、CSV/PDF 导出
├── widgets/    # 共用表单、实体标记与本地化映射
└── l10n/       # zh/en ARB 与生成代码
```
