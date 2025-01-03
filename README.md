# connect-vps-openvpn-tunnel
اتصال دو سرور مجازی با OpenVPN برای تونلینگ ترافیک و افزایش امنیت. مناسب برای تغییر مسیر ترافیک و بهبود امنیت شبکه با نصب و پیکربندی آسان.
برای تونل کردن ارتباط دو سرور مجازی که هر دو دارای OpenVPN هستند، می‌توانید از یک پیکربندی کلاینت-سرور استفاده کنید که سرور اول به عنوان کلاینت و سرور دوم به عنوان سرور عمل کند. در زیر یک اسکریپت برای تنظیم این پیکربندی آورده شده است:

### اسکریپت تنظیم OpenVPN برای اتصال دو سرور
```bash
#!/bin/bash

# Variables
SERVER1_IP="IP_SERVER_1" # آدرس IP سرور 1
SERVER2_IP="IP_SERVER_2" # آدرس IP سرور 2
OPENVPN_PORT=1194        # پورت OpenVPN

# Install OpenVPN on both servers
echo "Installing OpenVPN on both servers..."
ssh root@$SERVER1_IP "apt update && apt install -y openvpn easy-rsa"
ssh root@$SERVER2_IP "apt update && apt install -y openvpn easy-rsa"

# Configure Server 2 as OpenVPN Server
echo "Configuring Server 2 as OpenVPN server..."
ssh root@$SERVER2_IP <<EOF
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
./easyrsa gen-crl
cp pki/ca.crt pki/dh.pem pki/private/server.key pki/issued/server.crt /etc/openvpn/
cat > /etc/openvpn/server.conf <<EOL
port $OPENVPN_PORT
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"
keepalive 10 120
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOL
systemctl enable openvpn@server
systemctl start openvpn@server
EOF

# Configure Server 1 as OpenVPN Client
echo "Configuring Server 1 as OpenVPN client..."
ssh root@$SERVER2_IP "cat /etc/openvpn/pki/ca.crt" > ca.crt
scp root@$SERVER1_IP:/etc/openvpn/easy-rsa/pki/private/client.key client.key
scp root@$SERVER1_IP:/etc/openvpn/easy-rsa/pki/issued/client.crt client.crt
ssh root@$SERVER1_IP <<EOF
cat > /etc/openvpn/client.conf <<EOL
client
dev tun
proto udp
remote $SERVER2_IP $OPENVPN_PORT
ca /etc/openvpn/ca.crt
cert /etc/openvpn/client.crt
key /etc/openvpn/client.key
persist-key
persist-tun
redirect-gateway def1
verb 3
EOL
systemctl enable openvpn@client
systemctl start openvpn@client
EOF

echo "OpenVPN setup completed. Server 1 is now tunneling traffic to Server 2."
```

### توضیحات
1. **سرور ۲ به عنوان OpenVPN سرور**:
   - فایل‌های کلیدی ایجاد می‌شود و سرویس OpenVPN به عنوان سرور تنظیم می‌گردد.
   - از آدرس آی‌پی سرور ۲ به عنوان مقصد استفاده می‌شود.

2. **سرور ۱ به عنوان OpenVPN کلاینت**:
   - کلیدهای مورد نیاز دریافت می‌شود و اتصال به سرور ۲ برقرار می‌شود.

3. **تونل ترافیک**:
   - سرور ۱ تمام ترافیک را از طریق تونل به سرور ۲ ارسال می‌کند.

4. **پورت‌ها و تنظیمات شبکه**:
   - از پورت UDP 1194 به عنوان پیش‌فرض استفاده شده است. در صورت نیاز، می‌توانید پورت دیگری را تنظیم کنید.

5. **اجرا**:
   - اسکریپت را در سیستم محلی خود ذخیره کرده و اجرا کنید. این اسکریپت به صورت خودکار تمام مراحل نصب و پیکربندی را انجام می‌دهد. 

برای اجرای این اسکریپت نیاز به دسترسی SSH به هر دو سرور دارید. همچنین اطمینان حاصل کنید که پورت‌های مربوطه در فایروال باز هستند.

برای اجرای اسکریپت، مراحل زیر را دنبال کنید:

1. **ایجاد فایل اسکریپت**  
ابتدا محتوای اسکریپت را در یک فایل ذخیره کنید. مثلاً فایل را با نام `setup_openvpn.sh` ایجاد کنید:
```bash
nano setup_openvpn.sh
```
سپس کد اسکریپت را در فایل قرار دهید و آن را ذخیره کنید.

---

2. **اعطای دسترسی اجرایی به اسکریپت**  
باید فایل را قابل اجرا کنید. دستور زیر را وارد کنید:
```bash
chmod +x setup_openvpn.sh
```

---

3. **اجرای اسکریپت**  
اکنون می‌توانید اسکریپت را اجرا کنید:
```bash
./setup_openvpn.sh
```

---

4. **ورود اطلاعات مورد نیاز**  
در اسکریپت، مقادیر متغیرهایی مانند `SERVER1_IP` و `SERVER2_IP` را با آدرس‌های IP سرورهای خود جایگزین کنید.

برای ویرایش این مقادیر، می‌توانید فایل اسکریپت را دوباره باز کرده و تغییرات لازم را انجام دهید:
```bash
nano setup_openvpn.sh
```

---

5. **نکته مهم درباره دسترسی SSH**  
اطمینان حاصل کنید که:
- امکان اتصال SSH به هر دو سرور وجود دارد.
- پورت 1194 (یا هر پورتی که در اسکریپت استفاده کرده‌اید) در فایروال باز است.

---

**نکته:** اگر مشکلی در اجرای اسکریپت وجود داشت، خروجی خطا را بررسی کنید و مطمئن شوید که تمامی پیش‌نیازها نصب شده‌اند.

در صورت نیاز به راهنمایی در تلگرام پیام دهید : @v2makers_admin
