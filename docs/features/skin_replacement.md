
### docs/features/skin_replacement.md 一键换皮功能文档

```markdown
# 一键换皮功能

## 功能概述

一键换皮系统允许您将现有角色动画快速应用到新的角色模型上，自动处理骨骼匹配和动画迁移。

```mermaid
sequenceDiagram
    participant 用户
    participant 插件
    participant 3ds Max
    用户->>插件: 选择目标角色
    插件->>3ds Max: 加载皮肤模板
    3ds Max-->>插件: 返回骨骼数据
    插件->>插件: 匹配骨骼结构
    插件->>3ds Max: 应用动画数据
    3ds Max-->>用户: 完成换皮操作
    使用流程
1.准备基础角色：

打开包含目标动画的角色文件（Skin模板文件），确保骨骼系统完整

2.选择换皮文件：LV列表当前显示的Max文件

3.启动换皮：

点击🦊Restyle按钮

设置输出目录（默认：SkinReplace_Output）

等待处理完成：

进度条显示当前状态

处理完成后自动打开输出目录

高级选项
选项	描述	默认值
附件骨骼导出	导出附加骨骼数据	启用
动画重定向	自动适配不同比例骨骼	禁用
错误报告	生成详细错误日志	启用
输出目录	自定义结果保存路径	SkinReplace_Output
技术说明
换皮过程分为三个阶段：

1.骨骼提取：

maxscript
fn extractSkeleton = (
    boneNodes = for obj in objects where isAttachmentBone obj collect obj
    return boneNodes
)
2.动画迁移：

使用biped.loadBipFile迁移BIP动作

通过LoadSaveAnimation.loadAnimation迁移XAF附件

3.结果优化：

自动清理无效骨骼节点

生成转换报告