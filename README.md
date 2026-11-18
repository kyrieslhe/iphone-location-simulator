# iPhone 定位模拟器

在 Mac 上通过 USB 为 iPhone 设置临时经纬度。可以用它检查地图或微信朋友圈等 App 如何使用模拟位置。程序通过 [pymobiledevice3 的定位模拟命令](https://doronz88.github.io/pymobiledevice3/latest/guides/cli-recipes/#dvt-examples) 使用 iPhone 的开发者接口。

## 支持哪些设备？

| 设备组合 | 怎么用 |
| --- | --- |
| Mac + iPhone | 用本仓库的 `iphone-location.command`，通过 USB 连接。**已在 iOS 27.2.1 真机上测试通过。** |
| Windows + iPhone | 可尝试直接用 `pymobiledevice3`，需要带 Apple Mobile Device Service 的 iTunes。本项目未在 Windows 上实测。 |
| Linux + iPhone | 可尝试直接用 `pymobiledevice3`，需要安装并启动 `usbmuxd`。本项目未在 Linux 上实测。 |
| iPad | 当前脚本只识别 iPhone。iPad 可以尝试直接用 `pymobiledevice3`，本项目未实测。 |
| 安卓 | 本工具使用苹果的开发者接口，安卓不适用。 |

微信等 App 是否采用模拟位置，以各自版本的实测结果为准。

## 安装

在 Mac 上使用本仓库的脚本需要 Python 3.9 或更新版本，以及一台通过 USB 连接的 iPhone。脚本使用 iOS 17 起提供的开发者连接方式。

```sh
git clone https://github.com/kyrieslhe/iphone-location-simulator.git
cd iphone-location-simulator
python3 -m venv .venv
./.venv/bin/python -m pip install -r requirements.txt
```

## 使用

1. 用数据线连接并解锁 iPhone。手机提示是否信任此电脑时，选择「信任」。
2. 打开 iPhone 的「设置 → 隐私与安全性 → 开发者模式」，开启后重启并确认。如果看不到开关，先运行 `./iphone-location.command reveal`，再检查设置。[Apple 开发者模式说明](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
3. 在 Finder 里双击 `iphone-location.command`，选「模拟定位」，输入纬度和经度。例如伦敦特拉法加广场是 `51.5080, -0.1281`。也可以在终端直接运行下面的命令。
4. 保持数据线和终端会话连接。在 iPhone「地图」中查看蓝点，再到微信朋友圈的「所在位置」看目标地点是否可选。
5. 测试结束后在终端按 **Control+C**，程序会发送停止模拟的指令。如果断开了 USB，请重新连接，再运行 `./iphone-location.command clear`。可以打开「地图」确认位置是否恢复。

```sh
# 查看 USB 连接、iOS 版本和开发者模式
./iphone-location.command status

# 模拟伦敦特拉法加广场，参数顺序为纬度、经度
./iphone-location.command set 51.5080 -0.1281

# 手动清除模拟位置
./iphone-location.command clear
```

## Windows、Linux 或 iPad

以下命令适用于尝试连接 iOS / iPadOS 17.4 或更新版本的设备。较早版本的连接方式见 [pymobiledevice3 安装说明](https://doronz88.github.io/pymobiledevice3/master/installation/)。先完成对应系统的驱动或服务安装，再用 USB 连接并解锁设备，信任电脑并开启开发者模式。运行命令时只连接一台要操作的设备。

```sh
python -m pip install pymobiledevice3==11.58.0
pymobiledevice3 usbmux list
pymobiledevice3 developer dvt simulate-location set -- 51.5080 -0.1281
```

如果系统用 `python3` 启动 Python，把安装命令里的 `python` 换成 `python3`。如果找不到 `pymobiledevice3` 命令，可以用 `python -m pymobiledevice3` 代替。

测试结束后，按终端提示退出模拟会话，再运行下面的命令清除模拟位置。

```sh
pymobiledevice3 developer dvt simulate-location clear
```

## 许可证

本项目采用 [GPL-3.0-or-later](LICENSE) 许可证。
