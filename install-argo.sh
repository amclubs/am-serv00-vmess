#!/usr/bin/env bash
set -euo pipefail

# install-argo.sh
# 极简 Cloudflare Tunnel 多域名自动安装脚本
# 支持 Token 或 JSON 凭证输入
# 作者：数字套利*AM

die(){ echo "✖ $*" >&2; exit 1; }
info(){ echo "→ $*"; }

# 是否 root
IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
  IS_ROOT=true
fi

# 定义颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
cyan='\033[1;36m'
bold='\033[1m'
re='\033[0m'

clear
echo -e "${cyan}"
echo "╔══════════════════════════════════════════╗"
echo "║   🚀 数字套利 Cloudflare Argo 安装器        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${re}"

printf "%-18s ${yellow}%s${re}\n"  "${green}📺 YouTube频道："   "https://youtube.com/@am_clubs"
printf "%-18s ${yellow}%s${re}\n"  "${green}💬 Telegram群："    "https://t.me/am_clubs"
printf "%-18s ${yellow}%s${re}\n"  "${green}💻 GitHub仓库："    "https://github.com/amclubs"
printf "%-18s ${yellow}%s${re}\n"  "${green}🌐 Blog博客网站："   "https://amclubss.com"

echo -e "${cyan}──────────────────────────────────────────${re}"

# 菜单主体
echo -e "${bold}${green}1) 安装 Argo Tunnel${re}"
echo -e "${bold}${red}2) 卸载 Argo Tunnel${re}"
echo -e "${bold}${yellow}3) 退出脚本${re}"
echo
# 动效输入箭头
for i in {1..1}; do
  echo -ne "${yellow}→ 请选择操作 (1/2/3): ${re}"
  sleep 0.2
  echo -ne "\r"
  sleep 0.2
done

# ========== 菜单逻辑 ==========
while true; do
  read -r -p "$(echo -e "${yellow}→ 请选择操作 (1/2/3): ${re}")" ACTION
  echo
  case "$ACTION" in
    1)
      echo "🟢 进入安装流程..."
      break
      ;;
    2)
      echo "🔴 进入卸载流程..."
      break
      ;;
    3)
      echo -e "${cyan}👋 已退出脚本。${re}"
      exit 0
      ;;
    *)
      echo -e "${red}✖ 无效选择，请输入 1、2 或 3。${re}"
      ;;
  esac
done


# 确保以 root 权限运行
#if [ "$(id -u)" -ne 0 ]; then
#  die "请以 root 或 sudo 权限运行此脚本。"
#fi

# ===============================================================
# 卸载逻辑
# ===============================================================
if [ "$ACTION" = "2" ]; then
  echo "⚠️ 开始卸载 Cloudflare Argo Tunnel..."

  if $IS_ROOT; then
    SERVICE_FILE="/etc/systemd/system/cloudflared.service"
    CRED_DIR="/root/.cloudflared"
    BIN_PATH="/usr/local/bin/cloudflared"
    systemctl disable --now cloudflared 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload || true
  else
    SERVICE_FILE="$HOME/.config/systemd/user/cloudflared.service"
    CRED_DIR="$HOME/.cloudflared"
    BIN_PATH="$HOME/.local/bin/cloudflared"
    systemctl --user disable --now cloudflared 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload || true
  fi

  rm -rf "$CRED_DIR" "$BIN_PATH"
  echo
  info "✅ 已卸载 Cloudflare Argo Tunnel"
  echo "删除内容："
  echo "  - $SERVICE_FILE"
  echo "  - $CRED_DIR"
  echo "  - $BIN_PATH"
  echo
  exit 0
fi

# ===============================================================
# 安装逻辑
# ===============================================================
# 检测系统类型
if [ -f /etc/alpine-release ]; then
  PKG_MGR="apk"
elif [ -f /etc/debian_version ]; then
  PKG_MGR="apt"
elif [ -f /etc/redhat-release ]; then
  PKG_MGR="yum"
else
  die "不支持的系统类型。"
fi

# 安装必要工具
install_tools(){
  case "$PKG_MGR" in
    apk)
      apk add --no-cache curl wget || true ;;
    apt)
      apt update -y && apt install -y curl wget || true ;;
    yum)
      yum install -y curl wget || true ;;
  esac
}

# 安装 cloudflared
install_cloudflared(){
  if command -v cloudflared >/dev/null 2>&1; then
    info "检测到 cloudflared 已安装。"
    return
  fi
  info "正在安装 cloudflared..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64)  FILE="cloudflared-linux-amd64" ;;
    aarch64|arm64) FILE="cloudflared-linux-arm64" ;;
    *) die "不支持的架构: $ARCH" ;;
  esac
		
  if $IS_ROOT; then
    DEST="/usr/local/bin"
  else
    DEST="$HOME/.local/bin"
    mkdir -p "$DEST"
    # 提示用户将 ~/.local/bin 加入 PATH（脚本不会自动修改 shell 文件）
    info "非 root 模式：cloudflared 将安装到 $DEST 。如果运行报 'cloudflared: command not found'，请将 $DEST 加入你的 PATH（例如在 ~/.profile/ ~/.bashrc 中添加）。"
  fi

  wget -q -O "${DEST}/cloudflared" "https://github.com/cloudflare/cloudflared/releases/latest/download/${FILE}" || die "下载 cloudflared 失败"
  chmod +x "${DEST}/cloudflared"
  info "✅ cloudflared 安装完成： ${DEST}/cloudflared"
}

install_tools
install_cloudflared

# CLOUD_BIN 确认（优先使用已安装的）
if command -v cloudflared >/dev/null 2>&1; then
  CLOUD_BIN="$(command -v cloudflared)"
else
  # fallback to local install path
  CLOUD_BIN="${HOME}/.local/bin/cloudflared"
fi

# 检查版本号
CF_VER="$("$CLOUD_BIN" --version 2>/dev/null | head -n1 | awk '{print $3}' || true)"
if [ -n "$CF_VER" ]; then
  echo "→ 检测到 cloudflared 版本：$CF_VER"
  if echo "$CF_VER" | grep -Eq '^202[4-5]\.'; then
    echo "  ✔ 新版 cloudflared 检测到，将启用新版兼容模式（不使用 --config 参数）"
  else
    echo "  ⚙ 旧版 cloudflared 检测到，将使用传统启动参数（--config）"
  fi
fi
echo

# CRED_DIR 根据是否 root 而定
if $IS_ROOT; then
  CRED_DIR="/root/.cloudflared"
else
  CRED_DIR="${HOME}/.cloudflared"
fi
CONFIG_FILE="$CRED_DIR/config.yml"
TOKEN_FILE="$CRED_DIR/token"
mkdir -p "$CRED_DIR"
chmod 700 "$CRED_DIR"

# 输入域名数量
while true; do
  read -r -p "需要配置多少个域名->端口？(例如 2)： " NUM
  if [[ "$NUM" =~ ^[0-9]+$ ]] && [ "$NUM" -gt 0 ]; then
    break
  else
    echo -e "${red}✖ 请输入有效的数字（必须大于 0）。${re}"
  fi
done

MAPPINGS=""

for i in $(seq 1 "$NUM"); do
  echo
  echo "=== 配置第 $i 个域名 ==="
		while true; do
				read -r -p "请输入要绑定的域名（Public Hostname）： " DOMAIN
				if [[ -n "$DOMAIN" ]]; then
						break
				else
						echo -e "${red}✖ 域名不能为空，请重新输入。${re}"
				fi
		done
  read -r -p "请输入本地监听端口（默认 2053）： " PORT
  PORT=${PORT:-2053}
  read -r -p "请输入 WebSocket 路径（默认 /）： " WS_PATH
  WS_PATH=${WS_PATH:-/}
  [[ "$WS_PATH" != /* ]] && WS_PATH="/$WS_PATH"
  read -r -p "请输入协议类型 (tcp/http/https，默认 http)： " PROTO
  PROTO=${PROTO:-http}
  case "$PROTO" in tcp|http|https) ;; *) PROTO="http" ;; esac
  MAPPINGS="${MAPPINGS}${DOMAIN},${PORT},${WS_PATH},${PROTO}\n"
done

echo
echo "请选择凭证方式："
echo "1) Cloudflare Token（推荐）"
echo "2) credentials JSON（直接粘贴内容）"
read -r -p "选择 (1/2) 默认 1： " MODE
MODE=${MODE:-1}

TUNNEL_TOKEN=""
CREDENTIAL_FILE=""

if [ "$MODE" = "1" ]; then
		while true; do
				read -r -p "请输入 Cloudflare Tunnel Token（以 eyJ 开头）： " TUNNEL_TOKEN
				if [[ -n "$TUNNEL_TOKEN" ]]; then
						break
				else
						echo -e "${red}✖ 必须输入 Token，请重新输入。${re}"
				fi
		done
  printf "%s" "$TUNNEL_TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  info "✅ Token 已保存：$TOKEN_FILE"

else
  while true; do
    echo
    echo "请输入 Cloudflare Tunnel credentials JSON 内容（可多行粘贴，输入完按回车两次结束）"
    echo "---------------------------------------------"
    JSON_CONTENT=""
    while IFS= read -r line; do
      [ -z "$line" ] && break
      JSON_CONTENT="${JSON_CONTENT}${line}\n"
    done
    echo "---------------------------------------------"
    echo "你输入的内容为："
    echo -e "$JSON_CONTENT"
    echo "---------------------------------------------"
    read -r -p "确认保存吗？(1=保存, 2=重新输入)： " CHOICE
    case "$CHOICE" in
      1)
        JSON_FILE_NAME="$(date +%Y%m%d-%H%M%S)-tunnel.json"
        CREDENTIAL_FILE="$CRED_DIR/$JSON_FILE_NAME"
        printf "%b" "$JSON_CONTENT" > "$CREDENTIAL_FILE"
        chmod 600 "$CREDENTIAL_FILE"
        info "✅ 凭证文件已保存：$CREDENTIAL_FILE"
        break
        ;;
      2)
        echo "🔁 重新输入..."
        ;;
      *)
        echo "无效选择，请输入 1 或 2。"
        ;;
    esac
  done
fi

# 生成 config.yml
info "生成配置文件：$CONFIG_FILE"
{
  echo "# Cloudflare Tunnel Auto Generated"
  echo
  echo "ingress:"
  echo -e "$MAPPINGS" | while IFS=',' read -r HOST PORT PATH PROTO; do
    [ -z "$HOST" ] && continue
    case "$PROTO" in
      tcp) SERVICE="tcp://localhost:${PORT}" ;;
      http) SERVICE="http://localhost:${PORT}" ;;
      https) SERVICE="https://localhost:${PORT}" ;;
    esac
    echo "  - hostname: ${HOST}"
    echo "    service: ${SERVICE}"
    echo "    originRequest:"
    echo "      noTLSVerify: true"
    echo "      httpHostHeader: ${HOST}"
    if [ "$PROTO" = "http" ] || [ "$PROTO" = "https" ]; then
      echo "      headers:"
      echo "        Connection: Upgrade"
      echo "        Upgrade: websocket"
    fi
    echo
  done
  echo "  - service: http_status:404"
} > "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"
info "✅ 配置文件写入完成。"

# ---------- 新版 cloudflared 兼容逻辑 ----------
USE_NEW_MODE=false
if "$CLOUD_BIN" tunnel run --help 2>&1 | grep -q -- '--token-file'; then
  USE_NEW_MODE=true
fi

if [ "$MODE" = "1" ]; then
  if [ "$USE_NEW_MODE" = true ]; then
    EXEC_CMD="$CLOUD_BIN tunnel run --token-file ${TOKEN_FILE}"
  else
    TOKEN_CONTENT="$(tr -d '\r\n' < "$TOKEN_FILE")"
    EXEC_CMD="$CLOUD_BIN tunnel run --token ${TOKEN_CONTENT} --config ${CONFIG_FILE}"
  fi
else
  if [ -n "${CREDENTIAL_FILE:-}" ] && [ -f "${CREDENTIAL_FILE}" ]; then
    EXEC_CMD="$CLOUD_BIN tunnel run --credentials-file ${CREDENTIAL_FILE}"
  else
    EXEC_CMD="$CLOUD_BIN tunnel run"
  fi
fi
# ---------- 兼容逻辑 END ----------

# ---------- 根据是否 root 创建 systemd 服务或 user service ----------
if $IS_ROOT; then
  SERVICE_FILE="/etc/systemd/system/cloudflared.service"
  info "生成 systemd 服务文件（system）: $SERVICE_FILE"
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Cloudflare Tunnel Service
After=network-online.target

[Service]
Type=simple
ExecStart=${EXEC_CMD}
Restart=on-failure
RestartSec=5s
User=root
WorkingDirectory=${CRED_DIR}

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now cloudflared || true
  sleep 2
  if systemctl is-active --quiet cloudflared; then
    info "✅ cloudflared system service 启动成功"
  else
   echo -e "\n${red}✖ Cloudflared 启动失败！${re}"
			echo "------------------------------------------------------------"
			echo "可能原因如下："
			echo -e "  ${yellow}[1]${re} 凭证 Token 或 credentials JSON 无效（登录 Cloudflare Zero Trust 检查）"
			echo -e "  ${yellow}[2]${re} config.yml 格式错误（缩进或冒号错位）"
			echo -e "  ${yellow}[3]${re} 端口未开放 / 被占用（检查端口是否被其他进程使用）"
			echo -e "  ${yellow}[4]${re} 网络被防火墙或代理阻断（cloudflared 无法连接 Cloudflare）"
			echo "------------------------------------------------------------"
			echo "📋 快速排查命令："
			echo "  journalctl -u cloudflared -n 50 --no-pager"
			echo "  systemctl status cloudflared"
			echo "------------------------------------------------------------"
			echo -e "❗ 解决后可执行： ${yellow}systemctl restart cloudflared${re}"
			echo
			echo -e "${red}⚠️ 安装未成功，请先排查上述问题后重试。${re}"
			echo
			exit 1
  fi

else
  # 非 root：创建用户级 systemd 单元（~/.config/systemd/user）
  USER_SERVICE_DIR="${HOME}/.config/systemd/user"
  mkdir -p "$USER_SERVICE_DIR"
  SERVICE_FILE="${USER_SERVICE_DIR}/cloudflared.service"
  info "生成 systemd 用户服务文件（user）: $SERVICE_FILE"
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Cloudflare Tunnel Service (user)
After=network-online.target

[Service]
Type=simple
ExecStart=${EXEC_CMD}
Restart=on-failure
RestartSec=5s
WorkingDirectory=${CRED_DIR}

[Install]
WantedBy=default.target
EOF

  # reload user unit files and start (注意：这里使用 --user)
  systemctl --user daemon-reload || true
  systemctl --user enable --now cloudflared || true
  sleep 1
  if systemctl --user is-active --quiet cloudflared; then
    info "✅ cloudflared 用户服务启动成功（systemd --user）"
    echo "注意：要使用户服务在系统重启后无须登录也能运行，请让管理员执行：loginctl enable-linger ${USER}"
    echo "（enable-linger 需要 root 权限，管理员只需执行一次）"
  else
    echo "✖ 用户服务启动失败。可选：使用 nohup 或 crontab @reboot 作为备选："
    echo "  nohup ${EXEC_CMD} >/dev/null 2>&1 &"
    echo "  或者 crontab -e 添加一行：@reboot ${EXEC_CMD} >/dev/null 2>&1"
				echo -e "\n${red}✖ Cloudflared 启动失败！${re}"
				echo "------------------------------------------------------------"
				echo "可能原因如下："
				echo -e "  ${yellow}[1]${re} 凭证 Token 或 credentials JSON 无效（登录 Cloudflare Zero Trust 检查）"
				echo -e "  ${yellow}[2]${re} config.yml 格式错误（缩进或冒号错位）"
				echo -e "  ${yellow}[3]${re} 端口未开放 / 被占用（检查端口是否被其他进程使用）"
				echo -e "  ${yellow}[4]${re} 网络被防火墙或代理阻断（cloudflared 无法连接 Cloudflare）"
				echo "------------------------------------------------------------"
				echo "📋 快速排查命令："
				echo "  journalctl -u cloudflared -n 50 --no-pager"
				echo "  systemctl status cloudflared"
				echo "------------------------------------------------------------"
				echo -e "❗ 解决后可执行： ${yellow}systemctl restart cloudflared${re}"
				echo
				echo -e "${red}⚠️ 安装未成功，请先排查上述问题后重试。${re}"
				echo
				exit 1
  fi
fi

echo
echo -e "${yellow}"
echo "✅安装完成"
echo "=========================================="
echo "config: $CONFIG_FILE"
[ -f "$TOKEN_FILE" ] && echo "token: $TOKEN_FILE"
[ -f "$CREDENTIAL_FILE" ] && echo "凭证: $CREDENTIAL_FILE"
echo
echo "映射列表："
echo -e "$MAPPINGS"
echo
echo "查看日志： journalctl -u cloudflared -f"
echo "重启服务： systemctl restart cloudflared"
echo "重新执行此脚本(选择2)可卸载"
echo "=========================================="
echo -e "${re}"

# final tip for each mapping
echo
echo "===客户端配置与 Zero Trust 面板设置提示==="
echo -e "$MAPPINGS" | while IFS=',' read -r DOMAIN PORT WS_PATH PROTO; do
  [ -z "$DOMAIN" ] && continue
  echo
  echo "💡 域名: ${DOMAIN}"
  echo "  ➤ Cloudflare Zero Trust 面板中添加 Service："
  echo "      Service type: HTTP"
  echo "      URL: http://localhost:${PORT}"
  echo "      Public hostname: ${DOMAIN}"
  echo
  echo "  ➤ v2rayN/v2rayNG 客户端设置示例："
  echo "      传输协议: WebSocket"
  echo "      路径: ${WS_PATH}"
  echo "      地址: ${DOMAIN}"
  echo "      端口: 443 (Cloudflare)"
  echo "      TLS: tls"
  echo
done
echo "=========================================="
echo
