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
CONFIG_FILE="/etc/mac_random/interfaces.conf"

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
    
    # 获取配置文件
    local config_file="$CONFIG_FILE"
    
    # 读取配置文件
    if [ -f "$config_file" ]; then
        local interfaces=$(grep "^INTERFACES=" "$config_file" | cut -d'"' -f2)
    else
        echo -e "${RED}配置文件未找到${NC}"
        exit 1
    fi
    
    # 修改接口
    for interface in $interfaces; do
        echo -e "\n${YELLOW}处理接口: $interface${NC}"
        local mac_info=$(generate_mac)
        local new_mac=$(echo "$mac_info" | tail -n1)
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
    echo -e "${YELLOW}检查必需的命令...${NC}"
    local missing_cmds=""
    
    # 逐个检查命令并显示状态
    for cmd in ip iwinfo hexdump crontab; do
        echo -n "检查 $cmd ... "
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}未找到${NC}"
            missing_cmds="$missing_cmds $cmd"
        else
            echo -e "${GREEN}已安装${NC}"
        fi
    done
    
    if [ -n "$missing_cmds" ]; then
        echo -e "${YELLOW}需要安装以下命令:${NC}$missing_cmds"
        echo -n "是否现在安装? [y/N] "
        read answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            echo "正在更新软件包列表..."
            opkg update
            for cmd in $missing_cmds; do
                echo "正在安装 $cmd ..."
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
    else
        echo -e "${GREEN}所有必需的命令都已安装${NC}"
    fi
}

# 获取WAN口名称
get_wan_interface() {
    echo -e "${YELLOW}正在检测WAN接口...${NC}"
    # 方法1: 从UCI配置获取
    local uci_wan=""
    if command -v uci >/dev/null 2>&1; then
        echo "尝试从UCI配置获取WAN接口..."
        uci_wan=$(uci get network.wan.device 2>/dev/null)
    fi
    
    # 方法2: 从默认路由获取
    echo "尝试从默认路由获取WAN接口..."
    local route_wan=$(ip route | grep default | awk '{print $5}' 2>/dev/null)
    
    echo "UCI配置的WAN接口: $uci_wan"
    echo "路由表的WAN接口: $route_wan"
    
    # 如果两种方法得到的结果不同，让用户选择
    if [ -n "$uci_wan" ] && [ -n "$route_wan" ] && [ "$uci_wan" != "$route_wan" ]; then
        echo -e "${YELLOW}检测到多个可能的WAN接口：${NC}"
        echo "1) $uci_wan (来自系统配置)"
        echo "2) $route_wan (来自当前路由)"
        echo "请选择要使用的WAN接口："
        read -p "输入选择 [1/2]: " wan_choice
        case "$wan_choice" in
            1) echo "$uci_wan" ;;
            2) echo "$route_wan" ;;
            *) echo "$uci_wan" ;;  # 默认使用UCI配置
        esac
    else
        # 如果只有一个有效值，返回该值
        [ -n "$uci_wan" ] && echo "$uci_wan" || echo "$route_wan"
    fi
}

# 获取所有网络接口
get_all_interfaces() {
    echo -e "${YELLOW}正在获取所有网络接口...${NC}"
    # 获取无线接口
    local wireless_interfaces=$(iwinfo | grep "ESSID" | cut -d" " -f1)
    # 获取有线接口（包括网桥）
    local wired_interfaces=$(ip link show | grep -E ": br-|: eth" | cut -d: -f2 | awk '{print $1}')
    
    echo "找到的无线接口: $wireless_interfaces"
    echo "找到的有线接口: $wired_interfaces"
    
    # 合并并返回所有接口
    echo "$wireless_interfaces $wired_interfaces" | tr ' ' '\n' | sort | uniq | tr '\n' ' '
}

# 配置要修改的接口
configure_interfaces() {
    echo -e "${YELLOW}开始配置接口...${NC}"
    local selected_interfaces=""
    
    # 获取接口列表
    echo "获取无线接口..."
    local wireless_interfaces=$(iwinfo | grep "ESSID" | cut -d" " -f1)
    echo "找到无线接口: $wireless_interfaces"
    
    echo "获取有线接口..."
    local wired_interfaces=$(ip link show | grep -E ": eth|: br-" | cut -d: -f2 | awk '{print $1}')
    echo "找到有线接口: $wired_interfaces"
    
    # 默认添加br-lan
    if ip link show br-lan >/dev/null 2>&1; then
        selected_interfaces="br-lan"
        echo "添加br-lan到选中接口"
    fi
    
    # 添加无线接口
    if [ -n "$wireless_interfaces" ]; then
        selected_interfaces="$selected_interfaces $wireless_interfaces"
        echo "添加无线接口到选中接口"
    fi
    
    # 询问是否修改WAN口
    printf "${YELLOW}是否要修改WAN口MAC地址？[y/N] ${NC}"
    read answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        local wan_interface=$(get_wan_interface)
        if [ -n "$wan_interface" ]; then
            selected_interfaces="$selected_interfaces $wan_interface"
            echo "添加WAN接口到选中接口"
        fi
    fi
    
    # 去除重复的接口
    selected_interfaces=$(echo "$selected_interfaces" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
    echo "最终选择的接口: $selected_interfaces"
    
    # 返回选择的接口列表
    echo "$selected_interfaces"
}

# 读取用户输入
read_input() {
    printf "%s" "$1"
    read answer
    echo "$answer"
}

# 创建配置文件
create_config() {
    local interfaces="$1"
    
    echo "创建配置文件..."
    
    # 创建配置目录
    if [ ! -d "/etc/mac_random" ]; then
        echo "创建配置目录..."
        mkdir -p "/etc/mac_random"
    fi
    
    # 写入配置文件
    echo "写入配置文件..."
    echo "$interfaces" > "$CONFIG_FILE"
    echo "配置文件已创建: $CONFIG_FILE"
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

# 获取接口描述
get_interface_description() {
    local interface="$1"
    local description=""
    
    # 检查是否是网桥接口
    if [ "$interface" = "br-lan" ]; then
        description="LAN口网桥（用于统一管理LAN口）"
        return
    fi
    
    # 检查无线接口
    if iwinfo "$interface" info >/dev/null 2>&1; then
        local hwmode=$(iwinfo "$interface" info 2>/dev/null | grep "Hardware Mode" | cut -d'"' -f2)
        local essid=$(iwinfo "$interface" info 2>/dev/null | grep "ESSID" | cut -d'"' -f2)
        local mode=$(iwinfo "$interface" info 2>/dev/null | grep "Mode:" | awk '{print $2}')
        
        if [ -n "$hwmode" ]; then
            case "$hwmode" in
                *5.0*|*5G*) description="5GHz无线接口" ;;
                *2.4*|*2G*) description="2.4GHz无线接口" ;;
                *) description="无线接口" ;;
            esac
        else
            description="无线接口"
        fi
        
        # 添加模式信息
        case "$mode" in
            "Client") description="$description (中继模式)" ;;
            "Master") 
                [ -n "$essid" ] && description="$description (SSID: $essid)"
                ;;
        esac
    fi
    
    # 检查以太网接口
    if [ -z "$description" ] && (ip link show "$interface" 2>/dev/null | grep -q "ether"); then
        # 检查是否是WAN口
        if ip route | grep default | grep -q "$interface"; then
            description="WAN口（连接外网）"
        else
            description="以太网接口"
            # 检查速率和状态
            local status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]* " | cut -d' ' -f2)
            [ -n "$status" ] && description="$description [$status]"
        fi
    fi
    
    echo "$description"
}

# 显示接口列表
show_interface_list() {
    local i=1
    echo -e "\n${YELLOW}可用的接口：${NC}"
    echo "0) 完成选择"
    
    # 先显示br-lan（如果存在）
    if ip link show br-lan >/dev/null 2>&1; then
        echo "$i) br-lan"
        i=$((i+1))
    fi
    
    # 显示带ESSID的接口
    if [ -n "$essid_interfaces" ]; then
        for interface in $essid_interfaces; do
            echo "$i) $interface"
            i=$((i+1))
        done
    fi
    
    # 显示其他接口
    for interface in $all_interfaces; do
        # 跳过已经显示的接口
        if [ "$interface" != "br-lan" ] && ! echo "$essid_interfaces" | grep -q "$interface"; then
            echo "$i) $interface"
            i=$((i+1))
        fi
    done
    
    # 如果已经选择了接口，显示已选择的接口
    if [ -n "$selected_interfaces" ]; then
        echo -e "\n${GREEN}已选择的接口：${NC}"
        echo "$selected_interfaces" | tr ' ' '\n' | while read -r iface; do
            echo "* $iface"
        done
    fi
    
    echo -e "\n${YELLOW}请选择接口编号（输入0完成选择）：${NC}"
    return $((i-1))
}

# 获取接口名称
get_interface_by_number() {
    local num=$1
    local i=1
    local interface=""
    
    # 检查br-lan
    if [ "$num" = "$i" ] && ip link show br-lan >/dev/null 2>&1; then
        echo "br-lan"
        return
    fi
    i=$((i+1))
    
    # 检查ESSID接口
    if [ -n "$essid_interfaces" ]; then
        for iface in $essid_interfaces; do
            if [ "$num" = "$i" ]; then
                echo "$iface"
                return
            fi
            i=$((i+1))
        done
    fi
    
    # 检查其他接口
    for iface in $all_interfaces; do
        if [ "$iface" != "br-lan" ] && ! echo "$essid_interfaces" | grep -q "$iface"; then
            if [ "$num" = "$i" ]; then
                echo "$iface"
                return
            fi
            i=$((i+1))
        fi
    done
}

# 手动选择接口
manual_select_interfaces() {
    local selected_interfaces=""
    local interface_list=""
    local i=1
    
    echo -e "\n${YELLOW}可用的网络接口：${NC}"
    
    # LAN口分组
    if ip link show br-lan >/dev/null 2>&1; then
        echo -e "\n${GREEN}LAN口：${NC}"
        local desc=$(get_interface_description "br-lan")
        echo "$i) br-lan${desc:+ - $desc}"
        interface_list="br-lan"
        i=$((i + 1))
    fi
    
    # 无线接口分组
    local wireless_found=0
    for interface in $all_interfaces; do
        if echo "$essid_interfaces" | grep -q "$interface"; then
            if [ $wireless_found -eq 0 ]; then
                echo -e "\n${GREEN}无线接口：${NC}"
                wireless_found=1
            fi
            local desc=$(get_interface_description "$interface")
            echo "$i) $interface${desc:+ - $desc}"
            interface_list="$interface_list $interface"
            i=$((i + 1))
        fi
    done
    
    # 中继接口分组
    local client_found=0
    for interface in $all_interfaces; do
        if echo "$interface" | grep -q "apcli"; then
            if [ $client_found -eq 0 ]; then
                echo -e "\n${GREEN}中继接口：${NC}"
                client_found=1
            fi
            local desc=$(get_interface_description "$interface")
            echo "$i) $interface${desc:+ - $desc}"
            interface_list="$interface_list $interface"
            i=$((i + 1))
        fi
    done
    
    # WAN口分组
    local wan_found=0
    for interface in $all_interfaces; do
        if echo "$wan_interfaces" | grep -q "$interface"; then
            if [ $wan_found -eq 0 ]; then
                echo -e "\n${GREEN}WAN口：${NC}"
                wan_found=1
            fi
            local desc=$(get_interface_description "$interface")
            echo "$i) $interface${desc:+ - $desc}"
            interface_list="$interface_list $interface"
            i=$((i + 1))
        fi
    done
    
    # 其他接口分组
    local other_found=0
    for interface in $all_interfaces; do
        if ! echo "$interface_list" | grep -q "$interface"; then
            if [ $other_found -eq 0 ]; then
                echo -e "\n${GREEN}其他接口：${NC}"
                other_found=1
            fi
            local desc=$(get_interface_description "$interface")
            echo "$i) $interface${desc:+ - $desc}"
            interface_list="$interface_list $interface"
            i=$((i + 1))
        fi
    done
    
    # 清理interface_list，确保没有多余的空格
    interface_list=$(echo "$interface_list" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    
    echo -e "\n${YELLOW}请选择要配置的接口（输入接口编号，多个接口用空格分隔，输入0完成选择）：${NC}"
    
    while true; do
        read -p "> " choices
        
        if [ "$choices" = "0" ]; then
            if [ -z "$selected_interfaces" ]; then
                echo -e "${RED}错误：至少需要选择一个接口${NC}"
                continue
            fi
            break
        fi
        
        local valid=1
        
        for choice in $choices; do
            if ! [ "$choice" -eq "$choice" ] 2>/dev/null; then
                echo -e "${RED}错误：'$choice' 不是有效的数字${NC}"
                valid=0
                break
            fi
            
            # 获取接口名称
            local selected_interface=$(echo "$interface_list" | tr ' ' '\n' | sed -n "${choice}p" | tr -d ' ')
            
            if [ -z "$selected_interface" ]; then
                echo -e "${RED}错误：'$choice' 不是有效的接口编号${NC}"
                valid=0
                break
            fi
            
            # 检查是否已经选择了这个接口
            if echo "$selected_interfaces" | grep -wq "$selected_interface"; then
                echo -e "${YELLOW}接口 $selected_interface 已经被选择，将被移除${NC}"
                selected_interfaces=$(echo "$selected_interfaces" | tr ' ' '\n' | grep -v "^$selected_interface$" | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
            else
                selected_interfaces="$selected_interfaces $selected_interface"
                selected_interfaces=$(echo "$selected_interfaces" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
            fi
        done
        
        if [ $valid -eq 1 ]; then
            echo -e "${GREEN}已选择的接口：${NC}"
            for interface in $selected_interfaces; do
                local desc=$(get_interface_description "$interface")
                echo "* $interface${desc:+ - $desc}"
            done
            echo -e "\n${YELLOW}继续选择其他接口或输入0完成选择${NC}"
        fi
    done
    
    # 将选择的接口写入临时文件
    echo "$selected_interfaces" > /tmp/selected_interfaces
}

# 安装脚本
install_script() {
    echo -e "${YELLOW}开始安装...${NC}"
    
    # 检查必需的命令
    check_dependencies
    
    # 配置接口
    echo -e "\n${YELLOW}配置网络接口...${NC}"
    local selected_interfaces=""
    
    # 获取可用接口
    echo "正在扫描网络接口..."
    
    # 获取所有接口
    local all_interfaces=$(ip link show | grep -E ": eth|: br-|: ra|: ap" | cut -d: -f2 | awk '{print $1}' | sort)
    local essid_interfaces=$(iwinfo | grep "ESSID" | grep -v "unknown" | cut -d" " -f1)
    local wan_interfaces=""
    
    # 检测WAN口
    if command -v uci >/dev/null 2>&1; then
        wan_interfaces=$(uci show network | grep "=wan" | cut -d. -f2 | cut -d= -f1)
    fi
    [ -z "$wan_interfaces" ] && wan_interfaces=$(ip route | grep default | awk '{print $5}' | sort | uniq)
    
    echo -e "\n${YELLOW}请选择接口配置方式：${NC}"
    echo "1) 默认设置（修改br-lan和带ESSID的无线接口）"
    echo "2) 手动选择接口"
    
    read -p "请选择 [1-2]: " interface_choice
    
    if [ "$interface_choice" = "1" ]; then
        # 默认设置
        echo -e "\n使用默认设置..."
        if ip link show br-lan >/dev/null 2>&1; then
            selected_interfaces="br-lan"
            echo "添加 br-lan"
        fi
        if [ -n "$essid_interfaces" ]; then
            for interface in $essid_interfaces; do
                echo "添加带ESSID的无线接口: $interface"
                selected_interfaces="$selected_interfaces $interface"
            done
        fi
        
        # 清理选择的接口列表
        selected_interfaces=$(echo "$selected_interfaces" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
        
        if [ -z "$selected_interfaces" ]; then
            echo -e "${RED}错误：未检测到可配置的默认接口${NC}"
            exit 1
        fi
        
        # 显示将配置的接口
        echo -e "\n${GREEN}将配置以下接口：${NC}"
        for interface in $selected_interfaces; do
            local desc=$(get_interface_description "$interface")
            echo "* $interface${desc:+ - $desc}"
        done
        
        # 确认配置
        echo -e "\n${YELLOW}是否确认使用以上配置？${NC}"
        echo "1) 确认"
        echo "2) 返回手动选择"
        read -p "请选择 [1-2]: " confirm_choice
        
        if [ "$confirm_choice" != "1" ]; then
            interface_choice=2
        fi
    fi
    
    if [ "$interface_choice" = "2" ]; then
        # 手动选择接口
        manual_select_interfaces
        if [ -f /tmp/selected_interfaces ]; then
            selected_interfaces=$(cat /tmp/selected_interfaces)
            rm -f /tmp/selected_interfaces
        else
            echo -e "${RED}错误：接口选择失败${NC}"
            exit 1
        fi
        
        if [ -z "$selected_interfaces" ]; then
            echo -e "${RED}错误：未选择任何接口${NC}"
            exit 1
        fi
    fi
    
    # 询问是否添加WAN口
    if [ -n "$wan_interfaces" ]; then
        echo -e "\n${YELLOW}检测到以下WAN接口：${NC}"
        echo "0) 不添加WAN接口"
        local wan_i=1
        local wan_array=""
        for wan in $wan_interfaces; do
            echo "$wan_i) $wan"
            wan_array="$wan_array $wan"
            wan_i=$((wan_i+1))
        done
        
        read -p "请选择要添加的WAN接口编号 [0-$((wan_i-1))]: " wan_choice
        if [ "$wan_choice" != "0" ] && [ "$wan_choice" -gt 0 ] && [ "$wan_choice" -lt "$wan_i" ]; then
            local wan_interface=$(echo "$wan_array" | tr ' ' '\n' | sed -n "${wan_choice}p" | tr -d ' ')
            if [ -n "$wan_interface" ]; then
                selected_interfaces="$selected_interfaces $wan_interface"
                echo -e "${GREEN}已添加WAN接口: $wan_interface${NC}"
            fi
        fi
    fi
    
    # 去除重复的接口并清理
    selected_interfaces=$(echo "$selected_interfaces" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
    
    echo -e "\n${GREEN}最终选择的接口：${NC}"
    for interface in $selected_interfaces; do
        local desc=$(get_interface_description "$interface")
        echo "* $interface${desc:+ - $desc}"
    done
    
    # 开始安装过程
    echo -e "\n${YELLOW}开始安装过程...${NC}"
    echo "创建配置文件..."
    create_config "$selected_interfaces"
    
    echo "创建主脚本..."
    create_mac_random_script
    
    echo "创建并启用init.d脚本..."
    create_init_script
    /etc/init.d/$INIT_SCRIPT_NAME enable
    
    setup_cron
    
    echo -e "\n${GREEN}安装完成！${NC}"
    echo "您可以通过以下方式使用："
    echo "1. 手动运行：$INSTALL_DIR/$SCRIPT_NAME"
    echo "2. 服务控制：/etc/init.d/$INIT_SCRIPT_NAME {start|stop|restart}"
    
    # 询问是否重启
    ask_reboot
}

# 卸载脚本
uninstall_script() {
    echo -e "${YELLOW}开始卸载...${NC}"
    
    # 停止服务
    if [ -f "$INIT_SCRIPT_PATH" ]; then
        if [ -x "$INIT_SCRIPT_PATH" ]; then
            echo "停止服务..."
            "$INIT_SCRIPT_PATH" stop >/dev/null 2>&1 || true
            "$INIT_SCRIPT_PATH" disable >/dev/null 2>&1 || true
        else
            echo "添加执行权限..."
            chmod +x "$INIT_SCRIPT_PATH"
            echo "停止服务..."
            "$INIT_SCRIPT_PATH" stop >/dev/null 2>&1 || true
            "$INIT_SCRIPT_PATH" disable >/dev/null 2>&1 || true
        fi
        echo "删除启动脚本..."
        rm -f "$INIT_SCRIPT_PATH"
    fi
    
    # 删除主脚本
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        echo "删除主脚本..."
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
    fi
    
    # 删除配置目录
    if [ -d "/etc/mac_random" ]; then
        echo "删除配置目录..."
        rm -rf "/etc/mac_random"
    fi
    
    # 删除定时任务
    if command -v crontab >/dev/null 2>&1; then
        echo "删除定时任务..."
        (crontab -l 2>/dev/null | grep -v "$SCRIPT_NAME" | crontab -) || true
    fi
    
    echo -e "${GREEN}脚本卸载完成${NC}"
    
    # 询问是否重启
    ask_reboot
}

# 询问是否重启
ask_reboot() {
    echo -e "\n${YELLOW}建议重启路由器以确保更改生效${NC}"
    echo "是否现在重启？"
    echo "1) 是"
    echo "2) 否"
    
    while true; do
        read -p "请选择 [1-2]: " choice
        case "$choice" in
            1)
                echo -e "${GREEN}系统将在3秒后重启...${NC}"
                sleep 1
                echo "3..."
                sleep 1
                echo "2..."
                sleep 1
                echo "1..."
                reboot
                break
                ;;
            2)
                echo -e "${YELLOW}请记得稍后手动重启路由器${NC}"
                break
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 显示帮助信息
show_help() {
    cat << EOF
MAC地址随机化脚本安装工具

使用方法: $0 [选项]

选项:
    -h, --help     显示此帮助信息
    -i, --install  安装脚本
    -u, --uninstall 卸载脚本
    
功能说明:
    此脚本用于安装/卸载 MAC 地址随机化服务，支持以下功能：
    
    1. 安装功能:
       - 自动检测并配置网络接口
       - 支持 LAN/WAN/无线接口的 MAC 地址随机化
       - 提供默认配置和手动选择两种配置方式
       - 自动创建启动服务和定时任务
    
    2. 卸载功能:
       - 完全清理所有相关文件和配置
       - 停止并移除系统服务
       - 清理定时任务
    
    3. 接口支持:
       - LAN接口 (br-lan)
       - 无线接口 (ra0, rax0等)
       - WAN接口 (可选)
       - 中继接口 (apcli等)
    
配置文件:
    - 接口配置: $CONFIG_FILE
    - 主程序: $INSTALL_DIR/$SCRIPT_NAME
    - 启动脚本: $INIT_SCRIPT_PATH
    
使用示例:
    1. 交互式安装:
       $0
    
    2. 直接安装:
       $0 --install
    
    3. 卸载:
       $0 --uninstall
    
    4. 帮助:
       $0 --help

注意事项:
    1. 需要 root 权限运行
    2. 建议安装/卸载后重启路由器
    3. 确保系统已安装必要的命令: ip, iwinfo, hexdump

更多信息请访问: https://github.com/cachenow/openwrt-mac-random-changer
EOF
}

# 处理命令行参数
process_args() {
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--install)
            install_script
            exit 0
            ;;
        -u|--uninstall)
            uninstall_script
            exit 0
            ;;
        "")
            # 无参数时显示交互式菜单
            return
            ;;
        *)
            echo -e "${RED}错误：未知选项 $1${NC}"
            echo "使用 -h 或 --help 查看帮助信息"
            exit 1
            ;;
    esac
}

# 显示主菜单
show_menu() {
    while true; do
        echo -e "${YELLOW}MAC地址随机化脚本安装/卸载工具${NC}"
        echo "1) 安装"
        echo "2) 卸载"
        echo "3) 帮助"
        echo "4) 退出"
        read -p "请选择 [1-4]: " choice
        
        case "$choice" in
            1)
                install_script
                break
                ;;
            2)
                uninstall_script
                break
                ;;
            3)
                show_help
                echo -e "\n按回车键继续..."
                read
                ;;
            4)
                echo "退出安装程序"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 主程序
main() {
    check_root
    
    # 处理命令行参数
    process_args "$1"
    
    # 显示交互式菜单
    show_menu
}

# 运行主程序
main "$@"
