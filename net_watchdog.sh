#!/bin/bash

# Token Telegram Bot và Chat ID
BOT_TOKEN="HERE!!!"
CHAT_ID="HERE!!!"

# Đặt ngưỡng ping (ms) để cảnh báo
PING_THRESHOLD=150

# Thư mục lưu log
LOG_DIR="/var/log/netwatchdog"
mkdir -p "$LOG_DIR"

# Các trang web cần kiểm tra
SITES=("wop.eton.vn" "dantri.com.vn" "vnexpress.net")

# Hàm gửi cảnh báo Telegram
send_alert() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
         -d chat_id="$CHAT_ID" -d text="$message"
}

while true
do
    # Lấy timestamp hiện tại
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    TODAY=$(date '+%Y-%m-%d')
    LOG_FILE="$LOG_DIR/network_$TODAY.log"

    # Lấy địa chỉ IP cục bộ và Gateway
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    GATEWAY_IP=$(ip route | grep default | awk '{print $3}')

    # Lấy tên người dùng
    USERNAME=$(whoami)

    # Kiểm tra nếu không có Gateway IP
    if [[ -z "$GATEWAY_IP" ]]; then
        MESSAGE="❌ [$TIMESTAMP] [$USERNAME] Không xác định được Gateway trên máy IP $LOCAL_IP"
        echo "$MESSAGE" >> "$LOG_FILE"
        send_alert "$MESSAGE"
        sleep 30
        continue
    fi

    # Ping Gateway
    PING_RESULT=$(ping -c 2 -W 1 "$GATEWAY_IP")
    if [[ $? -ne 0 ]]; then
        MESSAGE="❌ [$TIMESTAMP] [$USERNAME] Mất kết nối mạng LAN (ping $GATEWAY_IP thất bại) từ IP $LOCAL_IP"
        echo "$MESSAGE" >> "$LOG_FILE"
        send_alert "$MESSAGE"
        sleep 30
        continue
    fi

    # Lấy chỉ số từ kết quả ping (byte, time, TTL)
    BYTE=$(echo "$PING_RESULT" | grep -oP 'bytes=\K\d+')
    TIME=$(echo "$PING_RESULT" | grep -oP 'time=\K[\d.]+')
    TTL=$(echo "$PING_RESULT" | grep -oP 'TTL=\K\d+')

    # Chỉ thông báo byte, time và TTL
    MESSAGE="📊 [$TIMESTAMP] [$USERNAME] Ping tới $GATEWAY_IP thành công. Dữ liệu: bytes=$BYTE time=$TIME ms TTL=$TTL"
    echo "$MESSAGE" >> "$LOG_FILE"
    send_alert "$MESSAGE"

    # Kiểm tra các trang web
    for SITE in "${SITES[@]}"
    do
        PING_RESULT=$(ping -c 3 -q "$SITE")
        if [[ $? -ne 0 ]]; then
            MESSAGE="🚫 [$TIMESTAMP] [$USERNAME] Không truy cập được $SITE từ IP $LOCAL_IP"
            echo "$MESSAGE" >> "$LOG_FILE"
            send_alert "$MESSAGE"
        else
            # Lấy chỉ số từ kết quả ping (byte, time, TTL)
            BYTE=$(echo "$PING_RESULT" | grep -oP 'bytes=\K\d+')
            TIME=$(echo "$PING_RESULT" | grep -oP 'time=\K[\d.]+')
            TTL=$(echo "$PING_RESULT" | grep -oP 'TTL=\K\d+')

            # Chỉ thông báo byte, time và TTL
            MESSAGE="📊 [$TIMESTAMP] [$USERNAME] Ping tới $SITE thành công. Dữ liệu: bytes=$BYTE time=$TIME ms TTL=$TTL"
            echo "$MESSAGE" >> "$LOG_FILE"
            send_alert "$MESSAGE"

            # Kiểm tra độ trễ
            if (( $(echo "$TIME > $PING_THRESHOLD" | bc -l) )); then
                MESSAGE="⚠️ [$TIMESTAMP] [$USERNAME] Ping cao ($TIME ms) đến $SITE từ IP $LOCAL_IP"
                echo "$MESSAGE" >> "$LOG_FILE"
                send_alert "$MESSAGE"
            fi
        fi
    done

    # Chờ 1 phút rồi thực hiện lại
    sleep 60
done
