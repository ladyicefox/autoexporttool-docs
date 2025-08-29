import psutil
import os
import sys
import time
import ctypes
import logging
from PyQt5 import QtWidgets, QtGui, QtCore

# 设置日志记录
def setup_logging():
    if getattr(sys, 'frozen', False):
        # 如果是打包后的程序
        application_path = os.path.dirname(sys.executable)
    else:
        # 如果是脚本
        application_path = os.path.dirname(os.path.abspath(__file__))
    
    log_path = os.path.join(application_path, 'memory_optimizer.log')
    logging.basicConfig(
        filename=log_path,
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    logging.info("程序启动")

def resource_path(relative_path):
    """获取资源的绝对路径"""
    try:
        # 打包后的资源路径
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    
    return os.path.join(base_path, relative_path)

class MainWindow(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("内存优化工具")
        self.setGeometry(100, 100, 450, 280)  # 稍微增加高度以容纳更大的数字
        self.setFixedSize(450, 280)  # 固定窗口大小
        
        # 创建中央部件
        central_widget = QtWidgets.QWidget()
        self.setCentralWidget(central_widget)
        
        # 创建主布局
        main_layout = QtWidgets.QVBoxLayout(central_widget)
        main_layout.setSpacing(10)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # 创建内存信息显示区域
        info_group = QtWidgets.QGroupBox("内存状态")
        info_layout = QtWidgets.QGridLayout(info_group)
        info_layout.setSpacing(8)
        
        # 创建标签和数字显示
        labels = ["总内存:", "已使用:", "可用:", "使用率:", "清理阈值:"]
        self.value_labels = []
        
        for i, label_text in enumerate(labels):
            label = QtWidgets.QLabel(label_text)
            label.setStyleSheet("font-size: 11px; color: #555;")
            value_label = QtWidgets.QLabel("--")
            value_label.setStyleSheet("font-size: 12px; font-weight: bold; color: #333;")
            
            info_layout.addWidget(label, i, 0)
            info_layout.addWidget(value_label, i, 1)
            self.value_labels.append(value_label)
        
        # 特别设置使用率标签的样式（更大更突出）
        self.usage_label = self.value_labels[3]
        self.usage_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #e74c3c;")
        
        # 创建进度条显示内存使用率
        self.progress_bar = QtWidgets.QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setTextVisible(True)
        self.progress_bar.setFixedHeight(22)
        self.progress_bar.setStyleSheet("""
            QProgressBar {
                border: 1px solid #ccc;
                border-radius: 4px;
                text-align: center;
                font-size: 11px;
                background-color: #f9f9f9;
            }
            QProgressBar::chunk {
                background-color: #3498db;
                border-radius: 3px;
            }
        """)
        
        # 创建按钮区域
        button_layout = QtWidgets.QHBoxLayout()
        button_layout.setSpacing(8)
        
        self.clean_button = QtWidgets.QPushButton("清理内存")
        self.clean_button.clicked.connect(self.clean_memory)
        self.clean_button.setFixedHeight(30)
        
        self.settings_button = QtWidgets.QPushButton("设置")
        self.settings_button.clicked.connect(self.show_settings)
        self.settings_button.setFixedHeight(30)
        
        self.minimize_button = QtWidgets.QPushButton("最小化")
        self.minimize_button.clicked.connect(self.hide)
        self.minimize_button.setFixedHeight(30)
        
        # 设置按钮样式
        button_style = """
            QPushButton {
                font-size: 12px;
                font-weight: bold;
                border: 1px solid #bdc3c7;
                border-radius: 4px;
                padding: 5px;
                background-color: #ecf0f1;
                color: #2c3e50;
            }
            QPushButton:hover {
                background-color: #d6dbdf;
            }
            QPushButton:pressed {
                background-color: #abb2b9;
            }
            QPushButton#clean_button {
                background-color: #e74c3c;
                color: white;
            }
            QPushButton#clean_button:hover {
                background-color: #c0392b;
            }
        """
        
        self.clean_button.setStyleSheet(button_style)
        self.clean_button.setObjectName("clean_button")
        
        for button in [self.settings_button, self.minimize_button]:
            button.setStyleSheet(button_style)
        
        button_layout.addWidget(self.clean_button)
        button_layout.addWidget(self.settings_button)
        button_layout.addWidget(self.minimize_button)
        
        # 添加到主布局
        main_layout.addWidget(info_group)
        main_layout.addWidget(self.progress_bar)
        main_layout.addLayout(button_layout)
        
        # 初始化内存监控定时器
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.update_memory_info)
        self.timer.start(1000)  # 每秒更新一次
        
        # 设置默认阈值 (80%)
        self.threshold = 80
        
        # 初始更新
        self.update_memory_info()
        
    def update_memory_info(self):
        """更新内存信息显示"""
        try:
            memory = psutil.virtual_memory()
            used_percent = memory.percent
            
            # 更新数字显示
            self.value_labels[0].setText(f"{memory.total//1024//1024}MB")
            self.value_labels[1].setText(f"{memory.used//1024//1024}MB")
            self.value_labels[2].setText(f"{memory.available//1024//1024}MB")
            self.value_labels[3].setText(f"{used_percent:.1f}%")
            self.value_labels[4].setText(f"{self.threshold}%")
            
            # 更新进度条
            self.progress_bar.setValue(int(used_percent))
            self.progress_bar.setFormat(f"{used_percent:.1f}%")
            
            # 根据使用率设置进度条颜色和文字颜色
            if used_percent > 90:
                self.progress_bar.setStyleSheet("""
                    QProgressBar {
                        border: 1px solid #ccc;
                        border-radius: 4px;
                        text-align: center;
                        font-size: 11px;
                        color: #c0392b;
                        background-color: #f9f9f9;
                    }
                    QProgressBar::chunk {
                        background-color: #e74c3c;
                        border-radius: 3px;
                    }
                """)
                self.usage_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #e74c3c;")
            elif used_percent > 70:
                self.progress_bar.setStyleSheet("""
                    QProgressBar {
                        border: 1px solid #ccc;
                        border-radius: 4px;
                        text-align: center;
                        font-size: 11px;
                        color: #d35400;
                        background-color: #f9f9f9;
                    }
                    QProgressBar::chunk {
                        background-color: #e67e22;
                        border-radius: 3px;
                    }
                """)
                self.usage_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #e67e22;")
            else:
                self.progress_bar.setStyleSheet("""
                    QProgressBar {
                        border: 1px solid #ccc;
                        border-radius: 4px;
                        text-align: center;
                        font-size: 11px;
                        color: #27ae60;
                        background-color: #f9f9f9;
                    }
                    QProgressBar::chunk {
                        background-color: #2ecc71;
                        border-radius: 3px;
                    }
                """)
                self.usage_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #27ae60;")
            
            # 如果内存使用超过阈值，自动清理
            if used_percent > self.threshold:
                self.clean_memory()
        except Exception as e:
            logging.error(f"更新内存信息时出错: {e}")
    
    def clean_memory(self):
        """清理内存的函数"""
        try:
            # 尝试释放当前进程的工作集
            self.empty_working_set()
            
            # 更新状态
            memory = psutil.virtual_memory()
            logging.info(f"内存清理完成，当前使用率: {memory.percent:.1f}%")
            
            # 显示通知
            QtWidgets.QMessageBox.information(self, "内存已清理", f"内存使用率: {memory.percent:.1f}%")
        except Exception as e:
            logging.error(f"清理内存时出错: {e}")
            QtWidgets.QMessageBox.warning(self, "错误", f"清理内存时出错: {e}")
    
    def empty_working_set(self):
        """清空当前进程的工作集（将内存移至页面文件）"""
        try:
            if os.name == 'nt':  # Windows系统
                current_process = ctypes.windll.kernel32.GetCurrentProcess()
                ctypes.windll.psapi.EmptyWorkingSet(current_process)
            # 其他系统可以添加相应的实现
        except Exception as e:
            logging.error(f"清空工作集时出错: {e}")
    
    def show_settings(self):
        """显示设置对话框"""
        try:
            dialog = QtWidgets.QDialog(self)
            dialog.setWindowTitle("内存清理设置")
            dialog.setModal(True)
            dialog.setFixedSize(300, 150)
            
            layout = QtWidgets.QVBoxLayout(dialog)
            layout.setSpacing(10)
            layout.setContentsMargins(15, 15, 15, 15)
            
            # 阈值设置
            threshold_layout = QtWidgets.QHBoxLayout()
            threshold_label = QtWidgets.QLabel("清理阈值:")
            threshold_label.setFixedWidth(80)
            threshold_label.setStyleSheet("font-size: 12px;")
            threshold_spin = QtWidgets.QSpinBox()
            threshold_spin.setRange(50, 95)
            threshold_spin.setValue(self.threshold)
            threshold_spin.setSuffix("%")
            threshold_spin.setStyleSheet("font-size: 12px;")
            threshold_layout.addWidget(threshold_label)
            threshold_layout.addWidget(threshold_spin)
            threshold_layout.addStretch()
            
            # 开机自启设置
            auto_start_layout = QtWidgets.QHBoxLayout()
            auto_start_check = QtWidgets.QCheckBox("开机自动启动")
            auto_start_check.setStyleSheet("font-size: 12px;")
            auto_start_check.setChecked(self.is_auto_start_enabled())
            auto_start_layout.addWidget(auto_start_check)
            auto_start_layout.addStretch()
            
            # 按钮
            button_box = QtWidgets.QDialogButtonBox(QtWidgets.QDialogButtonBox.Ok | QtWidgets.QDialogButtonBox.Cancel)
            button_box.accepted.connect(dialog.accept)
            button_box.rejected.connect(dialog.reject)
            
            layout.addLayout(threshold_layout)
            layout.addLayout(auto_start_layout)
            layout.addWidget(button_box)
            
            if dialog.exec_() == QtWidgets.QDialog.Accepted:
                self.threshold = threshold_spin.value()
                self.set_auto_start(auto_start_check.isChecked())
                # 更新阈值显示
                self.value_labels[4].setText(f"{self.threshold}%")
                QtWidgets.QMessageBox.information(self, "设置已保存", f"内存清理阈值已设置为 {self.threshold}%")
                logging.info(f"内存清理阈值已设置为 {self.threshold}%")
        except Exception as e:
            logging.error(f"显示设置时出错: {e}")
    
    def is_auto_start_enabled(self):
        """检查是否已设置开机自启"""
        if os.name != 'nt':
            return False
            
        try:
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                                r"Software\Microsoft\Windows\CurrentVersion\Run", 
                                0, winreg.KEY_READ)
            try:
                winreg.QueryValueEx(key, "MemoryOptimizer")
                return True
            except FileNotFoundError:
                return False
            finally:
                winreg.CloseKey(key)
        except Exception:
            return False
    
    def set_auto_start(self, enable):
        """设置或取消开机自启"""
        if os.name != 'nt':
            return
            
        try:
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                                r"Software\Microsoft\Windows\CurrentVersion\Run", 
                                0, winreg.KEY_WRITE)
            
            if enable:
                # 获取当前可执行文件路径
                exe_path = sys.executable if getattr(sys, 'frozen', False) else sys.argv[0]
                winreg.SetValueEx(key, "MemoryOptimizer", 0, winreg.REG_SZ, f'"{exe_path}" --minimized')
            else:
                try:
                    winreg.DeleteValue(key, "MemoryOptimizer")
                except FileNotFoundError:
                    pass  # 如果值不存在，不需要处理
                    
            winreg.CloseKey(key)
        except Exception as e:
            logging.error(f"设置开机自启时出错: {e}")
    
    def closeEvent(self, event):
        """重写关闭事件，最小化到托盘而不是退出"""
        event.ignore()
        self.hide()
        self.tray_icon.showMessage(
            "内存优化工具",
            "程序已最小化到系统托盘，双击托盘图标可重新打开窗口。",
            QtGui.QIcon(resource_path("memory.ico")),
            2000
        )

class SystemTrayIcon(QtWidgets.QSystemTrayIcon):
    def __init__(self, main_window, parent=None):
        super(SystemTrayIcon, self).__init__(parent)
        self.main_window = main_window
        
        # 使用资源路径加载图标
        icon_path = resource_path("memory.ico")
        self.setIcon(QtGui.QIcon(icon_path))
        
        self.menu = QtWidgets.QMenu(parent)
        
        # 添加菜单项
        self.status_action = self.menu.addAction("内存状态: 检测中...")
        self.show_action = self.menu.addAction("显示主窗口")
        self.show_action.triggered.connect(self.show_main_window)
        
        self.clean_action = self.menu.addAction("立即清理内存")
        self.clean_action.triggered.connect(self.main_window.clean_memory)
        
        self.settings_action = self.menu.addAction("设置")
        self.settings_action.triggered.connect(self.main_window.show_settings)
        
        exit_action = self.menu.addAction("退出")
        exit_action.triggered.connect(self.quit_application)
        
        self.setContextMenu(self.menu)
        self.activated.connect(self.on_tray_icon_activated)
        
        # 内存监控定时器
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.update_status)
        self.timer.start(5000)  # 每5秒更新一次状态
    
    def on_tray_icon_activated(self, reason):
        if reason == self.DoubleClick:  # 双击托盘图标
            self.show_main_window()
    
    def update_status(self):
        """更新托盘图标状态"""
        try:
            memory = psutil.virtual_memory()
            used_percent = memory.percent
            
            # 更新状态文本
            status_text = f"内存使用: {used_percent:.1f}% ({memory.used//1024//1024}MB/{memory.total//1024//1024}MB)"
            self.status_action.setText(status_text)
            
            # 根据内存使用率更新托盘图标提示
            self.setToolTip(f"内存优化工具 - {status_text}")
        except Exception as e:
            logging.error(f"更新托盘状态时出错: {e}")
    
    def show_main_window(self):
        """显示主窗口"""
        self.main_window.show()
        self.main_window.activateWindow()
        self.main_window.raise_()
    
    def quit_application(self):
        """安全退出应用程序"""
        logging.info("程序退出")
        self.main_window.timer.stop()
        QtWidgets.QApplication.quit()

def main():
    # 设置日志
    setup_logging()
    
    # 创建应用程序实例
    app = QtWidgets.QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    
    # 设置应用程序图标
    icon_path = resource_path("memory.ico")
    app.setWindowIcon(QtGui.QIcon(icon_path))
    
    try:
        # 创建主窗口
        main_window = MainWindow()
        
        # 创建系统托盘图标
        tray_icon = SystemTrayIcon(main_window)
        tray_icon.show()
        
        # 将托盘图标保存到主窗口，以便访问
        main_window.tray_icon = tray_icon
        
        # 检查启动参数，决定是否显示主窗口
        if "--minimized" not in sys.argv:
            main_window.show()
        
        logging.info("应用程序启动成功")
        sys.exit(app.exec_())
    except Exception as e:
        logging.error(f"应用程序启动时出错: {e}")
        # 显示错误消息框
        error_msg = QtWidgets.QMessageBox()
        error_msg.setIcon(QtWidgets.QMessageBox.Critical)
        error_msg.setText("应用程序启动失败")
        error_msg.setInformativeText(str(e))
        error_msg.exec_()

if __name__ == "__main__":
    # 检查管理员权限
    if os.name == 'nt':
        try:
            import ctypes
            if not ctypes.windll.shell32.IsUserAnAdmin():
                # 重新以管理员权限运行
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
                sys.exit(0)
        except:
            pass  # 如果无法检查管理员权限，继续运行
    
    main()