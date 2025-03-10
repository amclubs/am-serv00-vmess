#!/bin/bash

# 定义颜色
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }

USERNAME=$(whoami)
HOSTNAME=$(hostname)

#export UUID=${UUID:-'d36c4d9f-31c4-45f1-8c64-102a6142001e'}
UUID=${1:-'d36c4d9f-31c4-45f1-8c64-102a6142001e'}
export UUID
echo "Using UUID: $UUID"

export NEZHA_SERVER=${NEZHA_SERVER:-''} 
export NEZHA_PORT=${NEZHA_PORT:-'5555'}     
export NEZHA_KEY=${NEZHA_KEY:-''} 
export ARGO_DOMAIN=${ARGO_DOMAIN:-''}   
export ARGO_AUTH=${ARGO_AUTH:-''} 

[[ "$HOSTNAME" == "s1.ct8.pl" ]] && WORKDIR="/home/${USERNAME}/.vmess" || WORKDIR="/home/${USERNAME}/.vmess"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR")


read_ip() {
    echo
    cat ip.txt
    reading "请输入上面可选IP中的任意一个 (回车默认选择): " IP
    if [[ -z "$IP" ]]; then
        IP=$(grep -m 1 "正常" ip.txt | awk -F ':' '{print $1}')
        if [ -z "$IP" ]; then
            IP=$(head -n 1 ip.txt | awk -F ':' '{print $1}')
        fi
    fi
    green "您选择的IP为: $IP"
}

read_ym() {
    echo
    echo "--------------------"
    yellow "1. Cloudflare 默认域名，支持 PROXYIP 变量功能 (推荐)"
    yellow "2. serv00 默认域名 (推荐)"
    yellow "回车默认选择1"
    echo "--------------------"

    reading "请输入reality域名或输入选择 (1-2): " ym

    if [[ -z "$ym" || "$ym" == "1" ]]; then
	ym="cdnjs.cloudflare.com"
    elif [[ "$ym" == "2" ]]; then
	ym="$USERNAME.serv00.net"
    elif [[ "$ym" != "1" && "$ym" != "2" && ! "$ym" =~ ^[a-zA-Z0-9.-]+$ ]]; then
	yellow "无效输入，使用默认 Cloudflare 域名"
	ym="cdnjs.cloudflare.com"
    fi

    green "您的 reality 域名为: $ym"
}

read_uuid() {
    echo
    reading "请输入UUID (回车默认生成): " UUID
    if [[ -z "$UUID" ]]; then
        UUID=$(uuidgen -r)
    fi
    green "您的UUID为: $UUID"
}

read_vless_port() {
    echo
    while true; do
        reading "请输入vless(reality)端口 (面板开放的tcp端口): " vless_port
        if [[ "$vless_port" =~ ^[0-9]+$ ]] && [ "$vless_port" -ge 1 ] && [ "$vless_port" -le 65535 ]; then
            green "你的vless(reality)端口为: $vless_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

read_vmess_port() {
    echo
    while true; do
        reading "请输入vmess端口 (面板开放的tcp端口): " vmess_port
        if [[ "$vmess_port" =~ ^[0-9]+$ ]] && [ "$vmess_port" -ge 1 ] && [ "$vmess_port" -le 65535 ]; then
            green "你的vmess端口为: $vmess_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的TCP端口"
        fi
    done
}

read_hysteria2_port() {
    echo
    while true; do
        reading "请输入hysteria2端口 (面板开放的udp端口): " hysteria2_port
        if [[ "$hysteria2_port" =~ ^[0-9]+$ ]] && [ "$hysteria2_port" -ge 1 ] && [ "$hysteria2_port" -le 65535 ]; then
            green "你的hysteria2端口为: $hysteria2_port"
            break
        else
            yellow "输入错误，请重新输入面板开放的UDP端口"
        fi
    done
}

install_singbox() {
echo -e "${yellow}本脚本安装reality、vmess、hysteria2 三协议节点${re}"
echo -e "${yellow}开始运行前，请确保在面板${purple}已开放 2个tcp端口 1个udp端口${re}"
echo -e "${yellow}请登录面板查看${purple}Additional services中的Run your own applications${yellow}已开启为${purplw}Enabled${yellow}状态${re}"
reading "\n确定继续安装吗？【y/n】: " choice
  case "$choice" in
    [Yy])
        cd $WORKDIR
	read_ip
	read_ym
	read_uuid
	read_vless_port
        read_vmess_port
	read_hysteria2_port
	download_singbox && wait
	argo_configure
        generate_config
        run_sb && sleep 3
        get_links
      ;;
    [Nn]) exit 0 ;;
    *) red "无效的选择，请输入y或n" && menu ;;
  esac
}

uninstall_singbox() {
  reading "\n确定要卸载吗？【y/n】: " choice
    case "$choice" in
       [Yy])
          kill -9 $(ps aux | grep '[w]eb' | awk '{print $2}')
          kill -9 $(ps aux | grep '[b]ot' | awk '{print $2}')
          # kill -9 $(ps aux | grep '[n]pm' | awk '{print $2}')
          rm -rf $WORKDIR
          ;;
        [Nn]) exit 0 ;;
    	*) red "无效的选择，请输入y或n" && menu ;;
    esac
}

kill_all_tasks() {
reading "\n清理所有进程将退出ssh连接，确定继续清理吗？【y/n】: " choice
  case "$choice" in
    [Yy]) killall -9 -u $(whoami) ;;
       *) menu ;;
  esac
}

get_ip_info() {
    sn=$(echo "$HOSTNAME" | cut -d '.' -f 1 | tr -d 's')
    mc=("$HOSTNAME" "cache$sn.serv00.com" "web$sn.serv00.com")
    rm -rf $WORKDIR/ip.txt

    for mc_item in "${mc[@]}"; do
        response=$(curl -s "https://pl.amclub.us.kg/api/data?hostname=$mc_item")
        
        if [[ -z "$response" || "$response" == *unknown* ]]; then
            # 如果API请求失败，尝试DNS解析
            for ip in "${mc[@]}"; do
                dig @8.8.8.8 +time=2 +short $ip >> $WORKDIR/ip.txt
                sleep 1
            done
            break
        else
            # 使用 jq 解析JSON数据并获取第一个IP
            ip=$(echo "$response" | jq -r '.[0].ip')
            status=$(echo "$response" | jq -r '.[0].status')
            
            if [[ "$status" == "Unblocked" ]]; then
                echo "$ip: 正常"  >> $WORKDIR/ip.txt
            else
                echo "$ip: 已墙"  >> $WORKDIR/ip.txt
            fi
        fi
    done
}

system_initialize() {
reading "\nserv00系统初始化，清理所有进程并清空所有安装应用，将退出ssh连接，确定继续清理吗？【y/n】: " choice
  case "$choice" in
    [Yy]) 
    killall -9 -u $(whoami)
    find ~ -type f -exec chmod 644 {} \; 2>/dev/null
    find ~ -type d -exec chmod 755 {} \; 2>/dev/null
    find ~ -type f -exec rm -f {} \; 2>/dev/null
    find ~ -type d -empty -exec rmdir {} \; 2>/dev/null
    find ~ -exec rm -rf {} \; 2>/dev/null
    ;;
    *) menu ;;
  esac
}

argo_configure() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
		    echo
      reading "是否需要使用固定argo隧道？【y/n】: " argo_choice
      [[ -z $argo_choice ]] && return
      [[ "$argo_choice" != "y" && "$argo_choice" != "Y" && "$argo_choice" != "n" && "$argo_choice" != "N" ]] && { red "无效的选择，请输入y或n"; return; }
      if [[ "$argo_choice" == "y" || "$argo_choice" == "Y" ]]; then
          # 读取 ARGO_DOMAIN 变量
          while [[ -z $ARGO_DOMAIN ]]; do
            reading "请输入argo固定隧道域名: " ARGO_DOMAIN
            if [[ -z $ARGO_DOMAIN ]]; then
                red "ARGO固定隧道域名不能为空，请重新输入。"
            else
                green "你的argo固定隧道域名为: $ARGO_DOMAIN"
            fi
          done
        
          # 读取 ARGO_AUTH 变量
          while [[ -z $ARGO_AUTH ]]; do
										  echo
            reading "请输入argo固定隧道密钥（Json或Token）: " ARGO_AUTH
            if [[ -z $ARGO_AUTH ]]; then
                red "ARGO固定隧道密钥不能为空，请重新输入。"
            else
                green "你的argo固定隧道密钥为: $ARGO_AUTH"
            fi
          done           
	  # reading "请输入argo固定隧道域名: " ARGO_DOMAIN
   #        green "你的argo固定隧道域名为: $ARGO_DOMAIN"
   #        reading "请输入argo固定隧道密钥（Json或Token）: " ARGO_AUTH
   #        green "你的argo固定隧道密钥为: $ARGO_AUTH"
			echo
	  echo -e "${red}注意：${purple}使用token，需要在cloudflare后台设置隧道端口和面板开放的tcp端口一致${re}"
      else
          green "ARGO隧道变量未设置，将使用临时隧道"
          return
      fi
  fi

  if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$ARGO_AUTH")
credentials-file: tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:$vmess_port
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    green "ARGO_AUTH mismatch TunnelSecret,use token connect to tunnel"
  fi
}

# Download Dependency Files
download_singbox() {
  ARCH=$(uname -m) && DOWNLOAD_DIR="." && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
  if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
      	FILE_INFO=("https://github.com/amclubs/am-serv00-vmess/releases/download/1.0.0/arm64-sb web" "https://github.com/amclubs/am-serv00-vmess/releases/download/1.0.0/arm64-bot13 bot")
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
      	FILE_INFO=("https://github.com/amclubs/am-serv00-vmess/releases/download/1.0.0/amd64-web web" "https://github.com/amclubs/am-serv00-vmess/releases/download/1.0.0/amd64-bot bot")
  else
      echo "Unsupported architecture: $ARCH"
      exit 1
  fi
  for entry in "${FILE_INFO[@]}"; do
      URL=$(echo "$entry" | cut -d ' ' -f 1)
      NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
      FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"
      if [ -e "$FILENAME" ]; then
          green "$FILENAME already exists, Skipping download"
      else
          wget -q -O "$FILENAME" "$URL"
          green "Downloading $FILENAME"
      fi
      chmod +x $FILENAME
  done
}

# Generating Configuration Files
generate_config() {

output=$(./web generate reality-keypair)
private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
echo "${private_key}" > private_key.txt
echo "${public_key}" > public_key.txt

openssl ecparam -genkey -name prime256v1 -out "private.key"
openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME.serv00.net"

  cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-openai"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "server": "wireguard"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
    "inbounds": [
   {
	"tag": "vless-reality-in",
	"type": "vless",
	"listen": "::",
	"listen_port": $vless_port,
	"users": [
		{
			"uuid": "$UUID",
			"flow": "xtls-rprx-vision"
		}
	],
	"tls": {
		"enabled": true,
		"server_name": "$ym",
		"reality": {
			"enabled": true,
			"handshake": {
				"server": "$ym",
				"server_port": 443
			},
			"private_key": "$private_key",
			"short_id": [
					""
			]
		}
	}
    },
    {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmess_port,
      "users": [
      {
        "uuid": "$UUID"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "/vmess-argo",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
				{
       "tag": "hysteria2-in",
       "type": "hysteria2",
       "listen": "$IP",
       "listen_port": $hysteria2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    }
 ],
    "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "162.159.195.142",
      "server_port": 4198,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:83c7:b31f:5858:b3a8:c6b1/128"
      ],
      "private_key": "mPZo+V9qlrMGCZ7+E6z2NI6NOV34PD++TpAR09PtCWI=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [
        26,
        21,
        228
      ]
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-openai"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-netflix"
        ],
        "outbound": "wireguard-out"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-netflix.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-openai",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/openai.srs",
        "download_detour": "direct"
      },      
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
   },
   "experimental": {
      "cache_file": {
      "path": "cache.db",
      "cache_id": "mycacheid",
      "store_fakeip": true
    }
  }
}
EOF
}

# running files
run_sb() {
  if [ -e web ]; then
    nohup ./web run -c config.json >/dev/null 2>&1 &
    sleep 2
    pgrep -x "web" > /dev/null && green "web is running" || { red "web is not running, restarting..."; pkill -x "web" && nohup ./web run -c config.json >/dev/null 2>&1 & sleep 2; purple "web restarted"; }
  fi

  if [ -e bot ]; then
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
    elif [[ $ARGO_AUTH =~ TunnelSecret ]]; then
      args="tunnel --edge-ip-version auto --config tunnel.yml run"
    else
      args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
    fi
    nohup ./bot $args >/dev/null 2>&1 &
    sleep 2
    pgrep -x "bot" > /dev/null && green "bot is running" || { red "bot is not running, restarting..."; pkill -x "bot" && nohup ./bot "${args}" >/dev/null 2>&1 & sleep 2; purple "bot restarted"; }
  fi
  
}

get_links(){
  
  get_argodomain() {
    if [[ -n $ARGO_AUTH ]]; then
      echo "$ARGO_DOMAIN"
    else
      grep -oE 'https://[[:alnum:]+\.-]+\.trycloudflare\.com' boot.log | sed 's@https://@@'
    fi
  }
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgoDomain:\e[1;35m${argodomain}\e[0m\n"
if [ -z ${argodomain} ]; then
red "Argo域名生成失败，Argo节点不可用，可卸载重新安装"
fi
sleep 1
# get ip
#IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
#sleep 1
# get ipinfo
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g') 
get_name() { if [ "$HOSTNAME" = "s1.ct8.pl" ]; then SERVER="CT8"; else SERVER=$(echo "$HOSTNAME" | cut -d '.' -f 1); fi; echo "$SERVER"; }
NAME="$ISP-$(get_name)"

sleep 1
# yellow "注意：v2ray或其他软件的跳过证书验证需设置为true,否则hy2或tuic节点可能不通\n"
rm -rf tmp.txt
vless_link="vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$ym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$NAME-vless-reality"
echo "$vless_link" >> tmp.txt
vmess_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/vmess-argo?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmess_link" >> tmp.txt
vmess_argo_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws-argo\", \"add\": \"visa.cn\", \"port\": \"80\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess-argo?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vmess_argo_link" >> tmp.txt
vmess_argo_tls_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$NAME-vmess-ws-tls-argo\", \"add\": \"time.is\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess-argo?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmess_argo_tls_link" >> tmp.txt
hysteria2_link="hysteria2://$UUID@$IP:$hysteria2_port?sni=www.bing.com&alpn=h3&insecure=1#$NAME-hysteria2"
echo "$hysteria2_link" >> tmp.txt
url=$(cat tmp.txt 2>/dev/null)
baseurl=$(echo -e "$url" | base64 -w 0)
echo

cat > list.txt <<EOF
======================================================
1、vless-reality节点（如果是Cloudflare域名，支持 PROXYIP 变量功能，如果serv00的IP被墙，此节点不可用）：
$vless_link

2、vmess节点（如果想使用CF的CDN端口回源(需域名)，客户端地址可修改优选IP/域名，7个80系端口随便换，被墙也能用）：
$vmess_link

3、vmess_argo节点（CF的隧道节点，客户端地址可修改优选IP/域名，7个80系端口随便换，被墙也能用）：
$vmess_argo_link

4、vmess_argo_tls节点（CF的隧道节点，客户端地址可修改优选IP/域名，6个443系端口随便换，被墙也能用）：
$vmess_argo_tls_link

5、hysteria2节点：
$hysteria2_link

6、所有节点信息：
$baseurl

======================================================
EOF
cat list.txt
purple "list.txt saved successfully"
purple "Running done!"
sleep 3 
# rm -rf web bot npm boot.log config.json sb.log core tunnel.yml tunnel.json
}


#主菜单
menu() {
    clear
    echo ""
    purple "=== serv00 | reality、vmess、hysteria2 三协议节点 一键安装脚本 ===\n"
    purple "修改自Serv00|ct8老王sing-box安装脚本"
    purple "根据老王脚本魔改版本，转载请著名出处，请勿滥用\n"
    echo -e "${green}AM科技 YouTube频道    ：${yellow}https://youtube.com/@am_clubs${re}"
    echo -e "${green}AM科技 GitHub仓库     ：${yellow}https://github.com/amclubs${re}"
    echo -e "${green}AM科技 个人博客       ：${yellow}https://amclubs.blogspot.com${re}"
    echo -e "${green}AM科技 TG交流群组     ：${yellow}https://t.me/am_clubs${re}"
    echo -e "${green}AM科技 脚本视频教程   ：${yellow}https://youtu.be/2B5yN09Wd_s${re}"
    echo   "==============="
    green  "1. 安装sing-box(reality、vmess、hysteria2)"
    echo   "==============="
    red    "2. 卸载sing-box"
    echo   "==============="
    green  "3. 查看节点信息"
    echo   "==============="
    yellow "4. 清理所有进程"
    echo   "==============="
    red    "5. serv00系统初始化"
    echo   "==============="
    red    "0. 退出脚本"
    echo   "==============="
    echo   "获取serv00服务器IP中......请稍等"
    echo   "--------------------"
    get_ip_info
    sn=$(hostname | awk -F '.' '{print $1}')
    green "serv00名称：$sn"
    green "可选IP如下(已墙的IP在Argo和CDN回源节点、PROXYIP变量都是可用)："
    cat $WORKDIR/ip.txt
    echo "--------------------"

    # 用户输入选择
    reading "请输入选择(0-5): " choice
    echo ""
    
    # 根据用户选择执行对应操作
    case "$choice" in
        1) install_singbox ;;
        2) uninstall_singbox ;;
        3) cat $WORKDIR/list.txt ;;
        4) kill_all_tasks ;;
        5) system_initialize ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 5" ;;
    esac
}


menu
