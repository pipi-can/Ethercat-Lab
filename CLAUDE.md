# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 构建

- **构建系统**: qmake（非 CMake）
- **Qt 版本**: 6.5.3（MinGW 64-bit）
- **IDE**: Qt Creator，配套 Qt 6.5.3 MinGW 64-bit 套件

```bash
# 在项目根目录下，使用 Qt 6.5.3 MinGW 64-bit 环境执行：
qmake EtherCAT-Lab.pro
mingw32-make
```

构建产物输出到 `build/Desktop_Qt_6_5_3_MinGW_64_bit-Debug/`。

## 架构

这是一个基于 Qt Quick（QML）的 EtherCAT 设备管理桌面应用——目前处于 Phase 1（ESI 解析器完成，待做 ViewModel 桥接）。

### C++ 层（`main.cpp`、`interfaces/`）

- `main.cpp` — 入口，创建 `QGuiApplication` + `QQmlApplicationEngine`。
- `interfaces/ESI_def.h` — 完整 ESI 数据模型，~20 个纯 C++ struct，覆盖 EtherCATInfo 全部字段（Device/Mailbox/PDO/Dictionary/DC/Slots/ESC/Enum 等）。
- `interfaces/esiparser.h/.cpp` — `ESIParser : QObject`，基于 `QXmlStreamReader` 的流式 XML 解析器。**已完成全部字段解析**，已通过 Copley XE2 真实 XML（600KB）验证。
- `ThemeManager`（C++ 单例）— 已存在但**已被 QML 侧同名单例取代**，后续可移除或精简。

### QML 层：布局树（当前实际结构）

```
ApplicationWindow (main.qml)
├── TitleBar (layouts/TitleBar/)
│   ├── IconButton "Open ESI" ──→ onOpenEsiClicked → fileDialog.open()
│   ├── Seprator
│   ├── 文件状态指示器（圆点 + "No file selected"）
│   └── InputField（搜索框，预留）
├── Seprator
├── NavigatorBar (layouts/NavigationBar/)          ← 50px 宽，3 项，Popup tooltip
├── StackView (mainStackView)                      ← 页面切换，replace() + Immediate
│   ├── Page 0: ESIBrowserWidget
│   │   ├── BrowserTreeWidget（左侧树面板，空状态 + 加载遮罩 + 拖拽调整宽度）
│   │   └── CenterInfoWidget（右侧，欢迎页 + 拖拽区 + 详情预留）
│   ├── Page 1: Object Dictionary（占位 Rectangle）
│   └── Page 2: PDO Mapping（占位 Rectangle）
└── 全局：FileDialog + Shortcut(Ctrl+O / Ctrl+F)
```

### 资源文件

- `qml.qrc` — 所有 QML 源文件 + JS + qmldir
- `resources.qrc` — SVG 图标（`resources/MainApp/`、`TitleBar/`、`NavigatorBar/`）

---

## 组件目录

### 通用组件（`layouts/components/`，qmldir 管理）

| 组件 | 用途 |
|------|------|
| `ColorImage` | `Image` + `ColorOverlay`（Qt5Compat），SVG/PNG 着色。所有图标组件的基础。 |
| `IconButton` | 图标+文字按钮，水平/垂直布局，place/hover/press 三态背景+图标+文字+边框色。 |
| `InputField` | 带可选左右图标的输入框，normal/focus 两态全部颜色属性。 |
| `Seprator` | 分割线 Rectangle（拼写 "Seprator" 是全局约定）。 |
| `ThemeManager` | `pragma Singleton`，通过 qmldir 声明。持有 `current` 主题对象。 |
| `ThemeConfig.js` | 纯 JS 数据，`DarkTheme` 对象（~38 个颜色属性）。 |
| `qmldir` | 声明模块类型 + `singleton ThemeManager`。 |

### 导航栏（`layouts/NavigationBar/`）

| 组件 | 要点 |
|------|------|
| `NavigatorBar` | 50px 宽，`ListView` + `ListModel`（name/tooltip/iconSource/iconWidth/iconHeight）。激活态左侧蓝色指示条。Popup tooltip 使用 `parent: Overlay.overlay` + `mapToItem` 定位 + `Timer(80ms)` 防闪烁。图标通过 `ColorImage` 三态着色。 |

### ESI 浏览器（`layouts/ESIBrowserWidget/`）

| 组件 | 要点 |
|------|------|
| `ESIBrowserWidget` | 容器：左 `BrowserTreeWidget` + 右 `CenterInfoWidget`。转发 `fileOpenRequested` / `fileDropped` 信号。 |
| `BrowserTreeWidget` | 标题 "ESI EXPLORER" + 节点计数。空状态：文件夹图标 + "Open an ESI file to start"。加载遮罩：Canvas 旋转圆环。右侧 4px 拖拽手柄（240–450px）。 |
| `CenterInfoWidget` | 面包屑（`hasSelection` 控制 0/32px 高度）。欢迎页：Logo + 标题 + 虚线拖拽区 + Browse Files / Load Example 按钮 + KbdLabel 快捷键提示。详情视图占位。 |

---

## 关键模式

### 主题系统

**数据流**：`ThemeConfig.js`（纯数据）→ `ThemeManager.qml`（单例）→ 所有组件的属性绑定。

```qml
// 直接绑定
color: ThemeManager.current.bgWindow

// 组件默认值（可被调用方覆盖）
property color bgColor: ThemeManager.current.inputBg
```

**新增主题**：在 `ThemeConfig.js` 添加同名属性 JS 对象 → `ThemeManager.switchTheme()` 加分支。无需改组件。

### StackView 页面管理

`main.qml` 中 `pageManager` 预创建 3 个 page（`Component.createObject`），保留引用防止 GC。导航切换用 `mainStackView.replace(target, {}, StackView.Immediate)`。**旧页面状态不丢失**（`pageManager.pages` 持有引用）。

### 文件加载信号链

```
TitleBar "Open ESI" ─┐
Ctrl+O 快捷键 ───────┼→ FileDialog.open() → onAccepted → loadEsiFile(url)
CenterInfoWidget:     │
  点击拖拽区 ────────┤      （fileOpenRequested 信号链）
  Browse Files 按钮 ─┘
  拖拽放下文件 ──────→ DropArea.onDropped → fileDropped(url) → loadEsiFile(url)
```

`loadEsiFile(url)` 是统一入口：剥 `file:///` 前缀 + Windows 盘符兼容 + XML 扩展名校验。

### Popup tooltip（NavigatorBar）

```qml
Popup {
    parent: Overlay.overlay     // 不受父容器裁剪
    x: root.mapToItem(null, root.width + 4, 0).x
    y: root.mapToItem(null, 0, itemCenterY - height/2).y
}
// 80ms delay close 防止相邻按钮滑动闪烁
```

### 空状态 / 加载态 / 内容态 切换

各 Widget 使用 `hasFile` / `hasSelection` 属性 + `visible` 绑定切换视图。如 `BrowserTreeWidget`：空状态 `visible: !hasFile`，树形容器 `visible: hasFile`。

---

## UI 原型参考

`ui-prototype/esi-browser-interactive.html` — 原生 HTML 原型，CSS 变量 + 完整交互。颜色、布局、间距均以此为基准。修改 QML 布局前应先对照此文件。

## ESI 解析器（`interfaces/esiparser.h/.cpp`）

### 调用方式

```cpp
ESIParser parser;
ECATInfo info = parser.parseECATInfo("path/to/file.xml");
// info.devices, info.modules, info.vendor, info.groups 已全部填充
```

### 解析覆盖范围

| 层级 | 函数 | 覆盖字段 |
|------|------|---------|
| 顶层 | `parseECATInfo` | Vendor, Groups, Devices, Modules |
| Device | `parseDevices` | Physics, Type/ProductCode/RevisionNo, Name, GroupType, Fmmu, Sm, RxPdo, TxPdo, Mailbox, Eeprom, Profile, Dc, Slots, ESC, ImageData16x14 |
| Mailbox | `parseMailBox` | DataLinkLayer, EoE/CoE/FoE/AoE/SoE/VoE, CoE 属性, InitCmd |
| Dictionary | `parseDictionary` + `parseDataTypes` + `parseObjects` | DataType (Name/BaseType/BitSize/ArrayInfo/SubItem), Object (Index/Name/Type/Flags/Enum/SubItem) |
| Dc | `parseDcOpModes` + `parseDcOpMode` | Name, Desc, AssignActivate, CycleTimeSync0(Factor), ShiftTimeSync0 |
| Slots | `parseSlots` | SlotPdoIncrement, SlotIndexIncrement, Slot → Name/Max/MinInstances/ModuleIdent |
| ESC | `parseESC` | Reg0108/0400/0410/0420 + 未知 RegXXXX 存入 extraRegs map |
| Enum | `parseEnum` + `parseEnumInfo` | 对象/SubItem 的 Enum/Denotation/Indication（贝克霍夫系常用） |

### QXmlStreamReader 关键陷阱（踩过的坑）

**1. 自闭合元素必须 `skipCurrentElement()`**

对于 `<EoE/>`、`<FoE/>`、`<AoE/>` 等自闭合元素，只设置标志位（如 `result.eoe = true`）不够——reader 会停在 StartElement 位置。下次 `readNextStartElement()` 读到的是 EndElement，直接返回 false，**后续同级元素全部丢失**。

```cpp
// ❌ 错误：reader 卡住，后续元素丢失
if (name == "EoE") {
    result.eoe = true;
}

// ✅ 正确：主动跳过自闭合元素
if (name == "EoE") {
    result.eoe = true;
    xml.skipCurrentElement();
}
```

**2. `readNextStartElement()` 的"当前元素"语义**

`readNextStartElement()` 在当前元素**内部**查找下一个 StartElement。如果 reader 正停在一个自闭合元素的 StartElement 上，它会先读到 EndElement → 判断到达当前元素末尾 → 返回 false。这就是陷阱 1 的根因。

**3. `#x` 前缀的 hex 值不会自动转换**

```cpp
// ❌ "SlotIndexIncrement='#x800'" → toUInt() 返回 0
result.slotIndexIncrement = xml.attributes().value("SlotIndexIncrement").toString().toUInt();

// ✅ 需要手动处理 #x 前缀
QString s = xml.attributes().value("SlotIndexIncrement").toString();
result.slotIndexIncrement = s.startsWith("#x") ? s.mid(2).toUInt(nullptr, 16) : s.toUInt();
```

### CoE 元素处理（自闭合 vs 非自闭合）

Device 层级 CoE 通常是自闭合的 `<CoE PdoAssign="1" .../>`（无 InitCmd），Module 层级的 CoE 包含子元素 `<CoE><InitCmd>...</InitCmd></CoE>`。

```cpp
} else if (name == "CoE") {
    result.coe = true;
    // 解析属性...
    // readNextStartElement(): 自闭合立即返回 false，非自闭合进入子元素
    while (xml.readNextStartElement()) {
        if (xml.name() == QStringView(u"InitCmd")) {
            result.initCmds.push_back(parseInitCmd(xml));
        } else {
            xml.skipCurrentElement();
        }
    }
}
```

## 项目设计文档

`EtherCAT_Lab_评估与架构设计_QML版.md` — 完整技术架构文档（v2.0），含四层架构、7 模块路线图、技术选型对比、风险识别。**当前处于 Phase 1 中期（解析器完成，待 ViewModel 桥接）**。
