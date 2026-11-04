# 数绘 (Graphica)

一款用 Flutter 构建的跨平台数学工具——把数学画出来。中文界面优先，支持函数图像、
科学/四则计算器、矩阵、交互几何与 3D 曲面。

A beautiful, Chinese-first cross-platform math studio built with Flutter.

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20Android%20%7C%20iOS%20%7C%20HarmonyOS-5ea8ff)

## 功能

| 模块 | 说明 |
| --- | --- |
| **函数图像** | 直角坐标 `y = f(x)`、极坐标 `r = f(θ)` 与隐式方程（如 `x² + y² = 9`）；自适应网格、平移缩放、悬停读数、分曲线颜色与语法校验。 |
| **科学计算器** | 自研表达式引擎：隐式乘法、幂、阶乘、三角/反三角、对数、常量、`ANS`、角度/弧度、历史记录与实时结果。 |
| **四则计算器** | 大按键、实时结果与计算历史胶带。 |
| **矩阵** | 1–6 阶可编辑 A/B 矩阵，加减乘、转置、求逆、行列式、迹与标量乘。 |
| **几何** | 点/线段/圆构造，0.5 网格吸附，拖动点，实时长度与半径；确认前显示虚线线段/圆与实时测量预览。 |
| **3D 曲面** | 支持添加多条 `z = f(x, y)` 曲面（各自颜色/显隐/删除），共享 z 轴透视渲染、深度排序与双面光照；无输入时显示与 Desmos 一致的包围盒、z=0 网格平面、带箭头与刻度值的 X/Y/Z 轴；着色/线框、自由旋转缩放与预设。 |
| **数学键盘** | 内置公式键盘，可直接输入 √、π、θ、x²、幂、括号、三角/对数函数与 `=`，适合手机输入。 |
| **公式排版** | 表达式以 LaTeX 正常数学符号显示：根号、分数、上下标、希腊字母等。 |
| **本地持久化** | 主题、强调色、角度单位、语言以及函数图像文档自动保存到本地 JSON。 |
| **导出 PNG** | 图像与 3D 曲面可一键导出高清 PNG。 |
| **设置** | 跟随系统/浅色/深色、5 种强调色、中文/English 切换、角度单位与 MIT 许可说明。 |
| **新手引导** | 首次打开自动显示分步使用指引，介绍功能、数学键盘、公式排版与多平台；可在设置中重新查看。 |

## 设计

界面：深色中性底、极光径向光晕、磨砂玻璃与高光描边、
渐变按钮、大圆角，以及“侧边栏 → 图标栏 → 底部导航”的响应式布局。
Windows 标题栏会随主题切换为暗色。

## 平台

Windows · Linux · Android · iOS · HarmonyOS（鸿蒙手机 / 平板 / 电脑）

目前Releases中只提供windows和Android的发布包，其它平台请自行编译；

鸿蒙工程已在 `module.json5` 中声明 `phone`、`tablet`、`2in1`（电脑）三种设备类型；
界面按宽度自动切换底部导航、图标栏与侧边栏，适配鸿蒙手机、平板和 PC 的自由窗口。
当前版本：**v0.1.0**。

除 Flutter SDK 自带组件外，仅使用纯 Dart/平台插件（`path_provider`），
数学排版使用本地内置的 MIT 许可 `flutter_math_fork`（已补充鸿蒙
`TargetPlatform.ohos` 兼容分支），因此鸿蒙工程可直接用 Hvigor 编译。

## 快速开始

```bash
flutter pub get
flutter run -d windows   # 也可使用 linux / android / ios / ohos
```

构建：

```bash
flutter build windows --release
flutter build linux --release
flutter build apk --release
flutter build ios --release        # 需要 macOS
flutter build hap --release        # HarmonyOS 鸿蒙
```

> **鸿蒙签名：** HAP 目标可以直接通过 Hvigor 编译；正式打包前需在
> DevEco Studio 中配置一次签名（File → Project Structure → Signing
> Configs → Automatically generate signature）。

## 目录结构

```text
lib/
  app.dart                     MaterialApp、主题、语言与窗口标题栏同步
  main.dart                    加载本地存储后启动
  core/
    math/expression.dart       词法分析、递归下降解析与求值
    math/latex.dart            表达式 → LaTeX（用于公式排版）
    math/matrix.dart           矩阵与线性代数
    storage/app_store.dart     本地 JSON 持久化（设置 / 图像）
    theme/                     设计令牌与 Material 3 主题
    utils/                     数字格式化、PNG 导出、触感、文本插入
    app_section.dart           导航枚举与中文/英文标签
    app_info.dart              产品元数据与 MIT 文本
  features/
    home/                      首页与功能卡片
    graphing/                  图像控制器、画笔、画布、表达式面板
    calculator/                科学计算器与四则计算器
    matrix/                    矩阵编辑与运算
    geometry/                  几何构造、画笔与工具
    three_d/                   3D 曲面画笔与设置
    settings/                  外观、语言、数学与关于
  l10n/l10n.dart               中文 / English 文案
  state/app_settings.dart      设置状态与持久化
  ui/
    shell/app_shell.dart       响应式导航壳
    widgets/                   极光背景、玻璃面板、数学键盘、公式渲染
third_party/flutter_math_fork  MIT 许可的数学排版库（含鸿蒙适配补丁）
test/                          解析器、矩阵、排版、持久化、交互与页面测试
```

## 表达式语法

- 运算符：`+ - * / ^ % !`，支持隐式乘法（`2x`、`3(x+1)`、`2sin(x)`）
- 常量：`pi`、`e`、`tau`、`phi`
- 函数：`sin cos tan sec csc cot asin acos atan sinh cosh tanh ln log log2 log10 sqrt cbrt abs exp floor ceil round sign min max pow atan2 mod gcd lcm ncr npr gamma fact`
- 多参数：`log(8, 2)`、`min(3, 1, 2)`
- 隐式方程：`x^2 + y^2 = 9`（选择“隐式曲线”类型）

## 测试

```bash
flutter analyze
flutter test
```

## 第三方许可

`third_party/flutter_math_fork` 为 MIT 许可的 `flutter_math_fork` 本地副本，
仅添加了 `TargetPlatform.ohos` 兼容分支，原始 `LICENSE` 保留在目录内。

## 许可证

本项目以 [MIT License](LICENSE) 发布。
