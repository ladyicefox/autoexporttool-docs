#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ScreenKeeper 完整修复版
- 解决 win32con 常量问题
- 优化打包兼容性
- 增强错误处理
"""

import sys
import time
import threading
import ctypes
from datetime import datetime, timedelta
import win32api
import win32gui
import win32process
from pystray import MenuItem as item, Icon
from PIL import Image
import tkinter as tk
from tkinter import simpledialog, messagebox
import json
import os

# ========== Windows 常量定义 (兼容所有pywin32版本) ==========
ES_CONTINUOUS = 0x80000000
ES_SYSTEM_REQUIRED = 0x00000001
ES_DISPLAY_REQUIRED = 0x00000002
KEYEVENTF_KEYUP = 0x0002
VK_SHIFT = 0x10
VK_CONTROL = 0x11
ERROR_ALREADY_EXISTS = 183
SW_HIDE = 0

# ========== 全局配置 ==========
CONFIG_FILE = "screen_keeper_config.json"
DEFAULT_SETTINGS = {
    "mode": "permanent",  # permanent / scheduled
    "wake_times": ["09:00", "13:00", "17:00"],
    "last_active": None
}

# ========== 配置管理 ==========
def load_config():
    """加载配置文件，失败时返回默认配置"""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                return {**DEFAULT_SETTINGS, **json.load(f)}  # 合并默认配置
        except Exception as e:
            print(f"配置加载错误: {e}, 使用默认配置")
    return DEFAULT_SETTINGS.copy()

def save_config(config):
    """保存配置文件"""
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

# ========== 核心功能 ==========
def prevent_screensaver():
    """阻止屏幕保护和系统睡眠"""
    # 设置线程执行状态
    ctypes.windll.kernel32.SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
    )
    
    def send_key_event():
        """模拟Shift键按下/释放"""
        ctypes.windll.user32.keybd_event(VK_SHIFT, 0, 0, 0)
        ctypes.windll.user32.keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0)
    
    def send_mouse_event():
        """模拟鼠标微移动"""
        x, y = win32api.GetCursorPos()
        for dx, dy in [(1,0), (0,0), (0,1), (0,0)]:
            win32api.SetCursorPos((x + dx, y + dy))
    
    def prevention_loop():
        """持续防止锁屏的循环"""
        while load_config().get('mode') == 'permanent':
            send_key_event()
            time.sleep(30)
            send_mouse_event()
            time.sleep(30)
    
    threading.Thread(target=prevention_loop, daemon=True).start()

def restore_defaults():
    """恢复系统默认电源设置"""
    ctypes.windll.kernel32.SetThreadExecutionState(ES_CONTINUOUS)

def scheduled_wakeup():
    """定时唤醒功能"""
    def wakeup_at(target_time):
        """在指定时间执行唤醒"""
        now = datetime.now()
        if now > target_time:
            target_time += timedelta(days=1)
        time.sleep((target_time - now).total_seconds())
        
        if load_config().get('mode') == 'scheduled':
            # 模拟Ctrl键按下/释放
            ctypes.windll.user32.keybd_event(VK_CONTROL, 0, 0, 0)
            ctypes.windll.user32.keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)
            
            # 临时激活防锁屏
            config = load_config()
            config['mode'] = 'permanent'
            save_config(config)
            prevent_screensaver()
            time.sleep(30)
            
            # 恢复定时模式
            config['mode'] = 'scheduled'
            save_config(config)
    
    # 启动所有定时任务
    for wake_time in load_config().get('wake_times', []):
        try:
            hour, minute = map(int, wake_time.split(':'))
            target = datetime.now().replace(
                hour=hour, minute=minute, second=0, microsecond=0
            )
            threading.Thread(target=wakeup_at, args=(target,), daemon=True).start()
        except ValueError:
            continue

# ========== 系统托盘 ==========
def create_tray_icon():
    """创建系统托盘图标和菜单"""
    image = Image.new('RGB', (64, 64), (40, 100, 200))
    
    def set_mode(mode):
        """切换工作模式"""
        config = load_config()
        config['mode'] = mode
        save_config(config)
        
        if mode == 'permanent':
            prevent_screensaver()
        else:
            restore_defaults()
            scheduled_wakeup()
        
        icon.title = f"屏幕卫士 ({'永久防锁屏' if mode == 'permanent' else '定时唤醒模式'})"
    
    def add_wake_time():
        """添加新的唤醒时间"""
        time_str = simpledialog.askstring("添加唤醒时间", "格式 HH:MM (例如 09:00):")
        if time_str:
            try:
                datetime.strptime(time_str, "%H:%M")
                config = load_config()
                config.setdefault('wake_times', []).append(time_str)
                save_config(config)
                messagebox.showinfo("成功", f"已添加: {time_str}")
            except ValueError:
                messagebox.showerror("错误", "时间格式无效")
    
    def show_wake_times():
        """显示当前唤醒时间"""
        times = load_config().get('wake_times', [])
        msg = "当前唤醒时间:\n" + "\n".join(times) if times else "未设置唤醒时间"
        messagebox.showinfo("唤醒时间", msg)
    
    def on_quit(icon):
        """退出程序"""
        restore_defaults()
        icon.stop()
        os._exit(0)
    
    # 创建菜单
    menu = (
        item('永久防锁屏', lambda: set_mode('permanent')),
        item('定时唤醒', lambda: set_mode('scheduled')),
        item('添加时间', add_wake_time),
        item('查看时间', show_wake_times),
        item('退出', on_quit),
    )
    
    # 初始状态
    mode = load_config().get('mode', 'permanent')
    icon = Icon(
        '屏幕卫士',
        image,
        f"屏幕卫士 ({'永久' if mode == 'permanent' else '定时'})",
        menu
    )
    return icon

# ========== 主程序 ==========
def main():
    """程序入口"""
    # 隐藏控制台窗口
    ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), SW_HIDE)
    
    # 防止多开
    mutex = ctypes.windll.kernel32.CreateMutexW(None, False, "Global\\ScreenKeeper")
    if ctypes.windll.kernel32.GetLastError() == ERROR_ALREADY_EXISTS:
        ctypes.windll.user32.MessageBoxW(0, "程序已在运行", "提示", 0x40)
        sys.exit(0)
    
    # 启动相应模式
    config = load_config()
    if config['mode'] == 'permanent':
        prevent_screensaver()
    else:
        scheduled_wakeup()
    
    # 运行系统托盘
    create_tray_icon().run()

if __name__ == "__main__":
    main()