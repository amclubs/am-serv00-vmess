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

read_vmess_port() {
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

read_nz_variables() {
  if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
      green "使用自定义变量哪吒运行哪吒探针"
      return
  else
      reading "是否需要安装哪吒探针？【y/n】: " nz_choice
      [[ -z $nz_choice ]] && return
      [[ "$nz_choice" != "y" && "$nz_choice" != "Y" ]] && return
      reading "请输入哪吒探针域名或ip：" NEZHA_SERVER
      green "你的哪吒域名为: $NEZHA_SERVER"
      reading "请输入哪吒探针端口（回车跳过默认使用5555）：" NEZHA_PORT
      [[ -z $NEZHA_PORT ]] && NEZHA_PORT="5555"
      green "你的哪吒端口为: $NEZHA_PORT"
      reading "请输入哪吒探针密钥：" NEZHA_KEY
      green "你的哪吒密钥为: $NEZHA_KEY"
  fi
}

install_singbox() {
echo -e "${yellow}本脚本安装vmess协议${purple}(vmess-ws)${re}"
echo -e "${yellow}开始运行前，请确保在面板${purple}已开放1个tcp端口${re}"
echo -e "${yellow}面板${purple}Additional services中的Run your own applications${yellow}已开启为${purplw}Enabled${yellow}状态${re}"
reading "\n确定继续安装吗？【y/n】: " choice
  case "$choice" in
    [Yy])
        cd $WORKDIR
        # read_nz_variables
        read_vmess_port
	argo_configure
        generate_config
        download_singbox && wait
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

argo_configure() {
  if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
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
      # if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
      # 	FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web")
      # else
      	FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot13 bot")
      # fi 
      # FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-sb web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot13 bot" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-swith npm")
  elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
      # if [[ -z $ARGO_AUTH || -z $ARGO_DOMAIN ]]; then
      # 	FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web")
      # else
      	FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-bot bot")
      # fi
      # FILE_INFO=("https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/amd64-web web" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-bot bot" "https://github.com/ansoncloud8/am-serv00-vmess/releases/download/1.0.0/arm64-npm npm")
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
      "path": "/vmess",
      "early_data_header_name": "Sec-WebSocket-Protocol"
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
  if [ -e npm ]; then
    tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
    if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
      NEZHA_TLS="--tls"
    else
      NEZHA_TLS=""
    fi
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
        export TMPDIR=$(pwd)
        nohup ./npm -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
	sleep 2
        pgrep -x "npm" > /dev/null && green "npm is running" || { red "npm is not running, restarting..."; pkill -x "npm" && nohup ./npm -s "${NEZHA_SERVER}:${NEZHA_PORT}" -p "${NEZHA_KEY}" ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2; purple "npm restarted"; }
    else
        purple "NEZHA variable is empty,skiping runing"
    fi
  fi

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
sleep 1
# get ip
IP=$(curl -s ipv4.ip.sb || { ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; })
sleep 1
# get ipinfo
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g') 
sleep 1
# yellow "注意：v2ray或其他软件的跳过证书验证需设置为true,否则hy2或tuic节点可能不通\n"
cat > list.txt <<EOF
vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$ISP\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/vmess?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)

vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$ISP\", \"add\": \"www.visa.com\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)

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
   purple "=== serv00 | AM科技 vmess一键安装脚本 ===\n"
   purple "修改自Serv00|ct8老王sing-box安装脚本"
   purple "根据老王脚本魔改版本，转载请著名出处，请勿滥用\n"
   echo -e "${green}AM科技 YouTube频道    ：${yellow}https://youtube.com/@am_clubs${re}"
   echo -e "${green}AM科技 GitHub仓库     ：${yellow}https://github.com/amclubs${re}"
   echo -e "${green}AM科技 个人博客       ：${yellow}https://amclubs.blogspot.com${re}"
   echo -e "${green}AM科技 TG交流群组     ：${yellow}https://t.me/am_clubs${re}"
   echo -e "${green}AM科技 脚本视频教程   ：${yellow}https://youtu.be/6UZXHfc3zEU${re}"

   green "1. 安装sing-box"
   echo  "==============="
   red "2. 卸载sing-box"
   echo  "==============="
   green "3. 查看节点信息"
   echo  "==============="
   yellow "4. 清理所有进程"
   echo  "==============="
   red "0. 退出脚本"
   echo "==========="
   reading "请输入选择(0-3): " choice
   echo ""
    case "${choice}" in
        1) install_singbox ;;
        2) uninstall_singbox ;; 
        3) cat $WORKDIR/list.txt ;; 
	4) kill_all_tasks ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 3" ;;
    esac
}
menu
