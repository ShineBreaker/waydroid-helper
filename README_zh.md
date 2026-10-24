# Waydroid Helper

**语言**: [English](README.md) | [中文](README_zh.md) | [Русский](README_ru.md)

Waydroid Helper 是一个基于 Python 和 PyGObject 的图形界面工具，用于配置 Waydroid、管理按键映射以及安装 Magisk 和 ARM 转译层等扩展。

## 功能特性

- 配置 Waydroid 属性与共享文件夹
- **按键映射。** 为 Android 应用和游戏映射键盘与鼠标操作：
  - 提供单击、连击、方向键、准星、开火、技能施法、右键行走与宏按键组件
  - 支持自定义按键绑定及布局导入导出
  - 详细用法见[按键映射指南](docs/KEY_MAPPING_zh.md)
- 为 Waydroid 安装扩展
  - [Magisk](https://github.com/topjohnwu/Magisk)
  - ~~[Magisk](https://github.com/HuskyDG/magisk-files/)~~
  - [libhoudini](https://github.com/supremegamers/vendor_intel_proprietary_houdini)
  - [libndk](https://github.com/supremegamers/vendor_google_proprietary_ndk_translation-prebuilt)
  - [OpenGapps](https://sourceforge.net/projects/opengapps/)
  - [MindTheGapps](https://github.com/MindTheGapps)
  - [MicroG](https://microg.org/)
  - [SmartDock](https://github.com/axel358/smartdock)

## 安装

### Arch

对于 Arch 用户，Waydroid Helper 在 AUR 中可用：
```
yay -S waydroid-helper
```

### Debian

##### 对于 **Debian Unstable** 运行以下命令：

```
echo 'deb http://download.opensuse.org/repositories/home:/CuteNeko:/waydroid-helper/Debian_Unstable/ /' | sudo tee /etc/apt/sources.list.d/home:CuteNeko:waydroid-helper.list
curl -fsSL https://download.opensuse.org/repositories/home:CuteNeko:waydroid-helper/Debian_Unstable/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_CuteNeko_waydroid-helper.gpg > /dev/null
echo -e "Package: python3-pywayland\nPin: origin \"download.opensuse.org\"\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/99-pywayland.pref
sudo apt update
sudo apt install waydroid-helper
```

##### 对于 **Debian Testing** 运行以下命令

```
echo 'deb http://download.opensuse.org/repositories/home:/CuteNeko:/waydroid-helper/Debian_Testing/ /' | sudo tee /etc/apt/sources.list.d/home:CuteNeko:waydroid-helper.list
curl -fsSL https://download.opensuse.org/repositories/home:CuteNeko:waydroid-helper/Debian_Testing/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_CuteNeko_waydroid-helper.gpg > /dev/null
echo -e "Package: python3-pywayland\nPin: origin \"download.opensuse.org\"\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/99-pywayland.pref
sudo apt update
sudo apt install waydroid-helper
```

##### 对于 **Debian 12** 运行以下命令：

```
echo 'deb http://download.opensuse.org/repositories/home:/CuteNeko:/waydroid-helper/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:CuteNeko:waydroid-helper.list
curl -fsSL https://download.opensuse.org/repositories/home:CuteNeko:waydroid-helper/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_CuteNeko_waydroid-helper.gpg > /dev/null
echo -e "Package: python3-pywayland\nPin: origin \"download.opensuse.org\"\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/99-pywayland.pref
sudo apt update
sudo apt install waydroid-helper
```

##### 对于 **Debian 13** 运行以下命令：

```
echo 'deb http://download.opensuse.org/repositories/home:/CuteNeko:/waydroid-helper/Debian_13/ /' | sudo tee /etc/apt/sources.list.d/home:CuteNeko:waydroid-helper.list
curl -fsSL https://download.opensuse.org/repositories/home:CuteNeko:waydroid-helper/Debian_13/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_CuteNeko_waydroid-helper.gpg > /dev/null
echo -e "Package: python3-pywayland\nPin: origin \"download.opensuse.org\"\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/99-pywayland.pref
sudo apt update
sudo apt install waydroid-helper
```

### Fedora

```
sudo dnf copr enable cuteneko/waydroid-helper
sudo dnf install waydroid-helper
```

按键映射器需要额外安装的包（DNF 包未声明这些依赖）：

- `vte291-gtk4`：GTK4 版 VTE 终端组件（程序引用 `Vte 3.91`）
- `python3-aiofiles` 和 `python3-httpx`：DNF 依赖中缺失的 Python 模块
- `android-tools`：提供 ADB，按键映射器与 Waydroid 通信必需；缺少时按键映射器会静默失败

### Ubuntu

```
sudo add-apt-repository ppa:ichigo666/ppa
echo -e "Package: python3-pywayland\nPin: origin \"ppa.launchpadcontent.net\"\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/99-ichigo666-ppa.pref
sudo apt update
sudo apt install waydroid-helper
```

### 从发布版本安装
1. 前往[发布页面](https://github.com/waydroid-helper/waydroid-helper/releases)
2. 下载适合您发行版的软件包
3. 安装软件包


### 手动构建和安装

对于手动安装，您需要安装依赖项并使用 Meson 构建项目。

#### Arch、Manjaro 和 EndeavourOS 基础发行版
1. 安装依赖项：

    ```bash
    sudo pacman -S gtk4 libadwaita meson ninja
    ```

2. 克隆仓库：
    ```
    git clone https://github.com/waydroid-helper/waydroid-helper.git
    cd waydroid-helper
    ```
3. 使用 Meson 构建和安装：
    ```
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    meson setup --prefix /usr build
    sudo ninja -C build install
    
    # 卸载 waydroid helper
    # sudo ninja -C build uninstall
    ```

#### Debian 和 Ubuntu 基础发行版
1. 安装依赖项：

    ```bash
    sudo apt install libgtk-4-1 libgtk-4-dev libadwaita-1-dev libadwaita-1-0 libgirepository1.0-dev gcc libcairo2-dev pkg-config python3-dev gir1.2-gtk-4.0 gir1.2-adw-1 gettext ninja-build fakeroot libdbus-1-dev desktop-file-utils software-properties-common -y
    ```

2. 克隆仓库：
    ```
    git clone https://github.com/waydroid-helper/waydroid-helper.git
    cd waydroid-helper
    ```
3. 使用 Meson 构建和安装：
    ```
    python3 -m venv .venv
    source .venv/bin/activate
    pip install meson
    pip install -r requirements.txt
    meson setup --prefix /usr build
    sudo ninja -C build install
    
    # 卸载 waydroid helper
    # sudo ninja -C build uninstall
    ```

#### RHEL、Fedora 和 Rocky 基础发行版
1. 安装依赖项：

    ```bash
    sudo dnf install gtk4 gtk4-devel libadwaita libadwaita-devel gobject-introspection-devel gcc cairo-devel pkgconf-pkg-config python3-devel gobject-introspection gtk4-devel libadwaita-devel gettext ninja-build fakeroot dbus-devel desktop-file-utils -y
    ```

2. 克隆仓库：
    ```
    git clone https://github.com/waydroid-helper/waydroid-helper.git
    cd waydroid-helper
    ```
3. 使用 Meson 构建和安装：
    ```
    python3 -m venv .venv
    source .venv/bin/activate
    pip install meson
    pip install -r requirements.txt
    meson setup --prefix /usr build
    sudo ninja -C build install
    
    # 卸载 waydroid helper
    # sudo ninja -C build uninstall
    ```

## 截图

![image-20241125011305536](assets/img/README/1_zh.png)

![](./assets/img/README/2_cn.png)
![](./assets/img/README/3_cn.png)

## 文档

- [按键映射指南](docs/KEY_MAPPING_zh.md)介绍了如何使用键盘和鼠标控制 Android 应用与游戏。

## 故障排除

### 共享文件夹不工作
启用 systemd 服务：
```
systemctl --user enable waydroid-monitor.service --now
sudo systemctl enable waydroid-mount.service --now
```

对于 AppImage 用户，需要将 D-Bus 配置文件和 systemd 单元文件复制到对应的系统目录：

```
usr
├── lib
│   └── systemd
│       ├── system
│       │   └── waydroid-mount.service
│       └── user
│           └── waydroid-monitor.service
└── share
    ├── dbus-1
    │   ├── system.d
    │   │   └── id.waydro.Mount.conf
    │   └── system-services
    │       └── id.waydro.Mount.service

```
### 安装 MicroG 或 GApps 后 Waydroid 无法启动
如果安装 MicroG 或 GApps 后 Waydroid 无法启动：

1. **使用 vanilla 镜像。** 确认 Waydroid 使用的是 vanilla 系统镜像，而非自带 GApps 的镜像。
2. **重置 Waydroid 数据。** 若问题仍未解决，删除 `~/.local/share/waydroid/data` 目录后重新执行 `sudo waydroid init -f`。该操作会清空所有 Waydroid 用户数据，请提前备份文件。

### ZygiskNext / ReZygisk 不工作

ZygiskNext 和 ReZygisk 依赖通过 `reboot` kprobe 钩子挂载的内核侧 IOCTL 接口 SuperCall。Waydroid 默认的 seccomp 配置拦截了 `reboot` 系统调用，导致 SuperCall 无法初始化。

从 Waydroid seccomp 配置中移除 `reboot` 规则并更新配置：

```
sudo sed -i '/reboot/d' /usr/lib/waydroid/data/configs/waydroid.seccomp
sudo waydroid upgrade -o
```

## 致谢

感谢 [scrcpy](https://github.com/Genymobile/scrcpy) 项目。Waydroid Helper 使用 `scrcpy-server` 注入按键映射的输入事件。
