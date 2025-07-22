#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ScreenKeeper 精简打包脚本
适用于 PyInstaller 6.0+ 版本
"""

import PyInstaller.__main__
import os

def main():
    # 获取当前工作目录
    base_dir = os.path.abspath(os.path.dirname(__file__))
    
    # 配置打包参数 (仅保留必要参数)
    params = [
        'screen_keeper.py',       # 主脚本
        '--onefile',              # 单文件模式
        '--noconsole',            # 无控制台窗口
        '--name=ScreenKeeper',    # 输出名称
        '--add-data={};.'.format(  # 添加配置文件
            os.path.join(base_dir, 'screen_keeper_config.json')
        ),
        '--hidden-import=pystray._win32',  # 必须的隐藏导入
        '--hidden-import=PIL._imaging',    # 必须的隐藏导入
        '--clean'                 # 清理构建缓存
    ]
    
    # 添加图标 (确保图标路径正确)
    icon_path = os.path.join(base_dir, 'icons', 'xru5r-0l619-001.ico')
    if os.path.exists(icon_path):
        params.append(f'--icon={icon_path}')
    else:
        print(f"[注意] 未找到图标文件: {icon_path}")
    
    # 执行打包
    PyInstaller.__main__.run(params)

if __name__ == '__main__':
    print("开始打包 ScreenKeeper...")
    main()
    print("打包完成！输出文件在 dist/ 目录")