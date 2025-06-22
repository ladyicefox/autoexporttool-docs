# AutoExportTool_Pro - 专业3ds Max动画工具

![插件界面截图](images/plugin_screenshot.png){ align=right width=300 }

**AutoExportTool Pro** 是一款面向3ds Max动画师的专业工具集，提供高效的批量导出/导入、一键换皮、BIP动作管理等核心功能，大幅提升动画制作效率。

## 主要特性

- 🚀 **批量处理**：同时处理多个FBX/BIP文件
- 🧬 **一键换皮**：快速将动画应用到不同角色模型
- 📂 **智能文件管理**：支持最近文件、常用路径和自动保存监控
- ⚙️ **可定制UI**：颜色主题、布局和快捷键自定义
- 🔌 **无缝集成**：工具栏菜单和自启动选项

[开始使用](#){ .md-button .md-button--primary }
[查看功能](#){ .md-button }

## 功能亮点

| 功能 | 描述 |
|------|------|
| **FBX批量导出** | 支持Auto/Skin/Bake三种导出模式 |
| **BIP动作管理** | 批量导出/导入Biped动画数据 |
| **智能换皮系统** | 自动迁移骨骼动画到新角色模型 |
| **文件归档** | 按版本自动整理Max场景文件 |
| **实时监控** | 自动保存目录变化即时响应 |


## 技术支持

```mermaid
graph LR
  A[3ds Max 2018+] --> B[AutoExportTool Pro]
  B --> C{FBX/BIP/XAF}
  C --> D[角色动画]
  C --> E[场景导出]
  C --> F[资源管理]
