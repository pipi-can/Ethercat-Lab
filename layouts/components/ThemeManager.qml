pragma Singleton
import QtQuick
import "ThemeConfig.js" as ThemeConfig

/*
 * @brief: 主题管理器单例。
 *         持有当前主题对象，所有组件通过 ThemeManager.current.xxx 绑定颜色。
 *         切换主题时只需给 current 赋值新主题对象，所有绑定自动刷新。
 */

QtObject {
    // 当前主题 —— 初始为 DarkTheme
    property var current: ThemeConfig.DarkTheme

    // 切换主题（后续添加 LightTheme 时使用）
    function switchTheme(name) {
        // @TODO: 等 LightTheme 定义后取消注释
        // if (name === "Light") current = ThemeConfig.LightTheme
        if (name === "Dark") current = ThemeConfig.DarkTheme
    }
}
