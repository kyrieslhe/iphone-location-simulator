# iPhone 定位模拟器

在 Mac 上通过 USB 为 iPhone 设置临时经纬度。可以用它检查地图或微信朋友圈等 App 如何使用模拟位置。程序通过 [pymobiledevice3 的定位模拟命令](https://doronz88.github.io/pymobiledevice3/latest/guides/cli-recipes/#dvt-examples) 使用 iPhone 的开发者接口。

## 安装

需要一台 Mac、Python 3.9 或更新版本，以及一台通过 USB 连接的 iPhone。此工具使用 iOS 17 起提供的连接方式。**定位模拟已在 iOS 27.2.1 真机上测试通过。** 微信等 App 是否采用模拟位置，以各自版本的实测结果为准。

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

## 许可证

本项目采用 [GPL-3.0-or-later](LICENSE) 许可证。
