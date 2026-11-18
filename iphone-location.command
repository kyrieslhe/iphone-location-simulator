#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""模拟通过 USB 连接的 iPhone 的定位。双击运行，或用 --help 查看命令。"""

import argparse
import json
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys


SIMULATE = ('developer', 'dvt', 'simulate-location')
PROJECT = Path(__file__).resolve().parent


class UserError(Exception):
    pass


def find_backend():
    local = PROJECT / '.venv' / 'bin' / 'pymobiledevice3'
    if local.is_file():
        return [str(local)]
    installed = shutil.which('pymobiledevice3')
    if installed:
        return [installed]
    raise UserError('找不到 pymobiledevice3。请按 README 的安装步骤创建 .venv 并安装依赖。')


def read_json(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise UserError(detail or f'设备查询失败（退出码 {result.returncode}）。')
    try:
        return json.loads(result.stdout)
    except ValueError as error:
        detail = result.stderr.strip() or result.stdout.strip()
        raise UserError(f'无法读取设备状态。\n{detail}') from error


def find_phone(backend):
    devices = read_json([*backend, 'usbmux', 'list'])
    phones = [device for device in devices
              if device.get('ConnectionType') == 'USB' and device.get('DeviceClass') == 'iPhone']
    if not phones:
        raise UserError('未找到 USB 连接的 iPhone。请解锁手机，接上数据线，并在提示时点「信任」。')
    if len(phones) > 1:
        raise UserError('检测到了多台 iPhone。请只保留要操作的 iPhone。')
    phone = phones[0]
    if not phone.get('UniqueDeviceID'):
        raise UserError('无法读取设备标识。请重新插拔数据线并检查信任状态。')
    return phone


def parse_coordinates(value):
    try:
        latitude, longitude = map(float, re.split(r'[\s,，]+', value.strip()))
    except ValueError as error:
        raise UserError('请输入纬度和经度，例如 35.68124, 139.76710。') from error
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise UserError('纬度应在 -90 到 90 之间，经度应在 -180 到 180 之间。')
    return latitude, longitude


def clear_location(command):
    result = subprocess.run(command, timeout=30, start_new_session=True)
    if result.returncode != 0:
        raise UserError('清除定位模拟失败。请保持手机连接后再次选择「恢复真实定位」。')
    print('已发送停止模拟的指令。可打开「地图」确认位置已恢复。')


def simulate(backend, device_args, coords):
    latitude, longitude = coords
    command = [*backend, *SIMULATE, 'set', *device_args, '--', str(latitude), str(longitude)]
    print(f'正在请求模拟定位（{latitude}, {longitude}）。请保持数据线连接。', flush=True)
    print('先在 iPhone「地图」里看蓝点，再检查微信朋友圈的「所在位置」。', flush=True)
    print('测试完后在这个窗口按 Control+C 结束并恢复定位。', flush=True)

    def stop_session(_signal, _frame):
        raise KeyboardInterrupt

    watched = (signal.SIGTERM, signal.SIGHUP)
    handlers = {sig: signal.signal(sig, stop_session) for sig in watched}
    try:
        with subprocess.Popen(command, start_new_session=True) as process:
            try:
                result = process.wait()
            except KeyboardInterrupt:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                result = 0
    finally:
        for sig, handler in handlers.items():
            signal.signal(sig, handler)
    if result != 0:
        raise UserError('模拟会话未能正常结束。如果地图上的位置已改变，请再运行「恢复真实定位」。')
    clear_location([*backend, *SIMULATE, 'clear', *device_args])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command')
    commands.add_parser('status', help='检查 USB 连接、iOS 版本和开发者模式')
    setting = commands.add_parser('set', help='开始模拟，按 Control+C 结束并恢复')
    setting.add_argument('latitude', type=float)
    setting.add_argument('longitude', type=float)
    commands.add_parser('clear', help='恢复真实定位')
    commands.add_parser('reveal', help='在 iPhone 设置中显示开发者模式开关')
    args = parser.parse_args()
    command = args.command
    if command is None:
        print('iPhone 定位模拟\n1. 模拟定位\n2. 恢复真实定位\n3. 检查连接\n4. 显示开发者模式开关')
        command = {'1': 'set', '2': 'clear', '3': 'status', '4': 'reveal'}.get(input('选择（回车退出）：').strip())
        if command is None:
            return

    backend = find_backend()
    phone = find_phone(backend)
    print(f"已连接 iPhone（iOS {phone.get('ProductVersion', '未知')}）", flush=True)
    device_args = ['--udid', phone['UniqueDeviceID']]
    if command == 'reveal':
        subprocess.run([*backend, 'amfi', 'reveal-developer-mode', *device_args], check=True, timeout=20)
        print('请在 iPhone 的「设置 → 隐私与安全性 → 开发者模式」开启，重启后再次确认。')
        return

    enabled = read_json([*backend, 'amfi', 'developer-mode-status', *device_args])
    if not isinstance(enabled, bool):
        raise UserError('无法确认开发者模式的状态。')
    print('开发者模式：' + ('已开启' if enabled else '未开启'), flush=True)
    if command == 'status':
        return
    if not enabled:
        raise UserError('请先在 iPhone 的「设置 → 隐私与安全性 → 开发者模式」开启，重启后确认。如果看不到开关，使用本程序的选项 4。')
    if command == 'clear':
        clear_location([*backend, *SIMULATE, 'clear', *device_args])
        return

    if args.command == 'set':
        coords = parse_coordinates(f'{args.latitude} {args.longitude}')
    else:
        coords = parse_coordinates(input('输入纬度、经度（例如 35.68124, 139.76710）：'))
    simulate(backend, device_args, coords)


if __name__ == '__main__':
    exit_status = 0
    try:
        main()
    except (UserError, OSError, subprocess.SubprocessError) as error:
        print(f'操作未完成：{error}', file=sys.stderr)
        exit_status = 1
    except (KeyboardInterrupt, EOFError):
        print('\n已退出。')
        exit_status = 130
    if len(sys.argv) == 1 and sys.stdin.isatty():
        try:
            input('按回车关闭。')
        except (KeyboardInterrupt, EOFError):
            pass
    sys.exit(exit_status)
