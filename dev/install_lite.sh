#!/bin/sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 脚本安装位置
INSTALL_DIR="/usr/bin"
SCRIPT_NAME="mac_random.sh"
INIT_SCRIPT_NAME="mac_random"
INIT_SCRIPT_PATH="/etc/init.d/$INIT_SCRIPT_NAME"

# MAC随机化脚本内容
create_mac_random_script() {
    cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查命令是否存在
check_commands() {
    for cmd in ip iwinfo hexdump; do
        if ! which "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}错误: 命令 '$cmd' 未找到${NC}"
            exit 1
        fi
    done
}

# 修改MAC地址
change_mac() {
    local interface="$1"
    local new_mac="$2"
    
    ip link set "$interface" down
    ip link set "$interface" address "$new_mac"
    ip link set "$interface" up
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功修改 $interface 的MAC地址为: $new_mac${NC}"
    else
        echo -e "${RED}修改 $interface 的MAC地址失败${NC}"
    fi
}

# 生成随机MAC地址
generate_mac() {
    # 生成一个1-48的随机数
    local rand=$(hexdump -n 1 -e '1/1 "%u"' /dev/urandom)
    local vendor_index=$((rand % 48))
    
    # 各大厂商的OUI前缀列表
    local prefix
    local vendor_name
    case "$vendor_index" in
        0|1|2) 
            prefix="D8:5D:4C"
            vendor_name="TP-Link"
            ;;
        3|4|5) 
            prefix="F4:EC:38"
            vendor_name="TP-Link"
            ;;
        6|7) 
            prefix="00:14:BF"
            vendor_name="Linksys"
            ;;
        8|9) 
            prefix="DC:9F:DB"
            vendor_name="Linksys"
            ;;
        10|11) 
            prefix="00:50:F1"
            vendor_name="Buffalo"
            ;;
        12|13) 
            prefix="20:4E:7F"
            vendor_name="Buffalo"
            ;;
        14|15) 
            prefix="00:18:E7"
            vendor_name="Netgear"
            ;;
        16|17) 
            prefix="B0:48:7A"
            vendor_name="Asus"
            ;;
        18|19) 
            prefix="00:15:6D"
            vendor_name="D-Link"
            ;;
        20|21) 
            prefix="00:24:6C"
            vendor_name="Qualcomm"
            ;;
        22|23) 
            prefix="48:2C:6A"
            vendor_name="Qualcomm"
            ;;
        24|25) 
            prefix="00:28:F8"
            vendor_name="Intel"
            ;;
        26|27) 
            prefix="3C:F8:62"
            vendor_name="Intel"
            ;;
        28|29) 
            prefix="00:0E:6A"
            vendor_name="Broadcom"
            ;;
        30|31) 
            prefix="00:17:C2"
            vendor_name="Broadcom"
            ;;
        32|33) 
            prefix="00:04:A3"
            vendor_name="MediaTek"
            ;;
        34|35) 
            prefix="00:14:A4"
            vendor_name="MediaTek"
            ;;
        36|37) 
            prefix="00:03:93"
            vendor_name="Apple"
            ;;
        38|39) 
            prefix="00:0A:27"
            vendor_name="Apple"
            ;;
        40|41) 
            prefix="00:12:17"
            vendor_name="Cisco"
            ;;
        42|43) 
            prefix="00:15:E8"
            vendor_name="Ubiquiti"
            ;;
        44|45) 
            prefix="00:0C:43"
            vendor_name="Ralink"
            ;;
        46|47) 
            prefix="00:14:6C"
            vendor_name="Netis"
            ;;
        *) 
            prefix="D8:5D:4C"
            vendor_name="TP-Link"
            ;;
    esac
    
    # 生成随机后缀
    local suffix=$(hexdump -n3 -e '/1 ":%02X"' /dev/urandom)
    
    # 输出厂商名称和MAC地址
    echo "使用厂商: $vendor_name"
    echo "$prefix$suffix"
}

# 主程序
main() {
    # 检查root权限
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}此脚本需要root权限运行${NC}"
        exit 1
    fi
    
    # 检查必需的命令
    check_commands
    
    # 修改br-lan接口
    echo -e "${YELLOW}开始修改 br-lan MAC地址...${NC}"
    local mac_info=$(generate_mac)
    local new_mac=$(echo "$mac_info" | tail -n1)
    echo -e "$mac_info"
    change_mac br-lan "$new_mac"
    
    # 获取无线接口列表并逐个修改
    echo -e "\n${YELLOW}开始修改无线接口MAC地址...${NC}"
    local wireless_interfaces=$(iwinfo | grep "ESSID" | cut -d" " -f1)
    
    for interface in $wireless_interfaces; do
        echo -e "\n${YELLOW}处理接口: $interface${NC}"
        mac_info=$(generate_mac)
        new_mac=$(echo "$mac_info" | tail -n1)
        echo -e "$mac_info"
        change_mac "$interface" "$new_mac"
    done
    
    echo -e "\n${GREEN}所有接口MAC地址修改完成${NC}"
}

# 运行主程序
main
EOF

    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
}

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}此脚本需要root权限运行${NC}"
        exit 1
    fi
}

# 检查并安装必需的命令
check_dependencies() {
    local missing_cmds=""
    for cmd in ip iwinfo hexdump crontab; do
        if ! which "$cmd" >/dev/null 2>&1; then
            missing_cmds="$missing_cmds $cmd"
        fi
    done
    
    if [ -n "$missing_cmds" ]; then
        echo -e "${YELLOW}需要安装以下命令:${NC}$missing_cmds"
        echo -n "是否现在安装? [y/N] "
        read answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            opkg update
            for cmd in $missing_cmds; do
                case "$cmd" in
                    ip) opkg install ip-full ;;
                    iwinfo) opkg install iwinfo ;;
                    hexdump) opkg install busybox ;;
                    crontab) opkg install cron ;;
                esac
            done
            echo -e "${GREEN}依赖安装完成${NC}"
        else
            echo -e "${RED}缺少必需的命令，退出安装${NC}"
            exit 1
        fi
    fi
}

# 创建init.d启动脚本
create_init_script() {
    cat > "$INIT_SCRIPT_PATH" << EOF
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1
PROG=$INSTALL_DIR/$SCRIPT_NAME

start_service() {
    procd_open_instance
    procd_set_param command \$PROG
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

reload_service() {
    stop
    start
}
EOF
    chmod +x "$INIT_SCRIPT_PATH"
}

# 配置定时任务
setup_cron() {
    echo -e "${YELLOW}是否要设置定时更换MAC地址？[y/N] ${NC}"
    read answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        echo -e "请选择定时更换周期："
        echo "1) 每小时"
        echo "2) 每天"
        echo "3) 每周"
        echo "4) 自定义"
        read -p "请选择 [1-4]: " period_choice
        
        case "$period_choice" in
            1) cron_time="0 * * * *" ;;
            2) cron_time="0 0 * * *" ;;
            3) cron_time="0 0 * * 0" ;;
            4)
                echo "请输入crontab格式的时间设置（分 时 日 月 周）："
                read cron_time
                ;;
            *) 
                echo -e "${RED}无效的选择，不设置定时任务${NC}"
                return
                ;;
        esac
        
        # 添加定时任务
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_NAME"; echo "$cron_time $INSTALL_DIR/$SCRIPT_NAME") | crontab -
        /etc/init.d/cron restart
        echo -e "${GREEN}定时任务设置完成${NC}"
    fi
}

# 安装脚本
install_script() {
    # 创建主脚本
    create_mac_random_script
    
    # 创建并启用init.d脚本
    create_init_script
    /etc/init.d/$INIT_SCRIPT_NAME enable
    
    echo -e "${GREEN}脚本安装完成${NC}"
}

# 卸载脚本
uninstall_script() {
    # 停止服务
    if [ -f "$INIT_SCRIPT_PATH" ]; then
        $INIT_SCRIPT_PATH stop
        $INIT_SCRIPT_PATH disable
        rm -f "$INIT_SCRIPT_PATH"
    fi
    
    # 删除主脚本
    rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    
    # 删除定时任务
    crontab -l 2>/dev/null | grep -v "$SCRIPT_NAME" | crontab -
    
    echo -e "${GREEN}脚本卸载完成${NC}"
}

# 主程序
main() {
    check_root
    
    echo -e "${YELLOW}MAC地址随机化脚本安装/卸载工具${NC}"
    echo "1) 安装"
    echo "2) 卸载"
    echo "3) 退出"
    
    read -p "请选择 [1-3]: " choice
    
    case "$choice" in
        1)
            echo -e "\n${YELLOW}开始安装...${NC}"
            check_dependencies
            install_script
            setup_cron
            echo -e "\n${GREEN}安装完成！${NC}"
            echo "您可以通过以下方式使用："
            echo "1. 手动运行：$INSTALL_DIR/$SCRIPT_NAME"
            echo "2. 服务控制：/etc/init.d/$INIT_SCRIPT_NAME {start|stop|restart}"
            ;;
        2)
            echo -e "\n${YELLOW}开始卸载...${NC}"
            uninstall_script
            ;;
        3)
            echo "退出安装程序"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            exit 1
            ;;
    esac
}

# 运行主程序
main

