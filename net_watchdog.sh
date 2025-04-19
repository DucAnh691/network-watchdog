#!/bin/bash

BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
PING_THRESHOLD=150
LOG_DIR="/var/log/netwatchdog"
SITES=("wop.eton.vn" "dantri.com.vn" "vnexpress.net")
mkdir -p "$LOG_DIR"

send_alert() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" -d text="$message"
}

while true
do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    TODAY=$(date '+%Y-%m-%d')
    LOG_FILE="$LOG_DIR/network_$TODAY.log"
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    GATEWAY_IP=$(ip route | grep default | awk '{print $3}')

    if [[ -z "$GATEWAY_IP" ]]; then
        MESSAGE="❌ [$TIMESTAMP] Không xác định được Gateway trên máy IP $LOCAL_IP"
        echo "$MESSAGE" >> "$LOG_FILE"
        send_alert "$MESSAGE"
        sleep 30
        continue
    fi

    ping -c 2 -W 1 "$GATEWAY_IP" > /dev/null
    if [[ $? -ne 0 ]]; then
        MESSAGE="❌ [$TIMESTAMP] Mất kết nối mạng LAN (ping $GATEWAY_IP thất bại) từ IP $LOCAL_IP"
        echo "$MESSAGE" >> "$LOG_FILE"
        send_alert "$MESSAGE"
        sleep 30
        continue
    fi

    for SITE in "${SITES[@]}"
    do
        PING_RESULT=$(ping -c 3 -q "$SITE")
        if [[ $? -ne 0 ]]; then
            MESSAGE="🚫 [$TIMESTAMP] Không truy cập được $SITE từ IP $LOCAL_IP"
            echo "$MESSAGE" >> "$LOG_FILE"
            send_alert "$MESSAGE"
        else
            AVG_LATENCY=$(echo "$PING_RESULT" | grep 'rtt' | awk -F'/' '{print $5}')
            if (( $(echo "$AVG_LATENCY > $PING_THRESHOLD" | bc -l) )); then
                MESSAGE="⚠️ [$TIMESTAMP] Ping cao ($AVG_LATENCY ms) đến $SITE từ IP $LOCAL_IP"
                echo "$MESSAGE" >> "$LOG_FILE"
                send_alert "$MESSAGE"
            fi
        fi
    done

    sleep 60
done
