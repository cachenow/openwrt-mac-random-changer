# OpenWrt MAC地址随机化脚本

这是一个专为OpenWrt系统开发的MAC地址随机化脚本，可以帮助您自动更改网络接口的MAC地址，提高网络隐私性和安全性。

## 功能特点

- 支持多个网络接口同时修改MAC地址
- 使用知名网络设备制造商的MAC地址前缀
- 支持开机自启动和定时更新
- 提供图形化的接口选择菜单
- 支持自动识别WAN口
- 完整的安装和卸载功能

## 系统要求

- OpenWrt系统
- root权限
- 必需的系统工具：
  - ip
  - iwinfo
  - hexdump
  - cron
  - uci

## 安装方法

1. 下载安装脚本到OpenWrt系统：
```bash
wget https://raw.githubusercontent.com/cachenow/openwrt-mac-random-changer/main/install.sh
```

2. 添加执行权限：
```bash
chmod +x install.sh
```

3. 运行安装脚本：
```bash
./install.sh
```

## 使用方法

安装完成后，您可以：

1. 直接运行命令修改MAC地址：
```bash
mac_random.sh
```

2. 通过OpenWrt启动脚本控制：
```bash
/etc/init.d/mac_random restart # 与运行 mac_random.sh 功能一致
```

## 配置文件

- 主配置文件位置：`/etc/mac_random/interfaces.conf`
- 启动脚本位置：`/etc/init.d/mac_random`
- 主程序位置：`/usr/bin/mac_random.sh`

## 卸载方法

运行安装脚本并选择卸载选项：
```bash
./install.sh -u
```

## 注意事项

1. 修改MAC地址会暂时中断网络连接
2. 建议在修改WAN口MAC地址前备份原始MAC地址
3. 某些ISP可能会限制MAC地址修改
4. 修改MAC地址可能会影响OpenWrt的一些网络设置

## 故障排除

如果遇到问题：

1. 检查是否有root权限
2. 确认所需的系统工具是否已安装
3. 检查网络接口名称是否正确
4. 使用`logread`命令查看系统日志获取详细错误信息
5. 检查OpenWrt系统版本兼容性

## 许可证

本项目采用 MIT 许可证
