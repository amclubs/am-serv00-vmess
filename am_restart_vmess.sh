#!/bin/bash

# 检查进程是否在运行
pgrep -x "web" > /dev/null

# 如果没有运行，则启动 vmess
if [ $? -ne 0 ]; then
    #nohup /home/${USER}/.vmess/web run -c /home/${USER}/.vmess/config.json >/dev/null 2>&1 &
	nohup /home/${USER}/.vmess/web run -c /home/${USER}/.vmess/config.json > /home/${USER}/.vmess/webtest.log 2>&1 &
fi

# 接收用户传入的参数（端口、字符串或json格式内容）
INPUT_PARAM=$1

# 检查进程是否在运行
pgrep -x "bot" > /dev/null

if [ $? -ne 0 ]; then
    case $INPUT_PARAM in
        # 如果是端口数字，启动第一个命令
        [0-9]*)
            #nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile /home/${USER}/.vmess/boot.log --loglevel info --url http://localhost:$INPUT_PARAM >/dev/null 2>&1 &
			nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile /home/${USER}/.vmess/boot.log --loglevel info --url http://localhost:$INPUT_PARAM > /home/${USER}/.vmess/bottest.log 2>&1 &
            ;;
        # 如果输入的参数是JSON格式，执行json固定隧道保活命令
        *)
            echo "$INPUT_PARAM" | jq empty >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                # JSON格式的内容
                #nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --config tunnel.yml run >/dev/null 2>&1 &
				nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --config tunnel.yml run > /home/${USER}/.vmess/bottest.log 2>&1 &
            else
                # token固定隧道保活命令
                #nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token "$INPUT_PARAM" >/dev/null 2>&1 &
				nohup /home/${USER}/.vmess/bot tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token "$INPUT_PARAM" > /home/${USER}/.vmess/bottest.log 2>&1 &
            fi
            ;;
    esac
fi
