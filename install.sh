#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}严重错误: ${plain} 请使用 root 权限运行此脚本 \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "未能检测到系统操作系统，请联系作者！" >&2
    exit 1
fi
echo "操作系统版本为: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}不支持的 CPU 架构! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "架构: $(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "arch" ]]; then
    echo "您的操作系统是 Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "您的操作系统是 Parch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "您的操作系统是 Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "您的操作系统是 Armbian"
elif [[ "${release}" == "alpine" ]]; then
    echo "您的操作系统是 Alpine Linux"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "您的操作系统是 OpenSUSE Tumbleweed"
elif [[ "${release}" == "openEuler" ]]; then
    if [[ ${os_version} -lt 2203 ]]; then
        echo -e "${red} 请使用 OpenEuler 22.03 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 CentOS 8 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 2004 ]]; then
        echo -e "${red} 请使用 Ubuntu 20 或更高版本!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} 请使用 Fedora 36 或更高版本!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "amzn" ]]; then
    if [[ ${os_version} != "2023" ]]; then
        echo -e "${red} 请使用 Amazon Linux 2023!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} 请使用 Debian 11 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 80 ]]; then
        echo -e "${red} 请使用 AlmaLinux 8.0 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 Rocky Linux 8 或更高版本 ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ol" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} 请使用 Oracle Linux 8 或更高版本 ${plain}\n" && exit 1
    fi
else
    echo -e "${red}您的操作系统不受此脚本支持。${plain}\n"
    echo "请确保您正在使用以下支持的操作系统之一:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- OpenEuler 22.03+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 8.0+"
    echo "- Rocky Linux 8+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    echo "- Amazon Linux 2023"
    exit 1
fi

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')

    # Get IPv4 address
    ipv4_address=$(curl -s https://api.ipify.org)
    if [[ -z "$ipv4_address" ]]; then
        ipv4_address="获取 IPv4 失败"
    fi

    # Get IPv6 address (try multiple methods for better compatibility)
    ipv6_address=$(curl -s -6 https://api6.ipify.org)
    if [[ -z "$ipv6_address" ]]; then
        ipv6_address=$(ip -6 addr show | grep "global dynamic" | awk '{print $2}' | cut -d'/' -f1 2>/dev/null)
    fi
    if [[ -z "$ipv6_address" ]]; then
        ipv6_address="未检测到 IPv6 地址"
    fi


    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            # Force panel to listen on localhost and a fixed port
            local config_port="58964" # You can choose any port, just make sure it's not commonly used.
            local config_address="127.0.0.1"

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}" -address "${config_address}"
            echo -e "这是一个全新安装，为了安全考虑，正在生成随机登录信息:"
            echo -e "###############################################"
            echo -e "${green}用户名: ${config_username}${plain}"
            echo -e "${green}密码: ${config_password}${plain}"
            echo -e "${green}端口 (仅本地访问): ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}面板已配置为仅监听本地主机以确保安全。${plain}"

            echo -e "${green}IPv4 地址: ${ipv4_address}${plain}"
            if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${green}IPv6 地址: ${ipv6_address}${plain}"
            fi

            echo -e "${green}访问 URL (通过 SSH 隧道或 HTTPS):${plain}"
            echo -e "${green}  IPv4: ${ipv4_address}:${config_port}/${config_webBasePath}${plain} (需要设置 SSH 隧道或 HTTPS)${plain}"
            if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${green}  IPv6: [${ipv6_address}]:${config_port}/${config_webBasePath}${plain} (需要设置 SSH 隧道或 HTTPS)${plain}"
            fi

            echo -e "###############################################"
            echo -e "${yellow}如果您忘记了登录信息，可以输入 'x-ui settings' 查看${plain}"
            echo -e "${yellow}要远程访问面板，您必须设置 SSH 隧道或配置 HTTPS。${plain}"

            echo -e "${yellow}对于 IPv4 SSH 隧道，请在本地终端中使用命令: ${blue}ssh -L ${config_port}:localhost:${config_port} root@${ipv4_address}${plain}${plain}。"
            echo -e "${yellow}然后，在本地浏览器中通过: ${blue}http://localhost:${config_port}/${config_webBasePath}${plain} 访问面板。${plain}"

            if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${yellow}对于 IPv6 SSH 隧道，请在本地终端中使用命令: ${blue}ssh -6 -L ${config_port}:localhost:${config_port} root@${ipv6_address}${plain}${plain}。"
                echo -e "${yellow}然后，在本地浏览器中通过: ${blue}http://[::1]:${config_port}/${config_webBasePath}${plain} 或 ${blue}http://localhost:${config_port}/${config_webBasePath}${plain} 访问面板。${plain}"
            fi

            echo -e "${yellow}请参考 x-ui 文档获取 HTTPS 设置说明。${plain}"

        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}WebBasePath 缺失或太短。正在生成新的...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}新的 WebBasePath: ${config_webBasePath}${plain}"

            echo -e "${green}IPv4 地址: ${ipv4_address}${plain}"
            if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${green}IPv6 地址: ${ipv6_address}${plain}"
            fi

            echo -e "${green}访问 URL (通过 SSH 隧道或 HTTPS):${plain}"
            echo -e "${green}  IPv4: https://${ipv4_address}:${existing_port}/${config_webBasePath}${plain} (需要设置 SSH 隧道或 HTTPS)${plain}"
            if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${green}  IPv6: https://[${ipv6_address}]:${existing_port}/${config_webBasePath}${plain} (需要设置 SSH 隧道或 HTTPS)${plain}"
            fi


            echo -e "${yellow}面板已配置为仅监听本地主机以确保安全。远程访问需要 SSH 隧道或 HTTPS。${plain}"

            echo -e "${yellow}对于 IPv4 SSH 隧道，请在本地终端中使用命令: ${blue}ssh -L ${existing_port}:localhost:${existing_port} root@${ipv4_address}${plain}${plain}。"
            echo -e "${yellow}然后，在本地浏览器中通过: ${blue}http://localhost:${existing_port}/${config_webBasePath}${plain} 访问面板。${plain}"

             if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
                echo -e "${yellow}对于 IPv6 SSH 隧道，请在本地终端中使用命令: ${blue}ssh -6 -L ${existing_port}:localhost:${existing_port} root@${ipv6_address}${plain}${plain}。"
                echo -e "${yellow}然后，在本地浏览器中通过: ${blue}http://[::1]:${existing_port}/${config_webBasePath}${plain} 或 ${blue}http://localhost:${existing_port}/${config_webBasePath}${plain} 访问面板。${plain}"
            fi

            echo -e "${yellow}请参考 x-ui 文档获取 HTTPS 设置说明。${plain}"
        fi
    else
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}检测到默认凭据。需要进行安全更新...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "已生成新的随机登录凭据:"
            echo -e "###############################################"
            echo -e "${green}用户名: ${config_username}${plain}"
            echo -e "${green}密码: ${config_password}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}如果您忘记了登录信息，可以输入 'x-ui settings' 查看${plain}"
            echo -e "${yellow}面板已配置为仅监听本地主机以确保安全。如果尚未配置远程访问，则需要 SSH 隧道或 HTTPS。${plain}"
        else
            echo -e "${green}用户名、密码和 WebBasePath 已正确设置。面板正在监听本地主机。退出...${plain}"
            echo -e "${green}面板已配置为仅监听本地主机以确保安全。如果尚未配置远程访问，则需要 SSH 隧道或 HTTPS。${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        tag_version=$(curl -Ls "https://api.github.com/repos/TachibanaKaze/4x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$tag_version" ]]; then
            echo -e "${red}无法获取 x-ui 版本，可能是由于 GitHub API 限制，请稍后重试${plain}"
            exit 1
        fi
        echo -e "已获取 x-ui 最新版本: ${tag_version}，开始安装..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/TachibanaKaze/4x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保您的服务器可以访问 GitHub ${plain}"
            exit 1
        fi
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.3.5"

        if [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]]; then
            echo -e "${red}请使用更新的版本 (至少 v2.3.5)。正在退出安装。${plain}"
            exit 1
        fi

        url="https://github.com/TachibanaKaze/4x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "开始安装 x-ui $1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui $1 失败，请检查版本是否存在 ${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    # Check the system's architecture and rename the file accordingly
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/TachibanaKaze/4x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} 安装完成，正在运行中...${plain}"
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui 控制菜单用法 (子命令):${plain}              │
│                                                       │
│  ${blue}x-ui${plain}              - 管理脚本                  │
│  ${blue}x-ui start${plain}        - 启动                            │
│  ${blue}x-ui stop${plain}         - 停止                             │
│  ${blue}x-ui restart${plain}      - 重启                          │
│  ${blue}x-ui status${plain}       - 当前状态                   │
│  ${blue}x-ui settings${plain}     - 当前设置                 │
│  ${blue}x-ui enable${plain}       - 开机自启                     │
│  ${blue}x-ui disable${plain}      - 关闭开机自启                │
│  ${blue}x-ui log${plain}          - 查看日志                       │
│  ${blue}x-ui banlog${plain}       - 查看 Fail2ban 封禁日志          │
│  ${blue}x-ui update${plain}       - 更新                           │
│  ${blue}x-ui legacy${plain}       - legacy 版本                   │
│  ${blue}x-ui install${plain}      - 安装                          │
│  ${blue}x-ui uninstall${plain}    - 卸载                        │
└───────────────────────────────────────────────────────┘"

    echo -e "${yellow}对于 SSH 端口转发 (本地端口转发 - Recommended):${plain}"

    echo -e "${yellow}IPv4:${plain}"
    echo -e "${yellow}  请在您的本地终端中使用以下命令来创建 IPv4 SSH 隧道:${plain} "
    echo -e "${blue}  ssh -L 58964:localhost:${existing_port} root@${ipv4_address}${plain}"
    echo -e "${yellow}  之后，在您的本地浏览器中访问面板，地址为:${plain}"
    echo -e "${blue}  http://localhost:58964${existing_webBasePath}${plain}"

    if [[ "$ipv6_address" != "未检测到 IPv6 地址" ]]; then
        echo -e ""
        echo -e "${yellow}IPv6:${plain}"
        echo -e "${yellow}  请在您的本地终端中使用以下命令来创建 IPv6 SSH 隧道:${plain} "
        echo -e "${blue}  ssh -6 -L 58964:localhost:${existing_port} root@${ipv6_address}${plain}"
        echo -e "${yellow}  之后，在您的本地浏览器中访问面板，地址为 (任选其一):${plain}"
        echo -e "${blue}  http://[::1]:58964${existing_webBasePath}${plain}"
        echo -e "${blue}  http://localhost:58964${existing_webBasePath}${plain}"
    fi

    echo -e "${yellow} (请将 '58964' 替换为您本地机器上想要使用的端口，例如 2222 或 58964)${plain}"
    echo -e "${yellow} (如果您设置了 WebBasePath，请在 URL 中附加 WebBasePath)${plain}"
}

echo -e "${green}运行中...${plain}"
install_base
install_x-ui $1
