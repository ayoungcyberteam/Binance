#!/bin/bash

echo "🛠️ MULAI SETUP VPS BOT BINANCE..."

# 1. Update & install tools dasar
apt update && apt upgrade -y
apt install -y curl wget git ufw fail2ban htop unzip net-tools python3 python3-pip tmux iptables-persistent mariadb-client python3-venv

# 2. Setup firewall UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

# 3. Tambahkan user non-root + password random
read -p "Masukkan nama user baru (misal adminbot): " NEW_USER
PASSWD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

adduser --disabled-password --gecos "" "$NEW_USER"
echo "${NEW_USER}:${PASSWD}" | chpasswd
usermod -aG sudo $NEW_USER

# 4. Ganti port SSH & nonaktifkan root login
read -p "Masukkan port SSH baru (misal 6969): " NEW_PORT
sed -i "s/#Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config
sed -i "s/Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
ufw allow $NEW_PORT/tcp
systemctl restart sshd

# 5. Aktifkan Fail2Ban
systemctl enable fail2ban
systemctl start fail2ban

# 6. Blok ping/ICMP (stealth)
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
sysctl -p

# 7. Tambahkan aturan iptables anti scan/DDoS ringan
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 50 -j REJECT
netfilter-persistent save

# 8. Install library bot Binance & koneksi database
pip install --upgrade pip
pip install python-binance mysql-connector-python pandas requests

# 9. Buat virtualenv untuk bot (opsional tapi rapi)
su - $NEW_USER -c "python3 -m venv ~/binance-env"
su - $NEW_USER -c "~/binance-env/bin/pip install --upgrade pip"
su - $NEW_USER -c "~/binance-env/bin/pip install python-binance mysql-connector-python pandas requests"

# 10. Output akhir
IPADDR=$(curl -s ifconfig.me)
echo "✅ SETUP SELESAI!"
echo "➡️ username : $NEW_USER"
echo "➡️ password : $PASSWD"
echo "➡️ SSH     : ssh $NEW_USER@$IPADDR -p $NEW_PORT"
echo "➡️ Python ENV : /home/$NEW_USER/binance-env"
echo "➡️ Bot tinggal jalankan di virtualenv tersebut."

echo "#RUN SERVER : bash <(curl -s https://raw.githubusercontent.com/ayoungcyberteam/Binance/refs/heads/main/server.sh)"
