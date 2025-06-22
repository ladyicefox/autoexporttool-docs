# 文件管理系统

## 功能概览
![文件管理界面](../images/file_management.png)

```mermaid
graph LR
A[文件列表] --> B[导航操作]
A --> C[文件操作]
A --> D[智能筛选]
B --> B1[返回上级]
B --> B2[常用路径]
C --> C1[添加文件]
C --> C2[删除文件]
C --> C3[重命名]
D --> D1[类型过滤]
D --> D2[最近文件]
```

## 核心操作

### 1. 添加文件
```maxscript
-- 手动添加单个文件
on btnBrowseFolder pressed do (
    files = getOpenFileName caption:"" types:"All Files|*.*"
    if files != undefined do addFileToLv files
)

-- 拖放添加文件
dotNet.addEventHandler Lv_model "DragDrop" (fn sender e = (
    files = e.Data.GetData(dotNetClass "DataFormats.FileDrop")
    for f in files do addFileToLv f
))
```

### 2. 智能筛选
<video controls width="80%">
  <source src="../videos/file_filtering.mp4" type="video/mp4">
  您的浏览器不支持视频标签
</video>

| 文件夹类型 | 自动识别规则 | 显示文件类型 |
|-----------|--------------|-------------|
| Scripts   | 包含"script" | *.ms, *.mse |
| Anim      | 包含"anim"   | *.bip, *.xaf |
| Scenes    | 包含"scene"  | *.max       |
| Models    | 包含"model"  | *.fbx       |

### 3. 路径管理
![常用路径](../gifs/path_management.gif)

```maxscript
-- 添加常用路径
global g_likedFolders = #()

fn addLikedFolder name path = (
    append g_likedFolders (itemsFolder name:name dir:path)
    saveConfig()
)
```

### 4. 最近文件
```maxscript
-- 加载最近文件
fn loadRecentFiles = (
    xmlPath = getDir #maxData + "\\RecentDocuments.xml"
    if doesFileExist xmlPath do (
        -- 解析XML代码...
    )
)
```

