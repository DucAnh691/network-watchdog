# Network Watchdog

Tự động kiểm tra kết nối mạng LAN/WiFi và gửi cảnh báo qua Telegram khi có dấu hiệu bất ổn.

# 1.Setup Linux

## Tạo script kiểm tra mạng
Tạo file tại:
/opt/net_watchdog/net_watchdog.sh

## Tạo systemd service
Tạo file service tại:
/etc/systemd/system/net_watchdog.service


## Cài đặt
sudo chmod +x /opt/net_watchdog/net_watchdog.sh 
sudo systemctl daemon-reexec 
sudo systemctl daemon-reload 
sudo systemctl enable net_watchdog.service 
sudo systemctl start net_watchdog.service 

## Kiểm tra hoạt động:
### Xem log
sudo journalctl -u net_watchdog.service -f
### Hoặc:
cat /var/log/netwatchdog/network_$(date '+%Y-%m-%d').log

# 2. Setup Window

## Cài WSL + Ubuntu
wsl --install
sau đó mở Microsoft Store -> Cài Ubuntu

## Mở Ubuntu WSL và setup môi trường
sudo apt update && sudo apt install curl bc -y

## Tạo file script
nano ~/network_watchdog.sh

## Cấp quyền và chạy nền
chmod +x ~/network_watchdog.sh
nohup ~/network_watchdog.sh > ~/watchdog.out 2>&1 &



