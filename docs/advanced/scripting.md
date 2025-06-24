# 脚本扩展开发

## API参考

classDiagram
    class AutoExportTool {
        +refreshFileListView()
        +processBipExport(string path)
        +processSkinReplacement()
        +addCustomButton(string name, string script)
    }
    
    class FileManager {
        +getFilesAndDirs(string path, string filter)
        +pseudoNaturalSort(string a, string b)
    }
    
    class ConfigManager {
        +saveUIConfig()
        +loadUIConfig()
        +addPreset(string name)
    }
    
    AutoExportTool "1" *-- "1" FileManager
    AutoExportTool "1" *-- "1" ConfigManager
```

## 扩展点示例

### 1. 添加自定义按钮
```maxscript
-- 创建自定义按钮
fn addCustomButton btnName script = (
    local btn = button btnName width:80 height:25
    
    -- 动态添加事件处理
    dotNet.addEventHandler btn "Click" (fn sender e = (
        try (execute script) catch (
            format "[自定义按钮错误] %: %" btnName (getCurrentException())
        )
    ))
    
    -- 添加到UI
    addToToolbarGroup btn
)
```

### 2. 扩展文件处理流程
```maxscript
-- 文件处理前回调
global g_preFileProcessCallbacks = #()

fn registerPreProcessCallback callbackFunc = (
    append g_preFileProcessCallbacks callbackFunc
)

-- 在文件处理循环中调用
fn processFiles files = (
    for callback in g_preFileProcessCallbacks do callback files
    
    for f in files do (
        -- 正常处理流程...
    )
)
```

### 3. 自定义导出格式
```maxscript
-- 注册自定义导出器
struct CustomExporter (
    name = "GLTF Exporter",
    extension = "gltf",
    exportFn = fn exportGLTF path = (
        -- GLTF导出实现...
    )
)

global g_customExporters = #()

fn registerExporter exporter = (
    append g_customExporters exporter
    -- 更新UI显示
    refreshExportFormatDropdown()
)

-- 使用示例
gltfExporter = CustomExporter()
registerExporter gltfExporter
```

## 示例脚本

### 批量重命名工具
```maxscript
fn batchRename prefix suffix = (
    for i=0 to (Lv_model.Items.Count-1) do (
        item = Lv_model.Items.Item[i]
        if item.Checked do (
            oldPath = item.Tag as String
            newName = prefix + (getFilenameFile oldPath) + suffix + (getFilenameType oldPath)
            newPath = (getFilenamePath oldPath) + newName
            
            if renameFile oldPath newPath do (
                item.SubItems.Item[1].Text = newName
                item.Tag = newPath
            )
        )
    )
)
```

### 自动归档脚本
```maxscript
fn autoArchiveFiles = (
    currentDate = localTime
    archiveDir = "Archive_" + formattedPrint currentDate[1] format:"04d" + \
                "_" + formattedPrint currentDate[2] format:"02d" + \
                "_" + formattedPrint currentDate[4] format:"02d"
    
    makeDir archiveDir
    for i=0 to (Lv_model.Items.Count-1) do (
        if Lv_model.Items.Item[i].Checked do (
            filePath = Lv_model.Items.Item[i].Tag as String
            copyFile filePath (archiveDir + "\\" + filenameFromPath filePath)
        )
    )
)
```

## 调试技巧
```markdown
1. **启用调试模式**：
   ```maxscript
   global g_debugMode = true
   
   fn logDebug msg = (
       if g_debugMode do format "DEBUG: %\n" msg
   )
   ```

2. **异常捕获**：
   ```maxscript
   try (
       riskyOperation()
   ) catch (
       stack = getCallStack()
       format "[错误] 操作失败: %\n调用堆栈: %" (getCurrentException()) stack
   )
   ```

3. **性能分析**：
   ```maxscript
   startTime = timeStamp()
   -- 执行代码...
   endTime = timeStamp()
   format "操作耗时: % 毫秒" (endTime - startTime)
   ```

4. **内存监控**：
   ```maxscript
   fn printMemoryUsage = (
       format "当前内存使用: % KB" (memUsed() / 1024)
   )
   ```
```

<div class="admonition tip">
<p class="admonition-title">最佳实践</p>
1. 使用版本控制管理自定义脚本<br>
2. 定期备份配置文件<br>
3. 在修改前创建预设快照<br>
4. 使用沙盒环境测试新脚本
</div>

