# Network Watchdog

Tự động kiểm tra kết nối mạng LAN/WiFi và gửi cảnh báo qua Telegram khi có dấu hiệu bất ổn.

## Cài đặt

```bash
git clone https://github.com/ten-ban/network-watchdog.git
cd network-watchdog
sudo cp network-watchdog.service /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl enable network-watchdog
sudo systemctl start network-watchdog
