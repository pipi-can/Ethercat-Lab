// ThemeConfig.js — 主题纯数据定义
// 每个主题就是一个 JS 对象，新增主题只需添加新对象即可。

const DarkTheme = {
    name: "Dark",

    // ── 背景 ──────────────────────────────────────────────────
    bgWindow:    "#15181D",   // 主窗口 / CenterWidget
    bgTitleBar:  "#1C1F26",   // 标题栏
    bgSeparator: "#282C34",   // 分割线

    // ── 强调色 ────────────────────────────────────────────────
    accent: "#5294E2",        // 蓝色强调（按钮、焦点边框等）
    accentHover: "#6aa3e8",
    accentPress: "#4580c8",
    accentMutedBg: "#145294E2", // accent 8% 透明，用于徽章背景

    // ── 语义色（状态 / 操作，对齐 HTML 原型）──────────────────
    success: "#42a85f",
    successHover: "#5abe6f",
    successPress: "#3a9554",
    successMutedBg: "#1442a85f", // success 8% 透明，TxPDO 标签
    warn: "#d4844a",
    warnHover: "#e89a5c",
    warnPress: "#c0743a",
    warnMutedBg: "#14d4844a",  // warn 8% 透明，IO 从站序号徽章
    danger: "#e0554a",
    dangerHover: "#e86a62",
    dangerPress: "#c84840",
    textOnSolid: "#ffffff",   // 实心按钮上的文字

    // ── 面板 / 表面 ───────────────────────────────────────────
    bgSurface: "#252830",     // 次级面板、中性按钮背景
    bgSurfaceHover: "#3a3d45",

    // ── 通用文字 ──────────────────────────────────────────────
    textPrimary:   "#ffffff", // 主要文字（白色）
    textSecondary: "#c0c0c0", // 次要文字（浅灰）
    textMuted:     "#8795B0", // 暗淡文字（状态提示、搜索框）

    // ── IconButton 默认值（三态：place / hover / press）───────
    buttonBg:          "#2a2a3a",
    buttonBgHover:     "#3a3a4e",
    buttonBgPress:     "#1a1a2a",
    buttonIcon:        "#c0c0c0",
    buttonIconHover:   "#ffffff",
    buttonIconPress:   "#ffffff",
    buttonText:        "#c0c0c0",
    buttonTextHover:   "#ffffff",
    buttonTextPress:   "#ffffff",
    buttonBorder:      "transparent",
    buttonBorderHover: "transparent",
    buttonBorderPress: "transparent",

    // ── InputField 默认值（两态：normal / focus）──────────────
    inputBg:              "#252540",
    inputBgFocus:         "#2a2a4a",
    inputText:            "#e0e0e0",
    inputTextFocus:       "#ffffff",
    inputCursor:          "#1a8fc9",
    inputCursorFocus:     "#1a8fc9",
    inputBorder:          "#3a3a52",
    inputBorderFocus:     "#1a8fc9",
    inputPlaceholder:     "#555566",
    inputPlaceholderFocus:"#666677",
    inputIcon:            "#c0c0c0",
    inputIconFocus:       "#ffffff",

    // ── NavigationBar 导航栏 ──────────────────────────────────
    bgNavRail:      "#111318",   // 导航栏背景
    navBorder:      "#2a2e36",   // 导航栏右边框
    navBgHover:     "#252830",   // 按钮悬停背景
    navBgActive:    "#1e5099",   // 按钮激活背景
    navIconDefault: "#555c69",   // 图标默认色
    navIconHover:   "#88909e",   // 图标悬停色
    navIconActive:  "#ffffff",   // 图标激活色
    navTooltipBg:   "#2a2e38"    // 提示框背景
}
